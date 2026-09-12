# Visor de sensores Garmin — Fase 1

Aplicación **Monkey C / Connect IQ** para **fēnix 7X Solar** (`fenix7x`).
Muestra mediciones simuladas; prepara la base de un visor y registrador de
Terrapin X y Kestrel 5700. No incluye cálculos balísticos ni soluciones de tiro.

## Qué funciona en esta fase

- Distancia como valor principal, unidad y hora local de recepción.
- Viento, dirección del viento, temperatura y presión de estación simulados.
- Nuevas distancias cada 8 s; meteorología cada 4 s; primera muestra: **428 m,
  4.2 m/s, 275°, 14 °C, 1009 hPa**.
- Botón **START**: nueva distancia simulada inmediata.
- Mantener **UP/MENU**: cambiar unidades o desconectar/reconectar cada mock.
- Métricas: m, m/s, °C, hPa. Imperiales: yd, mph, °F, inHg. La elección se
  conserva al cerrar la app y también está disponible en ajustes de Connect IQ.
- Indicadores independientes: `OK`, `SIN DATOS`, `SIN CONEX.`, `ANTIGUO` y
  `DESC./ANT.` (desconectado y antiguo). Umbrales: distancia 30 s, meteo 15 s.
  Una desconexión conserva el último valor con su estado y hora originales.
- Fondo negro, texto blanco, geometría proporcional y selección de fuentes por
  espacio. La unidad de distancia se dibuja aparte de la fuente numérica.
- Temporizador detenido cuando se oculta la vista o se cierra la app. Las
  mediciones solo se generan mientras se muestra el visor; no hay servicio de fondo.

**Todos los valores son ficticios**, identificados con `DEMO`. No hay conexión
real ni almacenamiento de mediciones todavía. El historial, `MeasurementRecord`,
detalle y borrado corresponden a la Fase 2. Los contratos base y mocks son una
base inicial para la Fase 3; no constituyen adaptadores reales.

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

Las tres pruebas Monkey C cubren antigüedad y sus límites, conversiones sin
modificar las mediciones y el ciclo de vida independiente de ambos mocks.

**Verificación realizada en este entorno:** compilación genérica con SDK 9.2.0
y tipos estrictos (`-l 3`), con y sin las pruebas; XML y script de compilación
validados. La compilación genérica avisa de que falta el perfil `fenix7x`.
**Pendiente:** compilación para el reloj, ejecución de tests y revisión visual
en simulador/dispositivo. La descarga del perfil consultada exige autenticación
Garmin (HTTP 401). El binario genérico no debe instalarse en el reloj.

Consultar el [guion manual](docs/verificacion.md), la
[investigación de comunicaciones](docs/comunicaciones.md) y la
[arquitectura y fases](docs/arquitectura.md).
