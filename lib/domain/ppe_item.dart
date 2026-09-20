import 'package:flutter/material.dart';

/// Personal protective equipment the detector can recognise.
enum PpeItem {
  helmet('Helmet', Icons.engineering_rounded),
  vest('Safety vest', Icons.checkroom_rounded),
  gloves('Gloves', Icons.back_hand_rounded),
  boots('Safety boots', Icons.hiking_rounded),
  goggles('Goggles', Icons.visibility_rounded),
  mask('Face mask', Icons.masks_rounded)
  ;

  const PpeItem(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Default equipment required on site.
  static const Set<PpeItem> defaults = {helmet, vest, gloves, boots};
}
