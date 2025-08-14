SELECT main.*
FROM (
    SELECT
        p.fsale_date,
        p.fzcounter,
        (p.ftax_sale - p.fptax_sale) AS ftax_sale,
        ROUND(p.ftax - p.fptax, 2) AS ftax,
        ROUND((p.ftax_sale - p.fptax_sale)/1.12 * 0.12, 2) AS cal_ftax
    FROM pos_reading p
    WHERE p.fzcounter >= '1'
    AND p.fcompanyid = 'SHOST-10050582'
    AND p.ftermid = '0002'
) AS main
WHERE CASE WHEN main.cal_ftax > main.ftax THEN main.cal_ftax - main.ftax ELSE main.ftax - main.cal_ftax END > 0.05
 
 
SELECT main.*
FROM (
    SELECT
        fdocument_no,
        frecno,
        ROUND(p.ftax_sale / 1.12 * 0.12,2) AS cal_ftax,
        p.ftax AS ftax
    FROM pos_sale p
    WHERE p.fsale_date >= '20250301'
    AND p.fcompanyid = 'SHOST-10050582'
    AND p.ftermid = '0002'
) AS main
WHERE CASE WHEN main.cal_ftax > main.ftax THEN main.cal_ftax - main.ftax ELSE main.ftax - main.cal_ftax END > 0.05



SELECT main.*
FROM (
    SELECT
        fdocument_no,
        frecno,
        p.ftax_sale,
        p.fnotax_sale,
        p.fvat_exempt,
        ROUND((p.ftax_sale + p.fnotax_sale + p.fvat_exempt) - (fscdiscount + fdiscount1 + fline_scdiscount),2) AS fcal_fgross,
        ROUND(p.fgross,2) AS fgross,
        p.ftax AS ftax
    FROM pos_sale p
    WHERE p.fsale_date >= '20250410'
    AND p.fcompanyid = 'SHOST-25031484'
    AND p.ftermid = '0001'
) AS main
WHERE CASE WHEN main.fcal_fgross > main.fgross THEN main.fcal_fgross - main.fgross ELSE main.fgross - main.fcal_fgross END > 0.05
 
SELECT * FROM sm_company 
 
SELECT main.*
FROM (
    SELECT
        p.fsale_date,
        p.fzcounter,
        (p.fgross - p.fpgross) AS gross_diff,
 
        IFNULL(SUM(s.fvat_exempt), 0) AS vat_exempt,
        IFNULL(SUM(s.fdiscount1), 0) AS pwd_discount,
        IFNULL(SUM(s.fscdiscount + s.fline_scdiscount), 0) AS senior_discount,
        IFNULL(SUM(fdiscount2),0)  AS fdiscount2,
        IFNULL(SUM(s.ftax_sale), 0) AS tax_sale,
        IFNULL(SUM(CASE
            WHEN info.fcode1 = 'SALE' AND info.fcode2 = 'NACD'
            THEN info.fdbl_data ELSE 0
        END), 0) AS nac_discount,
 
	CASE
		WHEN 
			ROUND((p.fgross - p.fpgross), 2)
			=
			ROUND(
			    (SUM(s.fvat_exempt) - SUM(s.fdiscount1) - SUM(fdiscount2) - SUM(s.fscdiscount + s.fline_scdiscount))
			    + (SUM(s.ftax_sale) - SUM(CASE
				WHEN info.fcode1 = 'SALE' AND info.fcode2 = 'NACD'
				THEN info.fdbl_data ELSE 0
			    END)),
			    2
			)
		THEN "OK"
		ELSE "NOT OK"
	END AS checker
	
        ,ROUND(
            (SUM(s.fvat_exempt) - SUM(s.fdiscount1) - SUM(fdiscount2) - SUM(s.fscdiscount + s.fline_scdiscount))
            + (SUM(s.ftax_sale) - SUM(CASE
                WHEN info.fcode1 = 'SALE' AND info.fcode2 = 'NACD'
                THEN info.fdbl_data ELSE 0
            END)),
            2
        ) AS calc_gross
 
    FROM pos_reading p
    LEFT JOIN pos_sale s
        ON s.fcompanyid = p.fcompanyid
        AND s.fzcounter = p.fzcounter
        AND s.fsale_date = p.fsale_date
        AND s.ftrx_no != 0
        AND s.fvoid_flag = 0
    LEFT JOIN pos_sale_info info
        ON info.fcompanyid = s.fcompanyid
        AND info.fpubid = s.fpubid
        AND info.frecno = s.frecno
        AND info.fcode1 = 'SALE'
        AND info.fcode2 = 'NACD'
    WHERE p.fzcounter >= '1'
      AND s.fcompanyid = 'SHOST-10050582'
      AND s.fpubid = 'SHOST-10050582-0002'
      AND p.ftermid = '0002'
    GROUP BY p.fsale_date, p.fzcounter, p.fpgross, p.fgross
) AS main
WHERE CASE WHEN ROUND(main.gross_diff,2) > ROUND(main.calc_gross,2) THEN ROUND(main.gross_diff,2) - ROUND(main.calc_gross,2) ELSE ROUND(main.calc_gross,2) - ROUND(main.gross_diff,2) END > 0.05