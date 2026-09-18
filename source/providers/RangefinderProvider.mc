import Toybox.Lang;

typedef RangeListener as Method(range as RangeMeasurement) as Void;

// Monkey C contract expressed as a base class (no Java-style interface syntax).
// Real transports will deliver measurements from their BLE event callbacks.
class RangefinderProvider extends SensorProvider {
    protected var _listener as RangeListener or Null;

    function initialize(source as String, simulated as Boolean) {
        SensorProvider.initialize(source, simulated);
        _listener = null;
    }

    function start(listener as RangeListener, stateListener as ProviderStateListener) as Void {
        if (isActive()) { return; }
        _listener = listener;
        begin(stateListener);
    }

    function stop() as Void {
        _listener = null;
        SensorProvider.stop();
    }

    protected function deliver(value as RangeMeasurement, token as Number) as Void {
        if (!accepts(token) || !isConnected()) { return; }
        if (!MeasurementValidation.range(value)) {
            setState(token, ProviderState.ERROR, "Distancia no válida");
            return;
        }
        var listener = _listener;
        if (listener != null) {
            listener.invoke(value.copy());
        }
    }
}
