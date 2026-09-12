# Comunicaciones: investigación inicial

Consulta: 12 de septiembre de 2026. Objetivo confirmado: **Garmin fēnix 7X Solar**,
producto Connect IQ `fenix7x`. No se ha probado ningún sensor físico.

## Qué ofrece Connect IQ

| Vía | Disponibilidad y alcance | Decisión inicial |
| --- | --- | --- |
| BLE directo | `Toybox.BluetoothLowEnergy`, desde API 3.1.0, permite actuar como central: escanear periféricos y operar como cliente GATT. La lista oficial incluye fēnix 7X. Requiere permiso `BluetoothLowEnergy`. | Candidato principal para ambos sensores, condicionado a protocolos y pruebas. |
| ANT / ANT+ | `Toybox.Ant` ofrece canales ANT; `Toybox.AntPlus` expone perfiles concretos. El hardware y el perfil del sensor deben ser compatibles. | No se ha identificado una interfaz ANT/ANT+ documentada de estos dos dispositivos. |
| Teléfono | `Toybox.Communications` intercambia mensajes con una app móvil mediante Connect IQ Mobile SDK y permite peticiones web. Requiere permiso `Communications`. | Alternativa: desarrollar una app Android/iOS que reciba los sensores y remita mediciones al reloj. |
| HTTP/Internet | `makeWebRequest` permite consultar un servicio, con el transporte disponible en el dispositivo/teléfono. | No sustituye GATT ni aporta por sí mismo acceso local al Terrapin/Kestrel. |

Referencias oficiales: [BLE](https://developer.garmin.com/connect-iq/api-docs/Toybox/BluetoothLowEnergy.html),
[ANT](https://developer.garmin.com/connect-iq/api-docs/Toybox/Ant.html),
[ANT+](https://developer.garmin.com/connect-iq/api-docs/Toybox/AntPlus.html),
[Communications](https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications.html).

La API BLE pública documenta el rol central, no un servidor GATT genérico ni
Bluetooth Classic/SPP. Un sensor que solo actuase como central requeriría otra
topología. La compatibilidad nativa de un accesorio con algún Garmin no demuestra
que una aplicación Connect IQ pueda obtener esas mediciones: hay que validar la
API y el protocolo accesibles a terceros.

Para usar el teléfono hace falta una **app compañera propia** o una integración
documentada equivalente. Garmin Connect no interpreta automáticamente los
mensajes propietarios de estos sensores. Véase el
[SDK móvil Android](https://developer.garmin.com/connect-iq/core-topics/mobile-sdk-for-android/).

La API BLE ofrece `getAvailableConnectionCount()` para consultar conexiones
disponibles. No se presupone que dos conexiones estén siempre libres: confirmar
en el reloj/firmware y con los demás sensores/apps activos. La integración con
el menú nativo de sensores mediante `SensorDelegate` requiere API 5.1.0 y debe
verificarse por dispositivo; no es requisito de esta demo con mínimo API 3.1.0.
[API BLE](https://developer.garmin.com/connect-iq/api-docs/Toybox/BluetoothLowEnergy.html),
[emparejamiento nativo](https://developer.garmin.com/connect-iq/core-topics/pairing-wireless-devices/).

## Terrapin X

El folleto de Vectronix identifica la interfaz como **Bluetooth 4.1 Low Energy**,
con conectividad a su app y al Kestrel 5700 Elite. También enumera brújula y
campos en su pantalla. Eso confirma el transporte, pero no los campos disponibles
en cada mensaje o modo de conexión.
[Ficha del fabricante, páginas 3–4](https://vectronix-shooting-solutions.com/wp-content/uploads/2024/01/TERRAPIN-X_Brochure_2019-01_EN.pdf).

No se ha localizado una especificación pública oficial de GATT y tramas en la
documentación consultada. Esto no demuestra que no exista o que no pueda
solicitarse. Pedir a Vectronix:

- Firmware compatible, rol BLE y modo para una aplicación de terceros.
- UUID de anuncios, servicios, características y descriptores; lectura,
  escritura/notificaciones, secuencia de suscripción y emparejamiento.
- Formato, fragmentación, endianness, escalas, unidades y valores inválidos.
- Identificación de **distancia medida**, azimut e inclinación si se exportan;
  referencia angular y diferencia respecto a otros valores del dispositivo.
- Timestamp/identificador de medición, repeticiones, ejemplos verificados y
  permisos de uso/distribución del protocolo.
- Límites de conexiones y coexistencia con el teléfono y Kestrel.

Hasta obtenerlo se usa `MockRangefinderProvider`. No se implementa un parser
supuesto ni se inicia remotamente una medición real.

## Kestrel 5700

**Confirmar que la unidad incorpora LiNK.** La documentación de la serie indica
que LiNK es Bluetooth Smart/BLE y que su disponibilidad depende de la variante.
[FAQ 5700](https://kestrelinstruments.com/faqs/question/tags/tag/5700/).

Kestrel ofrece solicitar el **weather data protocol** mediante su **Kestrel
Technology Agreement**, enlazado desde soporte. Esa es la vía a seguir para este
visor meteorológico; no se ha solicitado ni firmado nada en nombre del usuario.
[Soporte oficial: integración de Communications Protocol](https://kestrelinstruments.com/support).

Necesitamos servicios/características, seguridad, comandos de suscripción o
lectura, formato de mensajes, unidades, valores inválidos, cadencia y condiciones
de conexión del firmware concreto. Confirmar individualmente: velocidad del
viento, dirección, temperatura, presión, humedad y posibles campos adicionales.

La dirección debe ser la dirección meteorológica exportada, con su referencia
definida; no inferirla de la orientación del reloj. Diferenciar presión de
estación (absoluta) de presión barométrica corregida. Densidad del aire y altitud
de densidad son magnitudes distintas: aceptar solo el campo que el dispositivo
proporcione, con nombre/unidad explícitos; no calcularlo en el reloj.

## Criterio de paso a las conexiones reales

Conservar adaptadores simulados hasta disponer de especificaciones y fixtures.
Después validar un sensor por separado y finalmente ambos en el fēnix 7X Solar:
conexión, notificaciones, unidades, datos ausentes, pérdida de enlace, apagado,
reconexión, latencia y consumo. BLE directo parece factible por el transporte;
**la interoperabilidad completa todavía no está demostrada**.

El alcance de todas las fases es recibir, presentar y registrar mediciones.
Solo se permiten conversiones de unidades para su presentación. No se incorporan
cálculos ni soluciones balísticas, correcciones, holdovers o ajustes de mira.
