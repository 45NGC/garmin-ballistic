import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// Demo acquisition with production local history. No sensor protocol or BLE.
class DemoController {
    var range as RangeMeasurement or Null = null;
    var weather as EnvironmentalMeasurement or Null = null;
    var rangefinder as MockRangefinderProvider;
    var weatherProvider as MockWeatherProvider;
    var history as MeasurementRepository;
    private var _timer as Timer.Timer;
    private var _running as Boolean = false;

    function initialize(store as HistoryStore or Null) {
        rangefinder = new MockRangefinderProvider();
        weatherProvider = new MockWeatherProvider();
        history = new MeasurementRepository(store == null ? new HistoryStore() : store);
        _timer = new Timer.Timer();
    }

    function start() as Void {
        if (_running) {
            return;
        }
        _running = true;
        history.load();
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
        history.append(RecordCodec.capture(value, weather, weatherProvider.isConnected()));
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
