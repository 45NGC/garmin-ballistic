# Arquitectura y fases

## Estructura inicial

```text
manifest.xml                 watch-app; objetivo fenix7x; sin permisos de radio
monkey.jungle                fuentes, tests y recursos
resources/                   icono, cadenas y ajuste de unidades
source/
  SensorViewerApp.mc          composición y ciclo de vida de la aplicación
  config/AppConfig.mc        unidades, cadencia demo, umbrales de antigüedad
  controllers/               coordinación de la demo y recepción de muestras
  ui/                        vistas, menú y conversiones de presentación
  models/                    muestras de distancia, meteo y antigüedad
  providers/                 contratos base con entrega por callbacks
    mock/                    fixtures deterministas, sin transporte
    terrapin/                reservado para adaptador real de Fase 4
    kestrel/                 reservado para adaptador real de Fase 5
  parsers/                   reservado para protocolos documentados
  storage/                   reservado para historial persistente
tests/                       pruebas Monkey C
docs/                        investigación, diseño y verificación
```

`AppBase` construye el controlador; la vista dibuja el estado y activa/desactiva
la demo al mostrarse/ocultarse. Los proveedores entregan objetos nuevos mediante
callbacks. Solo los mocks necesitan `pump()`, dirigido por un temporizador del
controlador; los proveedores reales serán dirigidos por eventos del transporte.
`RangefinderProvider` y `WeatherProvider` son clases base con contratos comunes.
Monkey Types también permite interfaces estructurales; no se usa la sintaxis
`interface ... implements ...` de Java.

Las clases actuales de medición son el subconjunto necesario para la demo; los
campos opcionales usan `null`. `timestamp` significa recepción en el reloj, no
hora de captura garantizada por el sensor. `receivedAtMs` solo sirve para medir
antigüedad dentro de la sesión. Las conversiones no modifican el modelo original.

## Plan incremental

1. **Fase 1, implementada:** visor simulado, distancia/hora, viento/dirección,
   temperatura/presión, ajuste de unidades, desconexión simulada independiente
   y avisos de antigüedad. Todo el estado de mediciones es temporal.
2. **Fase 2, pendiente:** completar modelos, `MeasurementRecord`, captura del
   ambiente al recibir distancia, repositorio local acotado, vista de historial,
   detalle y borrado desde menú.
3. **Fase 3, pendiente:** consolidar los contratos iniciales, inyectar proveedores,
   añadir estados buscando/conectando/conectado/desconectado/error, eventos de
   estado y escenarios de datos ausentes/parciales. Evitar dependencias del
   controlador de producción con las clases mock.
4. **Fase 4, condicionada:** `TerrapinRangefinderProvider` y parser, únicamente con
   especificación accesible. Investigación inicial en `comunicaciones.md`.
5. **Fase 5, condicionada:** `KestrelWeatherProvider` y parser meteorológico LiNK,
   únicamente con especificación autorizada.
6. **Fase 6, pendiente:** validación física exterior y múltiples resoluciones,
   reconexión con espera progresiva y escaneos acotados, actualización por cambios,
   medición de consumo y manejo de suspensión. Sin prometer recepción continua
   con la app cerrada o en segundo plano.

## Diseño del registro para Fase 2

Un evento válido de distancia creará un `MeasurementRecord` nuevo, incluso si
coincide numéricamente con el anterior. No crear registros al repintar ni al
actualizar solo la meteorología. Si el protocolo permite retransmisiones,
deduplicar por su identificador/secuencia documentado, no por distancia.

Campos del registro serializado (diseño, todavía no implementado):

| Campo | Significado |
| --- | --- |
| schemaVersion | Versión del formato persistente |
| timestamp | Recepción de la distancia en el reloj, Unix segundos |
| distance / unit | Distancia original y unidad m/yd |
| azimuth / inclination | Valores proporcionados o null, grados |
| windSpeed / windDirection | m/s y grados, o null |
| temperature / pressure / humidity | °C, hPa y % HR, o null |
| environmentalTimestamp | Recepción de la muestra ambiental, o null |
| environmentalAgeSeconds | Antigüedad de esa muestra al medir |
| environmentalStale / environmentalConnected | Calidad y estado al medir |
| rangeSource / weatherSource / simulated | Procedencia, incluida la demo |

Copiar los valores del último ambiente recibido en ese instante. Los cambios
meteorológicos posteriores no deben modificar registros anteriores. Si falta
meteo, guardar la distancia con campos ambientales `null`; si está desactualizada,
conservarla con su fecha y marca de antigüedad. Preservar también la semántica de
presión y referencia de dirección cuando se incorporen protocolos reales.

Usar `Application.Storage`, serialización explícita y límites de memoria; no
serializar directamente instancias de clases. La capacidad se elegirá tras
medir el tamaño real de cada registro en el reloj. Documentación oficial:
[Storage](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html).
