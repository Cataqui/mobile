import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qui/qui.dart';

void main() {
  group('QuiHero Golden Tests', () {
    goldenTest(
      'when rendering the text variant at rest, it should match the approved golden',
      fileName: 'qui_hero_text_resting',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'text_resting',
            child: SizedBox(
              width: 300,
              child: QuiHero.text(
                tag: 'test-text',
                text: 'Vendedora de Loja',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'text_with_padding',
            child: SizedBox(
              width: 300,
              child: QuiHero.text(
                tag: 'test-text-padded',
                text: 'Servente de Obra',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'text_with_overflow',
            child: SizedBox(
              width: 200,
              child: QuiHero.text(
                tag: 'test-text-overflow',
                text: 'Ajudante de Carga e Descarga em Supermercado',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'when rendering the box variant at rest, it should match the approved golden',
      fileName: 'qui_hero_box_resting',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'box_with_child',
            child: SizedBox(
              width: 300,
              height: 100,
              child: QuiHero.background(
                tag: 'test-box-with-child',
                decoration: BoxDecoration(color: const Color(0xFFFF4A4B), borderRadius: BorderRadius.circular(38)),
                padding: const EdgeInsets.all(16),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Cataquí',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'box_decoration_only',
            child: SizedBox(
              width: 300,
              height: 80,
              child: QuiHero.background(
                tag: 'test-box-decoration',
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF4A4B), width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'when rendering the group variant at rest, it should match the approved golden',
      fileName: 'qui_hero_group_resting',
      builder: () => GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(300),
        children: [
          GoldenTestScenario(
            name: 'group_resting',
            child: SizedBox(
              width: 300,
              child: QuiHero.group(
                tag: 'test-group',
                heroes: [
                  QuiHero.text(
                    text: '1 dia atrás',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF999999)),
                    padding: const EdgeInsets.only(bottom: 6),
                  ),
                  QuiHero.text(
                    text: 'Separador de Mercadorias',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    padding: const EdgeInsets.only(bottom: 4),
                  ),
                  QuiHero.text(
                    text: r'R$2.200/mês',
                    style: const TextStyle(fontSize: 25, color: Color(0xFF00DD55), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  });
}
