# Visor de sensores Garmin — Fases 1, 2 y 3

Aplicación **Monkey C / Connect IQ** para **fēnix 7X Solar** (`fenix7x`).
Muestra y registra localmente mediciones simuladas; prepara la integración de
Terrapin X y Kestrel 5700. No incluye cálculos balísticos ni soluciones de tiro.

## Qué funciona en esta fase

- Distancia como valor principal, unidad y hora local de recepción.
- Viento, dirección del viento, temperatura y presión de estación simulados.
- Al abrir: BUSCANDO → CONECTANDO → CONECTADO (unos 2 s en la demo).
  Después, nuevas distancias cada 8 s y meteorología cada 4 s; primera muestra: **428 m,
  4.2 m/s, 275°, 14 °C, 1009 hPa**.
- Botón **START**: nueva distancia simulada inmediata.
- Mantener **UP/MENU**: historial, unidades, estados/errores y escenarios de cada mock.
- Métricas: m, m/s, °C, hPa. Imperiales: yd, mph, °F, inHg. La elección se
  conserva al cerrar la app y también está disponible en ajustes de Connect IQ.
- Indicadores independientes: `OK`, `SIN DATOS`, `SIN CONEX.`, `ANTIGUO` y
  `DESC./ANT.` (desconectado y antiguo). Umbrales: distancia 30 s, meteo 15 s.
  Una desconexión conserva el último valor con su estado y hora originales.
- Fondo negro, texto blanco, geometría proporcional y selección de fuentes por
  espacio. La unidad de distancia se dibuja aparte de la fuente numérica.
- Temporizador detenido cuando se oculta la vista o se cierra la app. Las
  mediciones solo se generan mientras se muestra el visor; no hay servicio de fondo.

**Todos los valores son ficticios**, identificados con `DEMO`, también en los
registros persistentes. No hay conexión real con Terrapin/Kestrel. La Fase 3 aporta contratos de
proveedores y simulaciones; las conexiones físicas corresponden a Fases 4 y 5.

## Proveedores y escenarios — Fase 3

`SensorController` recibe `RangefinderProvider`, `WeatherProvider`, un almacén y
un driver opcional. No depende de los mocks ni interpreta mensajes. La composición
en `SensorViewerApp` selecciona los mocks y `DemoDriver`; para proveedores por
eventos se inyecta `null` como driver. El contrato se documenta en
[source/providers/README.md](source/providers/README.md).

En **UP/MENU**, pulsa **Escenario telémetro** o **Escenario meteo** para pasar al
siguiente escenario de ese dispositivo. El orden es:

1. **Normal**: conexión simulada y muestras completas.
2. **Desconectado**: conserva los últimos valores y avisa de la pérdida del enlace.
3. **Error simulado**: muestra ERROR; el motivo se consulta en el menú.
4. **Conectado sin datos**: muestra SIN DATOS si nunca hubo muestra, o ANTIGUO
   cuando la anterior supere su umbral. No actualiza la hora del último valor.
5. **Datos parciales**: el telémetro entrega distancia sin azimut/inclinación;
   meteo entrega viento/temperatura sin dirección/presión/humedad (`--`).

La siguiente selección vuelve a Normal. Los escenarios son independientes y
permanecen durante esta sesión, incluso al abrir/cerrar menús. En Normal el
azimut/inclinación simulados son 275°/−2°. START solo genera distancia si el mock
está conectado y produce datos. No envía órdenes a ningún sensor real.

Los callbacks de estado distinguen detenido, buscando, conectando, conectado,
desconectado y error. Al entrar en menús se detienen los proveedores; el menú
muestra el estado que tenían justo antes de abrirlo. Al volver se repite la
conexión simulada. Una muestra parcial reemplaza la anterior completa, sin
mezclar campos de tiempos distintos. Los eventos de sesiones anteriores se
ignoran tras parar o cambiar de conexión.

El historial conserva el nombre del proveedor que entregó cada muestra. Se marca
como simulado si la distancia o el ambiente asociado son simulados. El esquema
persistente sigue siendo versión 1 y admite los registros de la Fase 2.

## Historial local — Fase 2

Cada evento de distancia guarda un `MeasurementRecord` con distancia/unidad
original, hora de recepción, azimut e inclinación disponibles, velocidad y
dirección del viento, temperatura, presión y humedad. La meteorología se copia
al medir y conserva su propia hora, antigüedad y estado de conexión: las
actualizaciones posteriores no cambian registros anteriores. La pantalla
principal sigue mostrando el último ambiente; el detalle muestra el guardado.

- **UP/MENU → Historial**: últimas **20** mediciones, de más reciente a más antigua.
- **UP/DOWN**: cambiar de registro. **START**: detalle completo desplazable.
- Dentro del historial, **UP/MENU → Borrar todo**: confirmar el borrado.
  **Cancelar** o **BACK** conserva los datos. **BACK** también permite volver
  del detalle, del historial y del menú principal.
