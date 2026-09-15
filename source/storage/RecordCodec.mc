import Toybox.Application;
import Toybox.Lang;

// Storage schema, not a sensor communication protocol. No proprietary parsing.
module RecordCodec {
    const VERSION = 1;

    function capture(range as RangeMeasurement, weather as EnvironmentalMeasurement or Null,
                     connected as Boolean) as MeasurementRecord {
        var age = null as Number or Null;
        var stale = true;
        if (weather != null) {
            var elapsed = range.receivedAtMs - weather.receivedAtMs;
            // A discontinuity has unknown age, rather than an invented zero.
            if (elapsed >= 0) { age = elapsed / 1000; }
            stale = Freshness.isStale(weather.receivedAtMs, range.receivedAtMs, AppConfig.WEATHER_STALE_MS);
        }
        return new MeasurementRecord({
            "timestamp" => range.timestamp,
            "distance" => range.distance,
            "unit" => range.unit,
            "azimuth" => range.azimuth,
            "inclination" => range.inclination,
            "windSpeed" => weather == null ? null : weather.windSpeed,
            "windDirection" => weather == null ? null : weather.windDirection,
            "temperature" => weather == null ? null : weather.temperature,
            "pressure" => weather == null ? null : weather.pressure,
            "humidity" => weather == null ? null : weather.humidity,
            "environmentalTimestamp" => weather == null ? null : weather.timestamp,
            "environmentalAgeSeconds" => age,
            "environmentalStale" => stale,
            "environmentalConnected" => connected,
            "rangeSource" => "MockRangefinder",
            "weatherSource" => weather == null ? null : "MockWeather",
            "simulated" => true
        } as RecordData);
    }

    function decode(raw as Object or Null) as MeasurementRecord or Null {
        if (!(raw instanceof Dictionary)) { return null; }
        var input = raw as Dictionary<Object, Object or Null>;
        var required = ["timestamp", "distance", "unit", "azimuth", "inclination",
            "windSpeed", "windDirection", "temperature", "pressure", "humidity",
            "environmentalTimestamp", "environmentalAgeSeconds", "environmentalStale",
            "environmentalConnected", "rangeSource", "weatherSource", "simulated"];
        for (var i = 0; i < required.size(); i += 1) {
            if (!input.hasKey(required[i])) { return null; }
        }
        var unit = input["unit"];
        if (!(unit instanceof String) || !(unit.equals("m") || unit.equals("yd"))) { return null; }
        if (!nonNegativeInteger(input["timestamp"]) || !boundedFloat(input["distance"], 0.0, 1000000000.0)) { return null; }
        if (!optionalFloat(input["azimuth"], 0.0, 360.0) || !optionalFloat(input["inclination"], -90.0, 90.0) ||
            !optionalFloat(input["windSpeed"], 0.0, 1000000000.0) || !optionalFloat(input["windDirection"], 0.0, 360.0) ||
            !optionalFloat(input["temperature"], -273.15, 1000000000.0) || !optionalFloat(input["pressure"], 0.0, 1000000000.0) ||
            !optionalFloat(input["humidity"], 0.0, 100.0)) { return null; }
        if (!(input["environmentalStale"] instanceof Boolean) || !(input["environmentalConnected"] instanceof Boolean) ||
            !(input["simulated"] instanceof Boolean) || !sourceName(input["rangeSource"])) { return null; }
        var at = input["environmentalTimestamp"];
        var age = input["environmentalAgeSeconds"];
        if (at == null) {
            if (age != null || input["weatherSource"] != null || !(input["environmentalStale"] as Boolean)) { return null; }
            var fields = ["windSpeed", "windDirection", "temperature", "pressure", "humidity"];
            for (var j = 0; j < fields.size(); j += 1) {
                if (input[fields[j]] != null) { return null; }
            }
        } else {
            if (!nonNegativeInteger(at) || !sourceName(input["weatherSource"])) { return null; }
            if (age != null && !nonNegativeInteger(age)) { return null; }
            if (age == null && !(input["environmentalStale"] as Boolean)) { return null; }
        }
        // Copy only known scalar fields; discard any unexpected keys/objects.
        var data = {} as RecordData;
        for (var k = 0; k < required.size(); k += 1) {
            var key = required[k] as String;
            data[key] = input[key] as RecordScalar;
        }
        return new MeasurementRecord(data);
    }

    function nonNegativeInteger(value as Object or Null) as Boolean {
        return value instanceof Number && value >= 0;
    }

    function sourceName(value as Object or Null) as Boolean {
        return value instanceof String && value.length() > 0 && value.length() <= 32;
    }

    function boundedFloat(value as Object or Null, low as Float, high as Float) as Boolean {
        // Both comparisons also reject NaN and infinities.
        return value instanceof Float && value >= low && value <= high;
    }

    function optionalFloat(value as Object or Null, low as Float, high as Float) as Boolean {
        return value == null || boundedFloat(value, low, high);
    }
}
