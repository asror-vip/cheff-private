class SearchUtils {
  static const Map<String, String> _cyrillicToLatin = {
    '\u0430': 'a', '\u0431': 'b', '\u0432': 'v', '\u0433': 'g', '\u0434': 'd', '\u0435': 'e', '\u0451': 'yo', '\u0436': 'zh',
    '\u0437': 'z', '\u0438': 'i', '\u0439': 'y', '\u043a': 'k', '\u043b': 'l', '\u043c': 'm', '\u043d': 'n', '\u043e': 'o',
    '\u043f': 'p', '\u0440': 'r', '\u0441': 's', '\u0442': 't', '\u0443': 'u', '\u0444': 'f', '\u0445': 'h', '\u0446': 'ts',
    '\u0447': 'ch', '\u0448': 'sh', '\u0449': 'shch', '\u044a': '', '\u044b': 'y', '\u044c': '', '\u044d': 'e', '\u044e': 'yu', '\u044f': 'ya',
    '\u049b': 'q', '\u045e': "o'", '\u0493': "g'", '\u04b3': 'h',
  };

  static String normalize(String text) {
    String result = text.toLowerCase().trim();
    _cyrillicToLatin.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }
}
