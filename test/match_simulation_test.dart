import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wicket_wars/data/match_simulation.dart';
import 'package:wicket_wars/data/models/pitch_condition.dart';

void main() {
  test('simulateBall returns valid outcomes over many trials', () {
    final rng = Random(42);
    for (var i = 0; i < 500; i++) {
      final r = simulateBall(
        SimBallContext(
          pitch: PitchCondition.balanced,
          legalBallsInInnings: i % 120,
          wicketsDown: i % 10,
          runsScoredThisInnings: i % 80,
          isChaseInnings: i.isEven,
          chaseTarget: i.isEven ? 120 : null,
        ),
        rng,
      );
      expect(r.wicket, anyOf(0, 1));
      if (r.wicket == 0) {
        expect(r.runs, anyOf(0, 1, 2, 3, 4, 6));
      } else {
        expect(r.runs, 0);
      }
    }
  });
}
