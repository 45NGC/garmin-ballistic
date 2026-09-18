# Adaptador Terrapin X — Fase 4

Aquí irán `TerrapinRangefinderProvider` y el ciclo BLE. El contrato es
`RangefinderProvider`: `start(measurementListener, stateListener)`, `stop()`, `isConnected()` y entrega de
`RangeMeasurement` por evento. La clase base no abre conexiones.

No hay UUID ni tramas de ejemplo atribuidos al fabricante. Para implementarlo
necesitamos la especificación de GATT y mensajes, firmware/modo de conexión,
semántica de distancia/unidades, azimut e inclinación y muestras verificadas.
Consultar [la investigación](../../../docs/comunicaciones.md).

Ver [contratos de proveedores](../README.md) para identidad, estados, sesiones
y entrega segura de callbacks. La base no implementa transporte ni parser.
