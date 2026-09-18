import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Composition root only: acquisition and presentation live in separate modules.
class SensorViewerApp extends Application.AppBase {
    private var _controller as SensorController;
    private var _demo as DemoDriver;

    function initialize() {
        AppBase.initialize();
        var rangefinder = new MockRangefinderProvider();
        var weather = new MockWeatherProvider();
        _demo = new DemoDriver(rangefinder, weather);
        _controller = new SensorController(rangefinder, weather, new HistoryStore(), _demo);
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [new DashboardView(_controller), new DashboardDelegate(_controller, _demo)];
    }

    function onStop(state as Dictionary or Null) as Void {
        _controller.stop();
    }

    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }
}
