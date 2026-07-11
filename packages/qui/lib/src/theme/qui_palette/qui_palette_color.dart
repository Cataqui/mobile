part of 'qui_palette.dart';

@immutable
class QuiPaletteColor extends Color {
  QuiPaletteColor({required List<Color> steps}) : _steps = steps, super(steps[8].toARGB32());

  final List<Color> _steps;

  Color operator [](int step) {
    if (step < 1) return _steps[0];
    if (step > 12) return _steps[11];
    return _steps[step - 1];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! QuiPaletteColor) return false;
    if (_steps.length != other._steps.length) return false;

    for (var i = 0; i < _steps.length; i++) {
      if (_steps[i] != other._steps[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hashAll(_steps);
}
