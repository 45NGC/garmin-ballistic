# Almacenamiento — Fase 2 implementada

`MeasurementRepository` guarda hasta 20 registros mediante `HistoryStore`, un
adaptador de `Application.Storage`. `RecordCodec` convierte entre datos
persistibles y `MeasurementRecord`; no interpreta protocolos de sensores.

- Clave única `measurementHistory`, con `schemaVersion: 1` y `records` ordenados
  de más reciente a más antiguo. Los registros son diccionarios de escalares,
  sin símbolos, referencias a muestras ni ticks de sesiones anteriores.
- Una escritura por evento de distancia; ninguna desde la UI o por evento meteo.
  El borrado escribe una lista vacía y no toca `Application.Properties`.
- Se actualiza la lista en memoria después de que Storage acepte la escritura.
  Si falla, el registro nuevo no se incorpora y se incrementa el aviso de pérdidas
  de esta sesión; el visor sigue activo. No se reintenta la medición perdida.
- Los registros válidos de un archivo parcialmente corrupto se pueden consultar,
  pero se bloquean nuevas escrituras hasta borrar explícitamente o reiniciar
  para intentar leer otra vez. Los formatos desconocidos se conservan igual.
- Una escritura única reduce estados intermedios; no se promete transaccionalidad
  ante un corte eléctrico, que requiere validación en hardware.
- Los 20 registros son un límite conservador. El test `historyGarminStorageRoundTrip`
  valida el tamaño con el serializador Garmin; su ejecución en el fēnix 7X queda
  pendiente. No ampliar capacidad sin medir almacenamiento y memoria.

Ver [arquitectura](../../docs/arquitectura.md) y
[pruebas](../../docs/verificacion.md). La elección de unidades es independiente.
