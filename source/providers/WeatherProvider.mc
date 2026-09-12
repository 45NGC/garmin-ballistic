import Toybox.Lang;

typedef WeatherListener as Method(weather as EnvironmentalMeasurement) as Void;

class WeatherProvider {
    protected var _listener as WeatherListener or Null;

    function initialize() {
        _listener = null;
    }

    function start(listener as WeatherListener) as Void {
        _listener = listener;
    }

    function stop() as Void {
        _listener = null;
    }

    function isConnected() as Boolean {
        return false;
    }

    protected function deliver(value as EnvironmentalMeasurement) as Void {
        var listener = _listener;
        if (listener != null) {
            listener.invoke(value);
        }
    }
}
