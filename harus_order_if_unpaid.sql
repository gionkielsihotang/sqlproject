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

-- pemanggilan prosedur
call hapus_order_if_unpaid(10167)