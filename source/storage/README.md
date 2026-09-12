# Almacenamiento — Fase 2

No hay historial implementado en la Fase 1. Únicamente se conserva la elección
de unidades con `Application.Properties`.

Implementar `MeasurementRepository` con `Application.Storage` y un historial
acotado ajustado a la memoria del reloj. Escribir al recibir un evento de
distancia, nunca desde `onUpdate()` ni en cada actualización meteorológica.

Persistir diccionarios/arrays admitidos por Storage, con versión de esquema y
validación al leer; no instancias de clases. Manejar almacenamiento lleno,
registros inválidos y fallos de escritura sin perder el visor. Mostrar si una
medición no pudo guardarse. Borrado explícito desde un menú con confirmación.
Ver [el plan de datos](../../docs/arquitectura.md).
