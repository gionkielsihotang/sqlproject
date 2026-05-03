-- perintah alter table untuk menambahkan kolom stockStatus di tabel products
ALTER TABLE products
ADD COLUMN stockStatus VARCHAR(20) DEFAULT 'In Stock';

DELIMITER $$
create procedure update_stok_setelah_order(
   in p_productCode varchar(15),
   in p_quantity int
)
begin
   update products
   -- set nilai qualityInStock dan stockStatus
   set
       quantityInStock = quantityInStock - p_quantity,
       stockStatus = case
                       when (quantityInStock - p_quantity) <= 0 then 'Low Stock'
                       else stockStatus -- membiarkan nilai stockStatus seperti semula
                     end
   where productCode = p_productCode;
end $$
DELIMITER ;

-- pemanggilan prosedur
CALL update_stok_setelah_order('S10_1678', 7933);
