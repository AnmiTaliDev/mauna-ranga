import '../bridge/generated/api/document.dart';
import 'fountain_elements.dart';

final RegExp _locationPrefix = RegExp(
  r'^(int|ext|est|i/e)[./]',
  caseSensitive: false,
);
final RegExp _sceneNumber = RegExp(r'\s*#[^#]*#\s*$');

class CompletionSession {
  const CompletionSession(this.lineStart, this.matches, this.index);

  final int lineStart;

  final List<String> matches;

  final int index;
}

List<String> completionCandidates(
  String text,
  List<FountainElement> elements,
  int exceptStart,
) {
  final Map<String, int> counts = <String, int>{};
  final Map<String, int> order = <String, int>{};
  for (final FountainElement element in elements) {
    if (element.start == exceptStart) {
      continue;
    }
    final String raw = text.substring(element.start, element.end);
    final String? entry = switch (element.kind) {
      ElementType.character => _characterName(raw),
      ElementType.sceneHeading => _location(raw),
      _ => null,
    };
    if (entry == null || entry.isEmpty) {
      continue;
    }
    counts[entry] = (counts[entry] ?? 0) + 1;
    order.putIfAbsent(entry, () => order.length);
  }
  return counts.keys.toList()..sort((String a, String b) {
    final int byCount = counts[b]!.compareTo(counts[a]!);
    return byCount != 0 ? byCount : order[a]!.compareTo(order[b]!);
  });
}

List<String> completionMatches(String prefix, List<String> candidates) {
  if (prefix.trim().isEmpty) {
    return <String>[];
  }
  final String upper = prefix.toUpperCase();
  if (prefix != upper && !_locationPrefix.hasMatch(prefix)) {
    return <String>[];
  }
  return <String>[
    for (final String candidate in candidates)
      if (candidate.startsWith(upper) && candidate != upper) candidate,
  ];
}

String _characterName(String raw) {
  String name = raw.startsWith('@') ? raw.substring(1) : raw;
  final int cut = name.indexOf(RegExp(r'[(^]'));
  if (cut >= 0) {
    name = name.substring(0, cut);
  }
  return name.trim().toUpperCase();
}

String? _location(String raw) {
  final String heading = raw
      .replaceFirst(_sceneNumber, '')
      .trim()
      .toUpperCase();
  if (!_locationPrefix.hasMatch(heading)) {
    return null;
  }
  final int dash = heading.lastIndexOf(' - ');
  return (dash > 0 ? heading.substring(0, dash) : heading).trim();
}
