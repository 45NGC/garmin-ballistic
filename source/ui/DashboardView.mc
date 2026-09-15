import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class DashboardView extends WatchUi.View {
    private var _controller as DemoController;

    function initialize(controller as DemoController) {
        View.initialize();
        _controller = controller;
    }

    function onShow() as Void { _controller.start(); }
    function onHide() as Void { _controller.stop(); }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var imperial = AppConfig.isImperial();
        var range = _controller.range;
        var weather = _controller.weather;
        var tick = System.getTimer();
        var rangeTick = range == null ? null : range.receivedAtMs;
        var weatherTick = weather == null ? null : weather.receivedAtMs;
        var rangeStatus = Freshness.status(_controller.rangefinder.isConnected(), rangeTick, tick, AppConfig.RANGE_STALE_MS);
        var weatherStatus = Freshness.status(_controller.weatherProvider.isConnected(), weatherTick, tick, AppConfig.WEATHER_STALE_MS);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        // Proportional safe areas accommodate round screens. Fonts are measured
        // against both width and height; no absolute device pixel coordinates.
        text(dc, w / 2, h * 0.09, _controller.history.hasWarning() ? "DEMO · ERROR REG." : "DEMO · DISTANCIA", w * 0.62, h * 0.07, false);
        text(dc, w / 2, h * 0.235, DisplayUnits.distance(range, imperial), w * 0.80, h * 0.22, true);
        text(dc, w / 2, h * 0.35, imperial ? "yd" : "m", w * 0.25, h * 0.065, false);
        text(dc, w / 2, h * 0.405, DisplayUnits.time(range) + "  " + rangeStatus, w * 0.88, h * 0.07, false);

        dc.drawLine(w * 0.12, h * 0.46, w * 0.88, h * 0.46);
        text(dc, w * 0.29, h * 0.51, "VIENTO", w * 0.38, h * 0.055, false);
        text(dc, w * 0.71, h * 0.51, "DIR. VIENTO", w * 0.38, h * 0.055, false);
        text(dc, w * 0.29, h * 0.60, DisplayUnits.wind(weather == null ? null : weather.windSpeed, imperial), w * 0.38, h * 0.09, false);
        text(dc, w * 0.71, h * 0.60, DisplayUnits.direction(weather == null ? null : weather.windDirection), w * 0.38, h * 0.09, false);
        text(dc, w * 0.29, h * 0.70, "TEMP", w * 0.32, h * 0.055, false);
        text(dc, w * 0.71, h * 0.70, "PRESIÓN", w * 0.32, h * 0.055, false);
        text(dc, w * 0.29, h * 0.78, DisplayUnits.temperature(weather == null ? null : weather.temperature, imperial), w * 0.32, h * 0.08, false);
        text(dc, w * 0.71, h * 0.78, DisplayUnits.pressure(weather == null ? null : weather.pressure, imperial), w * 0.32, h * 0.08, false);
        text(dc, w / 2, h * 0.89, "METEO " + weatherStatus, w * 0.56, h * 0.06, false);
    }

    private function text(dc as Graphics.Dc, x as Numeric, y as Numeric, value as String,
                          width as Numeric, height as Numeric, large as Boolean) as Void {
        var fonts = large
            ? [Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY]
            : [Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY];
        var font = Graphics.FONT_XTINY;
        for (var i = 0; i < fonts.size(); i += 1) {
            if (dc.getTextWidthInPixels(value, fonts[i]) <= width && dc.getFontHeight(fonts[i]) <= height) {
                font = fonts[i];
                break;
            }
        }
        dc.drawText(x, y, font, value, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
