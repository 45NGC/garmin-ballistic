import Toybox.Application;
import Toybox.Lang;

// Narrow I/O boundary, replaceable by an in-memory store in Monkey C tests.
// One key keeps schema + records together. Never clear other app settings.
class HistoryStore {
    const KEY = "measurementHistory";

    function initialize() {}
    function read() as Application.Storage.ValueType {
        return Application.Storage.getValue(KEY);
    }
    function write(value as Application.Storage.ValueType) as Void {
        Application.Storage.setValue(KEY, value);
    }
}
