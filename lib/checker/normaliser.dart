/// Text normalisation applied before any rule matching.
///
/// Scammers deliberately use homoglyphs and zero-width characters to defeat
/// keyword matching ("myg0v", "Аustralia Post" with a Cyrillic А). Normalising
/// first means one rule handles all the variants.
library;

const Map<String, String> _homoglyphs = {
  // Cyrillic characters that render as Latin ones
  '\u0410': 'A', '\u0412': 'B', '\u0415': 'E', '\u041A': 'K', '\u041C': 'M', '\u041D': 'H',
  '\u041E': 'O', '\u0420': 'P', '\u0421': 'C', '\u0422': 'T', '\u0423': 'Y', '\u0425': 'X',
  '\u0405': 'S', '\u0406': 'I', '\u0408': 'J', '\u0430': 'a', '\u0435': 'e', '\u043E': 'o',
  '\u0440': 'p', '\u0441': 'c', '\u0443': 'y', '\u0445': 'x', '\u0455': 's', '\u0456': 'i',
  '\u0458': 'j', '\u04BB': 'h', '\u04CF': 'l', '\u0501': 'd', '\u051B': 'q', '\u051D': 'w',
  // Greek characters that render as Latin ones
  '\u0391': 'A', '\u0392': 'B', '\u0395': 'E', '\u0396': 'Z', '\u0397': 'H', '\u0399': 'I',
  '\u039A': 'K', '\u039C': 'M', '\u039D': 'N', '\u039F': 'O', '\u03A1': 'P', '\u03A4': 'T',
  '\u03A5': 'Y', '\u03A7': 'X', '\u03BF': 'o', '\u03C1': 'p', '\u03BD': 'v', '\u03B1': 'a',
  // Fullwidth characters that render as Latin ones
  '\uFF10': '0', '\uFF11': '1', '\uFF12': '2', '\uFF13': '3', '\uFF14': '4', '\uFF15': '5',
  '\uFF16': '6', '\uFF17': '7', '\uFF18': '8', '\uFF19': '9', '\uFF21': 'A', '\uFF22': 'B',
  '\uFF23': 'C', '\uFF24': 'D', '\uFF25': 'E', '\uFF26': 'F', '\uFF27': 'G', '\uFF28': 'H',
  '\uFF29': 'I', '\uFF2A': 'J', '\uFF2B': 'K', '\uFF2C': 'L', '\uFF2D': 'M', '\uFF2E': 'N',
  '\uFF2F': 'O', '\uFF30': 'P', '\uFF31': 'Q', '\uFF32': 'R', '\uFF33': 'S', '\uFF34': 'T',
  '\uFF35': 'U', '\uFF36': 'V', '\uFF37': 'W', '\uFF38': 'X', '\uFF39': 'Y', '\uFF3A': 'Z',
  '\uFF41': 'a', '\uFF42': 'b', '\uFF43': 'c', '\uFF44': 'd', '\uFF45': 'e', '\uFF46': 'f',
  '\uFF47': 'g', '\uFF48': 'h', '\uFF49': 'i', '\uFF4A': 'j', '\uFF4B': 'k', '\uFF4C': 'l',
  '\uFF4D': 'm', '\uFF4E': 'n', '\uFF4F': 'o', '\uFF50': 'p', '\uFF51': 'q', '\uFF52': 'r',
  '\uFF53': 's', '\uFF54': 't', '\uFF55': 'u', '\uFF56': 'v', '\uFF57': 'w', '\uFF58': 'x',
  '\uFF59': 'y', '\uFF5A': 'z',
};

final RegExp _zeroWidth =
    RegExp('[\u200B\u200C\u200D\u2060\uFEFF\u00AD]');
final RegExp _whitespace = RegExp(r'\s+');

String normalise(String input) {
  var s = input;
  s = s.replaceAll(_zeroWidth, '');
  s = s.split('').map((c) => _homoglyphs[c] ?? c).join();
  s = s
      .replaceAll(RegExp('[\u2018\u2019\u201B]'), "'")
      .replaceAll(RegExp('[\u201C\u201D]'), '"')
      .replaceAll(RegExp('[\u2010-\u2015]'), '-');
  s = s.replaceAll(_whitespace, ' ').trim();
  return s;
}

/// Hosts from any http(s) URL in the text, lowercased, `www.` stripped.
List<String> extractHosts(String text) {
  return RegExp(r'\bhttps?://([^\s/?#]+)', caseSensitive: false)
      .allMatches(text)
      .map((m) => m.group(1)!.toLowerCase().replaceFirst(RegExp(r'^www\.'), ''))
      .toList(growable: false);
}

bool hostMatchesAny(String host, List<String> allowed) =>
    allowed.any((d) => host == d || host.endsWith('.$d'));
