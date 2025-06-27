-- SET ----------------------------------------------------------------------------------------------------
SET 	
    @pubID := 'SHOST-10050582-0002'
	,@trx_no := '308880'
	,@termID := '0002';	
-- ----------------------------------------------------------------------------------------------------	

-- pos_sale_product
-- pos_sale_product_discount
-- pos_sale
-- pos_sale_info
-- pos_sale_senior	
	
-- pos_sale_product ----------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------
SELECT	'' AS 'pos_sale_product'
    ,psd.frecno
	,psd.fproductid
	,psd.funitprice
	,psd.fqty
	,psd.ftax_type
	
	,psd.fdiscp
	
	,psd.fsc_discp
	-- ,psd.fscdiscount
	
	,psd.fdiscount_percent1
	-- ,psd.fdiscount1
	
	,psd.fdiscount_percent2
	-- ,psd.fdiscount2
	
	,psd.fdiscount_percent4
	-- ,psd.fdiscount4
	
	,psd.fdiscount_percent5
	-- ,psd.fdiscount5
	
	,psd.fdiscount_percent6
	-- ,psd.fdiscount6
	
	,psd.ftotal_line
	,psd.fstatus_flag
	
	-- ,psd.ftotal_discount
	
FROM pos_sale_product psd
	JOIN pos_sale ps 
		ON psd.frecno = ps.frecno
WHERE psd.fpubid = @pubID 
	AND ps.ftrx_no = @trx_no;
-- ----------------------------------------------------------------------------------------------------



-- pos_sale_product_discount ----------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------
SELECT '' AS 'pos_sale_product_discount'
    ,sub1.* 
FROM (
    SELECT 
        pspd.*
        ,ps.fpubid AS sale_fpubid
        ,ps.frecno AS sale_frecno
        ,ps.ftrx_no
    FROM pos_sale_product_discount pspd
        JOIN pos_sale ps 
            ON pspd.frecno = ps.frecno
    WHERE pspd.fpubid = @pubID
        AND ps.ftrx_no = @trx_no
) sub1;
-- ----------------------------------------------------------------------------------------------------



-- pos_sale ----------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------
SELECT '' AS 'pos_sale'
	,fpubid
	,fsale_date
	,frecno
	,fdocument_no
	,ftrx_no
	
	,fvoid_flag
	,freturn_flag
	
	,fcustomer_count
	,(fscratio * fcustomer_count) AS Seniors
	
	,''
	,''
	,fscdiscount
	,fdiscount
	,fline_discount
	,ftotal_discount
	,''
	,''
	,fdiscount1
	,fdiscount2
	,fdiscount3
	,fdiscount4
	,fdiscount5
	-- ,fdiscount6
	,''
	-- ,fdiscount_percent6
	,fdiscp
	
	
	,''
	,''
	,''
	,fgross
	,fsubtotal
	,''
	,finc_tax
	,fexc_tax
	,''
	,finc_sale
	,fexc_sale
	,''
	,fevat
	,fnotax_sale
	,fnosale
	,ftax
	,ftax_sale
	,fvat_exempt
		
FROM pos_sale 
WHERE fpubid = @pubID AND ftrx_no = @trx_no;
-- ----------------------------------------------------------------------------------------------------	

-- select *
-- FROM pos_sale 
-- WHERE fpubid = @pubID AND ftrx_no = @trx_no;
-- ----------------------------------------------------------------------------------------------------



-- pos_sale_info ----------------------------------------------------------------------------------------------------	
-- ----------------------------------------------------------------------------------------------------	
SELECT '' AS 'pos_sale_info'
    ,sub2.* 
FROM (
    SELECT 
        psi.*
        ,ps.fpubid AS sale_fpubid
        ,ps.frecno AS sale_frecno
        ,ps.ftrx_no
    FROM pos_sale_info psi
        JOIN pos_sale ps 
            ON psi.frecno = ps.frecno
    WHERE psi.fpubid = @pubID 
        AND ps.ftrx_no = @trx_no
) sub2;
-- ----------------------------------------------------------------------------------------------------	



-- pos_sale_senior ----------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------
SELECT '' AS 'pos_sale_senior'
    ,sub3.* 
FROM(
    SELECT 
        pss.*
        ,ps.fpubid AS sale_fpubid
        ,ps.frecno AS sale_frecno
        ,ps.ftrx_no
    FROM pos_sale_senior pss
        JOIN pos_sale ps 
            ON pss.frecno = ps.frecno
    WHERE pss.fpubid = @pubID 
        AND ps.ftrx_no = @trx_no
) sub3;
-- ----------------------------------------------------------------------------------------------------