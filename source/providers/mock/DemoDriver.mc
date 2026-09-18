import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

// Simulation and its controls live outside the application controller.
class DemoDriver extends AcquisitionDriver {
    var rangefinder as MockRangefinderProvider;
    var weather as MockWeatherProvider;

    function initialize(rangeProvider as MockRangefinderProvider, weatherProvider as MockWeatherProvider) {
        AcquisitionDriver.initialize();
        rangefinder = rangeProvider;
        weather = weatherProvider;
    }
    function tick(at as Number, elapsed as Number) as Void {
        weather.pump(at, elapsed);
        rangefinder.pump(at, elapsed, false);
    }
    function measureNow() as Void {
        if (rangefinder.isConnected()) { rangefinder.pump(Time.now().value(), System.getTimer(), true); }
    }
}
