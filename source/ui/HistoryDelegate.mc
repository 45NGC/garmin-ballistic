import Toybox.Lang;
import Toybox.WatchUi;

class HistoryDelegate extends WatchUi.BehaviorDelegate {
    private var _view as HistoryView;
    private var _history as MeasurementRepository;

    function initialize(view as HistoryView, history as MeasurementRepository) {
        BehaviorDelegate.initialize();
        _view = view;
        _history = history;
    }

    function onNextPage() as Boolean { _view.move(1); return true; }
    function onPreviousPage() as Boolean { _view.move(-1); return true; }
    function onSelect() as Boolean {
        var record = _view.selected();
        if (record != null) { HistoryDetails.show(record); }
        return true;
    }
    function onBack() as Boolean { WatchUi.popView(WatchUi.SLIDE_DOWN); return true; }

    function onMenu() as Boolean {
        // Explicit confirmation; BACK and the first/default item cancel.
        var menu = new WatchUi.Menu2({:title => "¿Borrar historial?"});
        menu.addItem(new WatchUi.MenuItem("Cancelar", "Conservar mediciones", :cancel, null));
        menu.addItem(new WatchUi.MenuItem("Borrar todo", "Solo el historial", :erase, null));
        var problem = _history.problem();
        if (problem != null) {
            menu.addItem(new WatchUi.MenuItem("Aviso", problem, :info, null));
        }
        if (_history.unsavedCount() > 0) {
            menu.addItem(new WatchUi.MenuItem("Sin guardar esta sesión", _history.unsavedCount().toString(), :info, null));
        }
        WatchUi.pushView(menu, new ClearHistoryDelegate(_history, menu), WatchUi.SLIDE_UP);
        return true;
    }
}

class ClearHistoryDelegate extends WatchUi.Menu2InputDelegate {
    private var _history as MeasurementRepository;
    private var _menu as WatchUi.Menu2;

    function initialize(history as MeasurementRepository, menu as WatchUi.Menu2) {
        Menu2InputDelegate.initialize();
        _history = history;
        _menu = menu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :cancel) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (item.getId() == :erase) {
            if (_history.clear()) {
                WatchUi.popView(WatchUi.SLIDE_DOWN);
            } else {
                _menu.setTitle("No se pudo borrar");
                WatchUi.requestUpdate();
            }
        }
    }
}
