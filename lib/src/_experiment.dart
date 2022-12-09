import 'dart:async';
import 'dart:math' as math;

import '_client.dart';

int _calcChange(int current, int target, {int threshold = 50}) {
  if (current < target - (threshold * 3)) return 2;
  if (current < target - threshold) return 1;
  if (current > target + (threshold * 5)) return -3;
  if (current > target + (threshold * 3)) return -2;
  if (current > target + threshold) return -1;
  return 0;
}

int minuteOfDay(int hour, int min) => hour * 60 + min;

final _m0700 = minuteOfDay(7, 00);
final _m0745 = minuteOfDay(7, 45);
final _m2300 = minuteOfDay(23, 00);
final _m2345 = minuteOfDay(23, 45);

final _minutes = [_m0700, _m0745, _m2300, _m2345];
bool _nearAnyMinutes(int threshold) {
  final now = DateTime.now();
  final m = minuteOfDay(now.hour, now.minute);
  for (final c in _minutes) {
    if ((c - m).abs() < threshold || (c - m + 24 * 60).abs() < threshold) {
      return true;
    }
  }
  return false;
}

int _target(int min, int max) {
  final now = DateTime.now();
  final m = minuteOfDay(now.hour, now.minute);
  if (m < _m0700 || m > _m2345) return min;
  if (m > _m0745 && m < _m2300) return max;
  if (m <= _m0745) {
    final diff = (m - _m0700) / (_m0745 - _m0700);
    return ((max - min) * diff + min).round();
  } else {
    final diff = (m - _m2300) / (_m2345 - _m2300);
    return ((min - max) * diff + max).round();
  }
}

Future<void> main() async {
  var extraSleep = 0;
  for (;;) {
    final controls = HeliosEasycontrols('http://192.168.1.101');
    var changed = false;
    try {
      final s = await controls.getStatus();
      final supplyChange =
          _calcChange(s.supplyAirRpm, _target(1100, 1400), threshold: 40);
      final extractChange =
          _calcChange(s.extractAirRpm, _target(900, 1100), threshold: 25);
      if (supplyChange == 0 && extractChange == 0) {
        print('${DateTime.now()} $s');
        extraSleep = math.min(extraSleep + 15, 300);
      } else {
        changed = true;
        extraSleep = 0;
        print('${DateTime.now()} $s $supplyChange/$extractChange');
        await controls.setFanSpeeds(
          supplyAirPct: s.supplyAirPct + supplyChange,
          extractAirPct: s.extractAirPct + extractChange,
        );
      }
    } catch (e, st) {
      print(e);
      print(st);
      extraSleep++;
    } finally {
      await controls.close();
    }

    final sleepDuration = Duration(
        seconds: (_nearAnyMinutes(60) || changed) ? 300 + extraSleep : 60 * 30);
    print('sleeping $sleepDuration...');
    await Future.delayed(sleepDuration);
  }
}
