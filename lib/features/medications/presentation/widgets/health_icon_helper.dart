import 'package:flutter/material.dart';

class HealthIconHelper {
  static IconData getIconData(String name) {
    switch (name) {
      case 'heart':
        return Icons.favorite;
      case 'pills':
        return Icons.medication;
      case 'bandage':
        return Icons.healing;
      case 'respiratory':
        return Icons.air;
      case 'stomach':
        return Icons.restaurant;
      case 'blood_pressure':
        return Icons.monitor_heart;
      case 'brain':
        return Icons.psychology;
      case 'eye':
        return Icons.visibility;
      default:
        return Icons.favorite;
    }
  }
}
