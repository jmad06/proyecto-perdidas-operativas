Consultas de calidad de datos para el modelo de Power BI. Verifican en SQL las anomalías conocidas del dataset citadas en:
- [Cómo se ha construido el proyecto](../docs/02-arquitectura-tecnica.md#cómo-se-ha-construido-el-proyecto)
- [Origen de los datos y anomalías detectadas](../docs/02-arquitectura-tecnica.md#origen-de-los-datos-y-anomalías-detectadas)
- [Consultas SQL](../docs/02-arquitectura-tecnica.md#consultas-sql)

> Este documento es distinto de `consultas.sql`: esta auditoría se ejecuta sobre los datos crudos en la fase 0 del pipeline. Se incorpora el filtro de periodo `fecha >= '2026-01-01' AND fecha < '2026-08-01'` en las 5 tablas de hechos. Ninguna comprobación excluye los ID 251/252/253, salvo 4a, 4b, 4d y 5a, que excluyen el 253 por el error documentado en la comprobación 2, y 4c, que compara ambos universos explícitamente y 3 que los aísla.

> Nota: `linea_id` existe en las 5 tablas de hechos y es único en el 100 % de las filas (comprobado), pero no se usa como criterio de esta comprobación. Al ser autoincremental,
> cualquier verificación por `linea_id` devolvería 0 duplicados por construcción y no respondería a la pregunta real: si el generador sintético produce combinaciones de fecha + producto + cantidad + precio repetidas con una frecuencia mayor de la esperable por azar. Esa pregunta solo puede responderse ignorando el identificador de línea.
---
# Índice de contenidos

- [1. Duplicados exactos por tabla](#1-duplicados-exactos-por-tabla)
	- [1a. Demarcas](#1a-demarcas)
	- [1b. Ventas](#1b-ventas)
	- [1c. Alteraciones](#1c-alteraciones)
	- [1d. Mermas](#1d-mermas)
- [2. Producto id=253: pvp_original = 0 en el 100 % de sus filas](#2-producto-id253-pvp_original-0-en-el-100-de-sus-filas)
- [3. Impacto de id=251, 252, 253 en Pérdidas por demarcas (€)](#3-impacto-de-id251-252-253-en-pérdidas-por-demarcas-)
- [4. Demarcas con pvp_demarca > pvp_original y con pvp_demarca = pvp_original](#4-demarcas-con-pvp_demarca-pvp_original-y-con-pvp_demarca-pvp_original)
	- [4a. pvp_demarca > pvp_original (excluido id=253)](#4a-pvp_demarca-pvp_original-excluido-id253)
	- [4b. pvp_demarca = pvp_original (excluido id=253)](#4b-pvp_demarca-pvp_original-excluido-id253)
	- [4c. % global de pvp_demarca > pvp_original (sobre demarcas totales, incluye id=253)](#4c-global-de-pvp_demarca-pvp_original-sobre-demarcas-totales-incluye-id253)
	- [4d. Alteraciones con cantidad < 0 (abonos/devoluciones)](#4d-alteraciones-con-cantidad-0-abonosdevoluciones)
- [5. pvp_original vs ventas.precio_unitario](#5-pvp_original-vs-ventasprecio_unitario)
	- [5a. Coincidencia por producto](#5a-coincidencia-por-producto)
	- [5b. Recálculo de Pérdidas por demarcas (€) con precio de venta real](#5b-recálculo-de-pérdidas-por-demarcas--con-precio-de-venta-real)
- [6. mermas.coste_unitario vs coste medio ponderado de compras](#6-mermascoste_unitario-vs-coste-medio-ponderado-de-compras)
	- [6a. Coincidencia línea a línea](#6a-coincidencia-línea-a-línea)
	- [6b. Recálculo de Coste de mermas (€) revalorizado](#6b-recálculo-de-coste-de-mermas--revalorizado)
- [7. Productos con demarca sin coste de compra en el periodo](#7-productos-con-demarca-sin-coste-de-compra-en-el-periodo)
- [8. Productos sin ninguna venta ni precio de compra en el periodo](#8-productos-sin-ninguna-venta-ni-precio-de-compra-en-el-periodo)
- [9. Diferencia entre Compras (€) y coste de mercancía vendida + mermas + alteraciones](#9-diferencia-entre-compras--y-coste-de-mercancía-vendida--mermas--alteraciones)
- [10. Unidades compradas vs con salida trazada + productos con salidas > compras](#10-unidades-compradas-vs-con-salida-trazada--productos-con-salidas--compras)
	- [10a. Totales de unidades](#10a-totales-de-unidades)
	- [10b. Productos con salidas superiores a compras](#10b-productos-con-salidas-superiores-a-compras)
- [11. Cobertura de coste_unitario en productos con demarca](#11-cobertura-de-coste_unitario-en-productos-con-demarca)
- [12. El 78,13% de demarcas bajo coste se vende a 1€ o menos](#12-el-7813-de-demarcas-bajo-coste-se-vende-a-1-o-menos)
- [13. El 97% de 132 productos con coste conocido y demarca tienen demarca bajo coste](#13-el-97-de-132-productos-con-coste-conocido-y-demarca-tienen-demarca-bajo-coste)
- [14. Peso de las demarcas bajo coste: 2.017,33 € sobre coste](#14-peso-de-las-demarcas-bajo-coste-201733--sobre-coste)
- [15. Comprobación de valores nulos en todas las tablas de hechos](#15-comprobación-de-valores-nulos-en-todas-las-tablas-de-hechos)

---

## 1. Duplicados exactos por tabla

### 1a. Demarcas

```sql
WITH base AS (
    SELECT
        (SELECT COALESCE(SUM(numero_filas - 1), 0)
         FROM (
             SELECT COUNT(*) AS numero_filas
             FROM demarcas
             WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
             GROUP BY fecha, producto_id, cantidad, pvp_original, pvp_demarca
             HAVING COUNT(*) > 1
         ) AS grupos_duplicados) AS duplicados_adicionales,
        (SELECT COUNT(*) FROM demarcas WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01') AS total_filas
)
SELECT
    duplicados_adicionales,
    total_filas,
    ROUND(duplicados_adicionales * 100.0 / NULLIF(total_filas, 0), 2) AS porcentaje_duplicados
FROM base;
```

Resultado de la consulta:

| duplicados_adicionales | total_filas | porcentaje_duplicados |
| ---------------------- | ----------- | --------------------- |
| 1186                   | 5235        | 22.66 %               |
### 1b. Ventas

```sql
WITH base AS (
    SELECT
        (SELECT COALESCE(SUM(numero_filas - 1), 0)
         FROM (
             SELECT COUNT(*) AS numero_filas
             FROM ventas_linea
             WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
             GROUP BY fecha, producto_id, cantidad, precio_unitario
             HAVING COUNT(*) > 1
         ) AS grupos_duplicados) AS duplicados_adicionales,
        (SELECT COUNT(*) FROM ventas_linea WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01') AS total_filas
)
SELECT
    duplicados_adicionales,
    total_filas,
    ROUND(duplicados_adicionales * 100.0 / NULLIF(total_filas, 0), 2) AS porcentaje_duplicados
FROM base;
```

Resultado de la consulta:

| duplicados_adicionales | total_filas | porcentaje_duplicados |
| ---------------------- | ----------- | --------------------- |
| 2731                   | 40470       | 6.75 %                |
### 1c. Alteraciones

```sql
WITH base AS (
    SELECT
        (SELECT COALESCE(SUM(numero_filas - 1), 0)
         FROM (
             SELECT COUNT(*) AS numero_filas
             FROM alteraciones
             WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
             GROUP BY fecha, producto_id, cantidad, coste_unitario, motivo
             HAVING COUNT(*) > 1
         ) AS grupos_duplicados) AS duplicados_adicionales,
        (SELECT COUNT(*) FROM alteraciones WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01') AS total_filas
)
SELECT
    duplicados_adicionales,
    total_filas,
    ROUND(duplicados_adicionales * 100.0 / NULLIF(total_filas, 0), 2) AS porcentaje_duplicados
FROM base;
```

Resultado de la consulta:

| duplicados_adicionales | total_filas | porcentaje_duplicados |
| ---------------------- | ----------- | --------------------- |
| 11                     | 124         | 8.87 %                |
### 1d. Mermas

```sql
WITH base AS (
    SELECT
        (SELECT COALESCE(SUM(numero_filas - 1), 0)
         FROM (
             SELECT COUNT(*) AS numero_filas
             FROM mermas
             WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
             GROUP BY fecha, producto_id, cantidad, coste_unitario
             HAVING COUNT(*) > 1
         ) AS grupos_duplicados) AS duplicados_adicionales,
        (SELECT COUNT(*) FROM mermas WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01') AS total_filas
)
SELECT
    duplicados_adicionales,
    total_filas,
    ROUND(duplicados_adicionales * 100.0 / NULLIF(total_filas, 0), 2) AS porcentaje_duplicados
FROM base;
```


Resultado de la consulta:

| duplicados_adicionales | total_filas | porcentaje_duplicados |
| ---------------------- | ----------- | --------------------- |
| 51                     | 1859        | 2.74 %                |

---

## 2. Producto id=253: pvp_original = 0 en el 100 % de sus filas


```sql
WITH base AS (
    SELECT
        (SELECT COUNT(*) FROM demarcas
         WHERE producto_id = 253 AND pvp_original = 0
           AND fecha >= '2026-01-01' AND fecha < '2026-08-01') AS filas_pvp_original_cero,
        (SELECT COUNT(*) FROM demarcas
         WHERE producto_id = 253
           AND fecha >= '2026-01-01' AND fecha < '2026-08-01') AS total_filas
)
SELECT
    filas_pvp_original_cero,
    total_filas,
    ROUND(filas_pvp_original_cero * 100.0 / NULLIF(total_filas, 0), 2) AS porcentaje_pvp_cero
FROM base;
```

Resultado de la consulta:

| filas_pvp_original_cero | total_filas | porcentaje_pvp_cero |
| ----------------------- | ----------- | ------------------- |
| 328                     | 328         | 100%                |

---

## 3. Impacto de id=251, 252, 253 en Pérdidas por demarcas (€)

```sql
SELECT
    COALESCE(SUM(cantidad * (pvp_original - pvp_demarca)), 0) AS impacto_ids_excluidos_eur
FROM demarcas
WHERE producto_id IN (251, 252, 253)
  AND pvp_demarca < pvp_original
  AND fecha >= '2026-01-01' AND fecha < '2026-08-01';
```

Resultado de la consulta: 

|impacto_ids_excluidos_eur|
|---|
|0|

---

## 4. Demarcas con pvp_demarca > pvp_original y con pvp_demarca = pvp_original

### 4a. pvp_demarca > pvp_original (excluido id=253)

```sql
SELECT
    COUNT(*) AS filas_reversion,
    COUNT(DISTINCT producto_id) AS productos_afectados,
    COALESCE(SUM(cantidad * (pvp_original - pvp_demarca)), 0) AS impacto_neto_eur
FROM demarcas
WHERE producto_id <> 253
  AND pvp_demarca > pvp_original
  AND fecha >= '2026-01-01' AND fecha < '2026-08-01';
```

Resultado de la consulta:

| filas_reversion | productos_afectados | impacto_neto_eur |
| --------------- | ------------------- | ---------------- |
| 101             | 15                  | -17.4619         |
### 4b. pvp_demarca = pvp_original (excluido id=253)

```sql
SELECT
    COUNT(*) AS filas_sin_cambio,
    COALESCE(SUM(cantidad * (pvp_original - pvp_demarca)), 0) AS impacto_neto_eur
FROM demarcas
WHERE producto_id <> 253
  AND pvp_demarca = pvp_original
  AND fecha >= '2026-01-01' AND fecha < '2026-08-01';
```

Resultado de la consulta:

| filas_sin_cambio | impacto_neto_eur |
| ---------------- | ---------------- |
| 286              | 0                |
### 4c. % global de pvp_demarca > pvp_original (sobre demarcas totales, incluye id=253)

```sql
WITH base AS (
    SELECT
        (SELECT COUNT(*) FROM demarcas
         WHERE pvp_demarca > pvp_original
           AND fecha >= '2026-01-01' AND fecha < '2026-08-01') AS filas_mayor,
        (SELECT COUNT(*) FROM demarcas
         WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01') AS total_filas
)
SELECT
    filas_mayor,
    total_filas,
    ROUND(filas_mayor * 100.0 / NULLIF(total_filas, 0), 2) AS porcentaje_pvp_demarca_mayor
FROM base;
```

Resultado de la consulta:

| filas_mayor | total_filas | porcentaje_pvp_demarca_mayor |
| ----------- | ----------- | ---------------------------- |
| 429         | 5235        | 8.19%                        |

### 4d. Alteraciones con cantidad < 0 (abonos/devoluciones)

```SQL
WITH base AS (
    SELECT
        (SELECT COUNT(*) FROM alteraciones
         WHERE cantidad < 0
           AND fecha >= '2026-01-01' AND fecha < '2026-08-01') AS filas_crudo,
        (SELECT COUNT(*) FROM alteraciones
         WHERE cantidad < 0
           AND producto_id NOT IN (251, 252, 253)
           AND fecha >= '2026-01-01' AND fecha < '2026-08-01') AS filas_filtrado
)
SELECT
    filas_crudo,
    filas_filtrado,
    filas_crudo - filas_filtrado AS diferencia_por_exclusion
FROM base;
```

Resultado de la consulta:

| filas_crudo | filas_filtrado | diferencia_por_exclusion |
| ----------- | -------------- | ------------------------ |
| 42          | 27             | 15                       |

---

## 5. pvp_original vs ventas.precio_unitario

### 5a. Coincidencia por producto

```sql
WITH frecuencias AS (
    SELECT producto_id, pvp_original, COUNT(*) AS frecuencia
    FROM demarcas
    WHERE producto_id <> 253 AND fecha >= '2026-01-01' AND fecha < '2026-08-01'
    GROUP BY producto_id, pvp_original
),
top_frecuencia AS (
    SELECT producto_id, MAX(frecuencia) AS max_frecuencia
    FROM frecuencias
    GROUP BY producto_id
),
pvp_moda AS (
    SELECT f.producto_id, AVG(f.pvp_original) AS pvp_original_moda
    FROM frecuencias AS f
    INNER JOIN top_frecuencia AS t
        ON t.producto_id = f.producto_id AND t.max_frecuencia = f.frecuencia
    GROUP BY f.producto_id
),
precio_venta_prod AS (
    SELECT producto_id, MIN(precio_unitario) AS precio_venta
    FROM ventas_linea
    WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
    GROUP BY producto_id
)
SELECT
    COUNT(*) AS total_productos,
    SUM(CASE WHEN ROUND(m.pvp_original_moda, 2) = ROUND(v.precio_venta, 2) THEN 1 ELSE 0 END) AS productos_coinciden,
    ROUND(SUM(CASE WHEN ROUND(m.pvp_original_moda, 2) = ROUND(v.precio_venta, 2) THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2) AS porcentaje_coinciden,
    ROUND(AVG(ABS(m.pvp_original_moda - v.precio_venta)), 2) AS desviacion_media_eur
FROM pvp_moda AS m
INNER JOIN precio_venta_prod AS v ON v.producto_id = m.producto_id;
```

Resultado de la consulta:

| total_productos | productos_coinciden | porcentaje_coinciden | desviacion_media_eur |
| --------------- | ------------------- | -------------------- | -------------------- |
| 132             | 43                  | 32,58 %              | 0.39                 |

### 5b. Recálculo de Pérdidas por demarcas (€) con precio de venta real

```sql
WITH venta_prod AS (
    SELECT producto_id, AVG(precio_unitario) AS precio_venta_medio
    FROM ventas_linea
    WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
    GROUP BY producto_id
)
SELECT
    ROUND(SUM(d.cantidad * (v.precio_venta_medio - d.pvp_demarca)), 2) AS perdida_demarcas_recalculada_eur
FROM demarcas AS d
INNER JOIN venta_prod AS v ON v.producto_id = d.producto_id
WHERE d.pvp_demarca < v.precio_venta_medio
  AND d.fecha >= '2026-01-01' AND d.fecha < '2026-08-01';
```
Resultado de la consulta:

| perdida_demarcas_recalculada_eur |
| -------------------------------- |
| 4228.41                          |

---

## 6. mermas.coste_unitario vs coste medio ponderado de compras

### 6a. Coincidencia línea a línea

```sql
WITH coste_medio AS (
    SELECT producto_id,
           SUM(coste_unitario * cantidad) * 1.0 / SUM(cantidad) AS coste_medio_ponderado
    FROM compras_linea
    WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
    GROUP BY producto_id
)
SELECT
    COUNT(*) AS total_lineas,
    SUM(CASE WHEN ROUND(m.coste_unitario, 2) = ROUND(c.coste_medio_ponderado, 2) THEN 1 ELSE 0 END) AS lineas_coinciden,
    ROUND(SUM(CASE WHEN ROUND(m.coste_unitario, 2) = ROUND(c.coste_medio_ponderado, 2) THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2) AS porcentaje_coinciden,
    ROUND(AVG(ABS(m.coste_unitario - c.coste_medio_ponderado)), 2) AS desviacion_media_eur
FROM mermas AS m
LEFT JOIN coste_medio AS c ON c.producto_id = m.producto_id
WHERE m.fecha >= '2026-01-01' AND m.fecha < '2026-08-01';
```

Resultado de la consulta:

| total_lineas | lineas_coinciden | porcentaje_coinciden | desviacion_media_eur |
| ------------ | ---------------- | -------------------- | -------------------- |
| 1859         | 200              | 10.76 %              | 0.42                 |

### 6b. Recálculo de Coste de mermas (€) revalorizado

```sql
WITH coste_medio AS (
    SELECT producto_id,
           SUM(coste_unitario * cantidad) * 1.0 / SUM(cantidad) AS coste_medio_ponderado
    FROM compras_linea
    WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
    GROUP BY producto_id
)
SELECT
    ROUND(SUM(m.cantidad * c.coste_medio_ponderado), 2) AS coste_mermas_revalorizado_eur
FROM mermas AS m
INNER JOIN coste_medio AS c ON c.producto_id = m.producto_id
WHERE m.fecha >= '2026-01-01' AND m.fecha < '2026-08-01';
```

Resultado de la consulta:

|coste_mermas_revalorizado_eur|
|---|
|1452.41|

---

## 7. Productos con demarca sin coste de compra en el periodo

```sql
WITH productos_demarca AS (
    SELECT DISTINCT producto_id
    FROM demarcas
    WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
),
productos_con_coste AS (
    SELECT DISTINCT producto_id
    FROM compras_linea
    WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
),
base AS (
    SELECT
        (SELECT COUNT(*) FROM productos_demarca AS pd
         WHERE pd.producto_id NOT IN (SELECT producto_id FROM productos_con_coste)) AS productos_sin_coste,
        (SELECT COUNT(*) FROM productos_demarca) AS total_productos_demarca
)
SELECT
    productos_sin_coste,
    total_productos_demarca,
    ROUND(productos_sin_coste * 100.0 / NULLIF(total_productos_demarca, 0), 2) AS porcentaje_sin_coste
FROM base;
```

Resultado de la consulta:

| productos_sin_coste | total_productos_demarca | porcentaje_sin_coste |
| ------------------- | ----------------------- | -------------------- |
| 10                  | 142                     | 7.04%                |

---

## 8. Productos sin ninguna venta ni precio de compra en el periodo

```sql
WITH productos_con_venta AS (
    SELECT DISTINCT producto_id
    FROM ventas_linea
    WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
),
coste AS (
    SELECT producto_id,
           CASE
               WHEN SUM(cantidad) = 0 OR SUM(cantidad) IS NULL THEN NULL
               ELSE SUM(coste_unitario * cantidad) * 1.0 / SUM(cantidad)
           END AS coste_medio
    FROM compras_linea
    WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
    GROUP BY producto_id
),
base AS (
    SELECT
        (SELECT COUNT(*) FROM productos AS p
         WHERE p.producto_id NOT IN (SELECT producto_id FROM productos_con_venta)) AS productos_sin_venta,
        (SELECT COUNT(*) FROM productos AS p
         LEFT JOIN coste c ON c.producto_id = p.producto_id
         WHERE c.coste_medio IS NULL) AS productos_sin_precio_compra,
        (SELECT COUNT(*) FROM productos) AS total_productos
)
SELECT
    productos_sin_venta,
    productos_sin_precio_compra,
    total_productos,
    ROUND(productos_sin_venta * 100.0 / NULLIF(total_productos, 0), 2)         AS porcentaje_sin_venta,
    ROUND(productos_sin_precio_compra * 100.0 / NULLIF(total_productos, 0), 2) AS porcentaje_sin_precio_compra
FROM base;
```

Resultado de la consulta:

| productos_sin_venta | productos_sin_precio_compra | total_productos | porcentaje_sin_venta | porcentaje_sin_precio_compra |
| ------------------- | --------------------------- | --------------- | -------------------- | ---------------------------- |
| 71                  | 71                          | 254             | 27.95%               | 27.95%                       |

---
## 9. Diferencia entre Compras (€) y coste de mercancía vendida + mermas + alteraciones

```sql
WITH coste_medio AS (
    SELECT producto_id,
           SUM(coste_unitario * cantidad) * 1.0 / SUM(cantidad) AS coste_medio_ponderado
    FROM compras_linea
    WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
    GROUP BY producto_id
),
base AS (
    SELECT
        (SELECT SUM(coste_unitario * cantidad) FROM compras_linea
         WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01') AS compras_eur,
        (SELECT SUM(v.cantidad * c.coste_medio_ponderado)
         FROM ventas_linea AS v INNER JOIN coste_medio AS c ON c.producto_id = v.producto_id
         WHERE v.fecha >= '2026-01-01' AND v.fecha < '2026-08-01') AS ventas_a_coste_eur,
        (SELECT SUM(d.cantidad * c.coste_medio_ponderado)
         FROM demarcas AS d INNER JOIN coste_medio AS c ON c.producto_id = d.producto_id
         WHERE d.fecha >= '2026-01-01' AND d.fecha < '2026-08-01') AS demarcas_a_coste_eur,
        (SELECT SUM(cantidad * coste_unitario) FROM mermas
         WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01') AS mermas_eur,
        (SELECT SUM(cantidad * coste_unitario) FROM alteraciones
         WHERE cantidad > 0 AND fecha >= '2026-01-01' AND fecha < '2026-08-01') AS alteraciones_eur
)
SELECT
    compras_eur, ventas_a_coste_eur, demarcas_a_coste_eur, mermas_eur, alteraciones_eur,
    compras_eur - ventas_a_coste_eur - demarcas_a_coste_eur - mermas_eur - alteraciones_eur AS diferencia_eur
FROM base;
```

Resultado de la consulta: 

| compras_eur  | ventas_a_coste_eur | demarcas_a_coste_eur | mermas_eur | alteraciones_eur | diferencia_eur |
| ------------ | ------------------ | -------------------- | ---------- | ---------------- | -------------- |
| 142717.45924 | 123411.76261       | 6306.1966            | 1636.4165  | 579.0354         | 10784.04813    |

---

## 10. Unidades compradas vs con salida trazada + productos con salidas > compras

### 10a. Totales de unidades

```sql
WITH base AS (
    SELECT
        (SELECT COALESCE(SUM(cantidad), 0) FROM compras_linea
         WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01') AS unidades_compradas,
        (SELECT COALESCE(SUM(cantidad), 0) FROM ventas_linea WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01')
        + (SELECT COALESCE(SUM(cantidad), 0) FROM mermas WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01')
        + (SELECT COALESCE(SUM(cantidad), 0) FROM demarcas WHERE cantidad > 0 AND fecha >= '2026-01-01' AND fecha < '2026-08-01')
        + (SELECT COALESCE(SUM(cantidad), 0) FROM alteraciones WHERE cantidad > 0 AND fecha >= '2026-01-01' AND fecha < '2026-08-01') AS 
          unidades_con_salida
          
)
SELECT
    unidades_compradas,
    unidades_con_salida,
    ROUND(unidades_con_salida * 100.0 / NULLIF(unidades_compradas, 0), 2) AS porcentaje_con_salida,
    unidades_compradas - unidades_con_salida AS unidades_sin_destino
FROM base;
```

Resultado de la consulta:

| unidades_compradas | unidades_con_salida | porcentaje_con_salida | unidades_sin_destino |
| ------------------ | ------------------- | --------------------- | -------------------- |
| 104730.462         | 96666.821           | 92.3                  | 8063.641             |

### 10b. Productos con salidas superiores a compras

```sql
WITH compras_prod AS (
    SELECT producto_id, SUM(cantidad) AS ud_compradas
    FROM compras_linea
    WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
    GROUP BY producto_id
),
salidas_prod AS (
    SELECT producto_id, SUM(cantidad) AS ud_salida
    FROM (
        SELECT producto_id, cantidad FROM ventas_linea WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
        UNION ALL
        SELECT producto_id, cantidad FROM mermas WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
        UNION ALL
        SELECT producto_id, cantidad FROM alteraciones WHERE cantidad > 0 AND fecha >= '2026-01-01' AND fecha < '2026-08-01'
        UNION ALL
        SELECT producto_id, cantidad FROM demarcas WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
    ) AS salidas
    GROUP BY producto_id
),
universo AS (
    SELECT producto_id FROM compras_prod
    UNION
    SELECT producto_id FROM salidas_prod
)
SELECT
    COUNT(*) AS total_productos_universo,
    SUM(CASE WHEN COALESCE(sp.ud_salida, 0) > COALESCE(cp.ud_compradas, 0) THEN 1 ELSE 0 END) AS productos_salida_mayor_compra
FROM universo AS u
LEFT JOIN compras_prod AS cp ON cp.producto_id = u.producto_id
LEFT JOIN salidas_prod AS sp ON sp.producto_id = u.producto_id;
```

Resultado de la consulta:

| total_productos_universo | productos_salida_mayor_compra |
| ------------------------ | ----------------------------- |
| 194                      | 68                            |

---
## 11. Cobertura de coste_unitario en productos con demarca

```sql
WITH productos_demarca AS (
    SELECT DISTINCT producto_id
    FROM demarcas
    WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
),
productos_con_coste AS (
    SELECT DISTINCT producto_id
    FROM compras_linea
    WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
),
base AS (
    SELECT
        (SELECT COUNT(*) FROM productos_demarca AS pd
         WHERE pd.producto_id IN (SELECT producto_id FROM productos_con_coste)) AS productos_con_coste_cubierto,
        (SELECT COUNT(*) FROM productos_demarca) AS total_productos_demarca
)
SELECT
    productos_con_coste_cubierto,
    total_productos_demarca,
    ROUND(productos_con_coste_cubierto * 100.0 / NULLIF(total_productos_demarca, 0), 2) AS porcentaje_cobertura
FROM base;
```

Resultado de la consulta:

| productos_con_coste_cubierto | total_productos_demarca | porcentaje_cobertura |
| ---------------------------- | ----------------------- | -------------------- |
| 132                          | 142                     | 92.96%               |
## 12. El 78,13% de demarcas bajo coste se vende a 1€ o menos.

``` SQL
WITH coste_medio AS (
    SELECT producto_id,
           SUM(coste_unitario * cantidad) * 1.0 / SUM(cantidad) AS coste_medio_ponderado
    FROM compras_linea
    WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
    GROUP BY producto_id
),
demarcas_bajo_coste AS (
    SELECT d.pvp_demarca
    FROM demarcas AS d
    INNER JOIN coste_medio AS c ON c.producto_id = d.producto_id
    WHERE d.cantidad > 0
      AND d.pvp_demarca < c.coste_medio_ponderado
      AND d.fecha >= '2026-01-01' AND d.fecha < '2026-08-01'
),
base AS (
    SELECT
        COUNT(*) AS total_demarcas_bajo_coste,
        SUM(CASE WHEN pvp_demarca <= 1.00 THEN 1 ELSE 0 END) AS demarcas_a_1_euro_o_menos
    FROM demarcas_bajo_coste
)
SELECT
    demarcas_a_1_euro_o_menos,
    total_demarcas_bajo_coste,
    ROUND(demarcas_a_1_euro_o_menos * 100.0 / NULLIF(total_demarcas_bajo_coste, 0), 2) AS porcentaje_a_1_euro
FROM base;
```

Resultado de la consulta: 

| demarcas_a_1_euro_o_menos | total_demarcas_bajo_coste | porcentaje_a_1_euro |
| ------------------------- | ------------------------- | ------------------- |
| 2705                      | 3462                      | 78.13 %             |
## 13. El 97% de 132 productos con coste conocido y demarca tienen demarca bajo coste

```SQL
WITH coste_medio AS (
    SELECT producto_id,
           SUM(coste_unitario * cantidad) * 1.0 / SUM(cantidad) AS coste_medio_ponderado
    FROM compras_linea
    WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
    GROUP BY producto_id
),
productos_con_coste_y_demarca AS (
    SELECT DISTINCT d.producto_id
    FROM demarcas AS d
    INNER JOIN coste_medio AS c ON c.producto_id = d.producto_id
    WHERE d.fecha >= '2026-01-01' AND d.fecha < '2026-08-01'
),
productos_bajo_coste AS (
    SELECT DISTINCT d.producto_id
    FROM demarcas AS d
    INNER JOIN coste_medio AS c ON c.producto_id = d.producto_id
    WHERE d.cantidad > 0
      AND d.pvp_demarca < c.coste_medio_ponderado
      AND d.fecha >= '2026-01-01' AND d.fecha < '2026-08-01'
),
base AS (
    SELECT
        (SELECT COUNT(*) FROM productos_con_coste_y_demarca) AS total_con_coste_y_demarca,
        (SELECT COUNT(*) FROM productos_con_coste_y_demarca AS pcd
         WHERE pcd.producto_id IN (SELECT producto_id FROM productos_bajo_coste)) AS productos_bajo_coste_n
)
SELECT
    productos_bajo_coste_n,
    total_con_coste_y_demarca,
    ROUND(productos_bajo_coste_n * 100.0 / NULLIF(total_con_coste_y_demarca, 0), 2) AS porcentaje_productos_bajo_coste
FROM base;
```

Resultado de la consulta: 

| productos_bajo_coste_n | total_con_coste_y_demarca | porcentaje_productos_bajo_coste |
| ---------------------- | ------------------------- | ------------------------------- |
| 128                    | 132                       | 96.97 %                         |

## 14. Peso de las demarcas bajo coste: 2.017,33 € sobre coste

```SQL
WITH coste_medio AS (
    SELECT producto_id,
           SUM(coste_unitario * cantidad) * 1.0 / SUM(cantidad) AS coste_medio_ponderado
    FROM compras_linea
    WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01'
    GROUP BY producto_id
),
base AS (
    SELECT
        (SELECT COALESCE(SUM(d.cantidad * (c.coste_medio_ponderado - d.pvp_demarca)), 0)
         FROM demarcas AS d
         INNER JOIN coste_medio AS c ON c.producto_id = d.producto_id
         WHERE d.cantidad > 0
           AND d.pvp_demarca < c.coste_medio_ponderado
           AND d.fecha >= '2026-01-01' AND d.fecha < '2026-08-01') AS perdida_demarca_bajo_coste_eur,
        (SELECT COALESCE(SUM(cantidad * coste_unitario), 0) FROM mermas
         WHERE fecha >= '2026-01-01' AND fecha < '2026-08-01')
        + (SELECT COALESCE(SUM(cantidad * (pvp_original - pvp_demarca)), 0) FROM demarcas
           WHERE cantidad > 0 AND pvp_demarca < pvp_original
             AND fecha >= '2026-01-01' AND fecha < '2026-08-01')
        + (SELECT COALESCE(SUM(cantidad * coste_unitario), 0) FROM alteraciones
           WHERE cantidad > 0 AND fecha >= '2026-01-01' AND fecha < '2026-08-01') AS perdida_operativa_total_eur
)
SELECT
    perdida_demarca_bajo_coste_eur,
    perdida_operativa_total_eur,
    ROUND(perdida_demarca_bajo_coste_eur * 100.0 / NULLIF(perdida_operativa_total_eur, 0), 2) AS porcentaje_bajo_coste
FROM base;
```

Resultado de la consulta:

| perdida_demarca_bajo_coste_eur | perdida_operativa_total_eur | porcentaje_bajo_coste |
| ------------------------------ | --------------------------- | --------------------- |
| 2017.3341                      | 7209.1149000000005          | 27.98 %               |
## 15. Comprobación de valores nulos en todas las tablas de hechos

```SQL
WITH base AS (
    SELECT
        (SELECT COUNT(*) FROM productos WHERE producto_id IS NULL OR nombre IS NULL OR tipo_venta IS NULL OR categoria IS NULL) AS nulos_productos,
        (SELECT COUNT(*) FROM demarcas WHERE (fecha >= '2026-01-01' AND fecha < '2026-08-01')
            AND (producto_id IS NULL OR cantidad IS NULL OR pvp_original IS NULL OR pvp_demarca IS NULL)) AS nulos_demarcas,
        (SELECT COUNT(*) FROM mermas WHERE (fecha >= '2026-01-01' AND fecha < '2026-08-01')
            AND (producto_id IS NULL OR cantidad IS NULL OR coste_unitario IS NULL)) AS nulos_mermas,
        (SELECT COUNT(*) FROM alteraciones WHERE (fecha >= '2026-01-01' AND fecha < '2026-08-01')
            AND (producto_id IS NULL OR cantidad IS NULL OR coste_unitario IS NULL OR motivo IS NULL)) AS nulos_alteraciones,
        (SELECT COUNT(*) FROM compras_linea WHERE (fecha >= '2026-01-01' AND fecha < '2026-08-01')
            AND (producto_id IS NULL OR cantidad IS NULL OR coste_unitario IS NULL)) AS nulos_compras,
        (SELECT COUNT(*) FROM ventas_linea WHERE (fecha >= '2026-01-01' AND fecha < '2026-08-01')
            AND (producto_id IS NULL OR cantidad IS NULL OR precio_unitario IS NULL)) AS nulos_ventas
)
SELECT * FROM base;
```

Resultado de la consulta: 

|nulos_productos|nulos_demarcas|nulos_mermas|nulos_alteraciones|nulos_compras|nulos_ventas|
|---|---|---|---|---|---|
|0|0|0|3|0|0|
