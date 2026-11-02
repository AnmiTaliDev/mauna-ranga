import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mauna_ranga/editor/search.dart';

TextEditingController controller(String text, [int caret = 0]) {
  return TextEditingController.fromValue(
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret),
    ),
  );
}

void main() {
  test('findNext selects matches ignoring case and wraps around', () {
    final TextEditingController text = controller('Steel met STEEL.');
    expect(findNext(text, 'steel'), isTrue);
    expect(text.selection, const TextSelection(baseOffset: 0, extentOffset: 5));
    expect(findNext(text, 'steel'), isTrue);
    expect(
      text.selection,
      const TextSelection(baseOffset: 10, extentOffset: 15),
    );
    expect(findNext(text, 'steel'), isTrue);
    expect(text.selection.start, 0);
    expect(findNext(text, 'missing'), isFalse);
    expect(findNext(text, ''), isFalse);
  });

  test('whole word skips matches inside longer words', () {
    final TextEditingController text = controller('STEEL and ST and STELLA');
    expect(findNext(text, 'st', wholeWord: true), isTrue);
    expect(text.selection.start, 10);
  });

  test('replaceAll counts matches and keeps the replacement literal', () {
    final TextEditingController text = controller('ST: hi.\n\nST: bye. St');
    expect(replaceAll(text, 'st', r'$1 STEEL', wholeWord: true), 3);
    expect(
      text.text,
      r'$1 STEEL: hi.'
      '\n\n'
      r'$1 STEEL: bye. $1 STEEL',
    );
    expect(replaceAll(text, 'nothing', 'x'), 0);
  });

  test('replaceAll with whole word leaves longer names alone', () {
    final TextEditingController text = controller('ST\nHello.\n\nSTELLA\nHi.');
    expect(replaceAll(text, 'ST', 'STEEL', wholeWord: true), 1);
    expect(text.text, 'STEEL\nHello.\n\nSTELLA\nHi.');
  });

  test('replaceCurrent replaces the selected match and selects the next', () {
    final TextEditingController text = controller('one two one');
    expect(findNext(text, 'one'), isTrue);
    expect(replaceCurrent(text, 'one', 'three'), isTrue);
    expect(text.text, 'three two one');
    expect(
      text.selection,
      const TextSelection(baseOffset: 10, extentOffset: 13),
    );
  });

  test('replaceCurrent without a matching selection only moves to a match', () {
    final TextEditingController text = controller('one two one', 4);
    expect(replaceCurrent(text, 'one', 'three'), isTrue);
    expect(text.text, 'one two one');
    expect(text.selection.start, 8);
  });
}
