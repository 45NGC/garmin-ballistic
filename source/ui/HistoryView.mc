import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// One record per page keeps the summary readable on the round 280px display.
class HistoryView extends WatchUi.View {
    private var _history as MeasurementRepository;
    private var _index as Number = 0;

    function initialize(history as MeasurementRepository) {
        View.initialize();
        _history = history;
    }

    function onShow() as Void {
        if (_index >= _history.count()) { _index = 0; }
        WatchUi.requestUpdate();
    }

    function move(delta as Number) as Void {
        var next = _index + delta;
        if (next >= 0 && next < _history.count()) { _index = next; }
        WatchUi.requestUpdate();
    }

    function selected() as MeasurementRecord or Null { return _history.get(_index); }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var record = selected();
        var count = _history.count();
        var title = record != null && record.isSimulated() ? "DEMO HIST. " : "HISTORIAL ";
        line(dc, 0.10, title + (count == 0 ? "0" : (_index + 1).toString() + "/" + count.toString()), 0.66, false);
        if (record == null) {
            line(dc, 0.36, "Sin mediciones", 0.85, false);
            line(dc, 0.49, "guardadas", 0.85, false);
        } else {
            var range = record.getRange();
            var weather = record.getWeather();
            var imperial = AppConfig.isImperial();
            line(dc, 0.22, DisplayUnits.timestamp(range.timestamp), 0.82, false);
            line(dc, 0.40, DisplayUnits.distance(range, imperial), 0.80, true);
            line(dc, 0.54, imperial ? "yd" : "m", 0.60, false);
            line(dc, 0.64, "VIENTO " + DisplayUnits.wind(weather == null ? null : weather.windSpeed, imperial), 0.86, false);
            line(dc, 0.73, "METEO " + record.weatherStatus(), 0.80, false);
        }
        if (_history.hasWarning()) {
            var problem = _history.problem();
            line(dc, 0.82, problem == null ? _history.unsavedCount().toString() + " sin guardar" : problem, 0.72, false);
        } else {
            line(dc, 0.82, record == null ? "MENU: borrar" : (record.isSimulated() ? "DEMO · START: detalle" : "START: detalle"), 0.72, false);
        }
        line(dc, 0.91, "UP/DOWN · MENU", 0.48, false);
    }

    private function line(dc as Graphics.Dc, y as Float, value as String, width as Float, large as Boolean) as Void {
        var fonts = large ? [Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_LARGE]
            : [Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY];
        var font = Graphics.FONT_XTINY;
        var maxHeight = dc.getHeight() * (large ? 0.23 : 0.08);
        for (var i = 0; i < fonts.size(); i += 1) {
            if (dc.getTextWidthInPixels(value, fonts[i]) <= dc.getWidth() * width && dc.getFontHeight(fonts[i]) <= maxHeight) {
                font = fonts[i]; break;
            }
        }
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * y, font, value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
