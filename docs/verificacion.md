# Verificación de Fase 1

## Automatizada

Ejecutar `bash scripts/build.sh --test` y `monkeydo bin/SensorViewer-tests.prg
fenix7x -t` con el simulador abierto. Se esperan tres tests sin fallos:

- `freshnessBoundaries`: ausencia, límite exacto y discontinuidad temporal,
  incluida la distinción entre desconexión y antigüedad.
- `displayConversionsPreserveSource`: conversiones, fuente en yardas, unidad
  desconocida, valor ausente y viento cero.
- `independentSourcesAndLifecycle`: cadencia, fuentes independientes, muestras
  anteriores intactas, parada, reinicio y desconexión con medición manual.

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
   memoria. No hay crecimiento de historial en esta fase.
9. Verificar también valores ausentes (`--`) mediante fixtures en el depurador;
   un cero válido debe seguir apareciendo como cero.

No se declara soporte de otros productos en el manifiesto. Antes de ampliarlo,
añadir su perfil y revisar recortes, fuentes y controles en cada resolución.
Las pruebas de radio, latencia, batería y legibilidad exterior requieren reloj
y sensores físicos en fases posteriores.
