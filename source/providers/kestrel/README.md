# Adaptador Kestrel — Fase 5

Aquí irá `KestrelWeatherProvider`, usando el protocolo meteorológico autorizado
para el modelo 5700 con LiNK y su firmware. El contrato es
`WeatherProvider`: `start(measurementListener, stateListener)`, `stop()`, `isConnected()` y entrega de
`EnvironmentalMeasurement` por evento.

Confirmar con Nielsen-Kellerman los campos exportados, unidades, significado de
la presión y dirección, autenticación y coexistencia de conexiones. No asumir
que todo lo mostrado en la pantalla del Kestrel se exporta por BLE.
Consultar [la investigación](../../../docs/comunicaciones.md).

Ver [contratos de proveedores](../README.md) para identidad, estados, sesiones
y entrega segura de callbacks. La base no implementa transporte ni parser.
