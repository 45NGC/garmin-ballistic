import Toybox.Application;
import Toybox.Lang;
import Toybox.Test;

(:test)
class MemoryHistoryStore extends HistoryStore {
    var value as Application.Storage.ValueType = null;
    var failRead as Boolean = false;
    var failWrite as Boolean = false;
    var writes as Number = 0;

    function initialize() { HistoryStore.initialize(); }
    function read() as Application.Storage.ValueType {
        if (failRead) { throw new Exception(); }
        return value;
    }
    function write(next as Application.Storage.ValueType) as Void {
        if (failWrite) { throw new Exception(); }
        value = next;
        writes += 1;
    }
}

(:test)
class HistoryFixtures {
    function initialize() {}
    function record(at as Number) as MeasurementRecord {
        return RecordCodec.capture(new RangeMeasurement(at, 20000, 428.0, "yd", 275.0, -2.0),
            new EnvironmentalMeasurement(at - 20, 0, 4.2, 270.0, 14.0, 1009.0, 62.0), false);
    }
}

(:test)
function historySnapshotsAreIndependent(logger as Test.Logger) as Boolean {
    var range = new RangeMeasurement(100, 20000, 428.0, "yd", 275.0, -2.0);
    var weather = new EnvironmentalMeasurement(80, 0, 4.2, 270.0, 14.0, 1009.0, 62.0);
    var record = RecordCodec.capture(range, weather, false);
    range.distance = 500.0;
    weather.windSpeed = 9.0;
    weather.timestamp = 101;
    Test.assertEqual(record.getRange().distance, 428.0);
    var capturedWeather = record.getWeather() as EnvironmentalMeasurement;
    Test.assertEqual(4.2, capturedWeather.windSpeed);
    Test.assertEqual(capturedWeather.timestamp, 80);
    Test.assertEqual(20, record.getAgeSeconds());
    Test.assertEqual(record.weatherStatus(), "DESC./ANT.");
    capturedWeather.windSpeed = 15.0;
    var copy = record.toData();
    copy["distance"] = 900.0;
    Test.assertEqual(record.getRange().distance, 428.0);
    Test.assertEqual(4.2, (record.getWeather() as EnvironmentalMeasurement).windSpeed);
    var decoded = RecordCodec.decode(record.toData()) as MeasurementRecord;
    Test.assertEqual(275.0, decoded.getRange().azimuth);
    Test.assertEqual(-2.0, decoded.getRange().inclination);
    Test.assertEqual(decoded.getRange().unit, "yd");
    Test.assertEqual(62.0, (decoded.getWeather() as EnvironmentalMeasurement).humidity);
    Test.assertEqual(decoded.weatherStatus(), "DESC./ANT.");
    return true;
}

(:test)
function historyMissingAndInvalidFields(logger as Test.Logger) as Boolean {
    var range = new RangeMeasurement(100, 1000, 0.0, "m", null, null);
    var missing = RecordCodec.capture(range, null, false);
    var restored = RecordCodec.decode(missing.toData()) as MeasurementRecord;
    Test.assert(restored.getWeather() == null);
    Test.assert(restored.getAgeSeconds() == null);
    Test.assertEqual(restored.weatherStatus(), "SIN DATOS");
    var partial = RecordCodec.capture(range, new EnvironmentalMeasurement(99, 500, 0.0, null, null, null, null), true);
    Test.assertEqual(0.0, (partial.getWeather() as EnvironmentalMeasurement).windSpeed);
    Test.assert((partial.getWeather() as EnvironmentalMeasurement).temperature == null);
    Test.assert(RecordCodec.decode(partial.toData()) != null);
    var future = RecordCodec.capture(range, new EnvironmentalMeasurement(101, 2000, null, null, null, null, null), true);
    Test.assert(future.getAgeSeconds() == null);
    Test.assertEqual(future.weatherStatus(), "ANTIGUO");
    Test.assert(RecordCodec.decode(future.toData()) != null);

    var invalid = new HistoryFixtures().record(100).toData();
    invalid["humidity"] = 101.0;
    Test.assert(RecordCodec.decode(invalid) == null);
    invalid = new HistoryFixtures().record(100).toData();
    invalid["unit"] = "unknown";
    Test.assert(RecordCodec.decode(invalid) == null);
    invalid = new HistoryFixtures().record(100).toData();
    invalid.remove("windDirection");
    Test.assert(RecordCodec.decode(invalid) == null);
    Test.assert(RecordCodec.decode("invalid") == null);
    return true;
}

(:test)
function historyPersistsAndEvictsOldest(logger as Test.Logger) as Boolean {
    var store = new MemoryHistoryStore();
    var repository = new MeasurementRepository(store);
    repository.load();
    Test.assertEqual(repository.count(), 0);
    for (var i = 0; i < AppConfig.HISTORY_LIMIT + 2; i += 1) {
        // Equal distances are separate measurement EVENTS.
        Test.assert(repository.append(new HistoryFixtures().record(100 + i)));
    }
    Test.assertEqual(repository.count(), AppConfig.HISTORY_LIMIT);
    Test.assertEqual((repository.get(0) as MeasurementRecord).getRange().timestamp, 101 + AppConfig.HISTORY_LIMIT);
    Test.assertEqual((repository.get(AppConfig.HISTORY_LIMIT - 1) as MeasurementRecord).getRange().timestamp, 102);
    var reopened = new MeasurementRepository(store);
    reopened.load();
    reopened.load();
    Test.assertEqual(reopened.count(), AppConfig.HISTORY_LIMIT);
    Test.assertEqual((reopened.get(0) as MeasurementRecord).weatherStatus(), "DESC./ANT.");
    Test.assert(reopened.get(-1) == null);
    Test.assert(reopened.get(AppConfig.HISTORY_LIMIT) == null);
    Test.assert(reopened.clear());
    var empty = new MeasurementRepository(store);
    empty.load();
    Test.assertEqual(empty.count(), 0);
    return true;
}

