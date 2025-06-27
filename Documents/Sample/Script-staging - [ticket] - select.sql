http://stmama.alliancewebpos.net

fcompanyid=STMAMA-22062783
ftermid=0013
fcreate_flag=1
fsale_date=20250101
fend_date=20250526
fzcounter=456
force=1



-------------------------------------------------- 
-- recreate_pos_hourly_sum.php
--------------------------------------------------
http://stmama.alliancewebpos.net/appserv/app/batch/fix/recreate_pos_hourly_sum.php?fcompanyid=STMAMA-22062783&ftermid=0013&fzcounter=456&fpassword=5678efgh&fsale_date=20250101&fend_date=20250526
--------------------------------------------------



-------------------------------------------------- 
-- recreate_reading.php
-- for when sales are missing or incorrect
--------------------------------------------------
http://stmama.alliancewebpos.net/appserv/app/batch/fix/recreate_reading.php?fcompanyid=STMAMA-22062783&ftermid=0013&fcreate_flag=1&fsale_date=20250101&fend_date=20250526&fzcounter=456&force=1
--------------------------------------------------



-------------------------------------------------- 
-- rebuild_reading.php
--------------------------------------------------
http://stmama.alliancewebpos.net/appserv/app/batch/fix/rebuild_reading.php?fcompanyid=STMAMA-22062783&ftermid=0013&fsale_date=20250101&fend_date=20250522&fpassword=5678efgh&fzcounter=456
--------------------------------------------------


-- SELECT --
{
    SELECT main.*
    FROM (
        SELECT
            a.fcompanyid AS fcompanyid,
            pos.ftrx_no AS ftrx_no,
            a.ftermid AS ftermid,
            a.fpubid AS fpubid,
            a.frecno AS frecno,
            a.ftax_type AS ftax_type,
            a.fsale_date AS fsale_date,
            pos.fvat_exempt AS VAT_EXEMPT,
            pos.ftax_sale AS Tax_Sale,
            pos.ftax AS Sales_Tax,
            senior_data.senior_count AS senior,
            pos.fcustomer_count AS cus_count,
            pos.ftotal_discount AS ftotal_discount,
            pos.fscdiscount AS fscdiscount,
            pos.fdiscount1 AS fdiscount1,
            pos.fline_scdiscount AS fline_scdiscount,
            a.fdiscount4 AS fdiscount4,
            CASE
                WHEN EXISTS (
            SELECT 1 
            FROM pos_sale_product sub 
            WHERE sub.frecno = a.frecno 
            AND sub.fdiscount4 <> 0
            AND sub.fpubid = a.fpubid
            AND sub.ftermid = a.ftermid
            AND sub.fcompanyid = a.fcompanyid
            )
                THEN pos.ftax_sale
                ELSE (
            CASE 
                WHEN EXISTS (
                SELECT 1 
                FROM pos_sale_product sub 
                WHERE sub.frecno = a.frecno 
                AND sub.ftax_type = 4
                AND sub.fpubid = a.fpubid
                AND sub.ftermid = a.ftermid
                AND sub.fcompanyid = a.fcompanyid
                ) 
                THEN SUM(CASE WHEN (a.ftax_type = 0 AND a.fstatus_flag NOT IN ('V','W')) THEN a.ftotal_line ELSE 0 END) - (CASE WHEN pos.fcustomer_count>senior_data.senior_count THEN pos.ftotal_discount ELSE 0 END)
                ELSE ROUND((pos.fsubtotal / pos.fcustomer_count) * 
                (pos.fcustomer_count - COALESCE(senior_data.senior_count, 0)), 2) - (CASE WHEN pos.fcustomer_count>senior_data.senior_count THEN pos.ftotal_discount ELSE 0 END)
            END            
                )
            END AS ExpctdTaxSale,
    
            CASE 
                WHEN EXISTS (
                    SELECT 1 
                    FROM pos_sale_product sub 
                    WHERE sub.frecno = a.frecno 
                    AND sub.ftax_type = 4
                    AND sub.fpubid = a.fpubid
                    AND sub.ftermid = a.ftermid
                    AND sub.fcompanyid = a.fcompanyid
                ) 
                THEN SUM(CASE WHEN (a.ftax_type = 4 AND a.fstatus_flag NOT IN ('V','W')) THEN a.funitprice * a.fqty ELSE 0 END) - (CASE WHEN pos.fcustomer_count-senior_data.senior_count=0 THEN pos.ftotal_discount ELSE 0 END)
                ELSE ROUND(((pos.fsubtotal - ((pos.fsubtotal / pos.fcustomer_count) * 
                    (pos.fcustomer_count - COALESCE(senior_data.senior_count, 0))))-(CASE WHEN pos.fcustomer_count-senior_data.senior_count=0 THEN pos.ftotal_discount ELSE 0 END)) / 1.12, 6)
            END AS ExpctdVatExempt,
            CASE
                WHEN EXISTS (
            SELECT 1 
            FROM pos_sale_product sub 
            WHERE sub.frecno = a.frecno 
            AND sub.fdiscount4 <> 0
            AND sub.fpubid = a.fpubid
            AND sub.ftermid = a.ftermid
            AND sub.fcompanyid = a.fcompanyid
            )
                THEN pos.ftax_sale / 1.12 * 0.12
                ELSE (
            CASE 
                WHEN EXISTS (
                SELECT 1 
                FROM pos_sale_product sub 
                WHERE sub.frecno = a.frecno 
                AND sub.ftax_type = 4
                AND sub.fpubid = a.fpubid
                AND sub.ftermid = a.ftermid
                AND sub.fcompanyid = a.fcompanyid
                ) 
                THEN (SUM(CASE WHEN (a.ftax_type = 0 AND a.fstatus_flag NOT IN ('V','W')) THEN a.ftotal_line ELSE 0 END) - (CASE WHEN pos.fcustomer_count>senior_data.senior_count THEN pos.ftotal_discount ELSE 0 END)) / 1.12 * 0.12
                ELSE (ROUND((pos.fsubtotal / pos.fcustomer_count) * 
                (pos.fcustomer_count - COALESCE(senior_data.senior_count, 0)), 2) - (CASE WHEN pos.fcustomer_count>senior_data.senior_count THEN pos.ftotal_discount ELSE 0 END)) / 1.12 * 0.12
            END            
                )
            END AS ExpctdSalesTax
        FROM pos_sale_product a 
        LEFT JOIN pos_sale pos
            ON pos.fpubid = a.fpubid 
            AND pos.frecno = a.frecno
        LEFT JOIN (
            SELECT ps.fcompanyid AS fcompanyid, ps.ftermid AS ftermid, ps.frecno AS frecno, ps.fpubid AS fpubid,
            CASE WHEN ps.fcustomer_count < 0
            THEN -ROUND(SUM((ps.fscratio * ABS(ps.fcustomer_count)) + COALESCE(psi.fint_data,0)),0)
            ELSE ROUND(SUM((ps.fscratio * ps.fcustomer_count) + COALESCE(psi.fint_data,0)),0) 
            END AS senior_count
            FROM pos_sale ps
            LEFT JOIN pos_sale_info psi ON (ps.fcompanyid=psi.fcompanyid AND ps.fpubid=psi.fpubid AND ps.frecno=psi.frecno AND psi.fcode1='SALE' AND psi.fcode2='#PWD')
            WHERE ps.fcompanyid = 'STMAMA-22062783' 
            AND ps.fpubid = 'STMAMA-22062783-0013'
            AND ps.ftermid = '0013'
            GROUP BY fcompanyid, ftermid, frecno
        ) senior_data 
        ON a.fcompanyid = senior_data.fcompanyid 
        AND a.fpubid = senior_data.fpubid 
        AND a.ftermid = senior_data.ftermid
        AND a.frecno = senior_data.frecno
        WHERE a.fcompanyid = 'STMAMA-22062783'
        AND a.fpubid = 'STMAMA-22062783-0013'
            AND a.ftermid = '0013'
            AND pos.ftrx_no != 0
            AND pos.fsale_date >= '20250101'
            AND pos.fsale_date <= '20250526'
            AND pos.fcustomer_count <> 0
            AND NOT (pos.fscdiscount <> 0 AND pos.fline_scdiscount <> 0)
        GROUP BY a.frecno
    ) main WHERE main.Tax_Sale <> main.ExpctdTaxSale OR main.VAT_EXEMPT <> main.ExpctdVatExempt;
}

