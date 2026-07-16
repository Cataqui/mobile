import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiToast Golden Tests', () {
    goldenTest(
      'when rendering error states, it should match the approved goldens',
      fileName: 'qui_toast_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(
          width: 390,
          height: 260,
        ),
        children: [
          GoldenTestScenario(
            name: 'error',
            child: const _ToastGoldenFrame(
              child: QuiToast(message: 'Nao foi possivel carregar agora'),
            ),
          ),
          GoldenTestScenario(
            name: 'long error',
            child: _ToastGoldenFrame(
              child: QuiToast(
                message: List.filled(
                  10,
                  'Tente novamente em alguns segundos',
                ).join(' '),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'strong shadow',
            child: const _ToastGoldenFrame(
              backgroundColor: Color(0xFFECEAF4),
              child: QuiToast(message: 'O mapa perdeu a conexao'),
            ),
          ),
          GoldenTestScenario(
            name: 'custom padding',
            child: const _ToastGoldenFrame(
              padding: EdgeInsets.fromLTRB(54, 48, 20, 16),
              child: QuiToast(message: 'uh lala'),
            ),
          ),
          GoldenTestScenario(
            name: 'custom icon',
            child: const _ToastGoldenFrame(
              child: QuiToast(
                message: 'Com icone personalizado',
                iconBuilder: _buildTestCustomIcon,
              ),
            ),
          ),
        ],
      ),
    );
  });
}

Widget _buildTestCustomIcon(QuiToastState state) {
  return SizedBox(
    key: const Key('qui_toast_custom_icon'),
    width: state.iconSize,
    height: state.iconSize,
    child: Icon(Icons.warning, color: state.iconColor, size: state.iconSize),
  );
}

class _ToastGoldenFrame extends StatelessWidget {
  const _ToastGoldenFrame({
    required this.child,
    this.backgroundColor = const Color(0xFFF6F4F1),
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: padding,
        child: Align(alignment: Alignment.topCenter, child: child),
      ),
    );
  }
}
