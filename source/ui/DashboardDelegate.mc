import Toybox.Lang;
import Toybox.WatchUi;

class DashboardDelegate extends WatchUi.BehaviorDelegate {
    private var _controller as DemoController;

    function initialize(controller as DemoController) {
        BehaviorDelegate.initialize();
        _controller = controller;
    }

    function onSelect() as Boolean {
        _controller.measureNow();
        return true;
    }

    function onMenu() as Boolean {
        var menu = new WatchUi.Menu2({:title => "Demo de sensores"});
        menu.addItem(new WatchUi.MenuItem("Historial", "Últimas " + AppConfig.HISTORY_LIMIT.toString() + " mediciones", :history, null));
        menu.addItem(new WatchUi.MenuItem("Cambiar unidades", AppConfig.isImperial() ? "Ahora: imperiales" : "Ahora: métricas", :units, null));
        menu.addItem(new WatchUi.MenuItem("Telémetro simulado", "Conectar / desconectar", :rangeConnection, null));
        menu.addItem(new WatchUi.MenuItem("Meteo simulada", "Conectar / desconectar", :weatherConnection, null));
        WatchUi.pushView(menu, new DemoMenuDelegate(_controller), WatchUi.SLIDE_UP);
        return true;
    }
}

class DemoMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _controller as DemoController;

    function initialize(controller as DemoController) {
        Menu2InputDelegate.initialize();
        _controller = controller;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :history) {
            var view = new HistoryView(_controller.history);
            WatchUi.pushView(view, new HistoryDelegate(view, _controller.history), WatchUi.SLIDE_UP);
            return;
        } else if (id == :units) {
            AppConfig.toggleUnits();
        } else if (id == :rangeConnection) {
            _controller.rangefinder.toggleConnection();
        } else if (id == :weatherConnection) {
            _controller.weatherProvider.toggleConnection();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
