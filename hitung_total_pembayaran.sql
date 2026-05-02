use classicmodels;

delimiter //
create procedure hitung_total_pembayaran(p_customerNumber INT) 
begin
	select customerNumber as 'Nomor customer', sum(amount) as 'Total'
	from payments 
	where payments.customerNumber = p_customerNumber
	group by payments.customerNumber;
end //
delimiter ;

call hitung_total_pembayaran(103);
