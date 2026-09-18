import Toybox.Lang;
import Toybox.Test;

// Event-only providers prove the controller works without a mock driver/pump.
(:test)
class EventRangeProvider extends RangefinderProvider {
    function initialize() { RangefinderProvider.initialize("FixtureRange", false); }
    function connect() as Void { setState(session(), ProviderState.CONNECTED, null); }
    function disconnect() as Void { setState(session(), ProviderState.DISCONNECTED, null); }
    function send(value as RangeMeasurement) as Void { deliver(value, session()); }
    function late(value as RangeMeasurement, token as Number) as Void { deliver(value, token); }
    function lateState(token as Number) as Void { setState(token, ProviderState.ERROR, "Obsolete"); }
}

(:test)
class EventWeatherProvider extends WeatherProvider {
    function initialize() { WeatherProvider.initialize("FixtureWeather", false); }
    function connect() as Void { setState(session(), ProviderState.CONNECTED, null); }
    function send(value as EnvironmentalMeasurement) as Void { deliver(value, session()); }
}

(:test)
class ThrowingRangeProvider extends EventRangeProvider {
    function initialize() { EventRangeProvider.initialize(); }
    function start(listener as RangeListener, stateListener as ProviderStateListener) as Void {
        RangefinderProvider.start(listener, stateListener);
        throw new Exception();
    }
}

(:test)
class StateProbe {
    var states as Array<Number> = [];
    var measurements as Number = 0;
    function initialize() {}
    function onState(state as Number, message as String or Null) as Void { states.add(state); }
    function onRange(value as RangeMeasurement) as Void { measurements += 1; }
}

(:test)
function providerSessionsRejectLateEvents(logger as Test.Logger) as Boolean {
    var range = new EventRangeProvider();
    var probe = new StateProbe();
    var value = new RangeMeasurement(100, 0, 428.0, "m", null, null);
    range.start(probe.method(:onRange), probe.method(:onState));
    var first = range.session();
    range.start(probe.method(:onRange), probe.method(:onState));
    Test.assertEqual(range.session(), first); // start is idempotent.
    Test.assertEqual(probe.states.size(), 1);
    Test.assertEqual(probe.states[0], ProviderState.SCANNING);
    range.connect();
    range.send(value);
    Test.assertEqual(probe.measurements, 1);
    range.stop();
    range.stop();
    range.late(value, first);
    range.lateState(first);
    Test.assertEqual(range.state(), ProviderState.STOPPED);
    Test.assertEqual(probe.measurements, 1);
    Test.assertEqual(probe.states.size(), 3);
    range.start(probe.method(:onRange), probe.method(:onState));
    range.connect();
    range.late(value, first);
    Test.assertEqual(probe.measurements, 1);
    range.send(value);
    Test.assertEqual(probe.measurements, 2);
    var connected = range.session();
    range.disconnect();
    range.connect();
    range.late(value, connected);
    range.lateState(connected);
    Test.assertEqual(probe.measurements, 2);
    Test.assertEqual(range.state(), ProviderState.CONNECTED);
    range.stop();
    return true;
}

(:test)
function controllerUsesInjectedEventsAndProvenance(logger as Test.Logger) as Boolean {
    var range = new EventRangeProvider();
    var weather = new EventWeatherProvider();
    var store = new MemoryHistoryStore();
    var controller = new SensorController(range, weather, store, null);
    controller.start();
    try {
        controller.start();
        range.connect();
        weather.connect();
        var input = new EnvironmentalMeasurement(99, 0, 4.2, 275.0, 14.0, 1009.0, 62.0);
        weather.send(input);
        input.windSpeed = 20.0;
        range.send(new RangeMeasurement(100, 1000, 428.0, "m", null, null));
        var record = controller.history.get(0) as MeasurementRecord;
        Test.assertEqual(record.rangeSource(), "FixtureRange");
        Test.assertEqual("FixtureWeather", record.weatherSource());
        Test.assert(!record.isSimulated());
        Test.assert(!controller.isDemo());
        Test.assertEqual(4.2, (record.getWeather() as EnvironmentalMeasurement).windSpeed);
        controller.onTick(); // With no driver, ticking cannot manufacture data.
        Test.assertEqual(store.writes, 1);
        controller.stop();
        controller.onRange(new RangeMeasurement(101, 2000, 429.0, "m", null, null));
        Test.assertEqual(store.writes, 1);
    } finally { controller.stop(); }
    // A simulated weather provider marks a mixed record only once it actually
    // contributes an environmental sample. The range-only record is real.
    var mixedRange = new EventRangeProvider();
    var mixedWeather = new MockWeatherProvider();
    var mixed = new SensorController(mixedRange, mixedWeather, new MemoryHistoryStore(), null);
    mixed.start();
    try {
        mixedRange.connect();
        mixedRange.send(new RangeMeasurement(100, 1000, 428.0, "m", null, null));
        Test.assert(!(mixed.history.get(0) as MeasurementRecord).isSimulated());
        mixedWeather.pump(100, 1000);
        mixedWeather.pump(101, 2000);
        mixedRange.send(new RangeMeasurement(102, 3000, 429.0, "m", null, null));
        var mixedRecord = mixed.history.get(0) as MeasurementRecord;
        Test.assert(mixedRecord.isSimulated());
        Test.assertEqual(mixedRecord.rangeSource(), "FixtureRange");
        Test.assertEqual("MockWeather", mixedRecord.weatherSource());
    } finally { mixed.stop(); }
    return true;
}

