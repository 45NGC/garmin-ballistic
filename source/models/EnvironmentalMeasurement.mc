import Toybox.Lang;

// Values supplied by the source. Null means unavailable, never an invented zero.
// Canonical units: m/s, degrees, Celsius, hPa, percent relative humidity.
class EnvironmentalMeasurement {
    function copy() as EnvironmentalMeasurement {
        return new EnvironmentalMeasurement(timestamp, receivedAtMs, windSpeed, windDirection, temperature, pressure, humidity);
    }
    var timestamp as Number;
    var receivedAtMs as Number;
    var windSpeed as Float or Null;
    var windDirection as Float or Null;
    var temperature as Float or Null;
    var pressure as Float or Null;
    var humidity as Float or Null;

    function initialize(at as Number, tick as Number, wind as Float or Null,
                        direction as Float or Null, temp as Float or Null,
                        stationPressure as Float or Null, rh as Float or Null) {
        timestamp = at;
        receivedAtMs = tick;
        windSpeed = wind;
        windDirection = direction;
        temperature = temp;
        pressure = stationPressure;
        humidity = rh;
    }
}
