use classicmodels;

-- case hitung total pembayaran
delimiter $$
create procedure hitung_total_pembayaran(p_customerNumber INT) -- berparameter in yakni nomor customer
begin
	select customerNumber as 'Nomor customer', sum(amount) as 'Total'
	from payments 
	where payments.customerNumber = p_customerNumber
	group by payments.customerNumber;
end $$
delimiter ;

-- pemanggilan:
call hitung_total_pembayaran(103);


-- case tingkat advance yakni dynamic sql
delimiter $$
create procedure cari_produk_dinamis (
	in p_kolom varchar (50),
	in p_nilai varchar (100),
	in p_order_by varchar(50) -- ketiganya merupakan parameter, yakni nama kolom, nilai yang diacu, serta pengurutan
)
begin
	-- diawali dengan melakukan set dahulu, yakni query yang akan dijalankan
	set @sql = concat('select * from products where ', p_kolom,
	' like ?
	order by ', p_order_by);

	prepare v_state from @sql; -- melakukan prepare menyimpan nilai ke variabel state
	
	set @nilai = p_nilai; -- set p_nilai sebagai @nilai agar dapat dibaca oleh execute
	execute v_state using @nilai; -- melakukan execute yakni menampilkan v_state dengan acuannya adalah @nilai
end $$
delimiter ;

-- pemanggilan:
call cari_produk_dinamis ('productLine', '%Vintage%', 'MSRP');

