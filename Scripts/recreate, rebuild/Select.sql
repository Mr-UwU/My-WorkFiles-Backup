-- Select --------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------
SET 	
    @companyID := 'SHOST-10050582',
	@pubID := 'SHOST-10050582-0002',
	@termID := '0002',
	@saleDateFrom := '20250101',
	@saleDateTo := '20250610';


SELECT main.*
    FROM (
        SELECT
            pos.fzcounter
            ,a.fcompanyid AS fcompanyid
            ,pos.ftrx_no AS ftrx_no
            ,a.ftermid AS ftermid
            ,a.fpubid AS fpubid
            ,a.ftax_type AS ftax_type
            ,a.fsale_date AS fsale_date
            ,senior_data.senior_count AS senior
            ,pos.fcustomer_count AS cus_count
            ,pos.ftotal_discount AS ftotal_discount
            ,pos.fscdiscount AS fscdiscount
            ,pos.fdiscount1 AS fdiscount1
            ,pos.fline_scdiscount AS fline_scdiscount
            ,a.fdiscount4 AS fdiscount4
            
            ,'' AS "_"
            ,'' AS "_2"
            ,a.frecno AS frecno
            ,pos.fdocument_no

            ,'' AS "_3"
            ,pos.finc_sale AS finc_sale
            ,pos.fexc_sale AS fexc_sale
            -- IF ^ == EXPECTED TAX SALE then OK
            ,(pos.finc_sale + pos.fexc_sale) AS "inc + exc"
            ,CASE
                WHEN (pos.finc_sale + pos.fexc_sale) = pos.ftax_sale
                THEN "OK"
                ELSE "NOT OK"
            END AS "<->"

            ,pos.ftax_sale AS Tax_Sale

            ,CASE
                WHEN (pos.finc_sale + pos.fexc_sale) = pos.ftax_sale
                THEN "X"
                ELSE "-->>"
            END AS "Need Update?"
            
            ,CASE
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
                        THEN    SUM(
                                    CASE 
                                        WHEN (a.ftax_type = 0 AND a.fstatus_flag NOT IN ('V','W')) 
                                        THEN a.ftotal_line 
                                        ELSE 0 
                                    END
                                ) 
                                - 
                                (CASE 
                                    WHEN pos.fcustomer_count>senior_data.senior_count 
                                    THEN pos.ftotal_discount 
                                    ELSE 0 
                                END)
                        ELSE    ROUND(
                                    (pos.fsubtotal / pos.fcustomer_count) 
                                    * 
                                    (pos.fcustomer_count - COALESCE(senior_data.senior_count, 0))
                                ,2) 
                                - 
                                (CASE 
                                    WHEN pos.fcustomer_count>senior_data.senior_count 
                                    THEN pos.ftotal_discount 
                                    ELSE 0 
                                END)
                    END            
                )
            END AS ExpctdTaxSale
    
            ,'' AS "__"
            ,pos.fvat_exempt AS VAT_EXEMPT
            ,CASE 
                WHEN EXISTS (
                    SELECT 1 
                    FROM pos_sale_product sub 
                    WHERE sub.frecno = a.frecno 
                        AND sub.ftax_type = 4
                        AND sub.fpubid = a.fpubid
                        AND sub.ftermid = a.ftermid
                        AND sub.fcompanyid = a.fcompanyid
                ) 
                THEN    SUM(
                            CASE 
                                WHEN (a.ftax_type = 4 AND a.fstatus_flag NOT IN ('V','W')) 
                                THEN a.funitprice * a.fqty
                                ELSE 0 
                            END
                        ) 
                        - 
                        (CASE 
                            WHEN pos.fcustomer_count-senior_data.senior_count=0 
                            THEN pos.ftotal_discount 
                            ELSE 0 
                        END)
                ELSE    ROUND(
                            (
                                (pos.fsubtotal 
                                    - 
                                    (
                                        (pos.fsubtotal / pos.fcustomer_count) 
                                        * 
                                        (pos.fcustomer_count - COALESCE(senior_data.senior_count, 0))
                                    )
                                )
                                -
                                (CASE 
                                    WHEN pos.fcustomer_count-senior_data.senior_count=0 
                                    THEN pos.ftotal_discount 
                                    ELSE 0 
                                END)
                            ) / 1.12
                        ,6)
            END AS ExpctdVatExempt

            ,'' AS "___"
            ,pos.ftax AS Sales_Tax
            -- SHOULD BE EQUAL
            ,CASE
                WHEN 
                    pos.ftax
                    =
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
                            THEN    (SUM
                                        (CASE
                                            WHEN (a.ftax_type = 0 AND a.fstatus_flag NOT IN ('V','W')) 
                                            THEN a.ftotal_line 
                                            ELSE 0 
                                        END) 
                                        - 
                                        (CASE 
                                            WHEN pos.fcustomer_count>senior_data.senior_count 
                                            THEN pos.ftotal_discount 
                                            ELSE 0 
                                        END)
                                    ) / 1.12 * 0.12
                            ELSE    (ROUND
                                        (
                                            (pos.fsubtotal / pos.fcustomer_count) 
                                            * 
                                            (pos.fcustomer_count - COALESCE(senior_data.senior_count, 0))
                                        ,2) 
                                        - 
                                        (CASE 
                                            WHEN pos.fcustomer_count>senior_data.senior_count 
                                            THEN pos.ftotal_discount 
                                            ELSE 0 
                                        END)    
                                    ) / 1.12 * 0.12
                            END            
                        )
                        END
                THEN "OK"
                ELSE "NOT OK"			 
            END AS "<<->>"

            ,CASE
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
                        THEN    (SUM
                                    (CASE 
                                        WHEN (a.ftax_type = 0 AND a.fstatus_flag NOT IN ('V','W')) 
                                        THEN a.ftotal_line 
                                        ELSE 0 
                                    END) 
                                    - 
                                    (CASE 
                                        WHEN pos.fcustomer_count>senior_data.senior_count 
                                        THEN pos.ftotal_discount 
                                        ELSE 0 
                                    END)
                                ) / 1.12 * 0.12
                        ELSE    (ROUND
                                    (
                                        (pos.fsubtotal / pos.fcustomer_count) 
                                        * 
                                        (pos.fcustomer_count - COALESCE(senior_data.senior_count, 0))
                                    ,2) 
                                    - 
                                    (CASE 
                                        WHEN pos.fcustomer_count>senior_data.senior_count 
                                        THEN pos.ftotal_discount 
                                        ELSE 0 
                                    END)
                                ) / 1.12 * 0.12
                    END            
                )
            END AS ExpctdSalesTax

        FROM pos_sale_product a 
        LEFT JOIN pos_sale pos
            ON pos.fpubid = a.fpubid 
            AND pos.frecno = a.frecno
        LEFT JOIN (
            SELECT ps.fcompanyid AS fcompanyid, ps.ftermid AS ftermid, ps.frecno AS frecno, ps.fpubid AS fpubid,
                CASE 
                    WHEN ps.fcustomer_count < 0
                    THEN -ROUND(SUM((ps.fscratio * ABS(ps.fcustomer_count)) + COALESCE(psi.fint_data,0)),0)
                    ELSE ROUND(SUM((ps.fscratio * ps.fcustomer_count) + COALESCE(psi.fint_data,0)),0) 
                END AS senior_count
            FROM pos_sale ps
            LEFT JOIN pos_sale_info psi ON (ps.fcompanyid=psi.fcompanyid AND ps.fpubid=psi.fpubid AND ps.frecno=psi.frecno AND psi.fcode1='SALE' AND psi.fcode2='#PWD')
            WHERE ps.fcompanyid = @companyID 
                AND ps.fpubid = @pubID
                AND ps.ftermid = @termID
            GROUP BY fcompanyid, ftermid, frecno
        ) senior_data 
            ON a.fcompanyid = senior_data.fcompanyid 
            AND a.fpubid = senior_data.fpubid 
            AND a.ftermid = senior_data.ftermid
            AND a.frecno = senior_data.frecno
        WHERE a.fcompanyid = @companyID
            AND a.fpubid = @pubID
            AND a.ftermid = @termID
            AND pos.ftrx_no != 0
            AND pos.fsale_date >= @saleDateFrom
            AND pos.fsale_date <= @saleDateTo
            AND pos.fcustomer_count <> 0
            AND NOT (pos.fscdiscount <> 0 AND pos.fline_scdiscount <> 0)
        GROUP BY a.frecno
    ) main 
    WHERE main.Tax_Sale <> main.ExpctdTaxSale 
        OR main.VAT_EXEMPT <> main.ExpctdVatExempt;
    -- --------------------------------------------------------------------------------------------------------------