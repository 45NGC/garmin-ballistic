# Parsers — Fases 4 y 5

Ubicación reservada para decodificadores puros, uno por protocolo documentado.
Recibirán bytes completos o fragmentos según la especificación y producirán
modelos validados o un error explícito, sin dibujar ni escribir almacenamiento.

Los mocks construyen modelos directamente: **no simulan un protocolo de cable**.
No se inventan UUID, offsets, comandos, checksum ni formatos propietarios.
Antes de cada parser: obtener especificación y fixtures autorizados; probar
truncamiento, unidades desconocidas, campos ausentes, duplicados y reconexión.
