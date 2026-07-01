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
        ],
      ),
    );

    goldenTest(
      'when rendering the box variant at rest, it should match the approved golden',
      fileName: 'qui_hero_box_resting',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'box_resting',
            child: SizedBox(
              width: 300,
              height: 100,
              child: QuiHero.box(
                tag: 'test-box',
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4A4B),
                  borderRadius: BorderRadius.circular(38),
                ),
                padding: const EdgeInsets.all(16),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Cataquí', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
