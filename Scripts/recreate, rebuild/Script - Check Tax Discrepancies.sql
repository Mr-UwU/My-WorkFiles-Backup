-- Select --------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------
SET 	
    @companyID := 'SHOST-10050582',
	@pubID := 'SHOST-10050582-0002',
	@termID := '0002',
	@saleDateFrom := '20250101',
	@saleDateTo := '20250510';


SELECT main.*
    FROM (
        SELECT
            pos.fzcounter
            ,a.fpubid AS fpubid
            ,' ' AS '.'
            ,a.fsale_date AS fsale_date
            ,a.ftax_type AS ftax_type
            ,' ' AS '..'
            ,pos.fcustomer_count AS customers
            ,senior_data.senior_count AS seniors

            ,ABS((fscratio * fcustomer_count)) AS Seniors_only
            ,(senior_data.senior_count) - ABS((fscratio * fcustomer_count)) as PWD
            ,pos.fscdiscount AS fscdiscount

            -- ,pos.ftotal_discount AS ftotal_discount
            -- ,pos.fdiscount1 AS fdiscount1
            -- ,pos.fline_scdiscount AS fline_scdiscount
            -- ,a.fdiscount4 AS fdiscount4
            
            ,' ' AS '...'
            ,' ' AS '....'
            ,a.frecno AS frecno
            ,pos.ftrx_no AS ftrx_no

            ,' ' AS '.....'

            -- Tax Sale --------------------------------------------------
            -- --------------------------------------------------
            ,pos.finc_sale AS finc_sale
            ,pos.fexc_sale AS fexc_sale

            ,(pos.finc_sale + pos.fexc_sale) AS "inc + exc"

            -- inc + exc sale should be equal to tax sale
            ,CASE
                WHEN (pos.finc_sale + pos.fexc_sale) = pos.ftax_sale
                THEN "<- OK ->"
                ELSE "NOT EQUAL"
            END AS "Checker Tax Sale 1"


            ,' ' AS "...................."

            ,ROUND(pos.ftax_sale, 4) AS Tax_Sale
            -- --------------------------------------------------

           
            
            -- checker tax sale --------------------------------------------------
            -- --------------------------------------------------
            ,CASE
                WHEN ( 
                    pos.ftax_sale 
                    = 
                    (
                        CASE
                            WHEN EXISTS (
                                SELECT 1 
                                FROM pos_sale_product psd
                                WHERE psd.frecno = pos.frecno
                                    AND psd.fpubid = pos.fpubid
                                    AND psd.ftermid = pos.ftermid
                                    AND psd.fcompanyid = pos.fcompanyid
                            )
                            THEN (
                                ROUND(
                                    (
                                        (
                                            (
                                                SELECT 
                                                    SUM(
                                                        CASE
                                                            WHEN sub.ftax_type = 0
                                                                AND sub.fstatus_flag NOT IN ('V','W')
                                                            THEN sub.ftotal_line 
                                                            ELSE 0
                                                        END
                                                    )
                                                FROM pos_sale_product sub 
                                                WHERE sub.frecno = a.frecno 
                                                    AND sub.fpubid = a.fpubid
                                                    AND sub.ftermid = a.ftermid
                                                    AND sub.fcompanyid = a.fcompanyid
                                            ) 
                                            + 
                                            (
                                                (
                                                    SELECT 
                                                        SUM(
                                                            CASE
                                                                WHEN sub.ftax_type = 1
                                                                    AND sub.fstatus_flag NOT IN ('V','W')
                                                                THEN sub.ftotal_line 
                                                                ELSE 0
                                                            END
                                                        )
                                                    FROM pos_sale_product sub 
                                                    WHERE sub.frecno = a.frecno 
                                                        AND sub.fpubid = a.fpubid
                                                        AND sub.ftermid = a.ftermid
                                                        AND sub.fcompanyid = a.fcompanyid
                                                ) * 1.12
                                            )
                                        )
                                        / pos.fcustomer_count
                                        * (pos.fcustomer_count 
                                            -   (
                                                    CASE 
                                                        WHEN pos.fcustomer_count > 0 
                                                        THEN (
                                                            SELECT COUNT(*)
                                                            FROM pos_sale_product pss
                                                            WHERE pss.frecno = a.frecno 
                                                                AND pss.fpubid = a.fpubid
                                                                AND pss.ftermid = a.ftermid
                                                                AND pss.fcompanyid = a.fcompanyid
                                                                AND pss.ftype IN (0,1)
                                                        ) 
                                                        ELSE 0 
                                                    END
                                                )
                                        )
                                    ) 
                                    - pos.ftotal_discount
                                        -- pos.fsubtotal * (pos.fdiscp/100)
                                , 4)
                            )
                            ELSE (
                                ROUND(
                                    (
                                        (
                                            (
                                                SELECT 
                                                    SUM(
                                                        CASE
                                                            WHEN sub.ftax_type = 0
                                                                AND sub.fstatus_flag NOT IN ('V','W')
                                                            THEN sub.ftotal_line 
                                                            ELSE 0
                                                        END
                                                    )
                                                FROM pos_sale_product sub 
                                                WHERE sub.frecno = a.frecno 
                                                    AND sub.fpubid = a.fpubid
                                                    AND sub.ftermid = a.ftermid
                                                    AND sub.fcompanyid = a.fcompanyid
                                            ) 
                                            + 
                                            (
                                                (
                                                    SELECT 
                                                        SUM(
                                                            CASE
                                                                WHEN sub.ftax_type = 1
                                                                    AND sub.fstatus_flag NOT IN ('V','W')
                                                                THEN sub.ftotal_line 
                                                                ELSE 0
                                                            END
                                                        )
                                                    FROM pos_sale_product sub 
                                                    WHERE sub.frecno = a.frecno 
                                                        AND sub.fpubid = a.fpubid
                                                        AND sub.ftermid = a.ftermid
                                                        AND sub.fcompanyid = a.fcompanyid
                                                ) * 1.12
                                            )
                                        )
                                        / pos.fcustomer_count
                                        * (pos.fcustomer_count 
                                            -   (
                                                    CASE 
                                                        WHEN pos.fcustomer_count > 0 
                                                        THEN (
                                                            SELECT COUNT(*)
                                                            FROM pos_sale_product pss
                                                            WHERE pss.frecno = a.frecno 
                                                                AND pss.fpubid = a.fpubid
                                                                AND pss.ftermid = a.ftermid
                                                                AND pss.fcompanyid = a.fcompanyid
                                                                AND pss.ftype IN (0,1)
                                                        ) 
                                                        ELSE 0 
                                                    END
                                                )
                                        )
                                    ) 
                                    - pos.ftotal_discount
                                        -- pos.fsubtotal * (pos.fdiscp/100)
                                , 4)
                            )
                        END
                    )
                )
                THEN "<- OK ->"
                ELSE "NOT EQUAL"
            END AS "Checker Tax Sale"
            -- --------------------------------------------------

            -- Expected Tax Sale --------------------------------------------------
            -- --------------------------------------------------
            ,CASE
                WHEN EXISTS (
                    SELECT 1 
                    FROM pos_sale_product psd
                    WHERE psd.frecno = pos.frecno
                        AND psd.fpubid = pos.fpubid
                        AND psd.ftermid = pos.ftermid
                        AND psd.fcompanyid = pos.fcompanyid
                )
                THEN (
                    ROUND(
                        (
                            (
                                (
                                    SELECT 
                                        SUM(
                                            CASE
                                                WHEN sub.ftax_type = 0
                                                    AND sub.fstatus_flag NOT IN ('V','W')
                                                THEN sub.ftotal_line 
                                                ELSE 0
                                            END
                                        )
                                    FROM pos_sale_product sub 
                                    WHERE sub.frecno = a.frecno 
                                        AND sub.fpubid = a.fpubid
                                        AND sub.ftermid = a.ftermid
                                        AND sub.fcompanyid = a.fcompanyid
                                ) 
                                + 
                                (
                                    (
                                        SELECT 
                                            SUM(
                                                CASE
                                                    WHEN sub.ftax_type = 1
                                                        AND sub.fstatus_flag NOT IN ('V','W')
                                                    THEN sub.ftotal_line 
                                                    ELSE 0
                                                END
                                            )
                                        FROM pos_sale_product sub 
                                        WHERE sub.frecno = a.frecno 
                                            AND sub.fpubid = a.fpubid
                                            AND sub.ftermid = a.ftermid
                                            AND sub.fcompanyid = a.fcompanyid
                                    ) * 1.12
                                )
                            )
                            / pos.fcustomer_count
                            * (pos.fcustomer_count 
                                -   (
                                        CASE 
                                            WHEN pos.fcustomer_count > 0 
                                            THEN (
                                                SELECT COUNT(*)
                                                FROM pos_sale_product pss
                                                WHERE pss.frecno = a.frecno 
                                                    AND pss.fpubid = a.fpubid
                                                    AND pss.ftermid = a.ftermid
                                                    AND pss.fcompanyid = a.fcompanyid
                                                    AND pss.ftype IN (0,1)
                                            ) 
                                            ELSE 0 
                                        END
                                    )
                            )
                        ) 
                        - pos.ftotal_discount
                            -- pos.fsubtotal * (pos.fdiscp/100)
                    , 4)
                )
                ELSE (
                    ROUND(
                        (
                            (
                                (
                                    SELECT 
                                        SUM(
                                            CASE
                                                WHEN sub.ftax_type = 0
                                                    AND sub.fstatus_flag NOT IN ('V','W')
                                                THEN sub.ftotal_line 
                                                ELSE 0
                                            END
                                        )
                                    FROM pos_sale_product sub 
                                    WHERE sub.frecno = a.frecno 
                                        AND sub.fpubid = a.fpubid
                                        AND sub.ftermid = a.ftermid
                                        AND sub.fcompanyid = a.fcompanyid
                                ) 
                                + 
                                (
                                    (
                                        SELECT 
                                            SUM(
                                                CASE
                                                    WHEN sub.ftax_type = 1
                                                        AND sub.fstatus_flag NOT IN ('V','W')
                                                    THEN sub.ftotal_line 
                                                    ELSE 0
                                                END
                                            )
                                        FROM pos_sale_product sub 
                                        WHERE sub.frecno = a.frecno 
                                            AND sub.fpubid = a.fpubid
                                            AND sub.ftermid = a.ftermid
                                            AND sub.fcompanyid = a.fcompanyid
                                    ) * 1.12
                                )
                            )
                            / pos.fcustomer_count
                            * (pos.fcustomer_count 
                                -   (
                                        CASE 
                                            WHEN pos.fcustomer_count > 0 
                                            THEN (
                                                SELECT COUNT(*)
                                                FROM pos_sale_product pss
                                                WHERE pss.frecno = a.frecno 
                                                    AND pss.fpubid = a.fpubid
                                                    AND pss.ftermid = a.ftermid
                                                    AND pss.fcompanyid = a.fcompanyid
                                                    AND pss.ftype IN (0,1)
                                            ) 
                                            ELSE 0 
                                        END
                                    )
                            )
                        ) 
                        - pos.ftotal_discount
                            -- pos.fsubtotal * (pos.fdiscp/100)
                    , 4)
                )
            END AS Expected_TaxSale
            -- --------------------------------------------------
    


            ,'' AS "....................1"

            -- Sales Tax --------------------------------------------------
            -- --------------------------------------------------  

            ,ROUND(pos.ftax, 4) AS Sales_Tax
            -- SHOULD BE EQUAL

            ,CASE
                WHEN (
                    pos.ftax
                    =
                    (
                        CASE
                            WHEN EXISTS (
                                SELECT 1 
                                FROM pos_sale_product psd
                                WHERE psd.frecno = pos.frecno
                                    AND psd.fpubid = pos.fpubid
                                    AND psd.ftermid = pos.ftermid
                                    AND psd.fcompanyid = pos.fcompanyid
                            )
                            THEN (
                                ROUND(
                                    (
                                        (
                                            (
                                                (
                                                    SELECT 
                                                        SUM(
                                                            CASE
                                                                WHEN sub.ftax_type = 0
                                                                    AND sub.fstatus_flag NOT IN ('V','W')
                                                                THEN sub.ftotal_line 
                                                                ELSE 0
                                                            END
                                                        )
                                                    FROM pos_sale_product sub 
                                                    WHERE sub.frecno = a.frecno 
                                                        AND sub.fpubid = a.fpubid
                                                        AND sub.ftermid = a.ftermid
                                                        AND sub.fcompanyid = a.fcompanyid
                                                ) 
                                                + 
                                                (
                                                    (
                                                        SELECT 
                                                            SUM(
                                                                CASE
                                                                    WHEN sub.ftax_type = 1
                                                                        AND sub.fstatus_flag NOT IN ('V','W')
                                                                    THEN sub.ftotal_line 
                                                                    ELSE 0
                                                                END
                                                            )
                                                        FROM pos_sale_product sub 
                                                        WHERE sub.frecno = a.frecno 
                                                            AND sub.fpubid = a.fpubid
                                                            AND sub.ftermid = a.ftermid
                                                            AND sub.fcompanyid = a.fcompanyid
                                                    ) * 1.12
                                                )
                                            )
                                            / pos.fcustomer_count
                                            * (pos.fcustomer_count
                                            -   (
                                                    CASE 
                                                        WHEN pos.fcustomer_count > 0 
                                                        THEN (
                                                            SELECT COUNT(*)
                                                            FROM pos_sale_product pss
                                                            WHERE pss.frecno = a.frecno 
                                                                AND pss.fpubid = a.fpubid
                                                                AND pss.ftermid = a.ftermid
                                                                AND pss.fcompanyid = a.fcompanyid
                                                                AND pss.ftype IN (0,1)
                                                        ) 
                                                        ELSE 0 
                                                    END
                                                )
                                            )
                                        ) 
                                        - pos.ftotal_discount
                                        --    pos.fsubtotal * (pos.fdiscp/100)
                                    )
                                    / 1.12 * 0.12
                                , 4)
                            )
                            ELSE 
                                ROUND(
                                    (
                                        (
                                            (
                                                (
                                                    SELECT 
                                                        SUM(
                                                            CASE
                                                                WHEN sub.ftax_type = 0
                                                                    AND sub.fstatus_flag NOT IN ('V','W')
                                                                THEN sub.ftotal_line 
                                                                ELSE 0
                                                            END
                                                        )
                                                    FROM pos_sale_product sub 
                                                    WHERE sub.frecno = a.frecno 
                                                        AND sub.fpubid = a.fpubid
                                                        AND sub.ftermid = a.ftermid
                                                        AND sub.fcompanyid = a.fcompanyid
                                                ) 
                                                + 
                                                (
                                                    (
                                                        SELECT 
                                                            SUM(
                                                                CASE
                                                                    WHEN sub.ftax_type = 1
                                                                        AND sub.fstatus_flag NOT IN ('V','W')
                                                                    THEN sub.ftotal_line 
                                                                    ELSE 0
                                                                END
                                                            )
                                                        FROM pos_sale_product sub 
                                                        WHERE sub.frecno = a.frecno 
                                                            AND sub.fpubid = a.fpubid
                                                            AND sub.ftermid = a.ftermid
                                                            AND sub.fcompanyid = a.fcompanyid
                                                    ) * 1.12
                                                )
                                            )
                                            / pos.fcustomer_count
                                            * (pos.fcustomer_count
                                            -   (
                                                    CASE 
                                                        WHEN pos.fcustomer_count > 0 
                                                        THEN (
                                                            SELECT COUNT(*)
                                                            FROM pos_sale_product pss
                                                            WHERE pss.frecno = a.frecno 
                                                                AND pss.fpubid = a.fpubid
                                                                AND pss.ftermid = a.ftermid
                                                                AND pss.fcompanyid = a.fcompanyid
                                                                AND pss.ftype IN (0,1)
                                                        ) 
                                                        ELSE 0 
                                                    END
                                                )
                                            )
                                        ) 
                                        - pos.ftotal_discount
                                        --    pos.fsubtotal * (pos.fdiscp/100)
                                    )
                                    / 1.12 * 0.12
                                , 4)
                        END
                    )
                )
                THEN "<- OK ->"
                ELSE "NOT EQUAL"			 
            END AS "Checker Sales Tax"

            -- Expected Sales Tax ---------------------------------------------
            -- --------------------------------------------------

            ,CASE
                WHEN EXISTS (
                    SELECT 1 
                    FROM pos_sale_product psd
                    WHERE psd.frecno = pos.frecno
                        AND psd.fpubid = pos.fpubid
                        AND psd.ftermid = pos.ftermid
                        AND psd.fcompanyid = pos.fcompanyid
                )
                THEN (
                    ROUND(
                        (
                            (
                                (
                                    (
                                        SELECT 
                                            SUM(
                                                CASE
                                                    WHEN sub.ftax_type = 0
                                                        AND sub.fstatus_flag NOT IN ('V','W')
                                                    THEN sub.ftotal_line 
                                                    ELSE 0
                                                END
                                            )
                                        FROM pos_sale_product sub 
                                        WHERE sub.frecno = a.frecno 
                                            AND sub.fpubid = a.fpubid
                                            AND sub.ftermid = a.ftermid
                                            AND sub.fcompanyid = a.fcompanyid
                                    ) 
                                    + 
                                    (
                                        (
                                            SELECT 
                                                SUM(
                                                    CASE
                                                        WHEN sub.ftax_type = 1
                                                            AND sub.fstatus_flag NOT IN ('V','W')
                                                        THEN sub.ftotal_line 
                                                        ELSE 0
                                                    END
                                                )
                                            FROM pos_sale_product sub 
                                            WHERE sub.frecno = a.frecno 
                                                AND sub.fpubid = a.fpubid
                                                AND sub.ftermid = a.ftermid
                                                AND sub.fcompanyid = a.fcompanyid
                                        ) * 1.12
                                    )
                                )
                                / pos.fcustomer_count
                                * (pos.fcustomer_count
                                -   (
                                        CASE 
                                            WHEN pos.fcustomer_count > 0 
                                            THEN (
                                                SELECT COUNT(*)
                                                FROM pos_sale_product pss
                                                WHERE pss.frecno = a.frecno 
                                                    AND pss.fpubid = a.fpubid
                                                    AND pss.ftermid = a.ftermid
                                                    AND pss.fcompanyid = a.fcompanyid
                                                    AND pss.ftype IN (0,1)
                                            ) 
                                            ELSE 0 
                                        END
                                    )
                                )
                            ) 
                            - pos.ftotal_discount
                            --    pos.fsubtotal * (pos.fdiscp/100)
                        )
                        / 1.12 * 0.12
                    , 4)
                )
                ELSE 
                    ROUND(
                        (
                            (
                                (
                                    (
                                        SELECT 
                                            SUM(
                                                CASE
                                                    WHEN sub.ftax_type = 0
                                                        AND sub.fstatus_flag NOT IN ('V','W')
                                                    THEN sub.ftotal_line 
                                                    ELSE 0
                                                END
                                            )
                                        FROM pos_sale_product sub 
                                        WHERE sub.frecno = a.frecno 
                                            AND sub.fpubid = a.fpubid
                                            AND sub.ftermid = a.ftermid
                                            AND sub.fcompanyid = a.fcompanyid
                                    ) 
                                    + 
                                    (
                                        (
                                            SELECT 
                                                SUM(
                                                    CASE
                                                        WHEN sub.ftax_type = 1
                                                            AND sub.fstatus_flag NOT IN ('V','W')
                                                        THEN sub.ftotal_line 
                                                        ELSE 0
                                                    END
                                                )
                                            FROM pos_sale_product sub 
                                            WHERE sub.frecno = a.frecno 
                                                AND sub.fpubid = a.fpubid
                                                AND sub.ftermid = a.ftermid
                                                AND sub.fcompanyid = a.fcompanyid
                                        ) * 1.12
                                    )
                                )
                                / pos.fcustomer_count
                                * (pos.fcustomer_count
                                -   (
                                        CASE 
                                            WHEN pos.fcustomer_count > 0 
                                            THEN (
                                                SELECT COUNT(*)
                                                FROM pos_sale_product pss
                                                WHERE pss.frecno = a.frecno 
                                                    AND pss.fpubid = a.fpubid
                                                    AND pss.ftermid = a.ftermid
                                                    AND pss.fcompanyid = a.fcompanyid
                                                    AND pss.ftype IN (0,1)
                                            ) 
                                            ELSE 0 
                                        END
                                    )
                                )
                            ) 
                            - pos.ftotal_discount
                            --    pos.fsubtotal * (pos.fdiscp/100)
                        )
                        / 1.12 * 0.12
                    , 4)
            END AS Expected_SalesTax

            -- --------------------------------------------------



            -- VAT Exempt --------------------------------------------------
            -- --------------------------------------------------
            ,'' AS "....................2"
            ,ROUND(pos.fvat_exempt, 4) AS VAT_EXEMPT



            -- Vat Exempt Checker ---------------------------------------------------
            -- --------------------------------------------------
            ,CASE
                WHEN(
                    (
                        ROUND(pos.fvat_exempt, 4)
                    )
                    =
                    (
                        CASE 
                            WHEN EXISTS (
                                SELECT 1 
                                FROM pos_sale_product sub 
                                WHERE sub.frecno = a.frecno 
                                    AND sub.fpubid = a.fpubid
                                    AND sub.ftermid = a.ftermid
                                    AND sub.fcompanyid = a.fcompanyid
                            )
                            THEN (
                                ROUND(
                                    (
                                        (
                                            (
                                                CASE 
                                                    WHEN(
                                                        (pos.fcustomer_count * pos.fscratio)
                                                        = 0
                                                    )
                                                    THEN 1
                                                    ELSE 0
                                                END
                                            ) 
                                            * 
                                            (
                                                SELECT 
                                                    SUM(
                                                        CASE
                                                            WHEN sub.ftax_type = 4
                                                                AND sub.fstatus_flag NOT IN ('V','W')
                                                            THEN sub.funitprice * sub.fqty  
                                                            ELSE 0
                                                        END
                                                    )
                                                FROM pos_sale_product sub 
                                                WHERE sub.frecno = a.frecno 
                                                    AND sub.fpubid = a.fpubid
                                                    AND sub.ftermid = a.ftermid
                                                    AND sub.fcompanyid = a.fcompanyid
                                            )
                                        )
                                        +
                                        (
                                            ((pos.fcustomer_count * pos.fscratio) <> 0)
                                            *
                                            (
                                                (
                                                    (
                                                        (
                                                            SELECT 
                                                                SUM(
                                                                    CASE
                                                                        WHEN sub.ftax_type = 0
                                                                            AND sub.fstatus_flag NOT IN ('V','W')
                                                                        THEN sub.ftotal_line 
                                                                        ELSE 0
                                                                    END
                                                                )
                                                            FROM pos_sale_product sub 
                                                            WHERE sub.frecno = a.frecno 
                                                                AND sub.fpubid = a.fpubid
                                                                AND sub.ftermid = a.ftermid
                                                                AND sub.fcompanyid = a.fcompanyid
                                                        ) 
                                                        + 
                                                        (
                                                            (
                                                                SELECT 
                                                                    SUM(
                                                                        CASE
                                                                            WHEN sub.ftax_type = 1
                                                                                AND sub.fstatus_flag NOT IN ('V','W')
                                                                            THEN sub.ftotal_line 
                                                                            ELSE 0
                                                                        END
                                                                    )
                                                                FROM pos_sale_product sub 
                                                                WHERE sub.frecno = a.frecno 
                                                                    AND sub.fpubid = a.fpubid
                                                                    AND sub.ftermid = a.ftermid
                                                                    AND sub.fcompanyid = a.fcompanyid
                                                            ) * 1.12
                                                        )
                                                    )
                                                    /
                                                    pos.fcustomer_count
                                                    *
                                                    (pos.fcustomer_count * pos.fscratio)
                                                    /
                                                    1.12
                                                )
                                                +
                                                (
                                                    SELECT 
                                                        SUM(
                                                            CASE
                                                                WHEN sub.ftax_type = 4
                                                                    AND sub.fstatus_flag NOT IN ('V','W')
                                                                THEN sub.funitprice * sub.fqty   
                                                                ELSE 0
                                                            END
                                                        )
                                                    FROM pos_sale_product sub 
                                                    WHERE sub.frecno = a.frecno 
                                                        AND sub.fpubid = a.fpubid
                                                        AND sub.ftermid = a.ftermid
                                                        AND sub.fcompanyid = a.fcompanyid
                                                )
                                            )
                                        )
                                    )
                                , 4)
                            )
                            ELSE (
                                ROUND(
                                    (
                                        (
                                            (
                                                CASE 
                                                    WHEN(
                                                        (pos.fcustomer_count * pos.fscratio)
                                                        = 0
                                                    )
                                                    THEN 1
                                                    ELSE 0
                                                END
                                            ) 
                                            * 
                                            (
                                                SELECT 
                                                    SUM(
                                                        CASE
                                                            WHEN sub.ftax_type = 4
                                                                AND sub.fstatus_flag NOT IN ('V','W')
                                                            THEN sub.funitprice * sub.fqty  
                                                            ELSE 0
                                                        END
                                                    )
                                                FROM pos_sale_product sub 
                                                WHERE sub.frecno = a.frecno 
                                                    AND sub.fpubid = a.fpubid
                                                    AND sub.ftermid = a.ftermid
                                                    AND sub.fcompanyid = a.fcompanyid
                                            )
                                        )
                                        +
                                        (
                                            ((pos.fcustomer_count * pos.fscratio) <> 0)
                                            *
                                            (
                                                (
                                                    (
                                                        (
                                                            SELECT 
                                                                SUM(
                                                                    CASE
                                                                        WHEN sub.ftax_type = 0
                                                                            AND sub.fstatus_flag NOT IN ('V','W')
                                                                        THEN sub.ftotal_line 
                                                                        ELSE 0
                                                                    END
                                                                )
                                                            FROM pos_sale_product sub 
                                                            WHERE sub.frecno = a.frecno 
                                                                AND sub.fpubid = a.fpubid
                                                                AND sub.ftermid = a.ftermid
                                                                AND sub.fcompanyid = a.fcompanyid
                                                        ) 
                                                        + 
                                                        (
                                                            (
                                                                SELECT 
                                                                    SUM(
                                                                        CASE
                                                                            WHEN sub.ftax_type = 1
                                                                                AND sub.fstatus_flag NOT IN ('V','W')
                                                                            THEN sub.ftotal_line 
                                                                            ELSE 0
                                                                        END
                                                                    )
                                                                FROM pos_sale_product sub 
                                                                WHERE sub.frecno = a.frecno 
                                                                    AND sub.fpubid = a.fpubid
                                                                    AND sub.ftermid = a.ftermid
                                                                    AND sub.fcompanyid = a.fcompanyid
                                                            ) * 1.12
                                                        )
                                                    )
                                                    /
                                                    pos.fcustomer_count
                                                    *
                                                    (pos.fcustomer_count * pos.fscratio)
                                                    /
                                                    1.12
                                                )
                                                +
                                                (
                                                    SELECT 
                                                        SUM(
                                                            CASE
                                                                WHEN sub.ftax_type = 4
                                                                    AND sub.fstatus_flag NOT IN ('V','W')
                                                                THEN sub.funitprice * sub.fqty   
                                                                ELSE 0
                                                            END
                                                        )
                                                    FROM pos_sale_product sub 
                                                    WHERE sub.frecno = a.frecno 
                                                        AND sub.fpubid = a.fpubid
                                                        AND sub.ftermid = a.ftermid
                                                        AND sub.fcompanyid = a.fcompanyid
                                                )
                                            )
                                        )
                                    )
                                , 4)
                            )
                        END
                    )
                )
                THEN "<- OK ->"
                ELSE "NOT EQUAL"
            END AS "Checker EVAT"
            -- --------------------------------------------------



            -- Expected VAT Exempt --------------------------------------------------
            -- --------------------------------------------------
            ,CASE 
                WHEN EXISTS (
                    SELECT 1 
                    FROM pos_sale_product sub 
                    WHERE sub.frecno = a.frecno 
                        AND sub.fpubid = a.fpubid
                        AND sub.ftermid = a.ftermid
                        AND sub.fcompanyid = a.fcompanyid
                )
                THEN (
                    ROUND(
                        CASE 
                            WHEN (
                                SELECT COUNT(*) 
                                FROM pos_sale_senior pss
                                WHERE pss.frecno = a.frecno 
                                    AND pss.fpubid = a.fpubid
                                    AND pss.ftermid = a.ftermid
                                    AND pss.fcompanyid = a.fcompanyid
                                    AND pss.ftype IN (0,1)
                            ) = 0
                            THEN (
                                SELECT 
                                    SUM(
                                        CASE
                                            WHEN sub.ftax_type = 4
                                                AND sub.fstatus_flag NOT IN ('V','W')
                                            THEN sub.funitprice * sub.fqty   
                                            ELSE 0
                                        END
                                    )
                                FROM pos_sale_product sub 
                                WHERE sub.frecno = a.frecno 
                                    AND sub.fpubid = a.fpubid
                                    AND sub.ftermid = a.ftermid
                                    AND sub.fcompanyid = a.fcompanyid
                            )
                            ELSE (
                                (
                                    (
                                        (
                                            SELECT 
                                                SUM(
                                                    CASE
                                                        WHEN sub.ftax_type = 0
                                                            AND sub.fstatus_flag NOT IN ('V','W')
                                                        THEN sub.ftotal_line 
                                                        ELSE 0
                                                    END
                                                )
                                            FROM pos_sale_product sub 
                                            WHERE sub.frecno = a.frecno 
                                                AND sub.fpubid = a.fpubid
                                                AND sub.ftermid = a.ftermid
                                                AND sub.fcompanyid = a.fcompanyid
                                        )
                                        +
                                        (
                                            SELECT 
                                                SUM(
                                                    CASE
                                                        WHEN sub.ftax_type = 1
                                                            AND sub.fstatus_flag NOT IN ('V','W')
                                                        THEN sub.ftotal_line 
                                                        ELSE 0
                                                    END
                                                )
                                            FROM pos_sale_product sub 
                                            WHERE sub.frecno = a.frecno 
                                                AND sub.fpubid = a.fpubid
                                                AND sub.ftermid = a.ftermid
                                                AND sub.fcompanyid = a.fcompanyid
                                        ) * 1.12
                                    )
                                    / pos.fcustomer_count
                                    *
                                    (
                                        SELECT COUNT(*) 
                                        FROM pos_sale_senior pss
                                        WHERE pss.frecno = a.frecno 
                                            AND pss.fpubid = a.fpubid
                                            AND pss.ftermid = a.ftermid
                                            AND pss.fcompanyid = a.fcompanyid
                                            AND pss.ftype IN (0,1)
                                    )
                                    / 1.12
                                )
                                +
                                (
                                    SELECT 
                                        SUM(
                                            CASE
                                                WHEN sub.ftax_type = 4
                                                    AND sub.fstatus_flag NOT IN ('V','W')
                                                THEN sub.funitprice * sub.fqty   
                                                ELSE 0
                                            END
                                        )
                                    FROM pos_sale_product sub 
                                    WHERE sub.frecno = a.frecno 
                                        AND sub.fpubid = a.fpubid
                                        AND sub.ftermid = a.ftermid
                                        AND sub.fcompanyid = a.fcompanyid
                                )
                            )
                        END
                    , 4)
                )
                ELSE (
                    ROUND(
                        CASE 
                            WHEN (
                                SELECT COUNT(*) 
                                FROM pos_sale_senior pss
                                WHERE pss.frecno = a.frecno 
                                    AND pss.fpubid = a.fpubid
                                    AND pss.ftermid = a.ftermid
                                    AND pss.fcompanyid = a.fcompanyid
                                    AND pss.ftype IN (0,1)
                            ) = 0
                            THEN (
                                SELECT 
                                    SUM(
                                        CASE
                                            WHEN sub.ftax_type = 4
                                                AND sub.fstatus_flag NOT IN ('V','W')
                                            THEN sub.funitprice * sub.fqty   
                                            ELSE 0
                                        END
                                    )
                                FROM pos_sale_product sub 
                                WHERE sub.frecno = a.frecno 
                                    AND sub.fpubid = a.fpubid
                                    AND sub.ftermid = a.ftermid
                                    AND sub.fcompanyid = a.fcompanyid
                            )
                            ELSE (
                                (
                                    (
                                        (
                                            SELECT 
                                                SUM(
                                                    CASE
                                                        WHEN sub.ftax_type = 0
                                                            AND sub.fstatus_flag NOT IN ('V','W')
                                                        THEN sub.ftotal_line 
                                                        ELSE 0
                                                    END
                                                )
                                            FROM pos_sale_product sub 
                                            WHERE sub.frecno = a.frecno 
                                                AND sub.fpubid = a.fpubid
                                                AND sub.ftermid = a.ftermid
                                                AND sub.fcompanyid = a.fcompanyid
                                        )
                                        +
                                        (
                                            SELECT 
                                                SUM(
                                                    CASE
                                                        WHEN sub.ftax_type = 1
                                                            AND sub.fstatus_flag NOT IN ('V','W')
                                                        THEN sub.ftotal_line 
                                                        ELSE 0
                                                    END
                                                )
                                            FROM pos_sale_product sub 
                                            WHERE sub.frecno = a.frecno 
                                                AND sub.fpubid = a.fpubid
                                                AND sub.ftermid = a.ftermid
                                                AND sub.fcompanyid = a.fcompanyid
                                        ) * 1.12
                                    )
                                    / pos.fcustomer_count
                                    *
                                    (
                                        SELECT COUNT(*) 
                                        FROM pos_sale_senior pss
                                        WHERE pss.frecno = a.frecno 
                                            AND pss.fpubid = a.fpubid
                                            AND pss.ftermid = a.ftermid
                                            AND pss.fcompanyid = a.fcompanyid
                                            AND pss.ftype IN (0,1)
                                    )
                                    / 1.12
                                )
                                +
                                (
                                    SELECT 
                                        SUM(
                                            CASE
                                                WHEN sub.ftax_type = 4
                                                    AND sub.fstatus_flag NOT IN ('V','W')
                                                THEN sub.funitprice * sub.fqty   
                                                ELSE 0
                                            END
                                        )
                                    FROM pos_sale_product sub 
                                    WHERE sub.frecno = a.frecno 
                                        AND sub.fpubid = a.fpubid
                                        AND sub.ftermid = a.ftermid
                                        AND sub.fcompanyid = a.fcompanyid
                                )
                            )
                        END
                    , 4)
                )
            END AS Expected_VatExempt
            -- --------------------------------------------------

        FROM pos_sale_product a 
        LEFT JOIN pos_sale pos
            ON pos.fpubid = a.fpubid 
            AND pos.frecno = a.frecno
        LEFT JOIN pos_sale_senior pss
            on pos.fpubid = pss.fpubid
            AND pos.ftermid = pss.ftermid
            AND pos.frecno = pss.frecno
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


            
            AND pos.fdiscount2 = 0
            AND pos.fdiscount4 = 0
            AND pos.fdiscount5 = 0
            AND pos.fdiscount6 = 0
        GROUP BY a.frecno
    ) main 
    WHERE main.Tax_Sale <> main.Expected_TaxSale     
        OR main.Sales_Tax <> main.Expected_SalesTax   
        OR main.VAT_EXEMPT <> main.Expected_VatExempt;
    -- --------------------------------------------------------------------------------------------------------------