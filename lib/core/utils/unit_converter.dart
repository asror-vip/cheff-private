class UnitConverter {
  /// Converts [quantity] from [fromUnit] to [toUnit].
  /// Supports common restaurant units:
  /// - kg <-> g / gr
  /// - l / litr <-> ml
  /// Returns original quantity if conversion is not supported or not needed.
  static double convert(double quantity, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return quantity;

    final from = fromUnit.toLowerCase().trim();
    final to = toUnit.toLowerCase().trim();

    if (from == to) return quantity;

    // Weight conversions
    if ((from == 'kg' || from == '\u043a\u0433') && (to == 'g' || to == 'gr' || to == '\u0433' || to == '\u0433\u0440')) {
      return quantity * 1000;
    }
    if ((from == 'g' || from == 'gr' || from == '\u0433' || from == '\u0433\u0440') && (to == 'kg' || to == '\u043a\u0433')) {
      return quantity / 1000;
    }

    // Volume conversions
    if ((from == 'l' || from == 'litr' || from == '\u043b' || from == '\u043b\u0438\u0442\u0440') && (to == 'ml' || to == '\u043c\u043b')) {
      return quantity * 1000;
    }
    if ((from == 'ml' || from == '\u043c\u043b') && (to == 'l' || to == 'litr' || to == '\u043b' || to == '\u043b\u0438\u0442\u0440')) {
      return quantity / 1000;
    }

    // Unhandled conversions (e.g. dona <-> dona, or mismatched like kg <-> litr)
    return quantity;
  }
}
