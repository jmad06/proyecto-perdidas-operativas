Documento organizado según las 5 carpetas de medidas del modelo (`_Medidas_Pérdidas_operativas`, `_Medidas_Ventas_compras`, `_Medidas_Rentabilidad_producto`, `_Medidas_Demarcas_bajocoste`, `_Medidas_Simulación`). Cada medida incluye un comentario de propósito y, cuando la fórmula tiene más de un paso lógico, comentarios inline explicando qué hace cada parte.

---

# Índice de contenidos

- [`_Medidas_Pérdidas_operativas`](#_medidas_pérdidas_operativas)
    - [% de alteraciones](#-de-alteraciones)
    - [% de demarca](#-de-demarca)
    - [% de mermas](#-de-mermas)
    - [% Eventos de demarca sobre el total](#-eventos-de-demarca-sobre-el-total)
    - [% pérdidas s/Compras](#-pérdidas-scompras)
    - [% pérdidas s/ventas](#-pérdidas-sventas)
    - [Aportación de unidades demarcadas (€)](#aportación-de-unidades-demarcadas-)
    - [Coste de mermas (€)](#coste-de-mermas-)
    - [Deterioro real del producto (€)](#deterioro-real-del-producto-)
    - [Indicador Relación Pérdida-Venta](#indicador-relación-pérdida-venta)
    - [Nº Eventos de pérdida](#nº-eventos-de-pérdida)
    - [Pérdida media por evento (€)](#pérdida-media-por-evento-)
    - [Pérdida operativa total (€)](#pérdida-operativa-total-)
    - [Pérdidas por alteraciones (€)](#pérdidas-por-alteraciones-)
    - [Pérdidas por demarca (€)](#pérdidas-por-demarca-)
    - [Compras sin destino trazado (€)](#compras-sin-destino-trazado-)
    - [Var % Pérdida operativa MoM](#var--pérdida-operativa-mom)
- [`_Medidas_Ventas_compras`](#_medidas_ventas_compras)
    - [Compras (€)](#compras-)
    - [Coste Medio de Compra (€)](#coste-medio-de-compra-)
    - [Ventas (€)](#ventas-)
- [`_Medidas_Rentabilidad_producto`](#_medidas_rentabilidad_producto)
    - [% Margen bruto del producto](#margen-bruto-del-producto)
    - [% Margen Neto sobre ventas a tarifa](#margen-neto-sobre-ventas-a-tarifa)
    - [% Margen perdido](#margen-perdido)
    - [Margen Bruto del producto (€)](#margen-bruto-del-producto-1)
    - [Margen Neto del producto](#margen-neto-del-producto)
- [`_Medidas_Demarcas_bajocoste`](#_medidas_demarcas_bajocoste)
    - [% pérdida total por demarca bajo coste](#pérdida-total-por-demarca-bajo-coste)
    - [Nº Eventos de demarca bajo coste](#nº-eventos-de-demarca-bajo-coste)
    - [Nº Productos con demarca bajo coste](#nº-productos-con-demarca-bajo-coste)
    - [Profundidad media de demarca bajo coste (%)](#profundidad-media-de-demarca-bajo-coste-)
    - [Pérdida por demarca bajo coste (€)](#pérdida-por-demarca-bajo-coste-)
    - [Tolerancia Demarca Bajo Coste](#tolerancia-demarca-bajo-coste)
- [`_Medidas_Simulación`](#_medidas_simulación)
    - [Precio de demarca simulado (€)](#precio-de-demarca-simulado-)
    - [Pérdida evitable máxima (€)](#pérdida-evitable-máxima-)
    - [Pérdida evitable simulada (€)](#pérdida-evitable-simulada-)
    - [Valor de Parámetro Recuperación](#valor-de-parámetro-recuperación)
- [Otras medidas y columnas calculadas (soporte visual, fuera de las 5 carpetas de KPIs)](#otras-medidas-y-columnas-calculadas-soporte-visual-fuera-de-las-5-carpetas-de-kpis)
    - [Coste Medio de Compra Histórico (€)](#coste-medio-de-compra-histórico-)
    - [Valor Cascada](#valor-cascada)
    - [Mapeo de categorías a partir de las Subcategorias originales](#mapeo-de-categorías-a-partir-de-las-subcategorias-originales)
    - [Tabla de calendario](#tabla-de-calendario)

---

## `_Medidas_Pérdidas_operativas`

### % de alteraciones

Expresa qué proporción de la pérdida operativa total corresponde a alteraciones, el componente de menor peso de los tres.

```dax
% de alteraciones =
DIVIDE (
    [Pérdidas por alteraciones (€)], [Pérdida operativa total (€)], BLANK()
)
```

### % de demarca

Expresa qué proporción de la pérdida operativa total corresponde a demarcas.

```dax
% de demarca =
DIVIDE (
    [Pérdidas por demarca (€)], [Pérdida operativa total (€)], BLANK()
)
```

### % de mermas

Expresa qué proporción de la pérdida operativa total corresponde a mermas, para identificar el peso de este componente frente a demarcas y alteraciones. Junto con % de demarca y % de alteraciones, los tres KPI suman exactamente 100% al compartir el mismo denominador, y son dinámicos al filtrar por categoría o producto, cada uno se recalcula sobre el subconjunto seleccionado.

```dax
% de mermas =
DIVIDE (
    [Coste de mermas (€)], [Pérdida operativa total (€)], BLANK()
)
```

### % Eventos de demarca sobre el total

Expresa qué proporción de todos los eventos de pérdida del negocio (mermas + demarcas válidas + alteraciones con cantidad > 0) son demarcas. No debe leerse como "% de demarca que son válidas", sino como el peso de las demarcas dentro del total de eventos de pérdida.

```dax
% Eventos de demarca sobre el total =
VAR EventosDemarca = CALCULATE (
    COUNTROWS ( demarcas ),
    demarcas[cantidad] > 0,
    demarcas[pvp_demarca] < demarcas[pvp_original]   // mismo criterio de demarca válida que en Pérdidas por demarca (€)
)
VAR TotalEventos = [Nº Eventos de pérdida]   // mermas + demarcas válidas + alteraciones con cantidad > 0
RETURN
    DIVIDE ( EventosDemarca, TotalEventos, BLANK() )
```

### % pérdidas s/Compras

Expresa la pérdida operativa total como porcentaje sobre las compras del periodo, para ver qué proporción de lo comprado termina perdiéndose.

```dax
% pérdidas s/Compras =
DIVIDE ( [Pérdida operativa total (€)], [Compras (€)], BLANK() )
```

### % pérdidas s/ventas

Expresa la pérdida operativa total como porcentaje sobre las ventas del periodo, para ver qué proporción de lo vendido se pierde por deterioro de stock.

```dax
% pérdidas s/ventas =
DIVIDE ( [Pérdida operativa total (€)], [Ventas (€)], BLANK() )
```

### Aportación de unidades demarcadas (€)

Calcula el impacto económico real de las unidades vendidas en demarca: ingreso real (pvp_demarca) menos coste real (Coste Medio de Compra Histórico), sin filtrar por dirección del cambio de precio. A diferencia de `Pérdidas por demarca (€)`, que solo cuenta bajadas reales de precio (pvp_demarca < pvp_original) porque mide oportunidad no aprovechada, esta medida incluye también las 101 filas de reversión (pvp_demarca > pvp_original) y las 286 sin cambio, porque son transacciones reales con ingreso y coste reales que sí deben contar en la contribución económica efectiva. Es el paso que usa la cascada de la página 1 y el componente que resta `Deterioro real del producto (€)`. No debe confundirse con `Pérdidas por demarca (€)` (4.993,66 €), que mide margen no percibido frente al precio original y no interviene en `Margen Neto del producto`. Puede ser positiva por producto (demarcas vendidas por encima del coste), lo que hace negativo el deterioro real y el % de margen perdido (caso Mandarina).

```dax
Aportación de unidades demarcadas (€) =
SUMX(
    demarcas,
    VAR CosteProd = RELATED(productos[Coste Medio de Compra Histórico (€)])
    RETURN
        IF(
            ISBLANK(CosteProd),
            BLANK(),   // sin coste conocido no se puede calcular la aportación real
            demarcas[cantidad] * (demarcas[pvp_demarca] - CosteProd)   // ingreso real menos coste real, sin filtrar por dirección del cambio de precio
        )
)
```

### Coste de mermas (€)

Suma el valor económico de todo el producto dado de baja por merma en el periodo, línea a línea (cantidad × coste unitario de cada evento de merma).

```dax
Coste de mermas (€) =
SUMX (
    mermas,
    mermas[cantidad] * mermas[coste_unitario]   // valor de cada línea de merma
)
```

### Deterioro real del producto (€)

Suma los dos componentes que sí son salida de caja real sin contrapartida de ingreso (mermas, alteraciones) y resta la aportación real de las unidades demarcadas, que sí tuvieron ingreso y coste reales. Sustituye a `Pérdidas por demarca (€)` dentro de esta suma porque esa medida es coste de oportunidad frente al precio de lista, no impacto real.

```dax
Deterioro real del producto (€) =
[Coste de mermas (€)] + [Pérdidas por alteraciones (€)] - [Aportación de unidades demarcadas (€)]
```

### Indicador Relación Pérdida-Venta

Índice entre -1 y 1 que compara ventas frente a pérdida operativa: cerca de 1 significa que la pérdida es despreciable frente a las ventas; cerca de 0 o negativo significa que la pérdida se acerca a o supera el volumen de ventas del producto. Es una forma normalizada de comparar productos de tamaños muy distintos sin que el importe absoluto distorsione la comparación. Movida desde _Medidas_Demarcas_bajocoste a esta carpeta por ser una medida de pérdida operativa general, no exclusiva de demarcas bajo coste.

```dax
Indicador Relación Pérdida-Venta =
VAR VentasProd = [Ventas (€)]
VAR ImpactoProd = [Pérdida operativa total (€)]
RETURN
    IF (
        VentasProd = 0,
        BLANK(),                                                     // sin ventas, el indicador no tiene sentido
        DIVIDE (
            VentasProd - ImpactoProd,                                // cuanto más grande la venta frente a la pérdida, más se acerca a 1
            VentasProd + ImpactoProd,
            BLANK()
        )
    )
```

### Nº Eventos de pérdida

Cuenta cuántos eventos individuales componen la pérdida operativa total: todas las líneas de merma, más las demarcas válidas (mismo filtro que la medida de pérdida por demarcas), más las alteraciones que restan valor (cantidad > 0).

```dax
Nº Eventos de pérdida =
COUNTROWS ( mermas )   // todas las mermas cuentan como evento
    + CALCULATE (
        COUNTROWS ( demarcas ),
        demarcas[cantidad] > 0,
        demarcas[pvp_demarca] < demarcas[pvp_original]   // mismo criterio de demarca válida que en Pérdidas por demarca (€)
    )
    + CALCULATE (
        COUNTROWS ( alteraciones ),
        alteraciones[cantidad] > 0   // solo alteraciones que restan stock/valor cuentan como evento de pérdida
    )
```

### Pérdida media por evento (€)

Divide la pérdida operativa total entre el número de eventos, para saber cuánto pierde el negocio en promedio cada vez que ocurre un evento de deterioro.

```dax
Pérdida media por evento (€) =
DIVIDE ( [Pérdida operativa total (€)], [Nº Eventos de pérdida], BLANK() )   // BLANK() si no hay eventos, evita división por cero
```

### Pérdida operativa total (€)

Suma los tres componentes del deterioro de stock en una única cifra: mermas + demarcas (rebaja de precio) + alteraciones (ajustes de inventario). Es el KPI central de impacto económico del proyecto.

```dax
Pérdida operativa total (€) =
[Coste de mermas (€)] + [Pérdidas por demarca (€)] + [Pérdidas por alteraciones (€)]
```

### Pérdidas por alteraciones (€)

Suma el valor económico de todos los ajustes de inventario (roturas, regularizaciones, incidencias), línea a línea. Se suman solo aquellas que tienen `cantidad > 0` debido a que las negativas son devoluciones o abonos que aportan valor, no restan.

```dax
Pérdidas por alteraciones (€) =
CALCULATE (
    SUMX (
        alteraciones,
        alteraciones[cantidad] * alteraciones[coste_unitario]
    ),
    alteraciones[cantidad] > 0   // solo alteraciones que restan valor
)
```

### Pérdidas por demarca (€)

Suma el valor perdido por vender producto rebajado de precio, solo contando las demarcas "normales" (precio de demarca por debajo del precio original). Los casos donde pvp_demarca > pvp_original se excluyen aquí a propósito: son casos atípicos que se conservan en el origen SQL como evidencia, pero no deben distorsionar el impacto económico.

```dax
Pérdidas por demarca (€) =
SUMX (
    FILTER ( demarcas, demarcas[pvp_demarca] < demarcas[pvp_original] ),   // solo demarcas válidas (rebaja real de precio)
    demarcas[cantidad] * ( demarcas[pvp_original] - demarcas[pvp_demarca] )   // diferencia de precio perdida por unidad, multiplicada por cantidad
)
```

### Compras sin destino trazado (€)

Usada para comprobar el importe comprado que no tiene salida trazada en ventas, mermas ni alteraciones dentro de la ventana temporal del proyecto. Renombrada desde `Unidades sin destino trazado (€)`: el nombre anterior decía "Unidades" pero la fórmula siempre ha devuelto un importe en euros, no un recuento de unidades.

```dax
Compras sin destino trazado (€) =
VAR ComprasEUR = [Compras (€)]
VAR VentasACosteEUR =
    SUMX (
        ventas,
        VAR CosteProd = RELATED ( productos[Coste Medio de Compra Histórico (€)] )
        RETURN IF ( ISBLANK ( CosteProd ), 0, ventas[cantidad] * CosteProd )   // unidades vendidas valoradas a coste, no a precio de venta
    )
VAR DemarcasACosteEUR =
    SUMX (
        demarcas,
        VAR CosteProd = RELATED ( productos[Coste Medio de Compra Histórico (€)] )
        RETURN IF ( ISBLANK ( CosteProd ), 0, demarcas[cantidad] * CosteProd )   // las unidades demarcadas son salida trazada (limitación 2)
    )
VAR MermasEUR = [Coste de mermas (€)]
VAR AlteracionesEUR = [Pérdidas por alteraciones (€)]
RETURN
    ComprasEUR - VentasACosteEUR - DemarcasACosteEUR - MermasEUR - AlteracionesEUR   // compras menos todas las salidas trazadas a coste
```

### Var % Pérdida operativa MoM

Calcula en porcentaje la variación de pérdida con respecto al mes anterior, mostrando el valor con formato condicional rojo si aumenta y verde si disminuye.

```dax
Var % Pérdida operativa MoM =
VAR MesSeleccionado =
    IF (
        HASONEVALUE ( Calendario[Mes Número] ),
        SELECTEDVALUE ( Calendario[Mes Número] ),
        CALCULATE ( MAX ( Calendario[Mes Número] ), ALLSELECTED ( Calendario ) )   // sin mes único seleccionado, usa el último mes visible
    )
VAR MesAnteriorNumero = MesSeleccionado - 1
VAR PerdidaMes =
    CALCULATE ( [Pérdida operativa total (€)], ALL ( Calendario ), Calendario[Mes Número] = MesSeleccionado )   // ALL() ignora el filtro de mes activo para poder fijar el mes manualmente
VAR PerdidaMesAnterior =
    CALCULATE ( [Pérdida operativa total (€)], ALL ( Calendario ), Calendario[Mes Número] = MesAnteriorNumero )
RETURN
    DIVIDE ( PerdidaMes - PerdidaMesAnterior, PerdidaMesAnterior, BLANK () )   // variación % respecto al mes anterior
```

---

## `_Medidas_Ventas_compras`

### Compras (€)

Total comprado en el periodo seleccionado, calculado línea a línea (cantidad × coste unitario de cada línea de compra).

```dax
Compras (€) =
SUMX (
    compras,
    compras[coste_unitario] * compras[cantidad]   // importe de cada línea de compra
)
```

### Coste Medio de Compra (€)

Coste medio ponderado por cantidad, no media aritmética simple. Es la medida base de la que dependen casi todas las demás medidas de coste del modelo: Margen Bruto del producto, las medidas de demarca bajo coste y las de simulación. Se pondera por cantidad por robustez ante datos reales, donde un mismo producto sí puede comprarse a precios distintos a lo largo del periodo. En este dataset el coste es constante por producto, por lo que la media ponderada y la simple coinciden; la ponderación es una salvaguarda, no una corrección de un sesgo observado.

```dax
Coste Medio de Compra (€) =
DIVIDE (
    SUMX ( compras, compras[coste_unitario] * compras[cantidad] ),   // valor total comprado
    SUM ( compras[cantidad] ),                                       // unidades totales compradas
    BLANK ()                                                          // BLANK() si el producto no tiene compras en el periodo
)
```

### Ventas (€)

Total vendido en el periodo seleccionado, calculado línea a línea (cantidad × precio unitario de cada línea de venta).

```dax
Ventas (€) =
SUMX (
    ventas,
    ventas[precio_unitario] * ventas[cantidad]   // importe de cada línea de venta
)
```

---

## `_Medidas_Rentabilidad_producto`

### % Margen bruto del producto

Expresa el margen bruto del producto como porcentaje sobre sus ventas.

```dax
% Margen bruto del producto =
DIVIDE (
    [Margen Bruto del producto (€)],
    [Ventas (€)],
    BLANK()
)
```

### % Margen Neto sobre ventas a tarifa

Expresa el margen neto del producto (tras deterioro) como porcentaje sobre sus ventas.

```dax
% Margen Neto sobre ventas a tarifa =
DIVIDE ( [Margen Neto del producto], [Ventas (€)], BLANK() )
```

### % Margen perdido

Mide qué proporción del margen bruto del producto se pierde por deterioro de stock. Un valor superior al 100% es posible y válido: ocurre cuando el impacto económico supera el propio margen bruto del producto, señal de que ese producto ya opera en pérdida por deterioro.

```dax
% Margen perdido =
DIVIDE ( [Deterioro real del producto (€)], [Margen Bruto del producto (€)], BLANK() )
```

### Margen Bruto del producto (€)

Calcula el margen bruto a nivel de producto individual: ventas del producto menos sus unidades vendidas multiplicadas por el coste medio ponderado. Reutiliza [Coste Medio de Compra (€)], que sí pondera, manteniendo consistencia con el resto del modelo.

```dax
Margen Bruto del producto (€) =
SUMX (
    VALUES ( productos[producto_id] ),                          // itera producto a producto
    VAR VentasProd = CALCULATE ( [Ventas (€)] )                  // ventas de ese producto en el contexto de filtro actual
    VAR UnidadesProd = CALCULATE ( SUM ( ventas[cantidad] ) )    // unidades vendidas de ese producto
    VAR CosteProd = CALCULATE ( [Coste Medio de Compra (€)] )    // coste medio ponderado de ese producto
    RETURN
        VentasProd - ( UnidadesProd * CosteProd )                // ventas menos coste de las unidades vendidas
)
```

### Margen Neto del producto

Resta el deterioro real del producto al margen bruto del producto, para obtener el margen que realmente queda tras el deterioro de stock.

```dax
Margen Neto del producto =
[Margen Bruto del producto (€)] - [Deterioro real del producto (€)]
```

---

## `_Medidas_Demarcas_bajocoste`

Estas medidas se centran en el caso más grave dentro de las demarcas: cuando el precio de venta rebajado queda por debajo del propio coste de compra del producto, es decir, se vende con pérdida directa.

### % pérdida total por demarca bajo coste

Expresa qué proporción de la pérdida operativa total corresponde específicamente a ventas por debajo de coste, el caso más grave de todo el deterioro de stock.

```dax
% pérdida total por demarca bajo coste =
DIVIDE (
    [Pérdida por demarca bajo coste (€)],
    [Pérdida operativa total (€)],
    BLANK()
)
```

### Nº Eventos de demarca bajo coste

Cuenta cuántos eventos de demarca tienen un precio de venta rebajado inferior al coste medio de compra del producto, producto a producto. Descarta los productos que no tienen eventos de demarca bajo coste.

```dax
Nº Eventos de demarca bajo coste =
VAR Tolerancia = [Tolerancia Demarca Bajo Coste]
VAR Resultado =
    SUMX (
        productos,
        VAR PrecioMin = productos[Coste Medio de Compra Histórico (€)]
        RETURN
            IF (
                ISBLANK ( PrecioMin ),
                0,   // sin coste conocido no se puede evaluar si hay demarca bajo coste
                CALCULATE (
                    COUNTROWS ( demarcas ),
                    demarcas[cantidad] > 0,
                    demarcas[pvp_demarca] < PrecioMin - Tolerancia   // precio de demarca por debajo del coste, con margen de tolerancia
                )
            )
    )
RETURN
    IF ( Resultado = 0, BLANK (), Resultado )   // deja fuera del visual a los productos sin eventos bajo coste
```

### Nº Productos con demarca bajo coste

Cuenta cuántos productos distintos tienen al menos un evento de demarca bajo coste, sin importar cuántas veces ocurra por producto.

```dax
Nº Productos con demarca bajo coste =
VAR Tolerancia = [Tolerancia Demarca Bajo Coste]
RETURN
SUMX (
    productos,
    VAR PrecioMin = productos[Coste Medio de Compra Histórico (€)]
    VAR TieneDemarcaBajoSuelo =
        CALCULATE (
            COUNTROWS ( demarcas ),
            demarcas[cantidad] > 0,
            demarcas[pvp_demarca] < PrecioMin - Tolerancia   // al menos un evento de demarca por debajo del coste
        ) > 0
    RETURN
        IF ( NOT ISBLANK ( PrecioMin ) && TieneDemarcaBajoSuelo, 1, BLANK() )   // BLANK() y no 0: así los productos sin demarca bajo coste no entran en la SUMX y no aparecen como fila en 0 en visuales de detalle por producto
)
```

### Profundidad media de demarca bajo coste (%)

Media simple del porcentaje de descuento sobre coste por EVENTO de demarca bajo coste, sin ponderar por cantidad. Responde a "cuando se decide rebajar por debajo del coste, ¿cuánto se rebaja típicamente?", que es una pregunta sobre la decisión operativa, no sobre el impacto económico.

```dax
Profundidad media de demarca bajo coste (%) =
VAR Tolerancia = [Tolerancia Demarca Bajo Coste]
RETURN
AVERAGEX (
    FILTER ( demarcas, demarcas[cantidad] > 0 ),
    VAR PrecioMin = RELATED ( productos[Coste Medio de Compra Histórico (€)] )
    RETURN
        IF (
            NOT ISBLANK ( PrecioMin ) && demarcas[pvp_demarca] < PrecioMin - Tolerancia,   // solo eventos de demarca bajo coste
            DIVIDE ( PrecioMin - demarcas[pvp_demarca], PrecioMin ),   // % de descuento sobre el coste, por evento
            BLANK ()
        )
)
```

### Pérdida por demarca bajo coste (€)

Suma el importe perdido específicamente por vender bajo coste: para cada línea de demarca, si su precio está por debajo del coste medio del producto, calcula cuánto se pierde por unidad y lo multiplica por la cantidad.

```dax
Pérdida por demarca bajo coste (€) =
VAR Tolerancia = [Tolerancia Demarca Bajo Coste]
VAR Resultado =
    SUMX (
        demarcas,
        VAR PrecioMin = RELATED ( productos[Coste Medio de Compra Histórico (€)] )
        RETURN
            IF (
                demarcas[cantidad] > 0
                    && NOT ISBLANK ( PrecioMin )
                    && demarcas[pvp_demarca] < PrecioMin - Tolerancia,   // línea de demarca válida y por debajo del coste
                demarcas[cantidad] * ( PrecioMin - demarcas[pvp_demarca] ),   // pérdida por unidad, multiplicada por cantidad
                0
            )
    )
RETURN
    IF ( Resultado = 0, BLANK(), Resultado )
```

### Tolerancia Demarca Bajo Coste

Medida auxiliar simple que define el nivel de tolerancia en `&& demarcas[pvp_demarca] < PrecioMin` para no tener que repetirlo en cada formula y poder modificarlo en todas a la vez.

```dax
Tolerancia Demarca Bajo Coste = 0.005
```

---

## `_Medidas_Simulación`

Estas medidas alimentan la página 5 (Simulación) y modelan el escenario "¿qué pasaría si las ventas por debajo de coste se hubieran hecho al coste?". El parámetro `Parámetro Recuperación` (tabla What-if de Power BI, 0 a 1 en pasos de 0,1) controla qué porcentaje de esa recuperación se aplica.

### Precio de demarca simulado (€)

Calcula, por producto, a qué precio de venta correspondería el porcentaje de recuperación elegido en el slider: interpola linealmente entre el precio de demarca real medio (slider en 0) y el coste medio de compra (slider en 1).

```dax
Precio de demarca simulado (€) =
VAR Tolerancia = [Tolerancia Demarca Bajo Coste]
VAR ProductoActual = SELECTEDVALUE ( productos[producto_id] )
VAR PrecioMin =
    CALCULATE (
        SELECTEDVALUE ( productos[Coste Medio de Compra Histórico (€)] ),
        productos[producto_id] = ProductoActual   // fuerza el contexto al producto actual, aunque la medida se evalúe fuera de una fila de productos
    )
VAR TablaBajoCoste =
    FILTER (
        demarcas,
        demarcas[cantidad] > 0
            && RELATED ( productos[Coste Medio de Compra Histórico (€)] ) - Tolerancia > demarcas[pvp_demarca]   // solo demarcas bajo coste de ese producto
    )
VAR PvpDemarcaPonderado =
    DIVIDE (
        SUMX ( TablaBajoCoste, demarcas[cantidad] * demarcas[pvp_demarca] ),
        SUMX ( TablaBajoCoste, demarcas[cantidad] )   // precio de demarca real medio, ponderado por cantidad (slider en 0)
    )
VAR Pct = [Valor de Parámetro Recuperación]
RETURN
    IF (
        ISBLANK ( ProductoActual )
            || ISBLANK ( PrecioMin )
            || ISBLANK ( PvpDemarcaPonderado ),   // sin alguno de los tres, no hay base para interpolar
        BLANK (),
        PvpDemarcaPonderado + ( PrecioMin - PvpDemarcaPonderado ) * Pct   // interpola entre el precio real (Pct=0) y el coste (Pct=1)
    )
```

### Pérdida evitable máxima (€)

Calcula el techo teórico de recuperación: cuánto se recuperaría si todas las demarcas bajo coste se hubieran vendido exactamente al coste, sin ningún descuento aplicado por el slider. Es la fórmula base sobre la que actúa el parámetro de recuperación. Reutiliza directamente `Pérdida por demarca bajo coste (€)` en vez de repetir su lógica: antes esta medida duplicaba carácter a carácter el `SUMX` de `Pérdida por demarca bajo coste (€)`, con el riesgo de que un cambio futuro en la tolerancia o el criterio de "bajo coste" se aplicara a una medida y no a la otra, descuadrando la página 4 (diagnóstico) frente a la página 5 (simulación).

```dax
Pérdida evitable máxima (€) =
[Pérdida por demarca bajo coste (€)]
```

### Pérdida evitable simulada (€)

Aplica el porcentaje del slider al techo teórico de recuperación. Con el slider al 100% coincide con `Pérdida evitable máxima (€)`; con el slider al 50 %, se evita la mitad de esa pérdida directa.

```dax
Pérdida evitable simulada (€) =
[Pérdida evitable máxima (€)] * [Valor de Parámetro Recuperación]
```

### Valor de Parámetro Recuperación

Lee la posición actual del slider de la página de Simulación (0 a 1). Si no hay selección, por defecto vale 1 (recuperación al 100%).

```dax
Valor de Parámetro Recuperación =
SELECTEDVALUE ( 'Parámetro Recuperación'[Parámetro Recuperación], 1 )
```

---

## Otras medidas y columnas calculadas (soporte visual, fuera de las 5 carpetas de KPIs)

### Coste Medio de Compra Histórico (€)

Réplica de la medida `Coste Medio de Compra (€)` pero como columna calculada, evaluada una vez por producto al refrescar el modelo en vez de una vez por cada fila de la consulta. Existe porque las 6 medidas de la familia `_Medidas_Demarcas_bajocoste` y `_Medidas_Simulación` necesitan un coste invariante al filtro de Calendario (usaban `REMOVEFILTERS(Calendario)` para forzarlo en una versión anterior), así que no dependen del contexto de fila en el que se llaman: es el mismo valor cada vez, solo cambia de un producto a otro. Convertirlo en columna evita repetir esa evaluación con `CALCULATE` + `REMOVEFILTERS` en cada fila de `demarcas` (5.235 filas hoy; con un dataset real de millones de filas, cada evaluación redundante sí sería medible). No sustituye a la medida `Coste Medio de Compra (€)`, que se mantiene para `Margen Bruto del producto (€)`: esa medida sí debe respetar el filtro de Calendario si el usuario segmenta por mes, algo que una columna calculada no puede hacer al evaluarse una sola vez en el refresh. Son dos cosas con semántica distinta que comparten fórmula por coincidencia (el coste es constante por producto en este dataset), no por diseño, de ahí el nombre distinto para no confundirlas.

```dax
Coste Medio de Compra Histórico (€) =
DIVIDE (
    SUMX ( RELATEDTABLE ( compras ), compras[coste_unitario] * compras[cantidad] ),   // valor total comprado del producto, sin filtro de Calendario
    SUMX ( RELATEDTABLE ( compras ), compras[cantidad] ),                             // unidades totales compradas del producto
    BLANK ()                                                                          // BLANK() si el producto no tiene compras registradas
)
```

### Valor Cascada

Alimenta el gráfico de cascada de la página 1. Usa una tabla auxiliar Pasos_Cascada (columna Paso, con 4 valores de texto) para que cada "categoría" del eje X del waterfall devuelva el valor correspondiente: margen bruto de producto como punto de partida, las tres deducciones en negativo, y el margen neto como total.

```dax
Valor Cascada =
VAR PasoActual = SELECTEDVALUE(Pasos_Cascada[Paso])
RETURN
    SWITCH(
        PasoActual,
        "Margen Bruto (producto)", [Margen Bruto del producto (€)],
        "Coste mermas", -[Coste de mermas (€)],
        "Aportación de ud demarcadas", [Aportación de unidades demarcadas (€)],
        "Pérdida por alteraciones", -[Pérdidas por alteraciones (€)],
        BLANK()
    )
```

### Mapeo de categorías a partir de las Subcategorias originales

Se utiliza para simplificar y reducir el número de Subcategorias de unas 20 a 7.

```dax
Categoría =
 SWITCH (
    TRUE (),
    productos[subcategoria] = "FRUTAS (TROPICALES)", "Fruta",
    productos[subcategoria] = "FRUTAS (DE HUESO, PEPITA Y ARTÍCULOS ESTACIONALES)", "Fruta",
    productos[subcategoria] = "FRUTA (MANZANAS)", "Fruta",
    productos[subcategoria] = "FRUTAS (CÍTRICOS)", "Fruta",
    productos[subcategoria] = "PERAS", "Fruta",
    productos[subcategoria] = "FRUTAS (ESPECIALIDADES)", "Fruta",
    productos[subcategoria] = "FRUTA TROPICAL (PLATANO Y BANANA)", "Fruta",
    productos[subcategoria] = "FRUTA DE SEMILLA (UVAS)", "Fruta",
    productos[subcategoria] = "HORTALIZAS (FRESÓN, MELONES Y SANDIAS)", "Fruta",
    productos[subcategoria] = "HORTALIZAS (FRUTO FLOR, LEGUMBRES, RAIZ Y ARBORESCENCIAS)", "Verdura",
    productos[subcategoria] = "HORTALIZAS BULBOS (CEBOLLAS Y AJOS)", "Verdura",
    productos[subcategoria] = "VERDURAS HOJA", "Verdura",
    productos[subcategoria] = "HORTALIZAS EMBARQUETADAS (VERDURAS HOJA, RAIZ Y FRUTO FLOR)", "Verdura",
    productos[subcategoria] = "HORTALIZAS (TUBERCULOS)", "Verdura",
    productos[subcategoria] = "HORTALIZAS (CHAMPIÑON / SETAS)", "Verdura",
    productos[subcategoria] = "ENSALADAS 4ª Y 5ª GAMA LÍQUIDOS (HORTALIZAS / VERDURA HOJA)", "Ensaladas 4ª y 5ª gama",
    productos[subcategoria] = "FRUTOS (SECOS Y DESIDRATADOS)", "Frutos secos",
    productos[subcategoria] = "ENCURTIDOS (FRUTOS Y HORTALIZAS)", "Encurtidos",
    productos[subcategoria] = "PLANTAS ESTACIONALES", "Plantas",
    productos[subcategoria] = "HORTALIZAS (PLANTAS AROMÁTICAS)", "Plantas",
    "Sin clasificar"
)
```

### Tabla de calendario

```dax
Calendario =
ADDCOLUMNS (
    CALENDAR ( DATE(2026,01,1), DATE(2026,07,31) ),
    "Año", YEAR ( [Date] ),
    "Mes Número", MONTH ( [Date] ),
    "Nombre Mes", FORMAT ( [Date], "MMMM" )
)
```

### Columna calculada `AñoMes`

```dax
AñoMes = DATE(Calendario[Año],Calendario[Mes Número], 1)
```