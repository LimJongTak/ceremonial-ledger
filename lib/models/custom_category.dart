class CustomCategory {
  final String emoji;
  final String label;

  const CustomCategory({required this.emoji, required this.label});

  /// SharedPreferences 저장 키: "emoji|label"
  String get key => '$emoji|$label';

  factory CustomCategory.fromKey(String key) {
    final idx = key.indexOf('|');
    if (idx == -1) return CustomCategory(emoji: '📝', label: key);
    return CustomCategory(
      emoji: key.substring(0, idx),
      label: key.substring(idx + 1),
    );
  }
}
