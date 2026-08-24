import 'package:flutter/material.dart';

/// Represents a searchable entry in the settings.
class SettingsEntry {
  final String id;
  final String title;
  final String subtitle;
  final List<String> keywords;
  final IconData icon;
  final String route;

  const SettingsEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    this.keywords = const [],
    required this.icon,
    required this.route,
  });
}
