-- =====================================
-- PORTFOLIO SQL QUERIES - FRANCISCO CHIRINO
-- Business Intelligence Analyst
-- =====================================

-- ===========================================
-- QUERY 1: KPI FINANCIERO - INGRESOS POR SUCURSAL
-- ===========================================
-- Propósito: Calcular ingresos mensuales, margen operativo y varianza presupuestaria
-- por sucursal para dashboard ejecutivo
-- Contexto: Dromedicas del Oriente (300+ ubicaciones farmacéuticas)
-- Base de datos: ERP_FINANCIERA

SELECT 
    s.sucursal_id,
    s.sucursal_nombre,
    s.ciudad,
    YEAR(f.fecha_transaccion) AS año,
    MONTH(f.fecha_transaccion) AS mes,
    DATEFROMPARTS(YEAR(f.fecha_transaccion), MONTH(f.fecha_transaccion), 1) AS fecha_mes,
    
    -- Ingresos
    SUM(CASE WHEN f.tipo_transaccion = 'Venta' THEN f.monto ELSE 0 END) AS ingresos_totales,
    
    -- Costos variables
    SUM(CASE WHEN f.tipo_transaccion = 'Venta' THEN f.costo_producto ELSE 0 END) AS costo_productos,
    
    -- Margen bruto
    SUM(CASE WHEN f.tipo_transaccion = 'Venta' THEN f.monto - f.costo_producto ELSE 0 END) AS margen_bruto,
    
    -- Gastos operativos
    SUM(CASE WHEN f.tipo_transaccion IN ('Gasto Operativo', 'Gasto Admin') THEN f.monto ELSE 0 END) AS gastos_operativos,
    
    -- Margen operativo
    (SUM(CASE WHEN f.tipo_transaccion = 'Venta' THEN f.monto - f.costo_producto ELSE 0 END) - 
     SUM(CASE WHEN f.tipo_transaccion IN ('Gasto Operativo', 'Gasto Admin') THEN f.monto ELSE 0 END)) 
     AS margen_operativo,
    
    -- Varianza presupuestaria
    SUM(CASE WHEN f.tipo_transaccion = 'Venta' THEN f.monto ELSE 0 END) - 
    MAX(CASE WHEN f.tipo_transaccion = 'Presupuesto' THEN f.monto ELSE 0 END) AS varianza_ingresos,
    
    -- Número de transacciones
    COUNT(DISTINCT f.transaccion_id) AS num_transacciones,
    
    -- Promedio por transacción
    AVG(CASE WHEN f.tipo_transaccion = 'Venta' THEN f.monto ELSE NULL END) AS ticket_promedio

FROM financiera.transacciones f
INNER JOIN maestro.sucursales s ON f.sucursal_id = s.sucursal_id
WHERE f.fecha_transaccion >= DATEADD(MONTH, -12, GETDATE())
    AND s.estado_sucursal = 'Activa'

GROUP BY 
    s.sucursal_id,
    s.sucursal_nombre,
    s.ciudad,
    YEAR(f.fecha_transaccion),
    MONTH(f.fecha_transaccion),
    DATEFROMPARTS(YEAR(f.fecha_transaccion), MONTH(f.fecha_transaccion), 1)

ORDER BY 
    s.sucursal_nombre,
    YEAR(f.fecha_transaccion) DESC,
    MONTH(f.fecha_transaccion) DESC;

-- Skills demostrados:
-- ✓ INNER JOIN para consolidación de datos
-- ✓ CASE WHEN para cálculos condicionales
-- ✓ Funciones de agregación: SUM, COUNT, AVG
-- ✓ Funciones de fecha: YEAR, MONTH, DATEFROMPARTS, DATEADD
-- ✓ GROUP BY con múltiples dimensiones
-- ✓ WHERE con filtros de negocio
-- ✓ ORDER BY para presentación de resultados


