# Análisis completo - Pérdidas operativas del stock

Parte 1 de 2 de la documentación ampliada del proyecto. Cubre el problema de negocio, la estructura del dashboard página a página, la simulación de recuperación y las conclusiones y recomendaciones derivadas del análisis. Para el pipeline técnico, el modelo de datos y las medidas DAX, ver [Parte 2: Arquitectura técnica](02-arquitectura-tecnica.md)

Periodo analizado: enero–julio 2026 (7 meses, más de 64.000 registros) en una frutería con inventario perecedero, sobre tres tipos de deterioro de stock: mermas, demarcas y alteraciones.

**7.204 € de pérdida operativa en el periodo (4,13 % de las ventas), de los que 2.017 € corresponden a pérdida directa evitable mediante un suelo de precio en demarca.**

![Página 1 del dashboard: resumen](img/dashboard-pagina1-resumen.png)

---
# Índice de contenidos

### Parte 1: El negocio

- [El problema de negocio](#el-problema-de-negocio)
- [Estructura del dashboard](#estructura-del-dashboard)
- [Simulación de recuperación: acción e impacto](#simulación-de-recuperación-acción-e-impacto)
- [Conclusiones](#conclusiones)
- [Recomendaciones](#recomendaciones)

---
## El problema de negocio

El proyecto se centra en una frutería que gestiona a diario un stock altamente perecedero. Parte de ese stock se pierde o se vende por debajo de su valor esperado por varias vías: producto que caduca o se estropea antes de venderse (mermas), producto que se rebaja de precio para adelantarse a ese deterioro (demarcas), y ajustes de inventario por roturas, errores de conteo o incidencias (alteraciones). El proyecto llama a la suma de estos tres efectos **deterioro económico del stock**.

**El objetivo del análisis** es cuantificar ese deterioro y ayudar a decidir dónde actuar primero.

Preguntas de negocio que responde el proyecto:

- ¿Cuánto dinero se pierde por deterioro del stock, en total y como porcentaje de compras-ventas y como afecta al margen de producto?
- ¿Qué productos y categorías concentran la mayor parte de la pérdida, y a qué tipo de pérdida corresponde? y ¿Qué productos tienen una relación pérdida-venta próxima a 0, y cuánto compromete esto su margen neto?
- ¿Las pérdidas son puntuales o recurrentes? ¿Qué categorías combinan alta frecuencia con alta pérdida?
- ¿Qué parte de las demarcas corresponden a ventas por debajo del propio coste de compra, el caso más grave?
- Si se actuara sobre esas ventas por debajo de coste, ¿cuánta pérdida directa sería evitable y bajo qué condición?

---

## Estructura del dashboard

El informe tiene 5 páginas, con una narrativa de cuánto → qué → con qué frecuencia → qué tan grave → cómo actuar
### Página 1: Resumen

**Qué responde**: ¿Cuánto se pierde por deterioro de stock, en términos absolutos y relativos a compras-ventas y cómo afecta al margen del producto?

- KPIs de cabecera (pérdida operativa total, compras, ventas, % de margen bruto de producto) y un gráfico de cascada que descompone el margen bruto del producto hasta el margen neto, restando coste de mermas, aportación de unidades demarcadas y pérdida de alteraciones.
- En los KPIs de cabecera también se muestra como referencia: variación con respecto al mes pasado, compras sin destino trazado, las pérdidas sobre compras, sobre ventas y % margen neto sobre ventas a tarifa y % de margen perdido.
- El gráfico de líneas muestra la evolución de los tres tipos de pérdidas a lo largo de los 7 meses.
- Segmentación por mes en el periodo enero-julio 2026.

>**Nota conceptual.** `Pérdida operativa total (€)` combina dos naturalezas económicas distintas: mermas (1.636,42 €) y alteraciones (574,04 €) son salidas de caja, producto que se destruye o se ajusta y deja de tener valor; demarcas (4.993,66 €) es margen no percibido sobre unidades que sí se llegaron a vender, no dinero perdido en sentido estricto. La cifra conjunta de 7.204 € es útil como KPI único de seguimiento, pero al presentarla conviene aclarar que el 69,32 % de ese importe es coste de oportunidad, no efectivo desembolsado.

> **Nota sobre la cascada.** El gráfico de cascada no resta `Pérdidas por demarca (€)` (4.993,66 €, la cifra de la nota anterior), sino `Aportación de unidades demarcadas (€)` (−1.235,88 €): el resultado real de esas mismas ventas en demarca, ingreso menos coste, sin compararlo contra el precio de lista. Son dos lecturas legítimas y compatibles de la misma actividad, no dos cálculos contradictorios: la primera cuantifica el margen no percibido frente al precio original (útil para seguimiento), la segunda cuantifica si esas ventas dejaron beneficio real (lo que efectivamente reduce el margen neto del producto). Al leer la cascada, el paso "Aportación de ud demarcadas" no debe interpretarse como una repetición de los 4.993,66 € citados arriba.

>**Nota de trazabilidad.** 10.789,05 € de las compras del periodo (7,56 % del importe comprado, 8,01 % de las unidades) no tienen salida trazada en ventas, demarcas, mermas ni alteraciones dentro de la ventana temporal. Las unidades demarcadas se cuentan como salida porque no figuran en `ventas_linea` (ver limitación 2). Al incluirlas, 66 productos muestran más salidas que compras, lo que indica que el generador sintético no cuadra el stock por producto: la diferencia restante puede corresponder a stock inicial, stock de cierre o artefactos del generador, y no se puede separar sin inventarios de apertura y cierre. Esta cifra mide ausencia de trazabilidad, no deterioro confirmado, y no debe sumarse a los 7.204 € de pérdida operativa.

![Página 1 del dashboard: resumen](img/dashboard-pagina1-resumen.png)

### Página 2: Ranking

**Pregunta 1: ¿Qué productos y categorías concentran la mayor parte de la pérdida, y a qué tipo de pérdida corresponde?**

- Gráfico de barras apiladas con desglose de las pérdidas operativas del stock por categoría (fruta, verdura, ensaladas 4ª y 5ª gama, plantas, frutos secos)
- Tres KPI de desglose por tipo de pérdida en porcentaje (mermas, demarcas, alteraciones) son dinámicos al seleccionar una categoría, por ejemplo Fruta, los tres KPI se recalculan mostrando el peso de cada tipo de pérdida específico de esa categoría. 
- Tabla de productos ordenada por pérdida operativa total, con indicador de relación pérdida-venta y margen afectado como columnas de contexto. 
- Segmentación por mes en el periodo enero-julio 2026.

![Página 2 del dashboard: tabla ordenada por pérdida operativa total, con KPI de desglose](img/dashboard-pagina2-ranking.png)


**Pregunta 2: ¿Qué productos tienen una relación pérdida-venta próxima a 0, y cuánto compromete esto su margen neto?**

- Misma tabla de productos, reconfigurada: ordenada por proximidad a 0 en dicho indicador, en lugar de por pérdida operativa absoluta. Este orden prioriza el desequilibrio relativo entre lo que un producto vende y lo que pierde, no el volumen de euros en juego: un producto de bajo volumen puede pasar desapercibido en la vista ordenada por pérdida absoluta y, sin embargo, ser el que más necesita revisión de precio de venta, frecuencia de compra o gestión de rotación.

Su gravedad no está en el volumen, sino en que el deterioro ya ha anulado por completo el margen que generaron.

![Página 2 del dashboard: tabla filtrada y ordenada por indicador relación pérdida-venta](img/dashboard-pagina2-ranking_2.png)

### Página 3: Frecuencia

**Qué responde**: ¿Las pérdidas son puntuales o recurrentes? ¿Qué categorías combinan alta frecuencia con alta pérdida?

- KPIs de cabecera: Total de eventos de pérdida, Eventos que son demarca, Pérdida media por evento y Pérdida operativa total.
- Scatter de productos según nº de eventos de pérdida (eje X) y pérdida operativa total (eje Y), con el tamaño de burbuja representando la pérdida media por evento y la categoría como leyenda de color. 
- Segmentación por categoría y mes en el periodo enero-julio 2026.

La magnitud relevante del gráfico no es la posición respecto a las medianas de cada eje por separado (estas solo muestran una referencia global), sino la proximidad de la masa de productos a cada una de las cuatro esquinas del espacio:

| Esquina                                           | Significado                                | Patrón observado (151 productos; medianas: 24 eventos, 23,82 €) |
| ------------------------------------------------- | ------------------------------------------ | --------------------------------------------------------------- |
| Inferior izquierda (pocos eventos, poca pérdida)  | Productos sin problema relevante           | 65 productos (43,0 %)                                           |
| Inferior derecha (muchos eventos, poca pérdida)   | Goteo frecuente de bajo impacto individual | 11 productos (7,3 %)                                            |
| Superior izquierda (pocos eventos, mucha pérdida) | Incidentes puntuales de gran magnitud      | 11 productos (7,3 %)                                            |
| Superior derecha (muchos eventos, mucha pérdida)  | Frecuencia y volumen altos a la vez        | 64 productos (42,4 %)                                           |

El 85,4 % de los productos (129 de 151) cae en la diagonal inferior-izquierda o superior-derecha. Solo 22 productos (14,6 %) son anómalos en un eje sin serlo en el otro, y son los que merecen mirada individual.

La lectura de negocio no es "casi todo el catálogo está limpio", sino que el deterioro es un fenómeno de goteo estructural, no de incidentes: la pérdida media por evento es de 1,12 € y ningún producto rompe esa proporcionalidad de forma significativa. El eje X es logarítmico, lo que comprime visualmente la cola derecha.

![Página 3 del dashboard: frecuencia](img/dashboard-pagina3-frecuencia.png)


> **Nota sobre mediana vs. promedio**: el scatter usa mediana en lugar de media para los ejes de referencia, porque unos pocos eventos de pérdida puntualmente muy alto distorsionan el promedio y dan una imagen poco representativa del comportamiento típico del producto.

### Página 4: Demarcas

**Qué responde**: de todas las pérdidas por demarca, ¿Cuánto corresponde específicamente a vender por debajo del coste de compra, el caso más grave?

Foco exclusivo en demarcas, que concentran el 69,32 % de la pérdida operativa total. 
- KPIs de cabecera: Eventos de demarca por debajo del coste, Productos con demarca por debajo del coste, Pérdidas por demarca bajo coste y Profundidad media de descuento bajo coste.
- Segmentación por categoría y mes en el periodo enero-julio 2026.

El scatter relaciona nº de eventos de demarca bajo coste (eje X) con profundidad media de descuento bajo coste (eje Y), con el tamaño de burbuja representando la pérdida por demarca bajo coste asociada. El propio gráfico ya está filtrado a demarcas por debajo de coste, por lo que ningún punto aparece por debajo de 0% en el eje Y (esta línea constante en 0% se añade solo como referencia informativa del suelo de coste, sin dividir el gráfico, conforme subimos por el eje Y más se aleja el precio de demarca del precio de coste). Una línea de mediana (eje X: 17 eventos; y línea de promedio en eje Y: 40,75 % profundidad media por producto) marcan la referencia global de cada eje, y la magnitud relevante, igual que en la página 3, es la proximidad de la masa de productos a cada una de las cuatro esquinas del espacio:

| Esquina                                               | Significado                                       | Patrón observado (128 productos; mediana 17 eventos, promedio 40,75 %) |
| ----------------------------------------------------- | ------------------------------------------------- | ---------------------------------------------------------------------- |
| Inferior izquierda (pocos eventos, poca profundidad)  | Demarcas bajo coste ocasionales y leves           | 36 productos (28,1 %)                                                  |
| Inferior derecha (muchos eventos, poca profundidad)   | Demarcas bajo coste recurrentes de descuento leve | 30 productos (23,4 %)                                                  |
| Superior izquierda (pocos eventos, mucha profundidad) | Descuento severo concentrado en pocos eventos     | 29 productos (22,7 %)                                                  |
| Superior derecha (muchos eventos, mucha profundidad)  | El caso más grave: frecuente y profundo a la vez  | 33 productos (25,8 %)                                                  |

Los cuatro cuadrantes están poblados de forma casi uniforme (entre el 22,7 % y el 28,1 %). Que un producto se demarque bajo coste a menudo no dice nada sobre cuánto se rebaja
cuando lo hace.

Ese es el hallazgo accionable: son dos palancas separadas. Reducir la frecuencia (rotación, tamaño de pedido) y reducir la profundidad (suelo de precio, demarcar antes) atacan poblaciones de producto distintas, y los 33 productos del cuadrante superior derecho son los únicos que necesitan las dos a la vez.

Las burbujas crecen hacia la derecha porque el tamaño codifica la pérdida acumulada, que crece por construcción con el número de eventos. No debe leerse como que las demarcas recurrentes sean más caras por unidad.

![Página 4 del dashboard: demarcas](img/dashboard-pagina4-demarcas.png)

> **Nota sobre mediana vs. promedio**: el scatter usa promedio en lugar de mediana en el eje Y por que va en sintonía al KPI `Profundidad media de demarca bajo coste` (al contrario que en la página 3) y mediana en el eje X debido a la presencia de unos pocos eventos de gran volumen que distorsionarían el promedio. 
### Página 5: Simulación

**Qué responde**: si el precio de demarca de esas unidades se acercara al coste, ¿cuánta pérdida directa sería evitable manteniendo el volumen de venta?

- KPIs de cabecera: `Pérdida por demarca bajo coste (€)` (importe de partida, heredado de la página 4), `Pérdida evitable simulada (€)` (según la posición del slider) y `% Venta mínima con suelo a coste`.
- Un control deslizante (`Posición del precio de demarca entre el real (0 %) y el coste (100 %)`, 0 a 100% en pasos de 10) permite mover el escenario de recuperación. 
- Un gráfico de barras agrupadas compara, por categoría, la pérdida original por demarca bajo coste frente a la recuperación potencial simulada en la posición actual del slider.
- Una tabla de productos desglosa, para cada uno, la recuperación potencial simulada en euros y el precio de demarca simulado resultante.
- Segmentación por mes en el periodo enero-julio 2026.

El desarrollo funcional completo de la mecánica del slider, las medidas DAX implicadas y un ejemplo verificado están en la siguiente sección.

![Página 5 del dashboard: simulación](img/dashboard-pagina5-simulación.png)

---
## Simulación de recuperación: acción e impacto

La página de Simulación traslada el diagnóstico de la página 4 a un escenario de acción: **¿qué pasaría si las ventas por debajo de coste se hubieran hecho al coste?**

**Mecánica del slider**: El slider fija la posición del precio de demarca simulado en el recorrido entre el precio real (0 %) y el coste medio de compra (100 %). Con volumen constante, mover el precio un X % de ese recorrido evita exactamente el X % de la pérdida bajo coste de cada evento, por eso el porcentaje de precio y el porcentaje de pérdida evitada coinciden en el modelo; en la realidad solo coincidirían si la demanda no reaccionara al precio.

En el extremo del 0%, el precio de demarca simulado coincide con el precio real actual (sin cambios). En el extremo del 100%, el precio simulado iguala el coste medio de compra y el impacto por venta bajo coste se anula en el modelo.

**Medidas implicadas**:

- `Pérdida evitable máxima (€)`: techo teórico al 100 %, misma lógica que `Pérdida por demarca bajo coste (€)` de la página 4, expresada como pérdida directa evitable.
- `Valor de Parámetro Recuperación`: lee la posición del slider (`SELECTEDVALUE` sobre la tabla `Parámetro Recuperación`, por defecto 1).
- `Recuperación potencial simulada (€)`: aplica el porcentaje del slider al techo teórico.
- `Precio de demarca simulado (€)`: interpola linealmente, por producto, entre el precio de demarca real medio (slider en 0) y el coste medio de compra (slider en 1).

**Ejemplo verificado** (Alcachofa, slider a 50%): recuperación potencial de 62,03 €, precio de demarca simulado de aproximadamente 2,22 €, partiendo de un coste medio de compra de 3,16 €.

>**Supuesto y limitación**: el escenario asume volumen de venta constante. No modela que un precio de demarca más alto pueda reducir la demanda o aumentar el volumen que termina en merma en lugar de venderse. El 100% es, por tanto, un techo teórico de recuperación, no una previsión de resultado.

---
## Conclusiones

- El deterioro de stock consume el 6,73 % del margen bruto del producto: de cada 100 € vendidos, el margen bruto de 29,32 € se reduce a un margen neto de 27,35 € tras mermas, demarcas y alteraciones. La pérdida operativa total representa el 4,13 % de las ventas del periodo.
- Las demarcas dominan el deterioro: concentran el 69,32% de la pérdida operativa total muy por encima de mermas (22,72 %) y alteraciones (7,97 %) y representan el 70,03 % de los eventos de pérdida operativa.
- El ranking por pérdida absoluta (Fresón, Plátano Canario, Uva Blanca sin Semilla) y el ranking por Indicador Relación Pérdida-Venta apenas se solapan: el segundo señala 3 productos con margen neto ya negativo, con Patata Cocida como caso extremo (428,57 % de margen perdido). Ninguno de los 3 aparece entre los diez primeros por importe absoluto; quedarían invisibles priorizando solo por euros.
- Priorizar solo por volumen de pérdida en euros dejaría fuera precisamente a los productos en mayor riesgo relativo, aquellos donde el negocio ya opera en pérdida directa sobre ese producto.
- Encurtidos (5 referencias, 448,11 € de venta) es la única categoría del catálogo con deterioro cero en los 7 meses. No es un hueco del análisis: es producto no perecedero en un catálogo dominado por fresco, y sirve como línea base de contraste frente al 4,13 % de pérdida sobre ventas del resto.
- A nivel de negocio la pérdida escala con la frecuencia: 129 de 151 productos (85,4 %) caen sobre la diagonal, 65 (43,0 %) en pocos eventos y poca pérdida y 64 (42,4 %) en muchos eventos y mucha pérdida. Solo 22 productos (14,6 %) rompen esa proporcionalidad y son los únicos que merecen revisión individual. Con 1,12 € de pérdida media por evento, el deterioro es un goteo estructural, no una acumulación de incidentes puntuales de gran importe.
- Dentro de las demarcas bajo coste el patrón deja de ser diagonal: los cuatro cuadrantes se reparten de forma casi uniforme entre el 22,7 % y el 28,1 % de los 128 productos afectados. Es decir, la frecuencia con la que un producto se demarca bajo coste no predice la profundidad del descuento: son dos palancas independientes, y solo los 33 productos (25,8 %) del cuadrante superior derecho necesitan actuar sobre las dos a la vez. En conjunto suman 2.017,33 € de pérdida con un 41,25 % de profundidad media de descuento.
- La simulación cuantifica el techo de recuperación: con el slider en 50%, el negocio evitaría 1.009 € de pérdida directa por demarcas bajo coste, asumiendo volumen de venta constante.
---
## Recomendaciones 

| #     | Hallazgo                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Acción                                                                                                                                                                            | Impacto                                                                                                                                                                                                                                                                                                                                                             |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1** | Las demarcas concentran el 69,32 % de la pérdida operativa total. De los 4.993,66 € de pérdida por demarcas, 4.099,49 € (82,1 %) (sobre eventos con rebaja real de precio, mismo criterio que la medida) corresponden a eventos cuyo precio de demarca cae por debajo del coste medio de compra, concentrados en 128 productos 97 % de los 132 con coste conocido y demarca registrada Ver: [Enlace](../SQL/auditoria.md#13-el-97-de-132-productos-con-coste-conocido-y-demarca-tienen-demarca-bajo-coste). Dentro de ese importe, 2.017,33 € son el tramo que queda estrictamente por debajo del coste, Ver: [Enlace](../SQL/auditoria.md#14-peso-de-las-demarcas-bajo-coste-201733--sobre-coste) | Fijar un suelo de precio en demarca (nunca por debajo del coste medio), aplicado primero a esos 128 productos.                                                                    | Elimina hasta ~2.000 € de pérdida directa (venta por debajo de coste) en 7 meses. No genera margen adicional: al 100 % del escenario esas unidades se venden al coste, con aportación cero (ver limitaciones 3 y 6 del documento [Enlace](02-arquitectura-tecnica.md#limitaciones-y-qué-debería-capturar-el-erp) |
| **2** | Fresón (536,42 €), Plátano Canario (436,54 €) y Uva Blanca sin Semilla (276,04 €) son los tres productos con mayor pérdida operativa absoluta, pero con Indicador Relación Pérdida-Venta alto (0,88, 0,88, 0,74): la pérdida es grande en euros porque el volumen de venta también lo es, no porque el producto esté mal gestionado en relación a su tamaño.                                                                                                                                                                                                                                                                                                                             | Priorizar seguimiento de rotación y frecuencia de reposición en estos 3 productos por su peso absoluto en el total independientemente de que su indicador relativo sea saludable. | Una mejora porcentual pequeña en estos productos mueve más euros absolutos que la misma mejora en productos de menor volumen.                                                                                                                                                                                                                                       |
| **3** | Patata Cocida tiene Indicador Relación Pérdida-Venta de −0,1 (pierde 16,2 € frente a 13,23 € vendidos); Albahaca (0,31); Rábano (0,4) y Frambuesa (0,44) son los otros tres casos por debajo de 0,5.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | Revisar viabilidad de estos 4 productos en catálogo: la pérdida representa entre el 39 % y el 122 % del valor vendido, frente a una media del negocio del 4,13 %                  | Identifica los productos donde el coste operativo de mantenerlos en stock supera lo que generan, como base para decidir su continuidad.                                                                                                                                                                                                                             |
| **4** | El 78,13 % de las demarcas bajo coste se vende a 1 € o menos. Ver [Enlace](../SQL/auditoria.md#12-el-7813-de-demarcas-bajo-coste-se-vende-a-1-o-menos)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Revisar si esos productos entran tarde al ciclo de demarca.                                                                                                                       | Reduce la profundidad media de descuento (41,25 %)                                                                                                                                                                                                                                                                                                                  |
| **5** | Ensaladas 4ª y 5ª gama pierde el 83,53 % de su deterioro en demarcas, el % más alto de las 5 categorías.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Auditar rotación y ciclo de vida de esta categoría en concreto.                                                                                                                   | Mayor margen de mejora relativo a su tamaño.                                                                                                                                                                                                                                                                                                                        |
| **6** | 3 productos operan con margen neto negativo: Patata Cocida (-12,42 €, -93,88 % sobre ventas), Albahaca (-2,77 €, -26,56 % sobre ventas) y Rábano (-0,21 €, -0,53 % sobre ventas, prácticamente en equilibrio).                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | Revisar precio de compra, tamaño de pedido o continuidad en catálogo, priorizando Patata Cocida y Albahaca por profundidad de la pérdida.                                         | Evita seguir financiando ventas con pérdida directa.                                                                                                                                                                                                                                                                                                                |

> **Nota:** estas recomendaciones no implican eliminar directamente ningún producto del catálogo. Antes de tomar esa decisión habría que comprobar su viabilidad real considerando otros factores no capturados en este modelo: exposición en tienda, calidad del producto, ventana media de venta y demás variables operativas que escapan al alcance de este análisis.