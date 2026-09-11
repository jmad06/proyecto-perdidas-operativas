# Arquitectura técnica - Pérdidas operativas del stock

Parte 2 de 2 de la documentación ampliada del proyecto. Cubre el pipeline de construcción, el modelo de datos en estrella, las columnas calculadas, el origen de los datos y anomalías detectadas, y las limitaciones del análisis. Para el problema de negocio y las conclusiones, ver [Parte 1: Análisis completo](01-analisis-completo.md).

**Stack:** SQL · Power BI · DAX

---
# Índice de contenidos

### Parte 2: Cómo se ha construido

- [Cómo se ha construido el proyecto](#cómo-se-ha-construido-el-proyecto)
- [Modelo de datos](#modelo-de-datos)
- [Columnas calculadas](#columnas-calculadas)
- [Origen de los datos y anomalías detectadas](#origen-de-los-datos-y-anomalías-detectadas)
- [Consultas SQL](#consultas-sql)
- [Medidas DAX](#medidas-dax)
- [Limitaciones y qué debería capturar el ERP](#limitaciones-y-qué-debería-capturar-el-erp)
---
## Cómo se ha construido el proyecto

El proyecto sigue un pipeline de 9 etapas, desde el diseño de la base de datos hasta la documentación final:

0. Diseño de la base de datos SQLite 3 mediante IA y chequeo de anomalías.
1. Conexión SQLite → Power BI vía driver ODBC sobre `fruit_store.db`, en modo Import.
2. Consultas SQL de extracción de las tablas de dimensiones y hechos.
3. Evaluación de calidad en Power Query: verificación ya realizada en SQL y documentada como chequeo (no como limpieza) de las anomalías conocidas; comprobación de tipos (`fecha` como fecha real, `producto_id` consistente y entero entre tablas); cobertura de `coste_unitario` confirmada en 132 de 142 productos con demarca (92,96 %). Exclusión de los productos con id=251 y 252 (`MATERIAL LOGISTICO (no vendible)`) y id=253 ("sin clasificar"), ninguno de los tres vendible ni relevante para el análisis de deterioro de stock. [Ver auditoría completa](../SQL/auditoria.md)
4. Modelado de datos y relaciones: `productos` como dimensión central con relación 1:N hacia las tablas de hechos, filtro en una única dirección (`productos` → hechos), y tabla de calendario para las medidas mensuales del periodo enero 2026 - julio 2026.
5. Tablas de medidas y KPIs en DAX, organizadas en varias tablas `_Medidas` por orden y legibilidad, construidas siempre desde las tablas de detalle. [Ver medidas DAX](../DAX/dax.md)
6. Construcción del informe visual: las 5 páginas descritas en el documento [01-análisis-completo](01-análisis-completo.md#estructura-del-dashboard), en orden.
7. Aplicación del tema visual UX (tema JSON + fondos por página) una vez cerrado el informe funcional.
8. Redacción de documentación, en dos partes que separan la relevancia de negocio de la relevancia técnica del proyecto.

---

## Modelo de datos

| Tabla                      | Grano                                                              | Columnas clave                                                                                                                  | Relación                                                                                 |
| -------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `productos`                | Un producto                                                        | `producto_id` (PK), `nombre`, `tipo_venta`, `subcategoria`, `Categoría (calc)`, ``Coste Medio de Compra Histórico (€) (calc.)`` | Dimensión central, 1:N hacia todas las tablas de hechos                                  |
| `Calendario`               | Un día                                                             | `Date`, `Año`, `Mes Número`, `Nombre Mes`, `AñoMes (cacl)`                                                                      | Dimensión de fecha, 1:N hacia `compras`, `ventas`, `demarcas`, `mermas` y `alteraciones` |
| `compras`                  | Una línea de compra                                                | `fecha`, `producto_id`, `cantidad`, `coste_unitario`                                                                            | `*` → `1` con `productos` y `Calendario`                                                 |
| `ventas`                   | Una línea de venta                                                 | `fecha`, `producto_id`, `cantidad`, `precio_unitario`                                                                           | `*` → `1` con `productos` y `Calendario`                                                 |
| `demarcas`                 | Un evento de rebaja de precio                                      | `fecha`, `producto_id`, `cantidad`, `pvp_original`, `pvp_demarca`                                                               | `*` → `1` con `productos` y `Calendario`                                                 |
| `mermas`                   | Un evento de pérdida de producto                                   | `fecha`, `producto_id`, `cantidad`, `coste_unitario`                                                                            | `*` → `1` con `productos` y `Calendario`                                                 |
| `alteraciones`             | Un evento de ajuste de inventario                                  | `fecha`, `producto_id`, `cantidad`, `coste_unitario`                                                                            | `*` → `1` con `productos` y `Calendario`                                                 |
| ``Pasos_Cascada``          | Tabla auxiliar para construir el gráfico de cascada de la página 1 | ``Orden``, ``Paso``                                                                                                             | Sin relaciones                                                                           |
| ``Parámetro Recuperación`` | Tabla auxiliar para construir el slider de la página 5             | `Parámetro recuperación (parámetro)`, `Valor de parámetro de recuperación`                                                      | Sin relaciones                                                                           |

---

## Columnas calculadas

- ``Productos[Categoría]``: columna calculada con mapeo a través de ``SWITCH`` sobre las Subcategorias de la base de datos, detallada en [dax.md](../DAX/dax.md#mapeo-de-categorías-a-partir-de-las-subcategorias-originales)
- ``Productos[Coste medio de compra Histórico (€)]``: columna calculada, coste medio ponderado por cantidad sobre todo el periodo, invariante al filtro de Calendario por construcción. Existe por rendimiento (evita CALCULATE con transición de contexto por cada fila de `demarcas`) y para las medidas de `_Medidas_Demarcas_bajocoste` y `_Medidas_Simulación`, que necesitan ese coste sin depender del mes seleccionado. No sustituye a la medida `Coste Medio de Compra (€)`, que sigue usándose en `Margen Bruto del producto (€)` porque esa sí debe respetar el filtro de mes. Detallada en [dax.md](../DAX/dax.md#coste-medio-de-compra-histórico-)
- `AñoMes`: columna calculada en la tabla calendario que se utiliza para ordenar la columna `Nombre Mes` y alimenta el gráfico de líneas de la página 1 del dashboard para que se vea ordenado cronológicamente.

---

## Origen de los datos y anomalías detectadas

La base de datos `fruit_store.db` es un dataset sintético, generado para modelar el comportamiento operativo de una frutería. La siguiente tabla documenta cada anomalía detectada en la auditoría de calidad (fase 0, [auditoria.md](../SQL/auditoria.md)), distinguiendo el universo crudo del universo ya filtrado en el modelo (excluidos los productos id 251, 252 y 253, ver [Cómo se ha construido el proyecto](#cómo-se-ha-construido-el-proyecto), punto 3), y clasificando cada una según su naturaleza: patrón esperado del proceso de generación, error de carga real, decisión de diseño del modelo, o limitación estructural del dataset que se documenta sin corregir.

| #   | Anomalía                                                            |       Universo crudo (auditoría fase 0) |                         Universo filtrado (modelo) | Comprobación | Calificación y motivo                                                                                                                                                                                                                                                                                                                                                                                                                             |
| --- | ------------------------------------------------------------------- | --------------------------------------: | -------------------------------------------------: | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1a  | Duplicados exactos, demarcas                                        |                   22,66 % (1.186/5.235) | No aplica: deduplicación previa a exclusión de ids | 1a           | **Esperado, no error.** 90,1 % de estos duplicados son productos `tipo_venta = ud`; con cantidad entera y precio fijo, `fecha + producto + cantidad + precios` colisiona de forma legítima por baja cardinalidad, no por carga duplicada. Sin duplicados en demarcas impacto de: -1.028,80 € (-20,6 %)                                                                                                                                            |
| 1b  | Duplicados exactos, ventas                                          |                   6,75 % (2.731/40.470) |                                          No aplica | 1b           | **Esperado.** 99,6 % son productos `ud`, mismo mecanismo que 1a.                                                                                                                                                                                                                                                                                                                                                                                  |
| 1c  | Duplicados exactos, alteraciones                                    |                         8,87 % (11/124) |                                          No aplica | 1c           | **Esperado.** 100 % son productos `ud`. Sin duplicados en alteraciones impacto de 0 €.                                                                                                                                                                                                                                                                                                                                                            |
| 1d  | Duplicados exactos, mermas                                          |                       2,74 % (51/1.859) |                                          No aplica | 1d           | **Único caso con presencia apreciable en `kg`** (20 de 51, 39,2 %): en cantidades continuas la colisión exacta es menos esperable y merece revisión puntual, no solo etiquetado como artefacto. Sin duplicados en mermas -61,51 € (-3,76 %)                                                                                                                                                                                                       |
| 2   | Producto id=253, `pvp_original = 0`                                 |                  100 % de sus 328 filas |                                Excluido del modelo | 2            | **Error de carga.** Patrón sistemático (no puntual) en un producto sin categoría real; motivo de exclusión, no de corrección                                                                                                                                                                                                                                                                                                                      |
| 3   | Impacto de ids 251/252/253 en `Pérdidas por demarca (€)`            |                                     0 € |                                                0 € | 3            | **Exclusión sin coste analítico.** 251 y 252 son envases logísticos, no vendibles (0 filas en demarcas); 253 se excluye por el error del punto 2. Ninguno afecta la medida                                                                                                                                                                                                                                                                        |
| 4a  | Demarcas con `pvp_demarca > pvp_original` (excl. 253)               | 101 filas, 15 productos, −17,46 € netos |                         Sin cambio, ya excluye 253 | 4a           | **Se conserva, no se corrige.** Reversión parcial de precio, evidencia trazable; se filtra en DAX (`pvp_demarca < pvp_original`) para no distorsionar la medida, pero se documenta en SQL                                                                                                                                                                                                                                                         |
| 4b  | Demarcas con `pvp_demarca = pvp_original` (excl. 253)               |                  286 filas, impacto 0 € |                                         Sin cambio | 4b           | **Sin impacto económico**, no requiere decisión                                                                                                                                                                                                                                                                                                                                                                                                   |
| 4c  | % global de `pvp_demarca > pvp_original` sobre el total de demarcas |                      8,19 % (429/5.235) |                                 2,06 % (101/4.907) | 4c           | **Redundante con 2 y 4a, no es una anomalía adicional.** De las 429 filas del universo crudo, 328 pertenecen al id=253: como su `pvp_original` es siempre 0, cualquier `pvp_demarca` positivo queda trivialmente "por encima" del original. Las 101 filas restantes son exactamente las mismas 101 filas y 15 productos ya documentados en 4a. Se incluye por completitud de la auditoría, no aporta hallazgo nuevo sobre el universo ya filtrado |
| 4d  | Alteraciones con `cantidad < 0`                                     |                               42 líneas |                                          27 líneas | 4d           | **Exclusión correcta por semántica.** Son abonos/devoluciones, aportan valor en vez de restarlo; incluirlas invertiría el signo de `Pérdidas por alteraciones (€)`                                                                                                                                                                                                                                                                                |
| 5a  | pvp_original vs precio de venta real, coincidencia                  |          43/132 (32,58 %), desv. 0,39 € |      Sin cambio: ninguno de los 132 es id excluido | 5a           | **Sensibilidad documentada, no corregida.** Recalculando con precio de venta real, `Pérdidas por demarca (€)` pasa de 4.993,66 € a 4.228,41 € (−15,3 %); se mantiene `pvp_original` como base porque es el campo de origen del modelo                                                                                                                                                                                                             |
| 6a  | mermas.coste_unitario vs coste medio ponderado                      |       200/1.859 (10,76 %), desv. 0,42 € |                                         Sin cambio | 6a           | **Sensibilidad documentada, no corregida.** Revalorizado, `Coste de mermas (€)` pasa de 1.636,42 € a 1.452,41 € (−11,2 %); mismo criterio que 5a                                                                                                                                                                                                                                                                                                  |
| 7   | Productos con demarca sin coste de compra                           |                         10/142 (7,04 %) |                                     9/141 (6,38 %) | 7            | **Exclusión por diseño**, no error: `NOT ISBLANK(PrecioMin)` los saca de toda medida dependiente del coste porque no hay base para calcularlo                                                                                                                                                                                                                                                                                                     |
| 8   | Productos sin ninguna venta ni coste de compra conocido             |                        71/254 (27,95 %) |                                   68/251 (27,09 %) | 8            | **Esperado en frutería con catálogo amplio.** Quedan fuera de rentabilidad y del Indicador Relación Pérdida-Venta por falta de base de comparación, no por error                                                                                                                                                                                                                                                                                  |
| 9   | Compras vs coste de venta + mermas + alteraciones                   |                  Diferencia 10.784.04 € |                                     **10.789,05€** | 9            | **Indicativo, no conciliado.** Depende del reparto de `compras_linea`/`ventas_linea` a nivel de producto; no es un error, es una limitación estructural del dataset para métricas a nivel de línea                                                                                                                                                                                                                                                |
| 10a | Unidades compradas con salida trazada                               |         96.666.821/104.730.462 (92.3 %) |                       96.336,3/104.730,5 (91,99 %) | 10a          | **Sin destino: 8.063,64 (crudo) / 8.394,2 (filtrado). Limitación estructural del dataset, no efecto de frontera.** Se documenta como limitación del generador sintético del dataset, sin origen exacto identificado                                                                                                                                                                                                                               |
| 10b | Productos con salida > compra                                       |                                  68/194 |                                             66/192 | 10b          | **Indicio de compras fuera de ventana**, no de error de datos; mismo motivo que 10a                                                                                                                                                                                                                                                                                                                                                               |
| 11  | Cobertura de coste en productos con demarca                         |                       132/142 (92,96 %) |                                  132/141 (93,62 %) | 11           | Mismo universo que 7, vista en positivo                                                                                                                                                                                                                                                                                                                                                                                                           |
| 15  | Valores nulos en `alteraciones.cantidad`                            |                                 3 filas |                           Excluidos en Power Query | 15           | Queda excluido a nivel de Power Query y en el propio filtro DAX `cantidad > 0`                                                                                                                                                                                                                                                                                                                                                                    |

---
## Consultas SQL

El detalle completo de las consultas de extracción utilizadas para nutrir el modelo de Power BI está en [consultas.sql](../SQL/consultas.sql), organizado por tabla de origen, en el mismo orden que las tablas descritas en [Modelo de datos](#modelo-de-datos)

Cada consulta extrae únicamente las columnas necesarias para el modelo (sin `SELECT *`) y aplica el filtro de ventana temporal del proyecto (``fecha >= '2026-01-01' AND fecha < '2026-08-01'``) en las tablas de hechos con grano diario.

Las cifras de [Origen de los datos y anomalías detectadas](#origen-de-los-datos-y-anomalías-detectadas) (duplicados, exclusiones, sensibilidad de bases de coste/precio, cobertura y conciliación) se verifican en SQL en [auditoria.md](../SQL/auditoria.md), en la misma carpeta `SQL/`.

>Nota de nomenclatura: las consultas hacen referencia a `ventas_linea` y `compras_linea`, los nombres de las tablas en el origen `fruit_store.db`. Power Query renombra ambas a `ventas` y `compras` al importar, para mantener consistencia con el resto de tablas de hechos del modelo (ver [Modelo de datos](#modelo-de-datos)); el detalle línea a línea de las medidas DAX y su documentación en `DAX.md` usa siempre el nombre ya normalizado (`ventas`, `compras`).

---
## Medidas DAX

Listado completo, organizado por las 5 carpetas reales del modelo, en el mismo orden en que aparecen en `dax.md`. Cada medida incluye su propósito de negocio; el detalle línea a línea con comentarios inline está en [dax.md](../DAX/dax.md)

### `_Medidas_Pérdidas_operativas`

|Medida|Propósito|
|---|---|
|`% de alteraciones`|Proporción de alteraciones sobre la pérdida operativa total|
|`% de demarca`|Proporción de demarcas sobre la pérdida operativa total|
|`% de mermas`|Proporción de mermas sobre la pérdida operativa total|
|`% Eventos de demarca sobre el total`|Muestra la proporción de eventos de demarca sobre todos los eventos de pérdida operativa.|
|`% pérdidas s/Compras`|Proporción relativa de pérdidas sobre las compras totales.|
|`% pérdidas s/ventas`|Proporción relativa de pérdidas sobre las ventas totales.|
|`Aportación de unidades demarcadas (€)`|Calcula el impacto económico real de las unidades vendidas en demarca.|
|`Coste de mermas (€)`|Valor económico del producto dado de baja por merma en el periodo|
|`Deterioro real del producto (€)`|Suma de los componentes que si son salida real de caja menos la aportación de unidades demarcadas que no tienen ingreso.|
|`Indicador Relación Pérdida-Venta`|Índice de -1 a 1 que compara ventas frente a pérdidas operativas, normalizado para comparar productos de tamaños distintos|
|`Nº Eventos de pérdida`|Recuento de eventos que componen la pérdida operativa total|
|`Pérdida media por evento (€)`|Pérdida operativa total dividida entre número de eventos|
|`Pérdida operativa total (€)`|Suma de los tres componentes anteriores; KPI central de pérdida operativa del stock|
|`Pérdidas por alteraciones (€)`|Valor económico de los ajustes de inventario del periodo (`cantidad > 0`)|
|`Pérdidas por demarca (€)`|Valor perdido por rebaja de precio, solo demarcas válidas (`pvp_demarca < pvp_original`)|
|`Compras sin destino trazado (€)`|Importe comprado que no ha sido trazado en ventas, mermas o alteraciones.|
|`Var % Pérdida operativa MoM`|Muestra la variación de pérdidas con respecto al mes pasado en formato condicional.|

### `_Medidas_Ventas_compras`

|Medida|Propósito|
|---|---|
|`Compras (€)`|Total comprado en el periodo, calculado línea a línea|
|`Coste Medio de Compra (€)`|Coste medio ponderado por cantidad; medida base de la que dependen la mayoría de medidas de coste del modelo|
|`Ventas (€)`|Total vendido en el periodo, calculado línea a línea|

### `_Medidas_Rentabilidad_producto`

|Medida|Propósito|
|---|---|
|`% Margen bruto del producto`|Margen bruto del producto sobre sus ventas.|
|`% Margen Neto sobre ventas a tarifa`|Margen neto del producto sobre sus ventas, sin incluir unidades demarcadas ya que estas no aparecen en el denominador.|
|`% Margen perdido`|Proporción del margen bruto del producto que se pierde por deterioro. Puede superar el 100% cuando la pérdida excede el margen bruto del producto.|
|`Margen Bruto del producto (€)`|Margen bruto a nivel de producto individual.|
|`Margen Neto del producto`|Margen bruto del producto menos el deterioro real del producto.|

### `_Medidas_Demarcas_bajocoste`

|Medida|Propósito|
|---|---|
|`% pérdida total por demarca bajo coste`|Proporción de la pérdida operativa total que corresponde al caso más grave (venta bajo coste)|
|`Nº Eventos de demarca bajo coste`|Eventos de demarca con precio de venta por debajo del coste medio de compra|
|`Nº Productos con demarca bajo coste`|Productos distintos con al menos un evento de demarca bajo coste|
|`Profundidad media de demarca bajo coste (%)`|Porcentaje medio de descuento sobre el coste en las demarcas bajo coste|
|`Pérdida por demarca bajo coste (€)`|Importe perdido específicamente por vender bajo coste.|
|`Tolerancia Demarca Bajo Coste`|Define el nivel de tolerancia en el precio base de las formulas de demarca bajo coste.|

### `_Medidas_Simulación`

Ver [Simulación de recuperación](01-análisis-completo.md#simulación-de-recuperación-acción-e-impacto) para el detalle funcional del escenario.

| Medida                            | Propósito                                                                                                                                   |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `Precio de demarca simulado (€)`  | Precio interpolado, por producto, entre el precio de demarca real medio y el coste medio de compra, según el porcentaje del slider          |
| `Pérdida evitable máxima (€)`     | Techo teórico de recuperación si todas las demarcas bajo coste se hubieran vendido al coste; reutiliza `Pérdida por demarca bajo coste (€)` |
| `Pérdida evitable simulada (€)`   | Techo teórico escalado por el porcentaje del slider                                                                                         |
| `Valor de Parámetro Recuperación` | Lee la posición del slider (0 a 1)                                                                                                          |

### Otras medidas y columnas calculadas (soporte visual, fuera de las 5 carpetas de KPIs)

| Medida                                | Propósito                                                                                                         |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `Coste Medio de Compra Histórico (€)` | Columna calculada, coste medio ponderado invariante al filtro de Calendario. Ver [Columnas calculadas](#columnas-calculadas)         |
| `Valor Cascada`                       | Alimenta el gráfico de cascada de la página 1, junto con la tabla auxiliar `Pasos_Cascada`                        |
| `Categoría`                           | Mapeo de categorías sobre las Subcategorias originales                                                            |
| `Tabla de calendario`                 | Tabla de fechas del modelo, base de las medidas mensuales                                                         |
| `AñoMes`                              | Columna calculada de la tabla Calendario, usada para ordenar cronológicamente el gráfico de líneas de la página 1 |

---

## Limitaciones y qué debería capturar el ERP

1. **Sin benchmark sectorial.** El 4,13 % de pérdida sobre ventas no se contrasta contra ninguna referencia sectorial. Sin ese punto de comparación, la cifra describe el negocio pero no permite concluir si su nivel de deterioro es alto o bajo para una frutería de su tamaño. Incorporar un benchmark de merma en retail de frescos es la primera extensión pendiente del análisis.
2. **El dataset no vincula `demarcas` con `ventas_linea`.** Cada producto tiene un único precio de venta en `ventas_linea` y las unidades demarcadas no aparecen en esa tabla, por lo que ni su ingreso ni su coste entran en `Margen Bruto del producto (€)`. Un ERP real debería registrar la venta demarcada como línea de venta con su precio efectivo y una marca de "venta en demarca", lo que permitiría calcular el margen neto real por producto en lugar de estimarlo.
3. **La simulación no modela elasticidad de demanda.** El escenario de recuperación [Simulación de recuperación](01-análisis-completo.md#simulación-de-recuperación-acción-e-impacto) asume volumen de venta constante al subir el precio de demarca hacia el coste, sin contemplar que un precio más alto pueda reducir ventas o aumentar el volumen que termina en merma.
4. **El ERP debería capturar, además:**
   - **Número de lote por producto**, para permitir trazabilidad individual del stock desde la compra hasta la venta, demarca o merma.
   - **Alertas automáticas de deadline de demarca**, ligadas a la fecha de caducidad o vida útil esperada del lote, para anticipar la necesidad de demarcar y minimizar tanto el volumen de merma como la profundidad del descuento necesario.
5. **El análisis se centra en estimaciones monetarias.** Sería valioso complementarlo con cruces en unidades físicas (`ud` y `kg`), para mostrar tanto el impacto económico como el impacto material del deterioro de stock, que también es relevante operativamente.
6. **Coste de compra tratado como constante.** Si el coste de compra hubiera variado realmente a lo largo del periodo (por estacionalidad, cambios de proveedor u otros factores), las medidas de demarca bajo coste podrían estar sobrestimando o subestimando la pérdida real de eventos concretos, al evaluarlos contra un coste medio en vez de contra el coste vigente en su fecha exacta.