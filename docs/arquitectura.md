# Arquitectura y fases

```text
source/
  SensorViewerApp.mc          composición y ciclo de vida
  config/AppConfig.mc        unidades, intervalos, antigüedad, límite del historial
  controllers/               recepción de muestras y guardado por evento de distancia
  ui/                        visor, historial, detalle, confirmación y conversiones
  models/                    RangeMeasurement, EnvironmentalMeasurement,
                             MeasurementRecord y Freshness
  providers/                 contratos base, estados, sesiones y driver opcional
    mock/                    fixtures deterministas
    terrapin/                reservado para Fase 4
    kestrel/                 reservado para Fase 5
  parsers/                   reservado para protocolos documentados
  storage/                   RecordCodec, MeasurementRepository, HistoryStore
tests/                      pruebas Monkey C de la demo y el historial
```

`AppBase` construye el controlador. El visor activa/desactiva los mocks al
mostrarse/ocultarse. Cada proveedor entrega objetos nuevos mediante callbacks;
solo `DemoDriver` utiliza `pump()` sobre los mocks. El controlador llama a un
`AcquisitionDriver` opcional; sin él, su temporizador solo refresca la antigüedad.
Los proveedores por eventos no necesitan driver ni son consultados periódicamente.

Un evento de distancia llega a `SensorController.onRange()`, que captura el último
ambiente con `RecordCodec.capture()` y solicita su persistencia al repositorio.
No se guarda por redibujado, conversión de unidades ni evento meteorológico.
Los menús, el historial y sus detalles detienen la adquisición simulada igual
que los menús de Fase 1; las conexiones en segundo plano quedan fuera del alcance.

## Modelos y persistencia

`RangeMeasurement` y `EnvironmentalMeasurement` contienen las muestras recibidas.
`timestamp` es recepción en el reloj en segundos Unix, no una hora de captura
que proporcione necesariamente el sensor. `receivedAtMs` mide antigüedad dentro
de la sesión. Los campos opcionales son `null`; no se sustituyen por cero.

`MeasurementRecord` contiene una copia de escalares sin setters; sus accesores
devuelven copias. Las actualizaciones de los proveedores y las conversiones de
presentación no pueden modificarlo. Las clases de muestra reconstruidas para
presentación tienen ticks cero; no se utilizan para recalcular antigüedad.

Formato persistido bajo `measurementHistory`:

```text
{ schemaVersion: 1, records: [ registroMásReciente, ..., registroMásAntiguo ] }
```

| Campo de cada registro | Significado |
| --- | --- |
| timestamp | Recepción de distancia, Unix segundos |
| distance / unit | Valor original y unidad m/yd |
| azimuth / inclination | Grados proporcionados, o null |
| windSpeed / windDirection | m/s y grados, o null |
| temperature / pressure / humidity | °C, hPa de estación y % HR, o null |
| environmentalTimestamp | Recepción de ambiente, o null |
| environmentalAgeSeconds | Antigüedad al medir; null si desconocida |
| environmentalStale / environmentalConnected | Estado al medir |
| rangeSource / weatherSource / simulated | Procedencia y marca de datos simulados |

Si falta ambiente, se guarda la distancia con campos meteo `null`. Si está antiguo
o desconectado, se conserva con su estado. Un salto del reloj de sesión produce
edad desconocida y marca de antigüedad; cambiar la hora civil no modifica los
ticks. La procedencia y marca de simulación vienen de los proveedores inyectados.
Los adaptadores futuros deberán aportar semántica de presión y referencia
angular verificadas; actualmente no hay adaptadores físicos.

`RecordCodec.decode()` valida campos obligatorios, tipos, unidad, valores finitos
y consistencia de ausencia de ambiente. Los límites numéricos amplios no son
especificaciones de precisión ni rangos operativos de ningún dispositivo.
El envoltorio valida la versión y el máximo de 20 registros.

El repositorio sustituye su lista en memoria solo tras guardar correctamente.
Un error de escritura deja disponible el visor y conserva los registros previos;
la medición fallida no se encola. El contador de pérdidas es de sesión y permanece
aunque una escritura posterior funcione. Datos dañados o versiones desconocidas
bloquean escrituras automáticas hasta recuperación en un reinicio o borrado
explícito. No se borran las preferencias de unidades.

El adaptador `HistoryStore` permite pruebas con fallos de lectura/escritura
inyectados sin tocar el historial real. Hay también un test con `Application.Storage`
bajo una clave independiente. Referencia oficial:
[Storage](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html).

## Fases

1. **Fase 1 implementada:** visor, unidades y mocks, estados y antigüedad.
2. **Fase 2 implementada:** snapshots de mediciones y ambiente, persistencia de
   últimas 20 mediciones, navegación, detalle, borrado confirmado y errores.
   Compilación genérica verificada; ejecución y validación visual pendientes.
3. **Fase 3 implementada:** contratos base por eventos, controlador inyectado,
   estados de transporte, invalidación de sesiones, validación de muestras,
   procedencia y escenarios simulados independientes. Ver [contratos](../source/providers/README.md).
4. **Fase 4 condicionada:** Terrapin real y parser con protocolo accesible.
5. **Fase 5 condicionada:** Kestrel LiNK real y parser meteorológico autorizado.
6. **Fase 6 pendiente:** validación exterior, otras resoluciones, reconexión y
   consumo medido con dispositivos físicos.

Todas las fases reciben, presentan y registran sensores; no incluyen cálculos
balísticos. Investigación y requisitos: [comunicaciones](comunicaciones.md).

## Ciclo de vida en Fase 3

`RangefinderProvider` y `WeatherProvider` heredan de `SensorProvider`, que gestiona
identidad, estado, suscripción a eventos e identificador de sesión. Los dos
callbacks son independientes: estado y medición. El controlador guarda solo
mediciones válidas recibidas mientras está activo y el proveedor está conectado.

Al parar o al pasar a búsqueda, desconexión o error se invalida la sesión
anterior. Los adaptadores deben conservar el token de cada operación asíncrona
al iniciarla y pasarlo al entregar datos/estado. Leer el token actual dentro de
un callback tardío eliminaría esta protección y está prohibido por el contrato.

El controlador inicia cada proveedor por separado; si uno falla, cancela ese
proveedor y conserva el error visible mientras el otro sigue operativo. No se
implementa todavía la reconexión automática de radio: el mock permite repetir
manualmente los escenarios y las Fases 4–6 concretarán transportes y reintentos.

La vista conserva muestras para mostrar su antigüedad, aunque se detenga la
adquisición. Los modelos entregados por los proveedores y almacenados por el
controlador son copias; no se mezclan campos entre muestras parciales. Solo se
utiliza un temporizador en esta composición, detenido al ocultar el visor.
