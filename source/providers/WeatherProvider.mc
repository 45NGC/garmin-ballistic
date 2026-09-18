import Toybox.Lang;

typedef WeatherListener as Method(weather as EnvironmentalMeasurement) as Void;

class WeatherProvider extends SensorProvider {
    protected var _listener as WeatherListener or Null;

    function initialize(source as String, simulated as Boolean) {
        SensorProvider.initialize(source, simulated);
        _listener = null;
    }

    function start(listener as WeatherListener, stateListener as ProviderStateListener) as Void {
        if (isActive()) { return; }
        _listener = listener;
        begin(stateListener);
    }

    function stop() as Void {
        _listener = null;
        SensorProvider.stop();
    }

    protected function deliver(value as EnvironmentalMeasurement, token as Number) as Void {
        if (!accepts(token) || !isConnected()) { return; }
        if (!MeasurementValidation.weather(value)) {
            setState(token, ProviderState.ERROR, "Ambiente no válido");
            return;
        }
        var listener = _listener;
        if (listener != null) {
            listener.invoke(value.copy());
        }
    }
}
