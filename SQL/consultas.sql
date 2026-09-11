/* Consultas de extracción para el modelo de Power BI, en el mismo orden que la tabla "Modelo de datos"
   de docs/02-arquitectura-tecnica.md.
   Nota: ventas_linea y compras_linea son los nombres de origen en fruit_store.db; Power Query las renombra
   a ventas y compras al importar. Las exclusiones de ids 251, 252 y 253 se aplican en Power Query. */

SELECT producto_id, nombre, tipo_venta, categoria AS subcategoria 
FROM productos;

SELECT fecha, producto_id, cantidad, coste_unitario 
FROM compras_linea 
WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01';

SELECT fecha, producto_id, cantidad, precio_unitario 
FROM ventas_linea 
WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01';

SELECT fecha, producto_id, cantidad, pvp_original, pvp_demarca 
FROM demarcas 
WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01';

SELECT fecha, producto_id, cantidad, coste_unitario 
FROM mermas 
WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01';

SELECT fecha, producto_id, cantidad, coste_unitario 
FROM alteraciones 
WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01';
