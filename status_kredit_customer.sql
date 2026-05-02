use classicmodels;

DELIMITER $$

CREATE PROCEDURE status_kredit_customer(IN p_customerNumber INT)
BEGIN
    DECLARE total_pembayaran DECIMAL(10,2);
    DECLARE rata_rata DECIMAL(10,2);

    CALL hitung_total_pembayaran(p_customerNumber);

    -- menghitung total customer sendiri
    SELECT SUM(amount)
    INTO total_pembayaran
    FROM payments
    WHERE customerNumber = p_customerNumber;

    -- menghitung rata-rata
    SELECT AVG(total)
    INTO rata_rata
    FROM (
        SELECT SUM(amount) AS total
        FROM payments
        GROUP BY customerNumber
    ) AS sub;

    -- menampilkan status
    IF total_pembayaran > rata_rata THEN
        SELECT 'BAIK' AS `Status Total Pembayaran`;
    ELSE
        SELECT 'KURANG' AS `Status Total Pembayaran`;
    END IF;

END $$

DELIMITER ;

CALL status_kredit_customer(103);
CALL status_kredit_customer(211);