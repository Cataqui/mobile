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
            child: const SizedBox(
              width: 300,
              child: QuiHeroText(
                'Vendedora de Loja',
                tag: 'test-text',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'text_with_padding',
            child: const SizedBox(
              width: 300,
              child: QuiHeroText(
                'Servente de Obra',
                tag: 'test-text-padded',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                padding: EdgeInsets.all(12),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'text_with_overflow',
            child: const SizedBox(
              width: 200,
              child: QuiHeroText(
                'Ajudante de Carga e Descarga em Supermercado',
                tag: 'test-text-overflow',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
      fileName: 'qui_hero_background_resting',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'box_with_child',
            child: SizedBox(
              width: 300,
              height: 100,
              child: QuiHeroBackground(
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
              child: QuiHeroBackground(
                tag: 'test-box-decoration',
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF4A4B), width: 2),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'box_with_top_edge_fade',
            child: const SizedBox(
              width: 300,
              height: 100,
              child: QuiHeroBackground(
                tag: 'test-box-fade-top',
                decoration: BoxDecoration(color: Color(0xFFFF4A4B)),
                edgeFade: QuiHeroEdgeFade(top: QuiEdgeFadeStyle()),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Top Fade',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'box_with_both_edge_fades',
            child: const SizedBox(
              width: 300,
              height: 100,
              child: QuiHeroBackground(
                tag: 'test-box-fade-both',
                decoration: BoxDecoration(color: Color(0xFFFF4A4B)),
                edgeFade: QuiHeroEdgeFade.vertical,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Both Fades',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
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
            child: const SizedBox(
              width: 300,
              child: QuiHeroGroup(
                tag: 'test-group',
                heroes: [
                  QuiHeroText(
                    '1 dia atrás',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF999999)),
                    padding: EdgeInsets.only(bottom: 6),
                  ),
                  QuiHeroText(
                    'Separador de Mercadorias',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    padding: EdgeInsets.only(bottom: 4),
                  ),
                  QuiHeroText(
                    r'R$2.200/mês',
                    style: TextStyle(fontSize: 25, color: Color(0xFF00DD55), fontWeight: FontWeight.w600),
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
