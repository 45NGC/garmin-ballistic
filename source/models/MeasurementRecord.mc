import Toybox.Lang;

typedef RecordScalar as Number or Float or String or Boolean or Null;
typedef RecordData as Dictionary<String, RecordScalar>;

// An immutable snapshot of a range event and the latest received environment.
// Factories in RecordCodec validate input. All accessors return copies.
class MeasurementRecord {
    private var _data as RecordData;

    function initialize(data as RecordData) {
        _data = copyData(data);
    }

    function toData() as RecordData { return copyData(_data); }

    private function copyData(data as RecordData) as RecordData {
        var result = {} as RecordData;
        var keys = data.keys();
        for (var i = 0; i < keys.size(); i += 1) {
            result[keys[i]] = data[keys[i]];
        }
        return result;
    }

    function getRange() as RangeMeasurement {
        // Monotonic ticks are deliberately not restored across sessions.
        return new RangeMeasurement(_data["timestamp"] as Number, 0,
            _data["distance"] as Float, _data["unit"] as String,
            _data["azimuth"] as Float or Null, _data["inclination"] as Float or Null);
    }

    function getWeather() as EnvironmentalMeasurement or Null {
        var at = _data["environmentalTimestamp"];
        if (at == null) { return null; }
        return new EnvironmentalMeasurement(at as Number, 0,
            _data["windSpeed"] as Float or Null, _data["windDirection"] as Float or Null,
            _data["temperature"] as Float or Null, _data["pressure"] as Float or Null,
            _data["humidity"] as Float or Null);
    }

    function getAgeSeconds() as Number or Null {
        return _data["environmentalAgeSeconds"] as Number or Null;
    }

    function weatherStatus() as String {
        if (_data["environmentalTimestamp"] == null) { return "SIN DATOS"; }
        var stale = _data["environmentalStale"] as Boolean;
        var connected = _data["environmentalConnected"] as Boolean;
        if (stale) { return connected ? "ANTIGUO" : "DESC./ANT."; }
        return connected ? "OK" : "SIN CONEX.";
    }

    function isSimulated() as Boolean { return _data["simulated"] as Boolean; }
    function rangeSource() as String { return _data["rangeSource"] as String; }
    function weatherSource() as String or Null { return _data["weatherSource"] as String or Null; }
}
