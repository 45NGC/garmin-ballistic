import Toybox.Lang;

// Phase 1 subset. Timestamp is the WATCH reception time (Unix seconds).
// receivedAtMs is session-only monotonic time; never persist it across launches.
class RangeMeasurement {
    var timestamp as Number;
    var receivedAtMs as Number;
    var distance as Float;
    var unit as String;
    var azimuth as Float or Null;
    var inclination as Float or Null;

    function initialize(at as Number, tick as Number, value as Float, sourceUnit as String,
                        bearing as Float or Null, angle as Float or Null) {
        timestamp = at;
        receivedAtMs = tick;
        distance = value;
        unit = sourceUnit;
        azimuth = bearing;
        inclination = angle;
    }
}
