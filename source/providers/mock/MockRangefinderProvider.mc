import Toybox.Lang;

class MockRangefinderProvider extends RangefinderProvider {
    private var _enabled as Boolean = true;
    private var _lastTick as Number or Null = null;
    private var _index as Number = 0;
    private var _distances as Array<Float> = [428.0, 431.0, 417.0, 452.0];

    function initialize() {
        RangefinderProvider.initialize();
    }

    function isConnected() as Boolean {
        return _enabled && _listener != null;
    }

    function toggleConnection() as Void {
        _enabled = !_enabled;
        _lastTick = null;
    }

    // Only the demo needs a clock-driven pump. A real provider uses notifications.
    function pump(at as Number, tick as Number, force as Boolean) as Void {
        if (!isConnected()) {
            return;
        }
        if (force || Freshness.isStale(_lastTick, tick, AppConfig.RANGE_INTERVAL_MS)) {
            _lastTick = tick;
            var value = new RangeMeasurement(at, tick, _distances[_index], "m", null, null);
            _index = (_index + 1) % _distances.size();
            deliver(value);
        }
    }
}
