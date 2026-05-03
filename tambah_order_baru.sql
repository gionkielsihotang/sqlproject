USE classicmodels;

DELIMITER $$

CREATE PROCEDURE tambah_order_baru(
    IN p_customerNumber INT,
    IN p_orderDate DATE,
    IN p_requiredDate DATE,
    IN p_productCode VARCHAR(15),
    IN p_quantityOrdered INT,
    OUT p_orderNumber INT
)
BEGIN
    DECLARE v_stok INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    	RESIGNAL;
    END;

    START TRANSACTION;
    -- cek stok
    SELECT quantityInStock
    INTO v_stok
    FROM products
    WHERE productCode = p_productCode;
    -- SIGNAL jika stok kurang
    IF v_stok < p_quantityOrdered THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stok tidak mencukupi';
    END IF;
    -- generate orderNumber
    SELECT IFNULL(MAX(orderNumber),0) + 1
    INTO p_orderNumber
    FROM orders;
    -- insert orders
    INSERT INTO orders(orderNumber, orderDate, requiredDate, status, customerNumber)
    VALUES(p_orderNumber, p_orderDate, p_requiredDate, 'In Process', p_customerNumber);
    -- insert orderdetails
    INSERT INTO orderdetails(orderNumber, productCode, quantityOrdered, priceEach, orderLineNumber)
    SELECT 
        p_orderNumber,
        p_productCode,
        p_quantityOrdered,
        buyPrice,
        1
    FROM products
    WHERE productCode = p_productCode;
    COMMIT;

END $$

DELIMITER ;

-- CASE BERHASIL
CALL tambah_order_baru(
    103,
    '2024-05-01',
    '2024-05-10',
    'S10_1678',
    5,
    @orderNum
);

SELECT @orderNum AS order_baru;

SELECT * FROM orders WHERE orderNumber = @orderNum;
SELECT * FROM orderdetails WHERE orderNumber = @orderNum;

-- CASE GAGAL
CALL tambah_order_baru(
    103,
    '2024-05-01',
    '2024-05-10',
    'S10_1678',
    999999,
    @orderNum
);
