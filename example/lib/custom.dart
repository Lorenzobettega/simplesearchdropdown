import 'dart:math';

class Custom {
  final String name;
  final int id;

  Custom(this.name, this.id);
}

int getRandomInt(int length) {
  const chars = '1234567890';
  final Random rnd = Random();
  return int.parse(
    String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(
          rnd.nextInt(chars.length),
        ),
      ),
    ),
  );
}
