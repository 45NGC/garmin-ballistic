import Toybox.Lang;

class MockWeatherProvider extends WeatherProvider {
    private var _scenario as Number = MockScenario.NORMAL;
    private var _lastTick as Number or Null = null;
    private var _index as Number = 0;

    function initialize() { WeatherProvider.initialize("MockWeather", true); }
    function scenarioLabel() as String { return MockScenario.label(_scenario); }
    function setScenario(mode as Number) as Void {
        if (mode < 0 || mode >= MockScenario.COUNT) { return; }
        _scenario = mode;
        _lastTick = null;
        if (isActive()) { setState(session(), ProviderState.SCANNING, null); }
    }
    function cycleScenario() as Void { setScenario((_scenario + 1) % MockScenario.COUNT); }

    function pump(at as Number, tick as Number) as Void {
        if (!isActive()) { return; }
        setState(session(), MockScenario.nextState(_scenario, state()),
            _scenario == MockScenario.ERROR ? "Error simulado de meteorología" : null);
        if (!isConnected() || _scenario == MockScenario.SILENT ||
            !Freshness.isStale(_lastTick, tick, AppConfig.WEATHER_INTERVAL_MS)) { return; }
        _lastTick = tick;
        var winds = [4.2, 4.6, 3.9, 4.1];
        var temperatures = [14.0, 14.1, 14.0, 13.9];
        var partial = _scenario == MockScenario.PARTIAL;
        deliver(new EnvironmentalMeasurement(at, tick, winds[_index], partial ? null : 275.0,
            temperatures[_index], partial ? null : 1009.0, partial ? null : 62.0), session());
        _index = (_index + 1) % winds.size();
    }
}
