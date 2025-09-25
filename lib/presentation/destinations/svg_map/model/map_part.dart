class MapPart {
  final String id;
  final String pathData;
  Map<String, String> attributes;

  MapPart({
    required this.id,
    required this.pathData,
    required this.attributes,
  });

  String get name => attributes['name'] ?? id;

  // Get all custom attributes (those starting with custom_)
  Map<String, String> get customAttributes {
    return Map.fromEntries(
        attributes.entries.where((entry) => entry.key.startsWith('custom_')));
  }

  // Get the single custom attribute if it exists
  MapEntry<String, String>? get singleCustomAttribute {
    final customAttrs = customAttributes;
    return customAttrs.isNotEmpty ? customAttrs.entries.first : null;
  }

  // Check if this part has a custom attribute
  bool get hasCustomAttribute {
    return customAttributes.isNotEmpty;
  }

  // Get non-custom attributes
  Map<String, String> get standardAttributes {
    return Map.fromEntries(
        attributes.entries.where((entry) => !entry.key.startsWith('custom_')));
  }
}