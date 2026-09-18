import Toybox.Lang;

class MockRangefinderProvider extends RangefinderProvider {
    private var _scenario as Number = MockScenario.NORMAL;
    private var _lastTick as Number or Null = null;
    private var _index as Number = 0;
    private var _distances as Array<Float> = [428.0, 431.0, 417.0, 452.0];

    function initialize() { RangefinderProvider.initialize("MockRangefinder", true); }
    function scenarioLabel() as String { return MockScenario.label(_scenario); }
    function setScenario(mode as Number) as Void {
        if (mode < 0 || mode >= MockScenario.COUNT) { return; }
        _scenario = mode;
        _lastTick = null;
        if (isActive()) { setState(session(), ProviderState.SCANNING, null); }
    }
    function cycleScenario() as Void { setScenario((_scenario + 1) % MockScenario.COUNT); }

    function pump(at as Number, tick as Number, force as Boolean) as Void {
        if (!isActive()) { return; }
        setState(session(), MockScenario.nextState(_scenario, state()),
            _scenario == MockScenario.ERROR ? "Error simulado del telémetro" : null);
        if (!isConnected() || _scenario == MockScenario.SILENT) { return; }
        if (force || Freshness.isStale(_lastTick, tick, AppConfig.RANGE_INTERVAL_MS)) {
            _lastTick = tick;
            var value = new RangeMeasurement(at, tick, _distances[_index], "m",
                _scenario == MockScenario.PARTIAL ? null : 275.0,
                _scenario == MockScenario.PARTIAL ? null : -2.0);
            _index = (_index + 1) % _distances.size();
            deliver(value, session());
        }
    }
}
