import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// Explicitly a demo composition. No BLE calls, parsing, or storage in Phase 1.
class DemoController {
    var range as RangeMeasurement or Null = null;
    var weather as EnvironmentalMeasurement or Null = null;
    var rangefinder as MockRangefinderProvider;
    var weatherProvider as MockWeatherProvider;
    private var _timer as Timer.Timer;
    private var _running as Boolean = false;

    function initialize() {
        rangefinder = new MockRangefinderProvider();
        weatherProvider = new MockWeatherProvider();
        _timer = new Timer.Timer();
    }

    function start() as Void {
        if (_running) {
            return;
        }
        _running = true;
        rangefinder.start(method(:onRange));
        weatherProvider.start(method(:onWeather));
        onTick();
        _timer.start(method(:onTick), AppConfig.UI_INTERVAL_MS, true);
    }

    function stop() as Void {
        _timer.stop();
        rangefinder.stop();
        weatherProvider.stop();
        _running = false;
    }

    function onRange(value as RangeMeasurement) as Void {
        range = value;
        // Phase 2: snapshot latest weather here, including its own timestamp,
        // then append one MeasurementRecord per range EVENT, even if equal.
        WatchUi.requestUpdate();
    }

    function onWeather(value as EnvironmentalMeasurement) as Void {
        weather = value;
        WatchUi.requestUpdate();
    }

    function onTick() as Void {
        if (!_running) {
            return;
        }
        var at = Time.now().value();
        var tick = System.getTimer();
        weatherProvider.pump(at, tick);
        rangefinder.pump(at, tick, false);
        // Repaint at 1 Hz to make stale data visible even when sources stop.
        WatchUi.requestUpdate();
    }

    function measureNow() as Void {
        if (_running) {
            rangefinder.pump(Time.now().value(), System.getTimer(), true);
        }
    }
}
