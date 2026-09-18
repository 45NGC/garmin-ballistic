import Toybox.Lang;
import Toybox.Test;

(:test)
function freshnessBoundaries(logger as Test.Logger) as Boolean {
    Test.assert(Freshness.isStale(null, 1000, 15000));
    Test.assert(!Freshness.isStale(1000, 15999, 15000));
    Test.assert(Freshness.isStale(1000, 16000, 15000));
    Test.assert(Freshness.isStale(1000, 999, 15000));
    Test.assertEqual(Freshness.status(false, 1000, 16000, 15000), "DESC./ANT.");
    Test.assertEqual(Freshness.status(false, 1000, 1001, 15000), "SIN CONEX.");
    return true;
}

(:test)
function displayConversionsPreserveSource(logger as Test.Logger) as Boolean {
    var range = new RangeMeasurement(100, 0, 100.0, "yd", null, null);
    Test.assertEqual(DisplayUnits.distance(range, false), "91");
    Test.assertEqual(DisplayUnits.distance(range, true), "100");
    Test.assertEqual(range.distance, 100.0);
    Test.assertEqual(range.unit, "yd");
    Test.assertEqual(DisplayUnits.wind(4.2, true), "9.4 mph");
    Test.assertEqual(DisplayUnits.temperature(0.0, true), "32 °F");
    Test.assertEqual(DisplayUnits.pressure(1013.25, true), "29.92 inHg");
    Test.assertEqual(DisplayUnits.wind(null, false), "--");
    Test.assertEqual(DisplayUnits.wind(0.0, false), "0.0 m/s");
    Test.assertEqual(DisplayUnits.distance(new RangeMeasurement(100, 0, 1.0, "?", null, null), false), "--");
    return true;
}

(:test)
class DemoProbe {
    var rangeCount as Number = 0;
    var weatherCount as Number = 0;
    var latestRange as RangeMeasurement or Null = null;

    function initialize() {}
    function onState(state as Number, message as String or Null) as Void {}
    function onRange(value as RangeMeasurement) as Void {
        rangeCount += 1;
        latestRange = value;
    }
    function onWeather(value as EnvironmentalMeasurement) as Void {
        weatherCount += 1;
    }
}

(:test)
function independentSourcesAndLifecycle(logger as Test.Logger) as Boolean {
    var probe = new DemoProbe();
    var rangefinder = new MockRangefinderProvider();
    var weather = new MockWeatherProvider();
    rangefinder.start(probe.method(:onRange), probe.method(:onState));
    weather.start(probe.method(:onWeather), probe.method(:onState));
    rangefinder.pump(99, -1000, false);
    weather.pump(99, -1000);
    rangefinder.pump(100, 0, false);
    weather.pump(100, 0);
    Test.assertEqual(probe.rangeCount, 1);
    Test.assertEqual(probe.weatherCount, 1);
    var first = probe.latestRange as RangeMeasurement;

    rangefinder.pump(101, 1000, false);
    Test.assertEqual(probe.rangeCount, 1);
    weather.setScenario(MockScenario.DISCONNECTED);
    weather.pump(108, 8000);
    rangefinder.pump(108, 8000, false);
    Test.assertEqual(probe.weatherCount, 1);
    Test.assertEqual(probe.rangeCount, 2);
    // Earlier sample objects must remain unchanged for future history snapshots.
    Test.assertEqual(first.distance, 428.0);
    Test.assertEqual(first.timestamp, 100);

    rangefinder.stop();
    rangefinder.pump(110, 10000, true);
    Test.assertEqual(probe.rangeCount, 2);
    rangefinder.start(probe.method(:onRange), probe.method(:onState));
    rangefinder.pump(110, 10000, true);
    rangefinder.pump(110, 10000, true);
    Test.assertEqual(probe.rangeCount, 3);
    rangefinder.setScenario(MockScenario.DISCONNECTED);
    rangefinder.pump(111, 11000, true);
    Test.assertEqual(probe.rangeCount, 3);
    rangefinder.stop();
    weather.stop();
    return true;
}
