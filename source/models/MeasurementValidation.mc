import Toybox.Lang;

// Sanity checks on decoded measurements, not device specifications or physics.
module MeasurementValidation {
    function number(value as Float, low as Float, high as Float) as Boolean {
        return value >= low && value <= high;
    }
    function optional(value as Float or Null, low as Float, high as Float) as Boolean {
        return value == null || number(value, low, high);
    }
    function range(value as RangeMeasurement) as Boolean {
        return value.timestamp >= 0 && (value.unit.equals("m") || value.unit.equals("yd")) &&
            number(value.distance, 0.0, 1000000000.0) && optional(value.azimuth, 0.0, 360.0) &&
            optional(value.inclination, -90.0, 90.0);
    }
    function weather(value as EnvironmentalMeasurement) as Boolean {
        return value.timestamp >= 0 && optional(value.windSpeed, 0.0, 1000000000.0) &&
            optional(value.windDirection, 0.0, 360.0) && optional(value.temperature, -273.15, 1000000000.0) &&
            optional(value.pressure, 0.0, 1000000000.0) && optional(value.humidity, 0.0, 100.0);
    }
}
