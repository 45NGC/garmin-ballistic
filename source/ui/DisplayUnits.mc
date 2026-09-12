import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Presentation conversions only; original measurements are never modified.
module DisplayUnits {
    function distance(value as RangeMeasurement or Null, imperial as Boolean) as String {
        if (value == null) {
            return "--";
        }
        var meters = value.distance;
        if (value.unit.equals("yd")) {
            meters *= 0.9144;
        } else if (!value.unit.equals("m")) {
            return "--";
        }
        return (imperial ? meters / 0.9144 : meters).format("%.0f");
    }

    function wind(value as Float or Null, imperial as Boolean) as String {
        if (value == null) { return "--"; }
        return (imperial ? value * 2.236936 : value).format("%.1f") + (imperial ? " mph" : " m/s");
    }

    function temperature(value as Float or Null, imperial as Boolean) as String {
        if (value == null) { return "--"; }
        return (imperial ? value * 1.8 + 32.0 : value).format("%.0f") + (imperial ? " °F" : " °C");
    }

    function pressure(value as Float or Null, imperial as Boolean) as String {
        if (value == null) { return "--"; }
        return imperial ? (value / 33.86389).format("%.2f") + " inHg" : value.format("%.0f") + " hPa";
    }

    function direction(value as Float or Null) as String {
        return value == null ? "--" : value.format("%.0f") + "°";
    }

    function time(value as RangeMeasurement or Null) as String {
        if (value == null) { return "--:--:--"; }
        var info = Gregorian.info(new Time.Moment(value.timestamp), Time.FORMAT_SHORT);
        return info.hour.format("%02d") + ":" + info.min.format("%02d") + ":" + info.sec.format("%02d");
    }
}
