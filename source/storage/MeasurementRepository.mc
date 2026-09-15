import Toybox.Application;
import Toybox.Lang;

class MeasurementRepository {
    private var _store as HistoryStore;
    private var _records as Array<MeasurementRecord> = [];
    private var _loaded as Boolean = false;
    private var _writable as Boolean = true;
    private var _problem as String or Null = null;
    private var _unsaved as Number = 0;

    function initialize(store as HistoryStore) { _store = store; }

    function load() as Void {
        if (_loaded) { return; }
        _loaded = true;
        try {
            var raw = _store.read();
            if (raw == null) { return; }
            if (!(raw instanceof Dictionary)) { blockWrites("Historial dañado"); return; }
            var version = raw["schemaVersion"];
            if (!(version instanceof Number) || version != RecordCodec.VERSION) {
                blockWrites("Formato no compatible"); return;
            }
            var rows = raw["records"];
            if (!(rows instanceof Array) || rows.size() > AppConfig.HISTORY_LIMIT) {
                blockWrites("Historial dañado"); return;
            }
            for (var i = 0; i < rows.size(); i += 1) {
                var record = RecordCodec.decode(rows[i]);
                if (record == null) {
                    blockWrites("Registros dañados");
                } else {
                    _records.add(record);
                }
            }
        } catch (error instanceof Exception) {
            blockWrites("Error al leer historial");
        }
    }

    private function blockWrites(message as String) as Void {
        _writable = false;
        _problem = message;
    }

    function count() as Number { return _records.size(); }
    function get(index as Number) as MeasurementRecord or Null {
        return index >= 0 && index < _records.size() ? _records[index] : null;
    }
    function unsavedCount() as Number { return _unsaved; }
    function problem() as String or Null { return _problem; }
    function hasWarning() as Boolean { return _problem != null || _unsaved > 0; }

    function append(record as MeasurementRecord) as Boolean {
        load();
        if (!_writable) { _unsaved += 1; return false; }
        if (RecordCodec.decode(record.toData()) == null) {
            _problem = "Medición no válida";
            _unsaved += 1;
            return false;
        }
        // Newest first. Keep the previous list until the complete write succeeds.
        var next = [record] as Array<MeasurementRecord>;
        for (var i = 0; i < _records.size() && next.size() < AppConfig.HISTORY_LIMIT; i += 1) {
            next.add(_records[i]);
        }
        try {
            persist(next);
            _records = next;
            _problem = null;
            // A subsequent success does not hide previously lost measurements.
            return true;
        } catch (error instanceof Exception) {
            _problem = "No se pudo guardar";
            _unsaved += 1;
            return false;
        }
    }

    // Called only after the UI's explicit erase confirmation.
    function clear() as Boolean {
        try {
            var empty = [] as Array<MeasurementRecord>;
            persist(empty);
            _records = empty;
            _loaded = true;
            _writable = true;
            _problem = null;
            _unsaved = 0;
            return true;
        } catch (error instanceof Exception) {
            _problem = "No se pudo borrar";
            return false;
        }
    }

    private function persist(records as Array<MeasurementRecord>) as Void {
        var rows = [] as Array<Application.Storage.ValueType>;
        for (var i = 0; i < records.size(); i += 1) {
            rows.add(records[i].toData() as Application.Storage.ValueType);
        }
        _store.write({"schemaVersion" => RecordCodec.VERSION, "records" => rows});
    }
}