(:test)
function historyWriteFailuresPreserveCommittedRecords(logger as Test.Logger) as Boolean {
    var store = new MemoryHistoryStore();
    var repository = new MeasurementRepository(store);
    Test.assert(repository.append(new HistoryFixtures().record(100)));
    store.failWrite = true;
    Test.assert(!repository.append(new HistoryFixtures().record(101)));
    Test.assertEqual(repository.count(), 1);
    Test.assertEqual((repository.get(0) as MeasurementRecord).getRange().timestamp, 100);
    Test.assertEqual(repository.unsavedCount(), 1);
    Test.assert(!repository.clear());
    Test.assertEqual(repository.count(), 1);
    var reopened = new MeasurementRepository(store);
    reopened.load();
    Test.assertEqual(reopened.count(), 1);
    store.failWrite = false;
    Test.assert(repository.append(new HistoryFixtures().record(102)));
    Test.assert(repository.hasWarning()); // A later success cannot hide the loss.
    Test.assertEqual(repository.unsavedCount(), 1);
    Test.assert(repository.clear());
    Test.assert(!repository.hasWarning());
    return true;
}

(:test)
function historyCorruptionDoesNotGetOverwritten(logger as Test.Logger) as Boolean {
    var store = new MemoryHistoryStore();
    store.value = {"schemaVersion" => RecordCodec.VERSION, "records" => [new HistoryFixtures().record(100).toData(), "broken"]};
    var repository = new MeasurementRepository(store);
    repository.load();
    Test.assertEqual(repository.count(), 1);
    Test.assert(repository.hasWarning());
    Test.assert(!repository.append(new HistoryFixtures().record(101)));
    Test.assertEqual(store.writes, 0);
    Test.assert(repository.clear());
    Test.assert(repository.append(new HistoryFixtures().record(102)));

    store.value = {"schemaVersion" => 999, "records" => []};
    var unsupported = new MeasurementRepository(store);
    unsupported.load();
    var writes = store.writes;
    Test.assert(!unsupported.append(new HistoryFixtures().record(103)));
    Test.assertEqual(store.writes, writes);
    store.failRead = true;
    var unreadable = new MeasurementRepository(store);
    unreadable.load();
    Test.assert(!unreadable.append(new HistoryFixtures().record(104)));
    Test.assertEqual(store.writes, writes);
    return true;
}

(:test)
function onlyRangeEventsCreateHistory(logger as Test.Logger) as Boolean {
    var store = new MemoryHistoryStore();
    var controller = new DemoController(store);
    controller.onWeather(new EnvironmentalMeasurement(99, 0, 4.2, 270.0, 14.0, 1009.0, 62.0));
    Test.assertEqual(store.writes, 0);
    var range = new RangeMeasurement(100, 20000, 428.0, "m", null, null);
    controller.onRange(range);
    controller.onWeather(new EnvironmentalMeasurement(101, 21000, 9.0, 280.0, 15.0, 1010.0, 63.0));
    Test.assertEqual(store.writes, 1);
    Test.assertEqual(4.2, ((controller.history.get(0) as MeasurementRecord).getWeather() as EnvironmentalMeasurement).windSpeed);
    controller.onRange(range);
    Test.assertEqual(store.writes, 2);
    Test.assertEqual(controller.history.count(), 2);
    return true;
}

(:test)
class IsolatedHistoryStore extends HistoryStore {
    function initialize() { HistoryStore.initialize(); }
    function read() as Application.Storage.ValueType {
        return Application.Storage.getValue("historyRoundTripTest");
    }
    function write(value as Application.Storage.ValueType) as Void {
        Application.Storage.setValue("historyRoundTripTest", value);
    }
}

(:test)
function historyGarminStorageRoundTrip(logger as Test.Logger) as Boolean {
    // Exercise Garmin serialization and the actual value-size limit. The real
    // history and unit settings are never touched by this integration test.
    var previous = Application.Storage.getValue("historyRoundTripTest");
    try {
        var store = new IsolatedHistoryStore();
        var repository = new MeasurementRepository(store);
        Test.assert(repository.clear());
        for (var i = 0; i < AppConfig.HISTORY_LIMIT; i += 1) {
            Test.assert(repository.append(new HistoryFixtures().record(100 + i)));
        }
        var reopened = new MeasurementRepository(new IsolatedHistoryStore());
        reopened.load();
        Test.assert(!reopened.hasWarning());
        Test.assertEqual(reopened.count(), AppConfig.HISTORY_LIMIT);
        Test.assertEqual((reopened.get(0) as MeasurementRecord).getRange().timestamp, 99 + AppConfig.HISTORY_LIMIT);
        Test.assertEqual(62.0, ((reopened.get(0) as MeasurementRecord).getWeather() as EnvironmentalMeasurement).humidity);
    } finally {
        if (previous == null) {
            Application.Storage.deleteValue("historyRoundTripTest");
        } else {
            Application.Storage.setValue("historyRoundTripTest", previous);
        }
    }
    return true;
}
