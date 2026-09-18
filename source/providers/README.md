# Contratos de proveedores — Fase 3

El controlador trabaja con `RangefinderProvider` y `WeatherProvider`, clases base
Monkey C que extienden `SensorProvider`. No depende de `Mock*` ni de una API de
radio. `SensorViewerApp` es el punto donde se eligen implementaciones.

## API común

- Constructor: identidad estable de 1–32 caracteres y marca de simulación.
- `start(measurementListener, stateListener)`: idempotente mientras está activo.
  Entrega SCANNING al comenzar. Cada tipo de proveedor recibe su modelo propio;
  el callback de estado recibe `(state, message)`.
- `stop()`: idempotente, elimina listeners e invalida sesiones. Un adaptador que
  lo sobrescriba debe llamar primero a la base y cancelar suscripciones, búsqueda
  y recursos del transporte, incluso si hay un fallo al liberarlos.
- `state()`, `errorMessage()`, `isConnected()`, `sourceName()`, `isSimulated()`:
  consulta del estado e identidad. Conectado no implica que haya datos recientes.
- `session()`: token de la conexión/operación actual; `accepts(token)` verifica
  que sigue activo. Un token anterior nunca debe reutilizarse tras una reconexión.
- `setState(token, state, message)`, protegido: publica un cambio solo si su token
  sigue vigente. Entrar en SCANNING, DISCONNECTED o ERROR cambia el token.
  Obtener el nuevo token al comenzar las operaciones que siguen a ese cambio.
- `deliver(measurement, token)`, protegido: ignora sesiones antiguas y estados
  distintos de CONNECTED. Valida la medición y entrega una copia. Una muestra
  inválida pasa el proveedor a ERROR, sin sustituir el último valor válido.

Estados: STOPPED, SCANNING, CONNECTING, CONNECTED, DISCONNECTED y ERROR. El
adaptador traduce sus eventos de transporte a estos estados. Si sobrescribe
`start`, debe comprobar `isActive()` antes de crear suscripciones duplicadas.
Las bases son contratos reutilizables; no se deben elegir como sensores concretos.

## Datos y callbacks

La distancia conserva su unidad original (`m` o `yd`); los campos ambientales
se normalizan a m/s, grados, °C, hPa de estación y % HR. Cada muestra lleva la hora
de recepción Unix y el tick de la misma recepción (`System.getTimer()`). Los
campos opcionales ausentes son `null`, no cero ni una copia del mensaje anterior.
Si el protocolo envía deltas en lugar de muestras completas, el adaptador deberá
reconstruir una muestra coherente conforme a su especificación documentada.

Al suscribirse a una operación asíncrona, guardar su token. En su callback,
pasar **ese token guardado** a `setState`/`deliver`; no consultar `session()`
entonces para etiquetar un evento antiguo como actual. Las bases cambian el token
al parar, comenzar búsqueda y perder una conexión. Esta protección incluye datos
y estados, y se prueba también después de arrancar de nuevo.

La identidad se usa para el historial; la marca de simulación es verdadera si
alguna de las muestras asociadas es simulada. No inferir procedencia a partir de
nombres del dispositivo o de tipos concretos dentro del controlador.

## Composición

```text
SensorViewerApp
  ├─ SensorController(RangefinderProvider, WeatherProvider, HistoryStore, driver)
  ├─ DashboardView(controller)
  └─ DashboardDelegate(controller, demoControls o null)
```

En la demo, `DemoDriver` implementa el hook opcional `AcquisitionDriver.tick` y
actúa también como controles simulados de la UI. Genera meteorología antes de
la distancia para permitir su asociación en el mismo ciclo. Al usar adaptadores
por eventos se pasan `null` tanto al driver como a los controles de demo. START
no genera ni ordena mediciones cuando no hay controles de demo.

El controlador solo utiliza un temporizador para actualizar la antigüedad y,
si está configurado, impulsar el driver. No consulta los proveedores reales en
ese temporizador. Los proveedores se detienen al ocultar el visor, incluidos los
menús y el historial. No se ofrece recepción en segundo plano en esta fase.

## Simulación determinista

Cada mock tiene `setScenario` y `cycleScenario`:

| Escenario | Efecto |
| --- | --- |
| NORMAL | SCANNING → CONNECTING → CONNECTED; datos completos |
| DISCONNECTED | No entrega muestras; conserva valores anteriores en el visor |
| ERROR | Error independiente con mensaje consultable en menú |
| SILENT | Conectado sin nuevas muestras; permite probar ausencia/antigüedad |
| PARTIAL | Campos opcionales null; no hereda datos de muestras anteriores |

Los tests pueden impulsar `DemoDriver.tick` con tiempos fijos. Los fixtures por
eventos de `tests/ProviderTests.mc` prueban la misma aplicación sin este driver.

Terrapin y Kestrel reales continúan pendientes de especificación del fabricante;
no se han inventado UUID, tramas, comandos ni permisos de radio.