- El historial permanece al cerrar/reabrir la app. Al llenarse, una nueva
  medición guardada sustituye a la más antigua. Distancias iguales se registran
  como eventos independientes.
- Los campos ausentes se muestran como `--`. La antigüedad y conexión mostradas
  en un registro corresponden al momento de medir, no a la hora de consulta.
- Los fallos de guardado se indican como `DEMO · ERROR REG.` en el visor y con
  su motivo/contador en el historial y su menú. Una medición cuya escritura falla
  sigue en el visor, pero no se incorpora al historial ni se reintenta después.
  El contador de pérdidas dura esta sesión, hasta borrar el historial o reiniciar.
- Un formato desconocido, lectura fallida o datos dañados bloquean nuevas
  escrituras para conservar el contenido. Se muestran los registros válidos
  recuperables. Se puede volver a intentar al reiniciar o borrar explícitamente
  el historial para empezar de nuevo. Un borrado fallido conserva los registros.

Solo se escribe al medir o al confirmar el borrado. Las unidades se conservan
por separado y no se borran. Mientras se navega por menús/historial, los mocks
están detenidos; al volver al visor pueden generar una nueva medición. Esta
versión no recibe sensores en segundo plano.

## Compilar y ejecutar

1. Instalar el [SDK Manager oficial de Garmin](https://developer.garmin.com/connect-iq/sdk/),
   descargar el SDK estable y el perfil **fēnix 7X**. El SDK 9.2.0 se ha usado
   para la comprobación del código. El mínimo de API declarado es 3.1.0.
2. Para trabajar en VS Code, instalar la extensión **Monkey C de Garmin** y
   seleccionar el SDK y la clave de desarrollo. También se puede usar la CLI.
3. Crear una clave de desarrollo propia. Ejemplo con OpenSSL:

   ```bash
   openssl genrsa -out /tmp/sensor-viewer-key.pem 4096
   openssl pkcs8 -topk8 -inform PEM -outform DER \
     -in /tmp/sensor-viewer-key.pem -out /tmp/sensor-viewer-key.der -nocrypt
   ```

   Guardar la clave definitiva en un lugar privado y duradero si se va a firmar
   una distribución. No subir claves al repositorio; `/tmp` es solo para pruebas.

4. Configurar rutas y compilar:

   ```bash
   export CONNECTIQ_SDK="/ruta/al/connectiq-sdk"
   export DEVELOPER_KEY="/tmp/sensor-viewer-key.der"
   bash scripts/build.sh
   ```

   Equivalente con el SDK en el PATH:

   ```bash
   monkeyc -f monkey.jungle -d fenix7x -o bin/SensorViewer.prg \
     -y "$DEVELOPER_KEY" -l 3 -w
   ```

5. Abrir el simulador y cargar la aplicación:

   ```bash
   "$CONNECTIQ_SDK/bin/connectiq"
   "$CONNECTIQ_SDK/bin/monkeydo" bin/SensorViewer.prg fenix7x
   ```

En Linux sin servidor gráfico, la compilación del SVG puede necesitar
`JAVA_TOOL_OPTIONS=-Djava.awt.headless=true`; el simulador sí necesita un entorno
gráfico. Si aparece `Invalid device id ... fenix7x`, verificar que el perfil se
ha descargado en SDK Manager para el mismo usuario que ejecuta el compilador.

## Verificación

```bash
bash scripts/build.sh --test
"$CONNECTIQ_SDK/bin/monkeydo" bin/SensorViewer-tests.prg fenix7x -t
```

Hay quince pruebas Monkey C: tres de demo, siete de historial y cinco de proveedores. Cubren
capturas independientes, valores ausentes/incorrectos, límite y orden, recarga,
escrituras fallidas, corrupción, eventos y serialización con Storage real bajo
una clave de pruebas independiente. El test de integración también llena el
historial para verificar el límite de tamaño del almacenamiento Garmin. Las
pruebas de proveedores cubren inyección sin mocks, procedencia, sesiones,
fallos independientes y datos parciales/inválidos.

**Verificación Fase 3 en este entorno:** compilación genérica con SDK 9.2.0
y tipos estrictos (`-l 3`), con y sin las pruebas; XML y script de compilación
validados. La compilación genérica avisa de que falta el perfil `fenix7x`.
**Pendiente:** compilación para el reloj, ejecución de tests y revisión visual
en simulador/dispositivo. La descarga del perfil consultada exige autenticación
Garmin (HTTP 401 en la investigación inicial); además faltan bibliotecas de
WebKit requeridas por el simulador Linux. Los tests están compilados, no
ejecutados. El binario genérico no debe instalarse en el reloj.

Consultar el [guion manual](docs/verificacion.md), la
[investigación de comunicaciones](docs/comunicaciones.md) y la
[arquitectura y fases](docs/arquitectura.md).
