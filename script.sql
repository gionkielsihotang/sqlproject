-- Stored Function hitung_total_pembayaran

delimiter $$
create procedure hitung_total_pembayaran(p_customerNumber INT)
 -- berparameter in yakni nomor customer
begin
	select customerNumber as 'Nomor customer', sum(amount) as 'Total'
	from payments 
	where payments.customerNumber = p_customerNumber
	group by payments.customerNumber;
end $$
delimiter ;


-- Stored Function Status_kredit_customer

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

-- Stored Procedure tambah_order_baru

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

-- Stored Procedure update_stok_setelah_order

-- Menambahkan Kolom stockStatus
ALTER TABLE products
ADD COLUMN stockStatus VARCHAR(20) DEFAULT 'In Stock';

DELIMITER $$
	CREATE PROCEDURE update_stok_setelah_order(
	   IN p_productCode VARCHAR(15),
	   IN p_quantity INT
	)
	
	BEGIN
	   UPDATE products
	
	   -- set nilai qualityInStock dan stockStatus
	   
	   SET
	       quantityInStock = quantityInStock - p_quantity,
	       stockStatus = CASE
	                       WHEN (quantityInStock - p_quantity) <= 0 THEN 'Low Stock'
	                       ELSE stockStatus -- membiarkan nilai stockStatus seperti semula
	                     END
	   WHERE productCode = p_productCode;
	END $$
DELIMITER ;

-- Stored Procedure laporan_penjualan_per_employee

DELIMITER $$
create procedure laporan_penjualan_per_employee(
   in p_startDate date,
   in p_endDate date
)
BEGIN

	-- variabel kontrol untuk menghentikan loop
   declare done int default 0;
   declare v_empNumber int;
   declare v_name varchar(100);
   declare v_total decimal(15,2);
   
	-- cursor untuk mengambil seluruh data employee
   declare cur_employee cursor for
       select employeeNumber, concat(firstName, ' ', lastName)
       from employees;
       
	-- handler: jika data habis, ubah done jadi 1
   declare continue handler for not found set done = 1;
   
	-- membuka cursor
   open cur_employee;
   
	-- loop untuk membaca data employee satu per satu
   read_loop: loop
	   
	    -- ambil data employee ke variabel
       fetch cur_employee into v_empNumber, v_name;
       
	    -- jika tidak ada data lagi, keluar dari loop
       if done then
           leave read_loop;
       end if;
       
	    -- hitung total penjualan per employee
       select
           sum(od.quantityOrdered * od.priceEach)
       into v_total
       from customers c
       join orders o on c.customerNumber = o.customerNumber
       join orderdetails od on o.orderNumber = od.orderNumber
       where c.salesRepEmployeeNumber = v_empNumber
       and o.orderDate between p_startDate and p_endDate;
	    -- tampilkan hasil (jika NULL jadi 0)
       select v_empNumber, v_name, ifnull(v_total,0) as total_penjualan;
   end loop;
   close cur_employee;
end $$
DELIMITER ;

-- Stored Procedure hapus_order_if_unpaid

delimiter $$
create procedure hapus_order_if_unpaid(
  in p_orderNumber int
)
begin
  -- deklarasi variabel
  declare v_is_valid int default 0;
  -- deklarasi exit handler jika terjadi error, akan terjadi rollback
  declare exit handler for sqlexception
  begin
      rollback;
      select 'Terjadi kesalahan sistem, penghapusan dibatalkan , rollback dilakukan' as status_pesan;
  end;
  -- cek syarat order apakah statusnya cancelled dan lebih dari 30 hari
  select 1 into v_is_valid
  from orders
  where orderNumber = p_orderNumber
    and status = 'Cancelled'
    and datediff(curdate(), orderDate) > 30;
   
  if v_is_valid = 1 then
      -- memulai transaksi penghapusan order
      start transaction;
      delete from orderdetails where orderNumber = p_orderNumber;
      delete from orders where orderNumber = p_orderNumber;
      commit;
      select concat('Penghapusan Berhasil : Order nomor ', p_orderNumber) as status_pesan;
  else
      select 'Penghapusan Gagal : Order tidak ditemukan, status bukan Cancelled, atau umur order belum > 30 hari.' as status_pesan;
  end if;
end $$
delimiter ;

-- Stored Procedure cari_produk_dinamis

delimiter $$
create procedure cari_produk_dinamis (
	in p_kolom varchar (50),
	in p_nilai varchar (100),
	in p_order_by varchar(50)
)
BEGIN
	-- set nilai query
	set @sql = concat('select * from products where ', p_kolom,
	' like ?
	order by ', p_order_by);
	prepare v_state from @sql; -- prepare menyimpan nilai ke variabel state
	
	set @nilai = p_nilai; -- set p_nilai sebagai @nilai agar dapat dibaca oleh execute


	execute v_state using @nilai; -- melakukan execute yakni menampilkan v_state dengan acuannya adalah @nilai
end $$
delimiter ;

-- Stored Procedure transfer_customer

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



