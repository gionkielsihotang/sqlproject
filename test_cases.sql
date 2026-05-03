use classicmodels;

-- pemanggilan stored function hitung_total_pembayaran 
call hitung_total_pembayaran(103);
call hitung_total_pembayaran(141);

-- pemanggilan stored function status_kredit_customer
CALL status_kredit_customer(103);
CALL status_kredit_customer(211);

-- pemanggilan stored procedure tambah_order_baru
CALL tambah_order_baru(103, '2024-05-01', '2024-05-10', 'S10_1678', 5, @orderNum);
CALL tambah_order_baru(103, '2024-05-01', '2024-05-10', 'S10_1678', 999999, @orderNum);

-- pemanggilan stored procedure update_stok_setelah_order
CALL update_stok_setelah_order('S10_1678', 7933);

-- pemanggilan stored procedure laporan_penjualan_per_employee
call laporan_penjualan_per_employee('2003-01-01','2004-12-31');

-- pemanggilan stored procedure hapus_order_if_unpaid
call hapus_order_if_unpaid(10167);

-- pemanggilan stored procedure cari_produk_dinamis
call cari_produk_dinamis ('productLine', '%Vintage%', 'MSRP');
call cari_produk_dinamis ('productName', '%Merce%', 'buyPrice');

-- pemanggilan stored procedure transfer_customer
CALL transfer_customer(311, 333);

