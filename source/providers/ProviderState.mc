import Toybox.Lang;

module ProviderState {
    const STOPPED = 0;
    const SCANNING = 1;
    const CONNECTING = 2;
    const CONNECTED = 3;
    const DISCONNECTED = 4;
    const ERROR = 5;

    function label(state as Number) as String {
        switch (state) {
            case SCANNING: return "BUSCANDO";
            case CONNECTING: return "CONECTANDO";
            case CONNECTED: return "CONECTADO";
            case DISCONNECTED: return "SIN CONEX.";
            case ERROR: return "ERROR";
        }
        return "DETENIDO";
    }

    function display(state as Number, receivedAt as Number or Null, now as Number, limit as Number) as String {
        if (state == CONNECTED) { return Freshness.status(true, receivedAt, now, limit); }
        var stale = receivedAt != null && Freshness.isStale(receivedAt, now, limit);
        if (state == DISCONNECTED) { return stale ? "DESC./ANT." : "SIN CONEX."; }
        if (state == ERROR) { return stale ? "ERROR/ANT." : "ERROR"; }
        if (state == SCANNING) { return stale ? "BUSC./ANT." : "BUSCANDO"; }
        if (state == CONNECTING) { return stale ? "CON./ANT." : "CONECTANDO"; }
        return stale ? "PAR./ANT." : "DETENIDO";
    }
}
