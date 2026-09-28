package com.cataqui.job_map

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.view.ViewGroup
import android.widget.FrameLayout
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.GoogleMapOptions
import com.google.android.gms.maps.MapView
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.CircleOptions
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MapStyleOptions
import io.flutter.view.TextureRegistry
import java.util.concurrent.Executors
import kotlin.math.roundToInt

class JobMapFramesBridge(
    private val activity: Activity,
    private val textureRegistry: TextureRegistry,
) : JobMapHostApi {
    private data class Scene(
        val widthPx: Int,
        val heightPx: Int,
        val widthPoints: Double,
        val heightPoints: Double,
        val nativeScale: Double,
        val previewScale: Double,
        val cameraLatitude: Double,
        val cameraLongitude: Double,
        val locationLatitude: Double,
        val locationLongitude: Double,
        val zoom: Double,
        val radiusMeters: Double,
        val radiusColorArgb: Int,
        val backgroundColorArgb: Int,
        val paddingBottomPoints: Double,
        val styleJson: String?,
    )

    private data class RenderRequest(
        val scene: Scene,
        val callback: (Result<NativeMapFrames>) -> Unit,
        var captureInProgress: Boolean = false,
        var frameDelivered: Boolean = false,
        var finalCaptureAttempts: Int = 0,
        var texture: TextureRegistry.SurfaceProducer? = null,
        var previewTexture: TextureRegistry.SurfaceProducer? = null,
        @Volatile var cancelled: Boolean = false,
    )

    private val mainHandler = Handler(Looper.getMainLooper())
    private val frameCopyExecutor = Executors.newSingleThreadExecutor()
    private val bitmapPaint = Paint(Paint.FILTER_BITMAP_FLAG)
    private val mapViews = arrayOfNulls<MapView>(2)
    private val googleMaps = arrayOfNulls<GoogleMap>(2)
    private val mapStyles = arrayOfNulls<String>(2)
    private val mapBackgroundColors = arrayOfNulls<Int>(2)
    private val mapHasRendered = BooleanArray(2)
    private val mapHasCircle = BooleanArray(2)
    private val pendingRenders = arrayOfNulls<RenderRequest>(2)
    private val frameTextures = mutableMapOf<Long, TextureRegistry.SurfaceProducer>()
    private var started = false
    private var resumed = false
    private var closed = false

    override fun readRenderCapabilities(): NativeMapCapabilities {
        val activityManager = activity.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        val thermalStatus = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            (activity.getSystemService(Context.POWER_SERVICE) as PowerManager).currentThermalStatus
        } else {
            PowerManager.THERMAL_STATUS_NONE
        }
        val thermalState = when {
            thermalStatus >= PowerManager.THERMAL_STATUS_CRITICAL -> 3
            thermalStatus >= PowerManager.THERMAL_STATUS_SEVERE -> 2
            thermalStatus >= PowerManager.THERMAL_STATUS_MODERATE -> 1
            else -> 0
        }
        return NativeMapCapabilities(
            lowMemory = memoryInfo.lowMemory,
            lowRamDevice = activityManager.isLowRamDevice,
            availableMemoryBytes = memoryInfo.availMem,
            totalMemoryBytes = memoryInfo.totalMem,
            processorCount = Runtime.getRuntime().availableProcessors().coerceAtLeast(1).toLong(),
            thermalState = thermalState.toLong(),
            maxRendererSlots = mapViews.size.toLong(),
        )
    }

    private fun readScene(args: NativeMapRenderRequest): Scene {
        val scene = Scene(
            widthPx = args.widthPx.toInt(),
            heightPx = args.heightPx.toInt(),
            widthPoints = args.widthPoints,
            heightPoints = args.heightPoints,
            nativeScale = args.nativeScale,
            previewScale = args.previewScale,
            cameraLatitude = args.cameraLatitude,
            cameraLongitude = args.cameraLongitude,
            locationLatitude = args.locationLatitude,
            locationLongitude = args.locationLongitude,
            zoom = args.zoom,
            radiusMeters = args.radiusMeters,
            radiusColorArgb = args.radiusColorArgb.toInt(),
            backgroundColorArgb = args.backgroundColorArgb.toInt(),
            paddingBottomPoints = args.paddingBottomPoints,
            styleJson = args.styleJson,
        )
        require(scene.widthPx > 0 && scene.heightPx > 0)
        require(scene.widthPoints > 0 && scene.heightPoints > 0)
        require(scene.nativeScale == 1.0 || scene.nativeScale == 0.5 || scene.nativeScale == 0.25)
        require(scene.previewScale > 0 && scene.previewScale <= scene.nativeScale)
        require(scene.cameraLatitude in -90.0..90.0 && scene.cameraLongitude in -180.0..180.0)
        require(scene.locationLatitude in -90.0..90.0 && scene.locationLongitude in -180.0..180.0)
        require(scene.zoom >= 0 && scene.radiusMeters >= 0 && scene.paddingBottomPoints >= 0)
        return scene
    }

    override fun render(request: NativeMapRenderRequest, callback: (Result<NativeMapFrames>) -> Unit) {
        if (closed) {
            callback(Result.failure(FlutterError("closed", "Map frame bridge is closed")))
            return
        }
        val slot = request.rendererSlot.toInt()
        require(slot in mapViews.indices) { "rendererSlot must be 0 or 1" }
        val renderRequest = RenderRequest(
            scene = readScene(request),
            callback = callback,
        )
        pendingRenders[slot]?.let { previous ->
            previous.cancelled = true
            if (!previous.frameDelivered) {
                previous.callback(Result.failure(FlutterError("superseded", "A newer map frame was requested")))
            }
        }
        pendingRenders[slot] = renderRequest
        val view = mapViews[slot]
        if (
            view == null ||
            mapBackgroundColors[slot] != renderRequest.scene.backgroundColorArgb ||
            (mapHasRendered[slot] && mapStyles[slot] != renderRequest.scene.styleJson)
        ) {
            if (view != null) destroyMapView(slot)
            createMapView(slot, renderRequest.scene)
        } else {
            resizeMapView(view, renderRequest.scene)
            renderWhenLaidOut(slot, view, renderRequest)
        }
        mainHandler.postDelayed({
            if (pendingRenders[slot] !== renderRequest) return@postDelayed
            pendingRenders[slot] = null
            renderRequest.cancelled = true
            if (!renderRequest.frameDelivered) {
                releaseRequestTextures(renderRequest)
                renderRequest.callback(Result.failure(FlutterError("mapTimeout", "Google Maps did not finish loading")))
            }
        }, 8000)
    }

    private fun createMapView(slot: Int, scene: Scene) {
        val camera = CameraPosition.builder()
            .target(LatLng(scene.cameraLatitude, scene.cameraLongitude))
            .zoom((scene.zoom - if (scene.nativeScale == 0.25) 2.0 else if (scene.nativeScale == 0.5) 1.0 else 0.0).toFloat())
            .build()
        val view = MapView(
            activity,
            GoogleMapOptions().liteMode(true).camera(camera).backgroundColor(scene.backgroundColorArgb),
        )
        mapViews[slot] = view
        mapBackgroundColors[slot] = scene.backgroundColorArgb
        mapHasRendered[slot] = false
        mapHasCircle[slot] = false
        val root = activity.findViewById<FrameLayout>(android.R.id.content)
        root.addView(view, 0, FrameLayout.LayoutParams(viewWidth(scene), viewHeight(scene)))
        view.onCreate(null)
        if (started) view.onStart()
        if (resumed) view.onResume()
        view.getMapAsync { map ->
            if (mapViews[slot] !== view) return@getMapAsync
            googleMaps[slot] = map
            map.mapType = GoogleMap.MAP_TYPE_NORMAL
            map.isIndoorEnabled = false
            map.isBuildingsEnabled = false
            map.uiSettings.isCompassEnabled = false
            map.uiSettings.isMapToolbarEnabled = false
            map.uiSettings.isZoomControlsEnabled = false
            pendingRenders[slot]?.let { renderWhenLaidOut(slot, view, it) }
        }
    }

    private fun viewWidth(scene: Scene): Int =
        (scene.widthPoints * activity.resources.displayMetrics.density * scene.nativeScale).toInt().coerceAtLeast(1)

    private fun viewHeight(scene: Scene): Int =
        (scene.heightPoints * activity.resources.displayMetrics.density * scene.nativeScale).toInt().coerceAtLeast(1)

    private fun resizeMapView(view: MapView, scene: Scene) {
        val width = viewWidth(scene)
        val height = viewHeight(scene)
        if (view.layoutParams.width == width && view.layoutParams.height == height) return
        view.layoutParams = FrameLayout.LayoutParams(width, height)
    }

    private fun renderWhenLaidOut(slot: Int, view: MapView, request: RenderRequest) {
        if (googleMaps[slot] == null) return
        view.post {
            if (pendingRenders[slot] !== request || mapViews[slot] !== view) return@post
            if (view.width != viewWidth(request.scene) || view.height != viewHeight(request.scene)) {
                view.post { renderWhenLaidOut(slot, view, request) }
                return@post
            }
            renderOnMap(slot, request)
        }
    }

    private fun renderOnMap(slot: Int, request: RenderRequest) {
        val map = googleMaps[slot] ?: return
        val scene = request.scene
        mapHasRendered[slot] = true
        if (mapStyles[slot] != scene.styleJson) {
            val style = scene.styleJson?.let(::MapStyleOptions)
            if (!map.setMapStyle(style)) {
                pendingRenders[slot] = null
                request.callback(Result.failure(FlutterError("mapStyle", "Google Maps rejected the map style")))
                return
            }
            mapStyles[slot] = scene.styleJson
        }
        val padding = (scene.paddingBottomPoints * viewHeight(scene) / scene.heightPoints).toInt()
        map.setPadding(0, 0, 0, padding)
        if (mapHasCircle[slot]) {
            map.clear()
            mapHasCircle[slot] = false
        }
        if (scene.radiusMeters > 0) {
            map.addCircle(
                CircleOptions()
                    .center(LatLng(scene.locationLatitude, scene.locationLongitude))
                    .radius(scene.radiusMeters)
                    .fillColor(scene.radiusColorArgb)
                    .strokeColor(Color.TRANSPARENT)
                    .strokeWidth(0f),
            )
            mapHasCircle[slot] = true
        }
        map.moveCamera(
            CameraUpdateFactory.newCameraPosition(
                CameraPosition.builder()
                    .target(LatLng(scene.cameraLatitude, scene.cameraLongitude))
                    .zoom((scene.zoom - if (scene.nativeScale == 0.25) 2.0 else if (scene.nativeScale == 0.5) 1.0 else 0.0).toFloat())
                    .build(),
            ),
        )
        map.setOnMapLoadedCallback {
            if (pendingRenders[slot] === request && googleMaps[slot] === map) {
                captureMap(slot, request)
            }
        }
    }

    private fun captureMap(slot: Int, request: RenderRequest) {
        if (request.captureInProgress) return
        val map = googleMaps[slot] ?: return
        request.captureInProgress = true
        map.snapshot { bitmap ->
            if (bitmap == null) {
                request.captureInProgress = false
                if (pendingRenders[slot] === request) retryCapture(slot, request)
                return@snapshot
            }
            if (pendingRenders[slot] !== request) {
                bitmap.recycle()
                return@snapshot
            }
            val texture = request.texture?.takeIf { frameTextures[it.id()] === it }
                ?: if (request.frameDelivered) null else textureRegistry.createSurfaceProducer().also {
                    it.setSize(request.scene.widthPx, request.scene.heightPx)
                    frameTextures[it.id()] = it
                    request.texture = it
                }
            val previewWidthPx = (request.scene.widthPoints * request.scene.previewScale).roundToInt()
                .coerceIn(1, request.scene.widthPx)
            val previewHeightPx = (request.scene.heightPoints * request.scene.previewScale).roundToInt()
                .coerceIn(1, request.scene.heightPx)
            val previewTexture = request.previewTexture?.takeIf { frameTextures[it.id()] === it }
                ?: if (request.frameDelivered) null else textureRegistry.createSurfaceProducer().also {
                    it.setSize(previewWidthPx, previewHeightPx)
                    frameTextures[it.id()] = it
                    request.previewTexture = it
                }
            if (texture == null && previewTexture == null) {
                bitmap.recycle()
                request.captureInProgress = false
                pendingRenders[slot] = null
                return@snapshot
            }
            frameCopyExecutor.execute {
                try {
                    if (request.cancelled) {
                        bitmap.recycle()
                        mainHandler.post {
                            if (!request.frameDelivered) releaseRequestTextures(request)
                        }
                        return@execute
                    }
                    if (texture != null) {
                        copyBitmapToTexture(bitmap, texture, request.scene.widthPx, request.scene.heightPx)
                    }
                    if (previewTexture != null) {
                        copyBitmapToTexture(bitmap, previewTexture, previewWidthPx, previewHeightPx)
                    }
                    bitmap.recycle()
                    mainHandler.post {
                        if (pendingRenders[slot] === request) {
                            request.captureInProgress = false
                            if (!request.frameDelivered) {
                                request.frameDelivered = true
                                request.callback(
                                    Result.success(
                                        NativeMapFrames(
                                            textureId = texture!!.id(),
                                            widthPx = request.scene.widthPx.toLong(),
                                            heightPx = request.scene.heightPx.toLong(),
                                            previewTextureId = previewTexture!!.id(),
                                            previewWidthPx = previewWidthPx.toLong(),
                                            previewHeightPx = previewHeightPx.toLong(),
                                            isFinal = true,
                                        ),
                                    ),
                                )
                            }
                            pendingRenders[slot] = null
                        } else if (!request.frameDelivered) {
                            releaseRequestTextures(request)
                        }
                    }
                } catch (error: Exception) {
                    bitmap.recycle()
                    mainHandler.post {
                        request.captureInProgress = false
                        if (pendingRenders[slot] === request) {
                            if (!request.frameDelivered) releaseRequestTextures(request)
                            pendingRenders[slot] = null
                            if (!request.frameDelivered) {
                                request.callback(Result.failure(FlutterError("frameCopy", error.message)))
                            }
                        } else if (!request.frameDelivered) {
                            releaseRequestTextures(request)
                        }
                    }
                }
            }
        }
    }

    private fun retryCapture(slot: Int, request: RenderRequest) {
        request.finalCaptureAttempts++
        if (request.finalCaptureAttempts <= 5) {
            mainHandler.postDelayed({
                if (pendingRenders[slot] === request) captureMap(slot, request)
            }, 150L * request.finalCaptureAttempts)
            return
        }
        pendingRenders[slot] = null
        if (!request.frameDelivered) {
            releaseRequestTextures(request)
            request.callback(Result.failure(FlutterError("mapSnapshot", "Google Maps returned no usable frame")))
        }
    }

    private fun copyBitmapToTexture(
        bitmap: Bitmap,
        texture: TextureRegistry.SurfaceProducer,
        widthPx: Int,
        heightPx: Int,
    ) {
        val surface = texture.surface
        val canvas: Canvas = surface.lockCanvas(null)
        try {
            canvas.drawBitmap(bitmap, null, Rect(0, 0, widthPx, heightPx), bitmapPaint)
        } finally {
            surface.unlockCanvasAndPost(canvas)
        }
    }

    private fun releaseRequestTextures(request: RenderRequest) {
        request.texture?.let(::releaseTrackedTexture)
        request.previewTexture?.let(::releaseTrackedTexture)
        request.texture = null
        request.previewTexture = null
    }

    private fun releaseTrackedTexture(texture: TextureRegistry.SurfaceProducer) {
        if (frameTextures[texture.id()] !== texture) return
        frameTextures.remove(texture.id())
        releaseTexturesAfterCopies(listOf(texture))
    }

    private fun releaseTexturesAfterCopies(textures: List<TextureRegistry.SurfaceProducer>) {
        if (textures.isEmpty()) return
        // A queued bitmap copy may still be drawing into one of these surfaces.
        frameCopyExecutor.execute {
            mainHandler.post { textures.forEach(TextureRegistry.SurfaceProducer::release) }
        }
    }

    private fun destroyMapView(slot: Int) {
        googleMaps[slot] = null
        mapStyles[slot] = null
        mapBackgroundColors[slot] = null
        mapHasRendered[slot] = false
        mapHasCircle[slot] = false
        val view = mapViews[slot] ?: return
        mapViews[slot] = null
        if (resumed) view.onPause()
        if (started) view.onStop()
        view.onDestroy()
        (view.parent as? ViewGroup)?.removeView(view)
    }

    override fun releaseTexture(textureId: Long) {
        frameTextures.remove(textureId)?.let { releaseTexturesAfterCopies(listOf(it)) }
    }

    override fun setScrollActive(active: Boolean, allowReadyPreview: Boolean) {}

    override fun disposeFrames() {
        for (slot in mapViews.indices) {
            pendingRenders[slot]?.let { request ->
                request.cancelled = true
                if (!request.frameDelivered) request.callback(Result.failure(FlutterError("disposed", "Map frame renderer was disposed")))
            }
            pendingRenders[slot] = null
            destroyMapView(slot)
        }
        val textures = frameTextures.values.toList()
        frameTextures.clear()
        releaseTexturesAfterCopies(textures)
    }

    fun onStart() {
        started = true
        mapViews.filterNotNull().forEach(MapView::onStart)
    }

    fun onResume() {
        resumed = true
        mapViews.filterNotNull().forEach(MapView::onResume)
    }

    fun onPause() {
        resumed = false
        mapViews.filterNotNull().forEach(MapView::onPause)
    }

    fun onStop() {
        started = false
        mapViews.filterNotNull().forEach(MapView::onStop)
    }

    fun onLowMemory() {
        mapViews.filterNotNull().forEach(MapView::onLowMemory)
    }

    fun close() {
        closed = true
        disposeFrames()
        frameCopyExecutor.shutdown()
    }
}