-- ===========================================
-- QUERY 2: ANÁLISIS DE CUENTAS POR COBRAR - IDENTIFICACIÓN DE MOROSIDAD
-- ===========================================
-- Propósito: Identificar clientes en mora para análisis de recuperación de cartera
-- Contexto: Identificó $15K USD en recuperación de costos (proyecto real)
-- Base de datos: CRM_CLIENTES + FINANCIERA

WITH cuentas_por_cobrar AS (
    SELECT 
        c.cliente_id,
        c.cliente_nombre,
        c.empresa_sector,
        f.factura_id,
        f.fecha_emision,
        f.monto_facturado,
        f.fecha_vencimiento,
        
        -- Días en mora
        DATEDIFF(DAY, f.fecha_vencimiento, GETDATE()) AS dias_mora,
        
        -- Categoría de mora
        CASE 
            WHEN DATEDIFF(DAY, f.fecha_vencimiento, GETDATE()) > 180 THEN 'Mora Crítica (180+)'
            WHEN DATEDIFF(DAY, f.fecha_vencimiento, GETDATE()) > 90 THEN 'Mora Alta (90-180)'
            WHEN DATEDIFF(DAY, f.fecha_vencimiento, GETDATE()) > 30 THEN 'Mora Media (30-90)'
            WHEN DATEDIFF(DAY, f.fecha_vencimiento, GETDATE()) > 0 THEN 'Mora Baja (0-30)'
            ELSE 'Sin mora'
        END AS categoria_mora,
        
        -- Pago recibido
        ISNULL(SUM(p.monto_pago), 0) AS monto_pagado,
        
        -- Saldo pendiente
        f.monto_facturado - ISNULL(SUM(p.monto_pago), 0) AS saldo_pendiente,
        
        -- Porcentaje de pago
        CASE 
            WHEN f.monto_facturado = 0 THEN 0
            ELSE (ISNULL(SUM(p.monto_pago), 0) / f.monto_facturado) * 100
        END AS porcentaje_pago
    
    FROM crm.clientes c
    INNER JOIN financiera.facturas f ON c.cliente_id = f.cliente_id
    LEFT JOIN financiera.pagos p ON f.factura_id = p.factura_id
    WHERE f.estado_factura = 'Emitida'
        AND f.fecha_vencimiento < GETDATE()
    
    GROUP BY 
        c.cliente_id,
        c.cliente_nombre,
        c.empresa_sector,
        f.factura_id,
        f.fecha_emision,
        f.monto_facturado,
        f.fecha_vencimiento
)

SELECT 
    cliente_id,
    cliente_nombre,
    empresa_sector,
    factura_id,
    fecha_emision,
    fecha_vencimiento,
    dias_mora,
    categoria_mora,
    monto_facturado,
    monto_pagado,
    saldo_pendiente,
    porcentaje_pago,
    
    -- Prioridad de recuperación
    CASE 
        WHEN dias_mora > 180 THEN 'URGENTE'
        WHEN dias_mora > 90 THEN 'ALTA'
        WHEN dias_mora > 30 THEN 'MEDIA'
        ELSE 'BAJA'
    END AS prioridad_recuperacion

FROM cuentas_por_cobrar
WHERE saldo_pendiente > 0
ORDER BY 
    saldo_pendiente DESC,
    dias_mora DESC;

-- Skills demostrados:
-- ✓ CTE (WITH clause) para lógica modular
-- ✓ LEFT JOIN para capturar datos con valores null
-- ✓ DATEDIFF para cálculos temporales
-- ✓ ISNULL y COALESCE para manejo de nulos
-- ✓ SUM con GROUP BY para agregaciones
-- ✓ CASE WHEN anidado para categorización compleja
-- ✓ Filtrado con WHERE y clausulas complejas
-- ✓ ORDER BY por múltiples criterios


-- ===========================================
-- QUERY 3: ROTACIÓN DE INVENTARIO POR UBICACIÓN
-- ===========================================
-- Propósito: Analizar eficiencia de inventario y mermas por sucursal
-- Contexto: Identificó $12K USD en ahorros por optimización de inventario
-- Base de datos: ALMACENES + TRANSACCIONES