(:test)
function partialAndInvalidSamplesPreserveMeaning(logger as Test.Logger) as Boolean {
    var range = new EventRangeProvider();
    var weather = new EventWeatherProvider();
    var controller = new SensorController(range, weather, new MemoryHistoryStore(), null);
    controller.start();
    try {
        range.connect();
        weather.connect();
        weather.send(new EnvironmentalMeasurement(99, 0, 4.2, 275.0, 14.0, 1009.0, 62.0));
        weather.send(new EnvironmentalMeasurement(100, 1000, 0.0, null, null, null, null));
        range.send(new RangeMeasurement(101, 2000, 428.0, "m", null, null));
        var record = controller.history.get(0) as MeasurementRecord;
        var captured = record.getWeather() as EnvironmentalMeasurement;
        Test.assertEqual(0.0, captured.windSpeed);
        Test.assert(captured.pressure == null);
        Test.assert(captured.temperature == null);
        weather.send(new EnvironmentalMeasurement(102, 3000, 4.2, null, null, null, 101.0));
        Test.assertEqual(controller.weatherState, ProviderState.ERROR);
        Test.assertEqual((controller.weather as EnvironmentalMeasurement).timestamp, 100);
        range.send(new RangeMeasurement(103, 4000, 429.0, "m", null, null));
        Test.assertEqual(controller.history.count(), 2);
        Test.assertEqual((controller.history.get(0) as MeasurementRecord).weatherStatus(), "SIN CONEX.");
        range.send(new RangeMeasurement(104, 5000, -1.0, "m", null, null));
        Test.assertEqual(controller.rangeState, ProviderState.ERROR);
        Test.assertEqual(controller.history.count(), 2);
    } finally { controller.stop(); }
    return true;
}

(:test)
function mockScenariosAreIndependent(logger as Test.Logger) as Boolean {
    var range = new MockRangefinderProvider();
    var weather = new MockWeatherProvider();
    var driver = new DemoDriver(range, weather);
    var controller = new SensorController(range, weather, new MemoryHistoryStore(), driver);
    weather.setScenario(MockScenario.SILENT);
    controller.start();
    try {
        Test.assertEqual(controller.rangeState, ProviderState.SCANNING);
        driver.tick(100, 0);
        Test.assertEqual(controller.rangeState, ProviderState.CONNECTING);
        driver.tick(101, 1000);
        Test.assertEqual(controller.rangeState, ProviderState.CONNECTED);
        Test.assertEqual(controller.weatherState, ProviderState.CONNECTED);
        Test.assert(controller.weather == null);
        Test.assertEqual((controller.history.get(0) as MeasurementRecord).weatherStatus(), "SIN DATOS");
        weather.setScenario(MockScenario.PARTIAL);
        driver.tick(102, 2000);
        driver.tick(103, 3000);
        Test.assert((controller.weather as EnvironmentalMeasurement).pressure == null);
        weather.setScenario(MockScenario.ERROR);
        driver.tick(104, 4000);
        Test.assertEqual(controller.weatherState, ProviderState.ERROR);
        Test.assertEqual(controller.rangeState, ProviderState.CONNECTED);
        weather.setScenario(MockScenario.DISCONNECTED);
        driver.tick(105, 5000);
        Test.assertEqual(controller.weatherState, ProviderState.DISCONNECTED);
        Test.assert(controller.weatherError == null);
        weather.setScenario(MockScenario.NORMAL);
        driver.tick(106, 6000);
        driver.tick(107, 7000);
        Test.assertEqual(1009.0, (controller.weather as EnvironmentalMeasurement).pressure);
        range.setScenario(MockScenario.SILENT);
        driver.tick(108, 8000);
        driver.tick(109, 9000);
        driver.tick(150, 50000);
        Test.assertEqual(controller.history.count(), 1);
        Test.assertEqual(ProviderState.display(controller.rangeState,
            (controller.range as RangeMeasurement).receivedAtMs, 50000, 30000), "ANTIGUO");
        controller.stop();
        driver.tick(151, 51000);
        Test.assertEqual(controller.history.count(), 1);
    } finally { controller.stop(); }
    return true;
}

(:test)
function oneProviderStartFailureDoesNotStopOther(logger as Test.Logger) as Boolean {
    var range = new ThrowingRangeProvider();
    var weather = new EventWeatherProvider();
    var controller = new SensorController(range, weather, new MemoryHistoryStore(), null);
    controller.start();
    try {
        Test.assertEqual(controller.rangeState, ProviderState.ERROR);
        Test.assert(!range.isActive());
        weather.connect();
        weather.send(new EnvironmentalMeasurement(100, 1000, 4.2, null, 14.0, null, null));
        Test.assertEqual(controller.weatherState, ProviderState.CONNECTED);
        Test.assertEqual(4.2, (controller.weather as EnvironmentalMeasurement).windSpeed);
        Test.assertEqual(controller.history.count(), 0);
    } finally { controller.stop(); }
    return true;
}
