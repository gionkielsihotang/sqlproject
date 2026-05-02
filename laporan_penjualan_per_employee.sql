USE classicmodels;

DELIMITER $$

create procedure laporan_penjualan_per_employee(
    in p_startDate date,
    in p_endDate date
)
begin
    declare done int default 0;
    declare v_empNumber int;
    declare v_name varchar(100);
    declare v_total decimal(15,2);

    declare cur_employee cursor for
        select employeeNumber, concat(firstName, ' ', lastName)
        from employees;

    declare continue handler for not found set done = 1;

    open cur_employee;

    read_loop: loop
        fetch cur_employee into v_empNumber, v_name;

        if done then
            leave read_loop;
        end if;

        select 
            sum(od.quantityOrdered * od.priceEach)
        into v_total
        from customers c
        join orders o on c.customerNumber = o.customerNumber
        join orderdetails od on o.orderNumber = od.orderNumber
        where c.salesRepEmployeeNumber = v_empNumber
        and o.orderDate between p_startDate and p_endDate;

        select v_empNumber, v_name, ifnull(v_total,0) as total_penjualan;

    end loop;

    close cur_employee;

end $$

DELIMITER ;

call laporan_penjualan_per_employee('2003-01-01','2004-12-31');