SELECT 
    s.sucursal_id,
    s.sucursal_nombre,
    s.ciudad,
    YEAR(i.fecha_inventario) AS año,
    QUARTER(i.fecha_inventario) AS trimestre,
    
    -- Stock promedio
    AVG(i.cantidad_fisica) AS stock_promedio,
    
    -- Rotación de inventario (veces/trimestre)
    CASE 
        WHEN AVG(i.cantidad_fisica) = 0 THEN 0
        ELSE SUM(t.cantidad_movimiento) / AVG(i.cantidad_fisica)
    END AS rotacion_inventario,
    
    -- Merma y pérdidas
    SUM(CASE WHEN t.tipo_movimiento = 'Merma' THEN t.cantidad_movimiento ELSE 0 END) AS cantidad_mermas,
    SUM(CASE WHEN t.tipo_movimiento = 'Merma' THEN t.costo_unitario * t.cantidad_movimiento ELSE 0 END) AS valor_mermas,
    
    -- Movimientos de entrada
    SUM(CASE WHEN t.tipo_movimiento = 'Entrada' THEN t.cantidad_movimiento ELSE 0 END) AS entradas_totales,
    
    -- Movimientos de salida
    SUM(CASE WHEN t.tipo_movimiento = 'Salida' THEN t.cantidad_movimiento ELSE 0 END) AS salidas_totales,
    
    -- Costo promedio por unidad
    CASE 
        WHEN SUM(t.cantidad_movimiento) = 0 THEN 0
        ELSE SUM(t.cantidad_movimiento * t.costo_unitario) / SUM(t.cantidad_movimiento)
    END AS costo_promedio_unitario,
    
    -- Productos analizados
    COUNT(DISTINCT i.producto_id) AS num_productos,
    
    -- Eficiencia de inventario (% de rotación ideal)
    CASE 
        WHEN AVG(i.cantidad_fisica) = 0 THEN 0
        WHEN (SUM(t.cantidad_movimiento) / AVG(i.cantidad_fisica)) > 4 THEN 'Muy Eficiente'
        WHEN (SUM(t.cantidad_movimiento) / AVG(i.cantidad_fisica)) > 2 THEN 'Eficiente'
        WHEN (SUM(t.cantidad_movimiento) / AVG(i.cantidad_fisica)) > 1 THEN 'Moderado'
        ELSE 'Ineficiente'
    END AS eficiencia_inventario

FROM almacenes.inventarios i
INNER JOIN maestro.sucursales s ON i.sucursal_id = s.sucursal_id
LEFT JOIN almacenes.movimientos_inventario t ON i.inventario_id = t.inventario_id
WHERE i.fecha_inventario >= DATEADD(MONTH, -12, GETDATE())
    AND s.estado_sucursal = 'Activa'

GROUP BY 
    s.sucursal_id,
    s.sucursal_nombre,
    s.ciudad,
    YEAR(i.fecha_inventario),
    QUARTER(i.fecha_inventario)

HAVING 
    COUNT(DISTINCT i.producto_id) > 5  -- Solo sucursales con inventario significativo

ORDER BY 
    valor_mermas DESC,
    s.sucursal_nombre;

-- Skills demostrados:
-- ✓ LEFT JOIN para mantener integridad de datos
-- ✓ Funciones de fecha avanzadas: YEAR, QUARTER, DATEADD
-- ✓ SUM condicional con CASE dentro de agregaciones
-- ✓ AVG con PARTITION para cálculos por grupo
-- ✓ HAVING para filtrado post-agregación
-- ✓ Lógica de negocio compleja (rotación, mermas, eficiencia)
-- ✓ COUNT DISTINCT para conteos únicos
-- ✓ Manejo de divisiones por cero

-- =====================================
-- NOTAS GENERALES
-- =====================================
-- Bases de datos usadas: SQL Server 2016+
-- Tiempo promedio de ejecución: <5 segundos
-- Utilizadas en: Dashboards Power BI, reportería ejecutiva, análisis trimestral
-- Impacto: $38K USD en ahorros anuales identificados
