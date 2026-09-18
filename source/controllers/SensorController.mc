import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// Coordinates injected providers; knows neither mocks nor transport protocols.
class SensorController {
    var range as RangeMeasurement or Null = null;
    var weather as EnvironmentalMeasurement or Null = null;
    var history as MeasurementRepository;
    var rangeState as Number = ProviderState.STOPPED;
    var weatherState as Number = ProviderState.STOPPED;
    var rangeError as String or Null = null;
    var weatherError as String or Null = null;
    private var _rangefinder as RangefinderProvider;
    private var _weatherProvider as WeatherProvider;
    private var _weatherSource as String or Null = null;
    private var _weatherSimulated as Boolean = false;
    private var _driver as AcquisitionDriver or Null;
    private var _timer as Timer.Timer;
    private var _running as Boolean = false;

    function initialize(rangefinder as RangefinderProvider, weatherProvider as WeatherProvider,
                        store as HistoryStore, driver as AcquisitionDriver or Null) {
        _rangefinder = rangefinder;
        _weatherProvider = weatherProvider;
        _driver = driver;
        history = new MeasurementRepository(store);
        _timer = new Timer.Timer();
    }

    function isDemo() as Boolean { return _rangefinder.isSimulated() || _weatherProvider.isSimulated(); }

    function start() as Void {
        if (_running) { return; }
        _running = true;
        history.load();
        // Either provider can fail without preventing the other from starting.
        try { _weatherProvider.start(method(:onWeather), method(:onWeatherState)); }
        catch (error instanceof Exception) {
            try { _weatherProvider.stop(); } catch (cleanupError instanceof Exception) {}
            onWeatherState(ProviderState.ERROR, "No se pudo iniciar meteo");
        }
        try { _rangefinder.start(method(:onRange), method(:onRangeState)); }
        catch (error instanceof Exception) {
            try { _rangefinder.stop(); } catch (cleanupError instanceof Exception) {}
            onRangeState(ProviderState.ERROR, "No se pudo iniciar telémetro");
        }
        _timer.start(method(:onTick), AppConfig.UI_INTERVAL_MS, true);
        WatchUi.requestUpdate();
    }

    function stop() as Void {
        if (!_running) { return; }
        // Invalidate callbacks before shutting down either transport.
        _running = false;
        _timer.stop();
        try { _rangefinder.stop(); } catch (error instanceof Exception) {}
        try { _weatherProvider.stop(); } catch (error instanceof Exception) {}
        rangeState = ProviderState.STOPPED;
        weatherState = ProviderState.STOPPED;
        rangeError = null;
        weatherError = null;
    }

    function onRangeState(state as Number, message as String or Null) as Void {
        if (!_running) { return; }
        rangeState = state;
        rangeError = message;
        WatchUi.requestUpdate();
    }
    function onWeatherState(state as Number, message as String or Null) as Void {
        if (!_running) { return; }
        weatherState = state;
        weatherError = message;
        WatchUi.requestUpdate();
    }
    function onRange(value as RangeMeasurement) as Void {
        if (!_running || rangeState != ProviderState.CONNECTED || !MeasurementValidation.range(value)) { return; }
        range = value.copy();
        history.append(RecordCodec.capture(value, weather, weatherState == ProviderState.CONNECTED,
            _rangefinder.sourceName(), _weatherSource,
            _rangefinder.isSimulated() || (weather != null && _weatherSimulated)));
        WatchUi.requestUpdate();
    }
    function onWeather(value as EnvironmentalMeasurement) as Void {
        if (!_running || weatherState != ProviderState.CONNECTED || !MeasurementValidation.weather(value)) { return; }
        // Replace the entire sample: absent fields must not retain older values.
        weather = value.copy();
        _weatherSource = _weatherProvider.sourceName();
        _weatherSimulated = _weatherProvider.isSimulated();
        WatchUi.requestUpdate();
    }
    function onTick() as Void {
        if (!_running) { return; }
        var driver = _driver;
        if (driver != null) { driver.tick(Time.now().value(), System.getTimer()); }
        WatchUi.requestUpdate();
    }
}
