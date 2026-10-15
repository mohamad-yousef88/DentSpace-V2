import 'package:flutter/material.dart';

/// Canonical list of tool categories.
///
/// The backend stores `category` as free text, so we write the English
/// `key` on create and translate on display. If an existing tool has a
/// non-catalogue string, we render it as-is (graceful fallback).
class ToolCategory {
  const ToolCategory({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
  });

  final String key;
  final String nameAr;
  final String nameEn;
  final IconData icon;

  String labelFor({required bool isArabic}) => isArabic ? nameAr : nameEn;
}

const List<ToolCategory> kToolCategories = [
  ToolCategory(
    key: 'diagnostic',
    nameAr: 'أدوات تشخيص',
    nameEn: 'Diagnostic',
    icon: Icons.search_rounded,
  ),
  ToolCategory(
    key: 'surgery',
    nameAr: 'أدوات جراحة',
    nameEn: 'Surgery',
    icon: Icons.medical_services_outlined,
  ),
  ToolCategory(
    key: 'filling',
    nameAr: 'حشو وترميم',
    nameEn: 'Filling & Restoration',
    icon: Icons.build_circle_outlined,
  ),
  ToolCategory(
    key: 'ortho',
    nameAr: 'تقويم',
    nameEn: 'Orthodontics',
    icon: Icons.straighten_rounded,
  ),
  ToolCategory(
    key: 'sterilization',
    nameAr: 'تعقيم',
    nameEn: 'Sterilization',
    icon: Icons.sanitizer_outlined,
  ),
  ToolCategory(
    key: 'xray',
    nameAr: 'أشعة',
    nameEn: 'X-Ray',
    icon: Icons.center_focus_strong_rounded,
  ),
  ToolCategory(
    key: 'other',
    nameAr: 'أخرى',
    nameEn: 'Other',
    icon: Icons.category_outlined,
  ),
];

/// Returns the category by key, or `null` when not found.
ToolCategory? toolCategoryByKey(String? key) {
  if (key == null) return null;
  for (final c in kToolCategories) {
    if (c.key == key) return c;
  }
  return null;
}

/// Translates a category value. Falls back to the raw string.
String translateToolCategory(String raw, {required bool isArabic}) {
  final hit = toolCategoryByKey(raw);
  return hit?.labelFor(isArabic: isArabic) ?? raw;
}

// ═══════════════════════════════════════════════════════════════
// Conditions
// ═══════════════════════════════════════════════════════════════
class ToolCondition {
  const ToolCondition({
    required this.key,
    required this.nameAr,
    required this.nameEn,
  });

  final String key;
  final String nameAr;
  final String nameEn;

  String labelFor({required bool isArabic}) => isArabic ? nameAr : nameEn;
}

const List<ToolCondition> kToolConditions = [
  ToolCondition(key: 'new', nameAr: 'جديد', nameEn: 'New'),
  ToolCondition(key: 'like_new', nameAr: 'شبه جديد', nameEn: 'Like new'),
  ToolCondition(key: 'good', nameAr: 'جيد', nameEn: 'Good'),
  ToolCondition(key: 'fair', nameAr: 'مقبول', nameEn: 'Fair'),
];

ToolCondition? toolConditionByKey(String? key) {
  if (key == null) return null;
  for (final c in kToolConditions) {
    if (c.key == key) return c;
  }
  return null;
}

String translateToolCondition(String raw, {required bool isArabic}) {
  final hit = toolConditionByKey(raw);
  return hit?.labelFor(isArabic: isArabic) ?? raw;
}