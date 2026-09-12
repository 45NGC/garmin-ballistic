# Adaptador Terrapin X — Fase 4

Aquí irán `TerrapinRangefinderProvider` y el ciclo BLE. El contrato inicial es
`RangefinderProvider`: `start(listener)`, `stop()`, `isConnected()` y entrega de
`RangeMeasurement` por evento. La clase base no abre conexiones.

No hay UUID ni tramas de ejemplo atribuidos al fabricante. Para implementarlo
necesitamos la especificación de GATT y mensajes, firmware/modo de conexión,
semántica de distancia/unidades, azimut e inclinación y muestras verificadas.
Consultar [la investigación](../../../docs/comunicaciones.md).
