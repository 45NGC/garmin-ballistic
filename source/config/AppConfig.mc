import Toybox.Application;
import Toybox.Lang;

module AppConfig {
    const METRIC = 0;
    const IMPERIAL = 1;
    const UI_INTERVAL_MS = 1000;
    const RANGE_INTERVAL_MS = 8000;
    const WEATHER_INTERVAL_MS = 4000;
    const RANGE_STALE_MS = 30000;
    const WEATHER_STALE_MS = 15000;

    function isImperial() as Boolean {
        var units = Application.Properties.getValue("UnitSystem");
        return units instanceof Number && units == IMPERIAL;
    }

    function toggleUnits() as Void {
        Application.Properties.setValue("UnitSystem", isImperial() ? METRIC : IMPERIAL);
    }
}
