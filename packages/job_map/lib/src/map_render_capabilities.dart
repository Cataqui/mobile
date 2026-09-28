import 'package:flutter/foundation.dart';
import 'package:job_map/src/enums/map_thermal_state.dart';

@immutable
final class MapRenderCapabilities {
  const MapRenderCapabilities({
    required this.lowMemory,
    required this.availableMemoryBytes,
    required this.totalMemoryBytes,
    required this.processorCount,
    required this.thermalState,
    required this.maxRendererSlots,
    this.lowRamDevice = false,
  });

  factory MapRenderCapabilities.fromMap(Map<Object?, Object?> values) {
    final lowMemory = values['lowMemory'];
    final lowRamDevice = values['lowRamDevice'];
    final availableMemoryBytes = values['availableMemoryBytes'];
    final totalMemoryBytes = values['totalMemoryBytes'];
    final processorCount = values['processorCount'];
    final thermalState = values['thermalState'];
    final maxRendererSlots = values['maxRendererSlots'];
    if (lowMemory is! bool ||
        lowRamDevice is! bool ||
        availableMemoryBytes is! int ||
        availableMemoryBytes < 0 ||
        totalMemoryBytes is! int ||
        totalMemoryBytes <= 0 ||
        processorCount is! int ||
        processorCount <= 0 ||
        thermalState is! int ||
        thermalState < 0 ||
        thermalState > 3 ||
        maxRendererSlots is! int ||
        maxRendererSlots <= 0) {
      throw const FormatException('Invalid native map rendering capabilities');
    }
    return MapRenderCapabilities(
      lowMemory: lowMemory,
      lowRamDevice: lowRamDevice,
      availableMemoryBytes: availableMemoryBytes,
      totalMemoryBytes: totalMemoryBytes,
      processorCount: processorCount,
      thermalState: MapThermalState.values[thermalState],
      maxRendererSlots: maxRendererSlots,
    );
  }

  final bool lowMemory;
  final bool lowRamDevice;
  final int availableMemoryBytes;
  final int totalMemoryBytes;
  final int processorCount;
  final MapThermalState thermalState;
  final int maxRendererSlots;
}
