import 'dart:async';
import 'package:puppeteer/puppeteer.dart';

class Status {
  final int supplyAirPct;
  final int supplyAirRpm;
  final int extractAirPct;
  final int extractAirRpm;

  Status({
    required this.supplyAirPct,
    required this.supplyAirRpm,
    required this.extractAirPct,
    required this.extractAirRpm,
  });

  @override
  String toString() =>
      '$supplyAirPct($supplyAirRpm)/$extractAirPct($extractAirRpm)';
}

class HeliosEasycontrols {
  final String baseUrl;
  Browser? _browser;

  HeliosEasycontrols(this.baseUrl);

  Future<R> _withPage<R>(Future<R> Function(Page page) fn) async {
    _browser ??= await puppeteer.launch(headless: true);
    final page = await _browser!.newPage();
    StreamSubscription? onRequestSubs;
    try {
      page.setRequestInterception(true);
      onRequestSubs = page.onRequest.listen((e) {
        if (e.resourceType == ResourceType.font ||
            e.resourceType == ResourceType.image ||
            e.resourceType == ResourceType.stylesheet) {
          e.abort();
          return;
        }
        e.continueRequest();
      });
      return await fn(page);
    } finally {
      await onRequestSubs?.cancel();
      await page.close();
    }
  }

  Future<void> close() async {
    await _browser?.close();
    _browser = null;
  }

  Future<_AdvancedWidgets> _gotoAdvanced(Page page) async {
    await page.goto('$baseUrl/', wait: Until.networkIdle);
    await Future.delayed(Duration(milliseconds: 1000));
    await page.waitForSelector('.dashboard-edit-limit-0');
    await page.goto('$baseUrl/#dashboard-expert-page', wait: Until.networkIdle);
    await page.waitForSelector(
        '.dashboard-slider[l10n-path="wizard.expert.fan.supply"] input');
    await Future.delayed(Duration(milliseconds: 500));
    return _AdvancedWidgets(
      supplyAirInput: await page
          .$('.dashboard-slider[l10n-path="wizard.expert.fan.supply"] input'),
      extractAirInput: await page
          .$('.dashboard-slider[l10n-path="wizard.expert.fan.extract"] input'),
      supplyAirRpm: await page.$(
          '.dashboard-slider-amount span[l10n-path="wizard.expert.fan.supply"]'),
      extractAirRpm: await page.$(
          '.dashboard-slider-amount span[l10n-path="wizard.expert.fan.extract"]'),
    );
  }

  Future<void> setFanSpeeds({
    required int supplyAirPct,
    required int extractAirPct,
  }) async {
    if (supplyAirPct < 0 || supplyAirPct > 99) {
      throw ArgumentError('supplyAirPct must be between 0-99');
    }
    if (extractAirPct < 0 || extractAirPct > 99) {
      throw ArgumentError('extractAirPct must be between 0-99');
    }
    await _withPage((page) async {
      final widgets = await _gotoAdvanced(page);

      Future<void> clearAndType(String text) async {
        await page.keyboard.down(Key.control);
        await page.keyboard.press(Key.keyA);
        await page.keyboard.up(Key.control);
        await page.keyboard.press(Key.backspace);
        await page.keyboard.type(text);
        await page.keyboard.press(Key.enter);
      }

      await widgets.supplyAirInput.focus();
      await clearAndType('$supplyAirPct');
      await Future.delayed(Duration(milliseconds: 50));
      await widgets.extractAirInput.focus();
      await Future.delayed(Duration(milliseconds: 2000));

      await widgets.extractAirInput.focus();
      await clearAndType('$extractAirPct');
      await Future.delayed(Duration(milliseconds: 50));
      await widgets.supplyAirInput.focus();
      await Future.delayed(Duration(milliseconds: 2000));

      // additional delay to make sure we set the value
      await Future.delayed(Duration(milliseconds: 5000));
    });
  }

  Future<Status> getStatus() async {
    return await _withPage((page) async {
      final widgets = await _gotoAdvanced(page);
      return Status(
        supplyAirPct:
            int.parse(await widgets.supplyAirInput.propertyValue('value')),
        supplyAirRpm: int.parse(
            (await widgets.supplyAirRpm.propertyValue('textContent'))
                .toString()
                .trim()),
        extractAirPct:
            int.parse(await widgets.extractAirInput.propertyValue('value')),
        extractAirRpm: int.parse(
            (await widgets.extractAirRpm.propertyValue('textContent'))
                .toString()
                .trim()),
      );
    });
  }
}

class _AdvancedWidgets {
  final ElementHandle supplyAirInput;
  final ElementHandle supplyAirRpm;
  final ElementHandle extractAirInput;
  final ElementHandle extractAirRpm;

  _AdvancedWidgets({
    required this.supplyAirInput,
    required this.supplyAirRpm,
    required this.extractAirInput,
    required this.extractAirRpm,
  });
}
