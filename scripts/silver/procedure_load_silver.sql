create or alter procedure silver.load_silver as
BEGIN
declare @start_time datetime,@end_time datetime,@batch_start_time datetime,@batch_end_time datetime;
begin try
set @batch_start_time=getdate();
print '======================================='
print'loading silver layer'
print'========================================='


print '======================================='
print'print crm tables'
print'========================================='

set @start_time=getdate();
truncate table silver.crm_cust_info; 
insert into silver.crm_cust_info(cst_id
      ,cst_key
      ,cst_firstname
      ,cst_lastname
      ,cst_material_status
      ,cst_gndr
      ,cst_create_date)
select cst_id,cst_key, 
TRIM(cst_firstname)as cst_firstname,
TRIM(cst_lastname)as cst_lastname,
case when UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
     when UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
     else 'n/a'
end cst_material_status,
case when UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
     when UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
     else 'n/a'
end cst_gndr,cst_create_date from( select
*, row_number() over (partition by cst_id order by cst_create_date desc)as flag_last from bronze.crm_cust_info
where cst_id is not null )t where flag_last=1

set @end_time=getdate();
print 'load duration: '+cast(datediff(second,@start_time,@end_time)as nvarchar)+'seconds';
print'==============================='
--select from silver.crm_sales_details



truncate table silver.crm_prd_info;
insert into silver.crm_prd_info(
prd_id,cat_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt)
select prd_id
      ,
      replace(substring(prd_key,1,5),'-','_')as cat_id,
      substring(prd_key,7,len(prd_key)) as prd_key
      ,prd_nm
      ,isnull(prd_cost,0) as prd_cost
      ,case when upper(trim(prd_line))='M' THEN 'Mountain'
            when upper(trim(prd_line))='R' THEN 'Road'
            when upper(trim(prd_line))='S' THEN 'Other sales'
            when upper(trim(prd_line))='T' THEN 'Touring'
            else 'n/a'
        end as prd_line
      ,cast(prd_start_dt as date) as prd_start_dt
      ,cast(lead(prd_start_dt)over (partition by prd_key order by prd_start_dt)-1 as date) as prd_end_dt from bronze.crm_prd_info





truncate table silver.crm_sales_details;
insert into silver.crm_sales_details(
sls_ord_num ,
sls_prd_key,
sls_cust_id ,
sls_order_dt ,
sls_ship_dt ,
sls_due_dt,
sls_sales ,
sls_quantity ,
sls_price 
)
select sls_ord_num,
sls_prd_key,
sls_cust_id,
case when sls_order_dt=0 or len(sls_order_dt)!=8 then null
	else cast(cast(sls_order_dt as varchar)as date)
end as sls_order_dt,
case when sls_ship_dt=0 or len(sls_ship_dt)!=8 then null
	else cast(cast(sls_ship_dt as varchar)as date)
end as sls_ship_dt,
case when sls_due_dt=0 or len(sls_due_dt)!=8 then null
	else cast(cast(sls_due_dt as varchar)as date)
end as sls_due_dt,
case when sls_sales is null or sls_sales<=0 or sls_sales!=sls_quantity*abs(sls_price)then sls_quantity*abs(sls_price)
else sls_sales
end as sls_sales,sls_quantity,
case when sls_price is null or sls_price<=0 then sls_sales/nullif(sls_quantity,0)
	else sls_price
end as sls_price
from bronze.crm_sales_details

print 'start of erp tables'
set @start_time=getdate();

truncate table silver.erp_cust_az12;
insert into silver.erp_cust_az12(cid,bdate,gen)
select case when cid like'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
ELSE cid END AS cid,
CASE WHEN bdate>GETDATE() THEN NULL ELSE  bdate END AS  bdate,
case when upper(trim(gen)) in ('F','FEMALE') then 'Female'
		when upper(trim(gen)) in ('M','MALE') then 'Male'
		else 'n/a' end as gen from bronze.erp_cust_az12




truncate table silver.erp_loc_a101;
insert into silver.erp_loc_a101(cid,cntry)select replace(cid,'_','')cid,case when trim(cntry)='DE' THEN 'Germany'
when trim(cntry) IN( 'US','USA') THEN 'UNITED STATES'
when trim(cntry)='' OR cntry is null THEN 'n/a' else trim(cntry) end as cntry from bronze.erp_loc_a101

--select * from bronze.erp_loc_a101



truncate table silver.erp_px_cat_g1v2;
insert into silver.erp_px_cat_g1v2 (id,cat,subcat,maintenance )select id,cat,subcat,maintenance from bronze.erp_px_cat_g1v2
set @batch_end_time=getdate();
print '======================================='
print'loading silver layer is completed'
print'-total load duration:'+cast(datediff(second,@batch_start_time,@batch_end_time)as varchar)+'seconds';
print'========================================='
end try
begin catch
print '======================================='
print'error occured during loading the data'
print'========================================='
end catch
END

-----------
