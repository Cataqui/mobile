package com.cataqui.job_map

import android.content.ComponentCallbacks2
import android.content.Context
import android.content.res.Configuration
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter

class JobMapPlugin : FlutterPlugin, ActivityAware, DefaultLifecycleObserver, ComponentCallbacks2 {
    private var engineBinding: FlutterPlugin.FlutterPluginBinding? = null
    private var lifecycle: Lifecycle? = null
    private var bridge: JobMapFramesBridge? = null
    private var flutterApi: JobMapFlutterApi? = null
    private var applicationContext: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        engineBinding = binding
        applicationContext = binding.applicationContext.also { it.registerComponentCallbacks(this) }
        flutterApi = JobMapFlutterApi(binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        detachActivity()
        applicationContext?.unregisterComponentCallbacks(this)
        applicationContext = null
        flutterApi = null
        engineBinding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        val engine = engineBinding ?: return
        bridge = JobMapFramesBridge(binding.activity, engine.textureRegistry)
        JobMapHostApi.setUp(engine.binaryMessenger, bridge)
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding).also { it.addObserver(this) }
    }

    override fun onDetachedFromActivityForConfigChanges() = detachActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)

    override fun onDetachedFromActivity() = detachActivity()

    private fun detachActivity() {
        lifecycle?.removeObserver(this)
        lifecycle = null
        val engine = engineBinding
        if (engine != null) JobMapHostApi.setUp(engine.binaryMessenger, null)
        bridge?.close()
        bridge = null
        flutterApi?.rendererReset { }
    }

    override fun onStart(owner: LifecycleOwner) {
        bridge?.onStart()
    }

    override fun onResume(owner: LifecycleOwner) {
        bridge?.onResume()
    }

    override fun onPause(owner: LifecycleOwner) {
        bridge?.onPause()
    }

    override fun onStop(owner: LifecycleOwner) {
        bridge?.onStop()
    }

    override fun onTrimMemory(level: Int) {
        if (level >= ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW) bridge?.onLowMemory()
    }

    override fun onLowMemory() {
        bridge?.onLowMemory()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {}
}
