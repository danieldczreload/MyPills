import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';

/// Family of Android OEM customisations that affect background work and
/// notifications. Used to drive setup-instruction UX (battery killers,
/// auto-launch toggles) per fabricator.
///
/// Reference: https://dontkillmyapp.com/
enum OemFamily {
  /// Near-stock Android (Pixel, Motorola, Nokia, …). No special setup needed.
  stock,

  /// Samsung One UI. Generally well-behaved; only the standard
  /// `ignoreBatteryOptimizations` request is needed, no dialog.
  samsung,

  /// Huawei + Honor. PowerGenie + App Launch manual mode.
  huawei,

  /// Xiaomi / Redmi / POCO (MIUI / HyperOS). Aggressive autostart blocking.
  xiaomi,

  /// OPPO / Realme (ColorOS). Similar to Xiaomi.
  oppo,

  /// Vivo / iQOO (FunTouch / OriginOS). Aggressive background limits.
  vivo,

  /// OnePlus (OxygenOS, ColorOS-based on newer versions).
  oneplus;

  /// Whether this family requires the user to walk through manual settings
  /// beyond the standard battery-optimization permission.
  bool get needsManualSetup => switch (this) {
    OemFamily.stock || OemFamily.samsung => false,
    _ => true,
  };
}

/// Lightweight wrapper that exposes the Android manufacturer / OEM family.
class DeviceManufacturerInfo {
  DeviceManufacturerInfo({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  String? _cachedManufacturer;
  OemFamily? _cachedFamily;

  Future<String> _manufacturer() async {
    if (_cachedManufacturer != null) return _cachedManufacturer!;
    if (!Platform.isAndroid) return _cachedManufacturer = '';
    final info = await _plugin.androidInfo;
    return _cachedManufacturer = info.manufacturer.toLowerCase();
  }

  Future<OemFamily> detectOem() async {
    if (_cachedFamily != null) return _cachedFamily!;
    final m = await _manufacturer();
    if (m.isEmpty) return _cachedFamily = OemFamily.stock;

    if (m.contains('huawei') || m.contains('honor')) {
      return _cachedFamily = OemFamily.huawei;
    }
    if (m.contains('xiaomi') ||
        m.contains('redmi') ||
        m.contains('poco')) {
      return _cachedFamily = OemFamily.xiaomi;
    }
    if (m.contains('oppo') || m.contains('realme')) {
      return _cachedFamily = OemFamily.oppo;
    }
    if (m.contains('vivo') || m.contains('iqoo')) {
      return _cachedFamily = OemFamily.vivo;
    }
    if (m.contains('oneplus')) {
      return _cachedFamily = OemFamily.oneplus;
    }
    if (m.contains('samsung')) {
      return _cachedFamily = OemFamily.samsung;
    }
    return _cachedFamily = OemFamily.stock;
  }
}
