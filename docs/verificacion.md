# Verificación de Fases 1 y 2

## Automatizada

Ejecutar `bash scripts/build.sh --test` y `monkeydo bin/SensorViewer-tests.prg
fenix7x -t` con el simulador abierto. Se esperan diez tests sin fallos (tres de demo y siete de historial):

- `freshnessBoundaries`: ausencia, límite exacto y discontinuidad temporal,
  incluida la distinción entre desconexión y antigüedad.
- `displayConversionsPreserveSource`: conversiones, fuente en yardas, unidad
  desconocida, valor ausente y viento cero.
- `independentSourcesAndLifecycle`: cadencia, fuentes independientes, muestras
  anteriores intactas, parada, reinicio y desconexión con medición manual.

- `historySnapshotsAreIndependent`: copia de distancia y ambiente, getters
  defensivos, serialización de campos opcionales y estado al medir.
- `historyMissingAndInvalidFields`: ambiente ausente/parcial, viento cero,
  edad desconocida, unidad/campos/valores inválidos.
- `historyPersistsAndEvictsOldest`: límite de 20, orden, distancias iguales,
  reapertura del repositorio y borrado persistente.
- `historyWriteFailuresPreserveCommittedRecords`: fallos de guardado/borrado,
  conservación del registro anterior y aviso de pérdidas de sesión.
- `historyCorruptionDoesNotGetOverwritten`: recuperación parcial, bloqueo de
  escrituras ante corrupción, versión desconocida y fallo de lectura.
- `onlyRangeEventsCreateHistory`: solo los callbacks de distancia guardan;
  actualizar ambiente no crea ni modifica registros previos.
- `historyGarminStorageRoundTrip`: serialización real mediante Storage,
  capacidad completa y recarga. Usa una clave aislada y restaura su contenido;
  no toca historial ni ajustes de unidades.

La compilación genérica con SDK 9.2.0 y tipos estrictos se ha completado. Los
**tests todavía no se han ejecutado**: falta el perfil `fenix7x` y bibliotecas
WebKit del simulador en este Linux. También están pendientes estas comprobaciones
visuales y la prueba en hardware.

## Manual — pendiente en simulador fēnix 7X (280 × 280)

1. Abrir: comprobar `DEMO`, 428 m, hora, 4.2 m/s, 275°, 14 °C y 1009 hPa.
   Distancia claramente mayor; etiquetas, acentos y unidades sin recorte.
2. Esperar 8 s: cambia la distancia y su hora. Entre eventos de distancia,
   la hora de esa muestra permanece fija aunque cambie el viento.
3. START: llega una distancia nueva. UP/MENU: abre el menú; BACK: regresa.
4. Cambiar a imperiales: verificar yd, mph, °F, inHg. Reiniciar la app y
   comprobar la preferencia. Cambiar desde los ajustes externos y comprobar
   el refresco de la vista. La hora de la muestra no cambia por convertir unidades.
5. Desconectar solo meteo: los valores se mantienen, aparece `SIN CONEX.` y,
   desde los 15 s de la última muestra, `DESC./ANT.`. La distancia sigue llegando.
6. Reconectar meteo: nueva muestra, indicador `OK`. Desconectar solo telémetro:
   distancia y hora se mantienen, START no genera muestras, meteo sigue viva.
   Desde los 30 s de la última distancia aparece `DESC./ANT.`.
7. Desconectar ambos y entrar/salir varias veces del menú: no aparecen nuevas
   muestras, las marcas de antigüedad no se reinician. Reconectar ambos.
8. Abrir menú o salir: comprobar en el depurador que se detiene el temporizador.
   Volver: se reanuda sin duplicar temporizadores. Repetir varias veces y revisar
   memoria. El historial nunca supera 20 registros.
9. Verificar también valores ausentes (`--`) mediante fixtures en el depurador;
   un cero válido debe seguir apareciendo como cero.

No se declara soporte de otros productos en el manifiesto. Antes de ampliarlo,
añadir su perfil y revisar recortes, fuentes y controles en cada resolución.
Las pruebas de radio, latencia, batería y legibilidad exterior requieren reloj
y sensores físicos en fases posteriores.

## Historial — guion de Fase 2

1. Abrir la app y generar tres mediciones con START. Entrar en UP/MENU →
   Historial. Verificar el orden: 1/N es la más reciente; UP/DOWN cambia de
   registro; no se sale de los límites primero/último.
2. START abre detalle. Comprobar distancia/unidad original, fecha y hora,
   azimut/inclinación (`--` en el mock actual), viento/dirección, temperatura,
   presión, humedad (62 % en el mock), hora/edad meteo y procedencia DEMO.
3. Volver al visor y esperar que cambie el viento. Abrir un registro anterior:
   debe conservar sus valores. La pantalla principal muestra ambiente actual,
   mientras el detalle conserva el capturado al medir.
4. Desconectar meteo, esperar más de 15 s y generar una distancia. El detalle
   debe conservar los últimos valores y marcar `DESC./ANT.` al medir. Cambiar
   unidades: los valores presentados cambian, los originales y las horas no.
5. Cerrar/reabrir la app. El historial anterior debe seguir presente, junto con
   la nueva medición que genera la demo al arrancar. Mantener la misma clave
   de aplicación al actualizar para comprobar persistencia entre versiones.
6. Generar más de 20 distancias. Solo quedan las últimas 20 guardadas, con la
   más antigua reemplazada en cada nueva escritura. Revisar memoria y tamaño
   de Storage con este límite en el simulador del fēnix 7X.
7. Dentro del historial, mantener UP/MENU. Seleccionar Cancelar o pulsar BACK:
   el historial sigue intacto. Repetir y seleccionar Borrar todo: aparece
   `Sin mediciones guardadas`. Cerrar/reabrir sin activar de nuevo el visor
   antes de salir; los registros antiguos no deben reaparecer. La demo genera
   una medición nueva al volver al visor o al iniciar de nuevo la app.
8. Comprobar que el borrado conserva las unidades. Consultar historial/detalle
   no genera registros mientras el visor está oculto.
9. Con el almacén de pruebas, provocar fallos de lectura/escritura. El visor
   debe seguir operativo y mostrar `DEMO · ERROR REG.`. El menú de historial
   muestra el motivo y las mediciones no guardadas de esta sesión. Una escritura
   posterior correcta no oculta pérdidas anteriores. Si falla el borrado,
   permanece el menú con `No se pudo borrar` y se puede cancelar o reintentar.
10. Cargar una fila inválida o versión desconocida con fixtures. No deben
    sobrescribirse automáticamente. Consultar los registros recuperados; el
    borrado confirmado permite comenzar otra vez.
