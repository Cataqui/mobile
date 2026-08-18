part of 'create_job_payment_amount_text.dart';

class _CreateJobPaymentAmountTextToken {
  const _CreateJobPaymentAmountTextToken({
    required this.id,
    required this.text,
    required this.left,
    required this.width,
    required this.digitIndex,
    required this.isDigit,
    required this.isSeparator,
  });

  final Object id;
  final String text;
  final double left;
  final double width;
  final int? digitIndex;
  final bool isDigit;
  final bool isSeparator;
}

class _CreateJobPaymentAmountTextLayout {
  _CreateJobPaymentAmountTextLayout({required this.tokens, required this.width});

  factory _CreateJobPaymentAmountTextLayout.resolve({
    required String text,
    required double Function(String text) widthOf,
  }) {
    final characters = text.characters.toList(growable: false);
    final firstDigitIndex = characters.indexWhere(_CreateJobPaymentAmountTextTransitionSpec.isDigit);
    final tokens = <_CreateJobPaymentAmountTextToken>[];
    var left = 0.0;
    var digitIndex = 0;

    if (firstDigitIndex < 0) {
      final width = widthOf(text);
      return _CreateJobPaymentAmountTextLayout(
        tokens: [
          _CreateJobPaymentAmountTextToken(
            id: 'prefix',
            text: text,
            left: 0,
            width: width,
            digitIndex: null,
            isDigit: false,
            isSeparator: false,
          ),
        ],
        width: width,
      );
    }

    if (firstDigitIndex > 0) {
      final prefix = characters.take(firstDigitIndex).join();
      final prefixWidth = widthOf(prefix);
      tokens.add(
        _CreateJobPaymentAmountTextToken(
          id: 'prefix',
          text: prefix,
          left: left,
          width: prefixWidth,
          digitIndex: null,
          isDigit: false,
          isSeparator: false,
        ),
      );
      left += prefixWidth;
    }

    final separatorIndexFromRight = <int, int>{};
    final separatorCounts = <String, int>{};
    for (var index = characters.length - 1; index >= math.max(firstDigitIndex, 0); index -= 1) {
      final character = characters[index];
      if (_CreateJobPaymentAmountTextTransitionSpec.isDigit(character)) continue;

      final separatorIndex = separatorCounts[character] ?? 0;
      separatorIndexFromRight[index] = separatorIndex;
      separatorCounts[character] = separatorIndex + 1;
    }

    for (var index = math.max(firstDigitIndex, 0); index < characters.length; index += 1) {
      final character = characters[index];
      final isDigit = _CreateJobPaymentAmountTextTransitionSpec.isDigit(character);
      final tokenWidth = widthOf(character);
      final Object id;
      final int? tokenDigitIndex;
      if (isDigit) {
        id = ('digit', digitIndex);
        tokenDigitIndex = digitIndex;
        digitIndex += 1;
      } else {
        id = ('separator', character, separatorIndexFromRight[index]!);
        tokenDigitIndex = null;
      }
      tokens.add(
        _CreateJobPaymentAmountTextToken(
          id: id,
          text: character,
          left: left,
          width: tokenWidth,
          digitIndex: tokenDigitIndex,
          isDigit: isDigit,
          isSeparator: !isDigit,
        ),
      );
      left += tokenWidth;
    }

    return _CreateJobPaymentAmountTextLayout(tokens: tokens, width: left);
  }

  final List<_CreateJobPaymentAmountTextToken> tokens;
  final double width;

  late final Map<Object, _CreateJobPaymentAmountTextToken> tokensById = {for (final token in tokens) token.id: token};

  _CreateJobPaymentAmountTextToken? tokenById(Object id) => tokensById[id];

  _CreateJobPaymentAmountTextToken? get lastDigit {
    for (final token in tokens.reversed) {
      if (token.isDigit) return token;
    }
    return null;
  }
}
