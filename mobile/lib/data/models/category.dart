import 'package:flutter/material.dart';

/// A task category with a display colour, mirroring the API's category shape.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.colorHex,
    this.deletedAt,
  });

  final String id;
  final String name;

  /// Hex string like '#22C55E'.
  final String colorHex;

  /// Non-null when soft-deleted (surfaced via sync); such rows are hidden in UI.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// Parse the hex string into a Flutter [Color]. Falls back to a neutral colour.
  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    final value = int.tryParse('FF$hex', radix: 16);
    return value == null ? const Color(0xFF6C63FF) : Color(value);
  }

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        colorHex: json['color'] as String? ?? '#6C63FF',
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
      );
}
