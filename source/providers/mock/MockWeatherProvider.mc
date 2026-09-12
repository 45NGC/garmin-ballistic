import Toybox.Lang;

class MockWeatherProvider extends WeatherProvider {
    private var _enabled as Boolean = true;
    private var _lastTick as Number or Null = null;
    private var _index as Number = 0;

    function initialize() {
        WeatherProvider.initialize();
    }

    function isConnected() as Boolean {
        return _enabled && _listener != null;
    }

    function toggleConnection() as Void {
        _enabled = !_enabled;
        _lastTick = null;
    }

    function pump(at as Number, tick as Number) as Void {
        if (!isConnected() || !Freshness.isStale(_lastTick, tick, AppConfig.WEATHER_INTERVAL_MS)) {
            return;
        }
        _lastTick = tick;
        // Deterministic fixtures, not calculated weather or a device protocol.
        var winds = [4.2, 4.6, 3.9, 4.1];
        var temperatures = [14.0, 14.1, 14.0, 13.9];
        deliver(new EnvironmentalMeasurement(at, tick, winds[_index], 275.0,
            temperatures[_index], 1009.0, 62.0));
        _index = (_index + 1) % winds.size();
    }
}
