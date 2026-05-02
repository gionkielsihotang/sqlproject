USE classicmodels;

DELIMITER $$

CREATE PROCEDURE transfer_customer(
    IN p_fromCustomer INT,
    IN p_toCustomer INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK TO save_awal;
    END;

    START TRANSACTION;

    -- penggunaan Savepoint
    SAVEPOINT save_awal;

    -- Memindahkan ordernya
    UPDATE orders
    SET customerNumber = p_toCustomer
    WHERE customerNumber = p_fromCustomer;

    COMMIT;

END $$

DELIMITER ;



CALL transfer_customer(211, 112);