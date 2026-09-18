import Toybox.Lang;

typedef ProviderStateListener as Method(state as Number, message as String or Null) as Void;

// Common lifecycle. Each asynchronous transport operation must retain the
// session token from subscription time, including when reconnecting.
class SensorProvider {
    private var _source as String;
    private var _simulated as Boolean;
    private var _state as Number = ProviderState.STOPPED;
    private var _message as String or Null = null;
    private var _stateListener as ProviderStateListener or Null = null;
    private var _active as Boolean = false;
    private var _session as Number = 0;

    function initialize(source as String, simulated as Boolean) {
        if (source.length() == 0 || source.length() > 32) { throw new Exception(); }
        _source = source;
        _simulated = simulated;
    }
    function sourceName() as String { return _source; }
    function isSimulated() as Boolean { return _simulated; }
    function state() as Number { return _state; }
    function errorMessage() as String or Null { return _message; }
    function isConnected() as Boolean { return _active && _state == ProviderState.CONNECTED; }
    function isActive() as Boolean { return _active; }
    function session() as Number { return _session; }
    function accepts(token as Number) as Boolean { return _active && token == _session; }

    protected function begin(listener as ProviderStateListener) as Void {
        _session += 1;
        _active = true;
        _stateListener = listener;
        setState(_session, ProviderState.SCANNING, null);
    }

    protected function setState(token as Number, next as Number, message as String or Null) as Void {
        if (!accepts(token)) { return; }
        if (next < ProviderState.SCANNING || next > ProviderState.ERROR) { return; }
        if (_state == next && _message == message) { return; }
        // Scanning again or losing a link invalidates callbacks from the old
        // connection, even if the provider itself has not been stopped.
        if (_state != next && (next == ProviderState.SCANNING ||
            next == ProviderState.DISCONNECTED || next == ProviderState.ERROR)) { _session += 1; }
        _state = next;
        _message = message;
        var listener = _stateListener;
        if (listener != null) { listener.invoke(next, message); }
    }

    function stop() as Void {
        if (!_active) { return; }
        _active = false;
        _session += 1;
        _state = ProviderState.STOPPED;
        _message = null;
        var listener = _stateListener;
        _stateListener = null;
        if (listener != null) { listener.invoke(_state, null); }
    }
}
