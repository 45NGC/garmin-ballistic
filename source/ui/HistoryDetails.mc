import Toybox.Lang;
import Toybox.WatchUi;

module HistoryDetails {
    function show(record as MeasurementRecord) as Void {
        var menu = new WatchUi.Menu2({:title => record.isSimulated() ? "Detalle · DEMO" : "Detalle"});
        var range = record.getRange();
        var weather = record.getWeather();
        var imperial = AppConfig.isImperial();
        add(menu, "Recibida en el reloj", DisplayUnits.timestamp(range.timestamp));
        add(menu, "Distancia", DisplayUnits.distance(range, imperial) + (imperial ? " yd" : " m"));
        add(menu, "Distancia original", range.distance.format("%.1f") + " " + range.unit);
        add(menu, "Azimut", DisplayUnits.direction(range.azimuth));
        add(menu, "Inclinación", DisplayUnits.direction(range.inclination));
        add(menu, "Viento", DisplayUnits.wind(weather == null ? null : weather.windSpeed, imperial));
        add(menu, "Dirección viento", DisplayUnits.direction(weather == null ? null : weather.windDirection));
        add(menu, "Temperatura", DisplayUnits.temperature(weather == null ? null : weather.temperature, imperial));
        add(menu, "Presión estación", DisplayUnits.pressure(weather == null ? null : weather.pressure, imperial));
        var humidity = weather == null ? null : weather.humidity;
        add(menu, "Humedad", humidity == null ? "--" : humidity.format("%.1f") + " %");
        add(menu, "Meteo recibida", weather == null ? "--" : DisplayUnits.timestamp(weather.timestamp));
        var age = record.getAgeSeconds();
        add(menu, "Edad meteo al medir", age == null ? "Desconocida" : age.toString() + " s");
        add(menu, "Estado meteo al medir", record.weatherStatus());
        add(menu, "Origen distancia", record.rangeSource());
        var source = record.weatherSource();
        add(menu, "Origen meteo", source == null ? "--" : source);
        WatchUi.pushView(menu, new ReadOnlyHistoryDelegate(), WatchUi.SLIDE_UP);
    }

    function add(menu as WatchUi.Menu2, label as String, value as String) as Void {
        menu.addItem(new WatchUi.MenuItem(label, value, null, null));
    }
}

class ReadOnlyHistoryDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() { Menu2InputDelegate.initialize(); }
    function onSelect(item as WatchUi.MenuItem) as Void {}
}
