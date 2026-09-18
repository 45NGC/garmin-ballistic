import Toybox.Lang;
import Toybox.WatchUi;

class DashboardDelegate extends WatchUi.BehaviorDelegate {
    private var _controller as SensorController;
    private var _demo as DemoDriver or Null;

    function initialize(controller as SensorController, demo as DemoDriver or Null) {
        BehaviorDelegate.initialize();
        _controller = controller;
        _demo = demo;
    }

    function onSelect() as Boolean {
        var demo = _demo;
        if (demo == null) { return false; }
        demo.measureNow();
        return true;
    }

    function onMenu() as Boolean {
        var menu = new WatchUi.Menu2({:title => "Sensores"});
        menu.addItem(new WatchUi.MenuItem("Historial", "Últimas " + AppConfig.HISTORY_LIMIT.toString() + " mediciones", :history, null));
        menu.addItem(new WatchUi.MenuItem("Cambiar unidades", AppConfig.isImperial() ? "Ahora: imperiales" : "Ahora: métricas", :units, null));
        menu.addItem(new WatchUi.MenuItem("Estado telémetro", ProviderState.label(_controller.rangeState), :info, null));
        menu.addItem(new WatchUi.MenuItem("Estado meteo", ProviderState.label(_controller.weatherState), :info, null));
        if (_controller.rangeError != null) {
            menu.addItem(new WatchUi.MenuItem("Error telémetro", _controller.rangeError, :info, null));
        }
        if (_controller.weatherError != null) {
            menu.addItem(new WatchUi.MenuItem("Error meteo", _controller.weatherError, :info, null));
        }
        var demo = _demo;
        if (demo != null) {
            menu.addItem(new WatchUi.MenuItem("Escenario telémetro", demo.rangefinder.scenarioLabel(), :rangeScenario, null));
            menu.addItem(new WatchUi.MenuItem("Escenario meteo", demo.weather.scenarioLabel(), :weatherScenario, null));
        }
        WatchUi.pushView(menu, new SensorMenuDelegate(_controller, demo), WatchUi.SLIDE_UP);
        return true;
    }
}

class SensorMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _controller as SensorController;
    private var _demo as DemoDriver or Null;

    function initialize(controller as SensorController, demo as DemoDriver or Null) {
        Menu2InputDelegate.initialize();
        _controller = controller;
        _demo = demo;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var demo = _demo;
        if (id == :info) { return; }
        if (id == :history) {
            var view = new HistoryView(_controller.history);
            WatchUi.pushView(view, new HistoryDelegate(view, _controller.history), WatchUi.SLIDE_UP);
            return;
        } else if (id == :units) {
            AppConfig.toggleUnits();
        } else if (id == :rangeScenario && demo != null) {
            demo.rangefinder.cycleScenario();
        } else if (id == :weatherScenario && demo != null) {
            demo.weather.cycleScenario();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