-- UPDATE --
{
    UPDATE pos_sale pos
    JOIN (
        SELECT
            a.fcompanyid AS fcompanyid,
            pos.ftrx_no AS ftrx_no,
            a.ftermid AS ftermid,
            a.fpubid AS fpubid,
            a.frecno AS frecno,
            CASE
                WHEN EXISTS (
                    SELECT 1 
                    FROM pos_sale_product sub 
                    WHERE sub.frecno = a.frecno 
                    AND sub.fdiscount4 <> 0
                    AND sub.fpubid = a.fpubid
                    AND sub.ftermid = a.ftermid
                    AND sub.fcompanyid = a.fcompanyid
                )
                THEN pos.ftax_sale

                ELSE (
                    CASE 
                        WHEN EXISTS (
                            SELECT 1 
                            FROM pos_sale_product sub 
                            WHERE sub.frecno = a.frecno 
                            AND sub.ftax_type = 4
                            AND sub.fpubid = a.fpubid
                            AND sub.ftermid = a.ftermid
                            AND sub.fcompanyid = a.fcompanyid
                        ) 
                        THEN SUM(CASE WHEN (a.ftax_type = 0 AND a.fstatus_flag NOT IN ('V','W')) THEN a.ftotal_line ELSE 0 END) - (CASE WHEN pos.fexc_sale<>0 OR pos.finc_sale<>0 THEN pos.ftotal_discount ELSE 0 END)
                        ELSE ROUND((pos.fsubtotal / pos.fcustomer_count) * 
                        (pos.fcustomer_count - COALESCE(senior_data.senior_count, 0)), 2) - (CASE WHEN pos.fexc_sale<>0 OR pos.finc_sale<>0 THEN pos.ftotal_discount ELSE 0 END)
                END            
                )
            END AS ExpctdTaxSale,

            CASE 
                WHEN EXISTS (
                    SELECT 1 
                    FROM pos_sale_product sub 
                    WHERE sub.frecno = a.frecno 
                    AND sub.ftax_type = 4
                    AND sub.fpubid = a.fpubid
                    AND sub.ftermid = a.ftermid
                    AND sub.fcompanyid = a.fcompanyid
                ) 
                THEN SUM(CASE WHEN (a.ftax_type = 4 AND a.fstatus_flag NOT IN ('V','W')) THEN a.funitprice * a.fqty ELSE 0 END) - (CASE WHEN pos.fexc_sale=0 AND pos.finc_sale=0 THEN pos.ftotal_discount ELSE 0 END)
                ELSE ROUND(((pos.fsubtotal - ((pos.fsubtotal / pos.fcustomer_count) * 
                    (pos.fcustomer_count - COALESCE(senior_data.senior_count, 0))))-(CASE WHEN pos.fexc_sale=0 AND pos.finc_sale=0 THEN pos.ftotal_discount ELSE 0 END)) / 1.12, 6)
            END AS ExpctdVatExempt,
            
            CASE
                WHEN EXISTS (
                    SELECT 1 
                    FROM pos_sale_product sub 
                    WHERE sub.frecno = a.frecno 
                    AND sub.fdiscount4 <> 0
                    AND sub.fpubid = a.fpubid
                    AND sub.ftermid = a.ftermid
                    AND sub.fcompanyid = a.fcompanyid
                )
                THEN pos.ftax_sale / 1.12 * 0.12
                ELSE (
                    CASE 
                        WHEN EXISTS (
                        SELECT 1 
                        FROM pos_sale_product sub 
                        WHERE sub.frecno = a.frecno 
                        AND sub.ftax_type = 4
                        AND sub.fpubid = a.fpubid
                        AND sub.ftermid = a.ftermid
                        AND sub.fcompanyid = a.fcompanyid
                        ) 
                    THEN (SUM(CASE WHEN (a.ftax_type = 0 AND a.fstatus_flag NOT IN ('V','W')) THEN a.ftotal_line ELSE 0 END) - (CASE WHEN pos.fexc_sale<>0 OR pos.finc_sale<>0 THEN pos.ftotal_discount ELSE 0 END)) / 1.12 * 0.12
                    ELSE (ROUND((pos.fsubtotal / pos.fcustomer_count) * 
                (pos.fcustomer_count - COALESCE(senior_data.senior_count, 0)), 2) - (CASE WHEN pos.fexc_sale<>0 OR pos.finc_sale<>0 THEN pos.ftotal_discount ELSE 0 END)) / 1.12 * 0.12
                END            
                )
            END AS ExpctdSalesTax

        FROM pos_sale_product a 
        LEFT JOIN pos_sale pos
            ON pos.fpubid = a.fpubid 
            AND pos.frecno = a.frecno
        LEFT JOIN (
            SELECT ps.fcompanyid AS fcompanyid, ps.ftermid AS ftermid, ps.frecno AS frecno, ps.fpubid AS fpubid,
            CASE WHEN ps.fcustomer_count < 0
            THEN -ROUND(SUM((ps.fscratio * ABS(ps.fcustomer_count)) + COALESCE(psi.fint_data,0)),0)
            ELSE ROUND(SUM((ps.fscratio * ps.fcustomer_count) + COALESCE(psi.fint_data,0)),0) 
            END AS senior_count
            FROM pos_sale ps
            LEFT JOIN pos_sale_info psi ON (ps.fcompanyid=psi.fcompanyid AND ps.fpubid=psi.fpubid AND ps.frecno=psi.frecno AND psi.fcode1='SALE' AND psi.fcode2='#PWD')
            WHERE ps.fcompanyid = 'STMAMA-22062783' 
            AND ps.fpubid = 'STMAMA-22062783-0013'
            AND ps.ftermid = '0013'
            GROUP BY fcompanyid, ftermid, frecno
        ) senior_data 
        ON a.fcompanyid = senior_data.fcompanyid 
        AND a.fpubid = senior_data.fpubid 
        AND a.ftermid = senior_data.ftermid
        AND a.frecno = senior_data.frecno
        WHERE a.fcompanyid = 'STMAMA-22062783'
        AND a.fpubid = 'STMAMA-22062783-0013'
            AND a.ftermid = '0013'
            AND pos.ftrx_no != 0
            AND pos.fsale_date >= '20250101'
            AND pos.fsale_date <= '20250526'
            AND pos.fcustomer_count <> 0
            AND NOT (pos.fscdiscount <> 0 AND pos.fline_scdiscount <> 0)
        GROUP BY a.frecno
    ) main
    ON pos.fcompanyid = main.fcompanyid
    AND pos.ftermid = main.ftermid 
    AND pos.fpubid = main.fpubid
    AND pos.frecno = main.frecno
    SET pos.ftax = main.ExpctdSalesTax,
        pos.ftax_sale = main.ExpctdTaxSale,
        pos.fvat_exempt = main.ExpctdVatExempt;
}
