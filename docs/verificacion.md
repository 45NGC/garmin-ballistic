# Verificación de Fases 1, 2 y 3

## Automatizada

Ejecutar `bash scripts/build.sh --test` y `monkeydo bin/SensorViewer-tests.prg
fenix7x -t` con el simulador abierto. Se esperan quince tests sin fallos (tres de demo, siete de historial y cinco de proveedores):

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

- `providerSessionsRejectLateEvents`: start/stop idempotentes, eventos y estados
  tardíos rechazados tras parar, reiniciar o perder la conexión.
- `controllerUsesInjectedEventsAndProvenance`: proveedores por eventos sin driver,
  datos copiados y procedencia no simulada conservada en el historial.
- `partialAndInvalidSamplesPreserveMeaning`: campos ausentes reemplazan los antiguos,
  viento cero válido, muestras inválidas rechazadas y fallos independientes.
- `mockScenariosAreIndependent`: los cinco escenarios, transiciones, ausencia de
  datos, antigüedad y parada del driver.
- `oneProviderStartFailureDoesNotStopOther`: error al iniciar un proveedor sin
  impedir que el otro entregue datos.

La compilación genérica con SDK 9.2.0 y tipos estrictos se ha completado. Los
**tests todavía no se han ejecutado**: falta el perfil `fenix7x` y bibliotecas
WebKit del simulador en este Linux. También están pendientes estas comprobaciones
visuales y la prueba en hardware.

## Manual — pendiente en simulador fēnix 7X (280 × 280)

1. Abrir: comprobar BUSCANDO → CONECTANDO durante unos 2 s. Después comprobar `DEMO`, 428 m, hora, 4.2 m/s, 275°, 14 °C y 1009 hPa.
   Distancia claramente mayor; etiquetas, acentos y unidades sin recorte.
2. Esperar 8 s: cambia la distancia y su hora. Entre eventos de distancia,
   la hora de esa muestra permanece fija aunque cambie el viento.
3. START: llega una distancia nueva. UP/MENU: abre el menú; BACK: regresa.
4. Cambiar a imperiales: verificar yd, mph, °F, inHg. Reiniciar la app y
   comprobar la preferencia. Cambiar desde los ajustes externos y comprobar
   el refresco de la vista. La hora de la muestra no cambia por convertir unidades.
5. Elegir escenario Desconectado solo en meteo: los valores se mantienen, aparece `SIN CONEX.` y,
   desde los 15 s de la última muestra, `DESC./ANT.`. La distancia sigue llegando.
6. Volver al escenario Normal en meteo: nueva muestra, indicador `OK`. Desconectar solo telémetro:
   distancia y hora se mantienen, START no genera muestras, meteo sigue viva.
   Desde los 30 s de la última distancia aparece `DESC./ANT.`.
7. Elegir Desconectado en ambos y entrar/salir varias veces del menú: no aparecen nuevas
   muestras, las marcas de antigüedad no se reinician. Reconectar ambos.
8. Abrir menú o salir: comprobar en el depurador que se detiene el temporizador.
   Volver: se reanuda sin duplicar temporizadores. Repetir varias veces y revisar
   memoria. El historial nunca supera 20 registros.
9. Verificar valores ausentes (`--`) con el escenario Datos parciales;
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
   azimut/inclinación (275°/−2° en Normal, `--` en Datos parciales), viento/dirección, temperatura,
   presión, humedad (62 % en el mock), hora/edad meteo y procedencia DEMO.
3. Volver al visor y esperar que cambie el viento. Abrir un registro anterior:
   debe conservar sus valores. La pantalla principal muestra ambiente actual,
   mientras el detalle conserva el capturado al medir.
4. Desconectar meteo, esperar más de 15 s y generar una distancia. El detalle
   debe conservar los últimos valores y marcar `DESC./ANT.` al medir. Cambiar
   unidades: los valores presentados cambian, los originales y las horas no.
5. Cerrar/reabrir la app. El historial anterior debe seguir presente, junto con
   la nueva medición que genera la demo al completar su conexión simulada. Mantener la misma clave
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

## Proveedores — guion de Fase 3

1. Abrir y observar BUSCANDO, CONECTANDO, y después las primeras muestras.
   START durante la búsqueda no acelera la conexión ni crea mediciones.
2. En UP/MENU, observar Estado telémetro/Estado meteo y seleccionar Escenario
   telémetro varias veces, entrando de nuevo al menú en cada selección. Confirmar
   el orden Normal → Desconectado → Error → Sin datos → Parciales → Normal.
   Repetir con meteo; cada selección solo afecta a ese proveedor.
3. Con meteo en Error, confirmar que sigue llegando distancia y que el detalle
   conserva la última meteo, con estado de desconexión al medir. El motivo del
   error se consulta al abrir el menú. Volver a Normal elimina el error.
4. Probar Conectado sin datos: con una muestra anterior, la hora no cambia y
   aparece ANTIGUO al superar su umbral; sin ninguna muestra aparece SIN DATOS.
   El estado de conexión del menú debe seguir siendo CONECTADO.
5. Pasar de Normal a Datos parciales en meteo. Dirección, presión y humedad
   pasan a `--`, aunque antes tuvieran valores. Crear una distancia y comprobar
   que esos campos también son null en el detalle del nuevo registro.
6. Pasar el telémetro a Datos parciales: distancia nueva, azimut/inclinación
   ausentes en su registro; la meteo sigue independiente.
7. Abrir/cerrar menús varias veces. Se detiene y reanuda la adquisición sin
   duplicar temporizadores o callbacks. El menú refleja el estado al abrirse,
   antes de que la vista detenga los proveedores.
8. Reabrir historial de Fase 2 con la misma aplicación: sigue siendo legible.
   La marca DEMO procede de cada registro y el esquema continúa en versión 1.

Los tests de tokens usan proveedores por eventos controlados para reproducir
callbacks tardíos sin radio. Sus resultados de ejecución quedan pendientes,
igual que las pruebas visuales en el simulador del fēnix 7X.
