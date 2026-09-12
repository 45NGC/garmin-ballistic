import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Composition root only: acquisition and presentation live in separate modules.
class SensorViewerApp extends Application.AppBase {
    private var _controller as DemoController;

    function initialize() {
        AppBase.initialize();
        _controller = new DemoController();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [new DashboardView(_controller), new DashboardDelegate(_controller)];
    }

    function onStop(state as Dictionary or Null) as Void {
        _controller.stop();
    }

    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }
}
