enum TaxonomyType {
  category,
  disease;

  static TaxonomyType fromString(String value) {
    return TaxonomyType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaxonomyType.category,
    );
  }
}
