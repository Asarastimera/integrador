--CREACION DE TRIGGER
CREATE TABLE productos_superan_umbral (
    id_producto INT,
    nombre_producto VARCHAR(255),
    total_vendido INT,
    fecha_superado DATETIME
);

SELECT * FROM productos_superan_umbral;

--Ejecucion de trigger con el registro de una venta correspondiente al vendedor con ID 9, 
--al cliente con ID 84, del producto con ID 103, por una cantidad de 1.876 unidades y un 
--valor de 1200 unidades.

DELIMITER //

CREATE TRIGGER trigger_umbral_ventas
AFTER INSERT ON sales
FOR EACH ROW
BEGIN
    DECLARE total INT;

    -- Calcular el total acumulado de unidades vendidas del producto
    SELECT SUM(Quantity)
    INTO total
    FROM sales
    WHERE ProductID = NEW.ProductID;

    -- Si el total supera las 200,000 unidades y el producto no está registrado en la tabla de monitoreo
    IF total > 200000 AND NOT EXISTS (
        SELECT 1 FROM productos_superan_umbral WHERE id_producto = NEW.ProductID
    ) THEN
        -- Insertar en la tabla de monitoreo con el ID del producto, nombre, total vendido y fecha
        INSERT INTO productos_superan_umbral (
            id_producto, nombre_producto, total_vendido, fecha_superado
        )
        SELECT 
            p.ProductID,
            p.ProductName,
            total,
            NOW()
        FROM products p
        WHERE p.ProductID = NEW.ProductID;
    END IF;
END;
//

DELIMITER ;
INSERT INTO sales (
    SalesPersonID,  -- Vendedor con ID 9
    CustomerID,     -- Cliente con ID 84
    ProductID,      -- Producto con ID 103
    Quantity,       -- Cantidad de 1,876 unidades
    Discount,       -- Descuento, 0 en este caso
    TotalPrice,     -- Valor de la venta, 1200
    SalesDate,      -- Fecha de la venta (ahora)
    TransactionNumber -- Un número único para la transacción
)
VALUES (
    9,            -- ID del vendedor
    84,           -- ID del cliente
    103,          -- ID del producto
    1876,         -- Cantidad vendida
    0.0,          -- Descuento
    1200.0,       -- Precio total
    NOW(),        -- Fecha y hora de la venta
    'TXN-REGISTRO-103' -- Número de la transacción
);
SELECT * FROM productos_superan_umbral;

--OPTIMIZACION 
--INDEX consulta 1
CREATE INDEX idx_ventas_producto_cliente_qty ON sales (ProductID, CustomerID, Quantity);

--INDEX consula 2
CREATE INDEX idx_ventas_producto_cliente_qty ON sales (ProductID, CustomerID, Quantity);
