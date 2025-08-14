SELECT -- fpubid
	fsale_date
	,ftrx_no
	-- ,fcustomer_count
	-- ,fsubtotal
	-- ,finc_sale
	-- ,fexc_sale
	-- ,' '
	-- ,fnotax_sale
	-- ,fzero_rated_sale
	,''
	,fvat_exempt
	,ftax_sale
	,ftax
	
	
FROM pos_sale
WHERE fsale_date >= 20250707
AND ftrx_no NOT IN (0)
AND ftrx_no >= 308930



SET 	
    @companyID := 'SHOST-10050582',
	@pubID := 'SHOST-10050582-0002',
	@termID := '0002',
	@saleDateFrom := '20250707',
	@saleDateTo := '20250714';