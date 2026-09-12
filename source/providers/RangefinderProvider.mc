import Toybox.Lang;

typedef RangeListener as Method(range as RangeMeasurement) as Void;

// Monkey C contract expressed as a base class (no Java-style interface syntax).
// Real transports will deliver measurements from their BLE event callbacks.
class RangefinderProvider {
    protected var _listener as RangeListener or Null;

    function initialize() {
        _listener = null;
    }

    function start(listener as RangeListener) as Void {
        _listener = listener;
    }

    function stop() as Void {
        _listener = null;
    }

    function isConnected() as Boolean {
        return false;
    }

    protected function deliver(value as RangeMeasurement) as Void {
        var listener = _listener;
        if (listener != null) {
            listener.invoke(value);
        }
    }
}
