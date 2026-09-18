import Toybox.Lang;

// Optional clock hook for generated sources. Real event-driven adapters need
// no driver; the controller's timer then only refreshes freshness indicators.
class AcquisitionDriver {
    function initialize() {}
    function tick(at as Number, elapsed as Number) as Void {}
}
