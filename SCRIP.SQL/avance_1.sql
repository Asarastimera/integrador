USE taller_data;
-- Obtencion de los 5 productos más vendidos (PUNTO A)

WITH productos_top5 AS (
    SELECT 
        ProductID,
        SUM(Quantity) AS cantidad_total
    FROM sales
    GROUP BY ProductID
    ORDER BY cantidad_total DESC
    LIMIT 5
),

-- cantidad vendida por producto y vendedor
ventas_por_vendedor AS (
    SELECT 
        s.ProductID,
        s.SalesPersonID,
        SUM(s.Quantity) AS cantidad_vendida,
        ROW_NUMBER() OVER (
            PARTITION BY s.ProductID
            ORDER BY SUM(s.Quantity) DESC
        ) AS rn
    FROM sales s
    WHERE s.ProductID IN (SELECT ProductID FROM productos_top5)
    GROUP BY s.ProductID, s.SalesPersonID
),

-- nombre del vendedor
top_vendedores AS (
    SELECT 
        vp.ProductID,
        vp.SalesPersonID,
        vp.cantidad_vendida,
        e.FirstName,
        e.LastName
    FROM ventas_por_vendedor vp
    JOIN employees e ON vp.SalesPersonID = e.EmployeeID
    WHERE vp.rn = 1
)

-- resultado con el producto
SELECT 
    pt.ProductID AS id_producto,
    p.ProductName AS nombre_producto,
    pt.cantidad_total AS total_vendido,
    tv.SalesPersonID AS id_vendedor,
    CONCAT(tv.FirstName, ' ', tv.LastName) AS vendedor_destacado,
    tv.cantidad_vendida AS vendido_por_vendedor
FROM productos_top5 pt
JOIN products p ON pt.ProductID = p.ProductID
JOIN top_vendedores tv ON pt.ProductID = tv.ProductID
ORDER BY total_vendido DESC;

--SEGUNDA PARTE PUNTO A

USE taller_data;
-- Obtencion de los 5 productos más vendidos

WITH productos_top5 AS (
    SELECT 
        ProductID,
        SUM(Quantity) AS cantidad_total
    FROM sales
    GROUP BY ProductID
    ORDER BY cantidad_total DESC
    LIMIT 5
),

-- cantidad vendida por producto y vendedor
ventas_por_vendedor AS (
    SELECT 
        s.ProductID,
        s.SalesPersonID,
        SUM(s.Quantity) AS cantidad_vendida,
        ROW_NUMBER() OVER (
            PARTITION BY s.ProductID
            ORDER BY SUM(s.Quantity) DESC
        ) AS rn
    FROM sales s
    WHERE s.ProductID IN (SELECT ProductID FROM productos_top5)
    GROUP BY s.ProductID, s.SalesPersonID
),

-- nombre del vendedor
top_vendedores AS (
    SELECT 
        vp.ProductID,
        vp.SalesPersonID,
        vp.cantidad_vendida,
        e.FirstName,
        e.LastName
    FROM ventas_por_vendedor vp
    JOIN employees e ON vp.SalesPersonID = e.EmployeeID
    WHERE vp.rn = 1
)

-- resultado con el producto y porcentaje
SELECT 
    pt.ProductID AS id_producto,
    p.ProductName AS nombre_producto,
    pt.cantidad_total AS total_vendido,
    tv.SalesPersonID AS id_vendedor,
    CONCAT(tv.FirstName, ' ', tv.LastName) AS vendedor_destacado,
    tv.cantidad_vendida AS vendido_por_vendedor,
    ROUND((tv.cantidad_vendida * 100.0) / pt.cantidad_total, 2) AS porcentaje_vendedor
FROM productos_top5 pt
JOIN products p ON pt.ProductID = p.ProductID
JOIN top_vendedores tv ON pt.ProductID = tv.ProductID
ORDER BY total_vendido DESC;

--PUNTO B porcentaje

USE taller_data;

WITH productos_mas_vendidos AS (
    SELECT 
        ProductID,
        SUM(Quantity) AS total_vendido
    FROM sales
    GROUP BY ProductID
    ORDER BY total_vendido DESC
    LIMIT 5
),
total_clientes AS (
    SELECT COUNT(DISTINCT CustomerID) AS total_clientes FROM sales
),
clientes_por_producto AS (
    SELECT 
        s.ProductID AS id_producto,
        COUNT(DISTINCT s.CustomerID) AS clientes_unicos
    FROM sales s
    WHERE s.ProductID IN (SELECT ProductID FROM productos_mas_vendidos)
    GROUP BY s.ProductID
)

SELECT 
    cpp.id_producto,
    p.ProductName AS nombre_producto,
    cpp.clientes_unicos,
    tc.total_clientes,
    ROUND((cpp.clientes_unicos * 100.0) / tc.total_clientes, 4) AS porcentaje_clientes
FROM clientes_por_producto cpp
JOIN products p ON cpp.id_producto = p.ProductID
CROSS JOIN total_clientes tc
ORDER BY porcentaje_clientes DESC;

--PUNTO C categorias
USE taller_data;

WITH ventas_por_producto AS (
    SELECT 
        s.ProductID AS id_producto,
        SUM(s.Quantity) AS total_vendido
    FROM sales s
    GROUP BY s.ProductID
),
ventas_con_categoria AS (
    SELECT 
        vp.id_producto,
        p.ProductName AS nombre_producto,
        p.CategoryID AS id_categoria,
        c.CategoryName AS nombre_categoria,
        vp.total_vendido,
        SUM(vp.total_vendido) OVER (PARTITION BY p.CategoryID) AS total_categoria,
        ROUND((vp.total_vendido * 100.0) / 
              SUM(vp.total_vendido) OVER (PARTITION BY p.CategoryID), 2) AS porcentaje_en_categoria
    FROM ventas_por_producto vp
    JOIN products p ON vp.id_producto = p.ProductID
    JOIN categories c ON p.CategoryID = c.CategoryID
),
top_5_productos AS (
    SELECT * 
    FROM ventas_con_categoria
    ORDER BY total_vendido DESC
    LIMIT 5
)

SELECT 
    id_producto,
    nombre_producto,
    nombre_categoria,
    total_vendido,
    total_categoria,
    porcentaje_en_categoria
FROM top_5_productos
ORDER BY porcentaje_en_categoria DESC;

--PUNTO D: 10 mas vendidos

USE taller_data;

WITH ventas_por_producto AS (
    SELECT 
        s.ProductID AS id_producto,
        SUM(s.Quantity) AS total_vendido
    FROM sales s
    GROUP BY s.ProductID
),
ventas_con_categoria_y_rank AS (
    SELECT 
        vp.id_producto,
        p.ProductName AS nombre_producto,
        p.CategoryID AS id_categoria,
        c.CategoryName AS nombre_categoria,
        vp.total_vendido,
        RANK() OVER (PARTITION BY p.CategoryID ORDER BY vp.total_vendido DESC) AS posicion_en_categoria
    FROM ventas_por_producto vp
    JOIN products p ON vp.id_producto = p.ProductID
    JOIN categories c ON p.CategoryID = c.CategoryID
),
top_10_productos AS (
    SELECT *
    FROM ventas_con_categoria_y_rank
    ORDER BY total_vendido DESC
    LIMIT 10
)

SELECT 
    id_producto,
    nombre_producto,
    nombre_categoria,
    total_vendido,
    posicion_en_categoria
FROM top_10_productos
ORDER BY total_vendido DESC;