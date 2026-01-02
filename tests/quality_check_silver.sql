--check for null or dublicates in primary key

select cst_id,count(*) from silver.crm_cust_info group by cst_id having count(*) > 1 or cst_id is null;

--check for unwanted spaces

select cst_key from silver.crm_cust_info where cst_key!=trim(cst_key)
;

--data standardization and consistency
select distinct cst_material_status from silver.crm_cust_info;






--check for null or dublicates in primary key

select prd_id,count(*) from silver.crm_prd_info group by prd_id having count(*) > 1 or prd_id is null;

--check for unwanted spaces

select prd_nm from silver.crm_prd_info where prd_nm!=trim(prd_nm)
;

--null check
select distinct prd_cost from silver.crm_prd_info where prd_cost<0 or prd_cost is null;

---data standerdization and consistency
select distinct  prd_line from silver.crm_prd_info 

--checking invalid dates(0st>end)
select * from silver.crm_prd_info where prd_end_dt<prd_start_dt;





---check for invalid dates
select nullif(sls_due_dt,0)as sls_due_dt from bronze.crm_sales_details where sls_due_dt<=0 or len(sls_due_dt)!=8 or sls_due_dt>20250101 or sls_due_dt<19000101

---check invalid date orders(or_date>shipp/due_dt)
select * from silver.crm_saes_details where ss_order_dt>sls_ship_dt or sls_order_dt>sls_due_dt;

--data consistency sales=quantity*sls_price
select distinct sls_sales,sls_quantity,sls_price from silver.crm_sales_details where sls_sales!=sls_quantity*sls_price or sls_sales is null or sls_quantity is null or sls_price is null or sls_sales <=0 or sls_quantity <=0 or sls_price <=0 order by sls_sales ,sls_quantity, sls_price 





--checking outof range dates birth date btwn 1924-1-1 and today
select distinct bdate from silver.erp_cust_az12 where bdate<'1924-01-01' or bdate>getdate();

---data standardization
select distinct gen from silver.erp_cust_az12;

select distinct cntry from silver.erp_loc_a101 order by cntry;

--unwanted spaces
select * from silver.erp_px_cat_g1v2 where cat!=trim(cat) or subcat!=trim(subcat) or maintenance!=trim(maintenance);

select distinct maintenance from  silver.erp_px_cat_g1v2;
