# Proyecto analítico de pérdidas operativas del stock

Análisis del deterioro económico de stock (mermas, demarcas y alteraciones) en una frutería con inventario perecedero, sobre 7 meses de operación (enero–julio 2026) y más de 64.000 registros.

![Página 1 del dashboard: resumen](docs/img/dashboard-pagina1-resumen.png)

---

## El problema

Una frutería con inventario altamente perecedero pierde parte del valor de su stock por tres vías: producto que se estropea antes de venderse (mermas), producto que se rebaja de precio para adelantarse a ese deterioro (demarcas), y ajustes de inventario por roturas o incidencias (alteraciones). Hasta ahora se seguían por separado, sin una cifra conjunta ni un criterio para decidir dónde actuar primero. La demarca en concreto se gestionaba como una herramienta sin coste, cuando de hecho es la mayor fuente de pérdida de las tres.

**Stack:** SQL · Power BI · DAX

---

## Resumen ejecutivo

El deterioro de stock consumió 7.204 € entre enero y julio de 2026 (4,13 % de las ventas), impulsado sobre todo por demarcas (69,32 % del total); dentro de ellas, 2.017 € corresponden a ventas por debajo del propio coste de compra en 128 productos, el único tramo con una palanca de decisión directa y clara, sobre el que se propone un suelo de precio en demarca que en el escenario simulado al 50 % evitaría 1.009 € de pérdida directa en el mismo periodo.

---

## Hallazgos clave

- **Las demarcas dominan el deterioro**: 69,32 % de la pérdida operativa total y 70,03 % de los 6.454 eventos registrados, muy por encima de mermas (22,72 %) y alteraciones (7,97 %).
- **El deterioro es goteo estructural, no incidentes puntuales**: 1,12 € de pérdida media por evento, y el 85,4 % de los productos con pérdida caen en la relación esperable entre frecuencia e importe.
- **Dentro de las demarcas, frecuencia y profundidad de descuento son palancas independientes**: un producto que se demarca a menudo no es necesariamente el que más se rebaja cuando lo hace; solo 33 de 128 productos combinan ambos problemas a la vez.
- **El ranking por euros absolutos oculta el riesgo real**: los tres productos con mayor pérdida en importe tienen una relación pérdida-venta saludable, mientras que tres productos distintos ya operan con margen neto negativo y no aparecen entre los diez primeros por volumen.
- **El 78,13 % de las demarcas bajo coste se vende a 1 € o menos**, señal de que el producto entra tarde al ciclo de demarca.

---
## Propuesta

Fijar un suelo de precio en demarca no inferior al coste medio de compra, aplicado en primer lugar a los 128 productos con eventos de venta bajo coste identificados en el análisis.

---

## Impacto

**2.017 € de pérdida directa evitable** en el periodo analizado (28 % de la pérdida operativa total) si el suelo de precio se aplica al 100 % de los casos identificados. La simulación incluida en el dashboard permite mover el precio de demarca simulado entre el precio real y el coste y ver el impacto esperado en cada escenario intermedio; al 50 %, el impacto es de 1.009 €.

---

## Documentación ampliada

| Documento                                                   | Contenido                                                                                                                             |
| :---------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------ |
| [Parte 1: Análisis completo](docs/01-análisis-completo.md)       | El problema de negocio, estructura del dashboard página a página, simulación de recuperación, conclusiones y recomendaciones          |
| [Parte 2: Arquitectura técnica](docs/02-arquitectura-tecnica.md) | Pipeline de construcción, modelo de datos, columnas calculadas, origen de los datos, anomalías detectadas y limitaciones              |
| [Consultas SQL](SQL/consultas.sql)                              | Extracción de cada tabla del modelo, referenciadas desde la Parte 2                                                                   |
| [Auditoría de datos](SQL/auditoria.md)                          | Las 15 comprobaciones de calidad de datos ejecutadas sobre la base cruda, referenciadas desde la Parte 2                              |
| [Medidas DAX](DAX/dax.md)                                       | Las 36 medidas y columnas calculadas del modelo, con propósito de negocio y comentarios línea a línea, referenciadas desde la Parte 2 |

---
## Requisitos y cómo reproducir

| Escenario                        | Requisito                                                                                                                                              |
| :------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Consulta o lectura del dashboard | Abrir `dashboard/dashboard.pbix` con Power BI Desktop. No requiere nada más: el modo de conexión es Import, los datos ya están embebidos en el `.pbix` |
| Actualización de datos           | Driver ODBC de SQLite instalado y modificar el parámetro `RutaDB` en Power Query para apuntar a la ubicación local de `fruit_store.db`                 |

---

## Contenido del repositorio

```
├── data
│   ├── fruit_store.db
│   └── csv/
│	    └── alteraciones.csv
│	    └── compras.csv
│	    └── demarcas.csv
│	    └── mermas.csv
│	    └── productos.csv
│	    └── ventas.csv
├── dashboard
│   └── dashboard.pbix
├── DAX
│   └── dax.md
├── SQL
│   ├── consultas.sql
│   └── auditoria.md
├── docs
│   ├── 01-analisis-completo.md
│   ├── 02-arquitectura-tecnica.md
│   └── img/
│	    └── dashboard-pagina1-resumen.png
│	    └── dashboard-pagina2-ranking.png
│	    └── dashboard-pagina2-ranking_2.png
│	    └── dashboard-pagina3-frecuencia.png
│	    └── dashboard-pagina4-demarcas.png
│	    └── dashboard-pagina5-simulación.png
├── .gitignore
├── LICENSE
└── README.md
```

---

## Protección de datos

`fruit_store.db` es una base de datos sintética generada para este proyecto. No contiene información de clientes, empleados ni de ningún negocio real; productos, cantidades, precios y fechas son datos simulados con fines demostrativos.

---

## Licencia

© Jose Maderas. Publicado bajo licencia MIT: se autoriza el uso, copia, modificación y distribución de este proyecto, incluso con fines comerciales, siempre que se mantenga el aviso de copyright original. El software se proporciona "tal cual", sin garantía de ningún tipo. Ver [LICENSE](LICENSE) para el texto completo.