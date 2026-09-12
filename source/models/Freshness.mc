import Toybox.Lang;

module Freshness {
    // A clock discontinuity is treated conservatively. Clock adjustments to
    // Unix time do not change freshness because the caller uses getTimer().
    function isStale(receivedAt as Number or Null, now as Number, limit as Number) as Boolean {
        if (receivedAt == null) {
            return true;
        }
        var elapsed = now - receivedAt;
        return elapsed < 0 || elapsed >= limit;
    }

    function status(connected as Boolean, receivedAt as Number or Null,
                    now as Number, limit as Number) as String {
        if (receivedAt == null) {
            return connected ? "SIN DATOS" : "SIN CONEX.";
        }
        if (isStale(receivedAt, now, limit)) {
            return connected ? "ANTIGUO" : "DESC./ANT.";
        }
        return connected ? "OK" : "SIN CONEX.";
    }
}
