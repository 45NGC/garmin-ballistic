import Toybox.Lang;

module MockScenario {
    const NORMAL = 0;
    const DISCONNECTED = 1;
    const ERROR = 2;
    const SILENT = 3;
    const PARTIAL = 4;
    const COUNT = 5;

    function label(mode as Number) as String {
        switch (mode) {
            case DISCONNECTED: return "Desconectado";
            case ERROR: return "Error simulado";
            case SILENT: return "Conectado sin datos";
            case PARTIAL: return "Datos parciales";
        }
        return "Normal";
    }
    function nextState(mode as Number, state as Number) as Number {
        if (mode == DISCONNECTED) { return ProviderState.DISCONNECTED; }
        if (mode == ERROR) { return ProviderState.ERROR; }
        if (state == ProviderState.SCANNING) { return ProviderState.CONNECTING; }
        return ProviderState.CONNECTED;
    }
}
