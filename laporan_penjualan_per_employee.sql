USE classicmodels;

--level Menengah (Intermediate)
DELIMITER $$

create procedure laporan_penjualan_per_employee(
    in p_startDate date,
    in p_endDate date
)
begin
    select 
        e.employeenumber,
        concat(e.firstName, ' ', e.lastName) as nama_employee,
        ifnull(sum(od.quantityOrdered * od.priceEach), 0) as total_penjualan
    from employees e
    left join customers c 
        on e.employeeNumber = c.salesRepEmployeeNumber
    left join orders o 
        on c.customerNumber = o.customerNumber
        and o.orderDate between p_startDate and p_endDate
    left join orderdetails od 
        on o.orderNumber = od.orderNumber
    group by e.employeeNumber, e.firstName, e.lastName
    order by total_penjualan desc;

end $$

DELIMITER ;

-- pemanggilan
call laporan_penjualan_per_employee('2003-01-01','2004-12-31');


-- Level Tinggi (Advanced)
DELIMITER $$

create procedure laporan_penjualan_per_employee(
    in p_startDate date,
    in p_endDate date
)
begin
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

-- pemanggilan procedure
call laporan_penjualan_per_employee('2003-01-01','2004-12-31');