-- Select --------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------
SET 	
    @companyID := 'SHOST-10050582',
	@pubID := 'SHOST-10050582-0002',
	@termID := '0002',
	@saleDateFrom := '20250709',
	@saleDateTo := '20250709';


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
            ,ABS((fscratio * fcustomer_count)) AS Seniors_only
            
            ,' ' AS '...'
            ,' ' AS '....'
            ,' ' AS '.....'

            -- Tax Sale ----------------------------------------------------------------------------------------------------
            -- --------------------------------------------------
            ,pos.finc_sale AS finc_sale
            ,pos.fexc_sale AS fexc_sale

            ,(pos.finc_sale + pos.fexc_sale) AS "inc + exc"

            ,' ' AS "...................."
            ,a.frecno AS frecno
            ,pos.ftrx_no AS ftrx_no



            ,ROUND(pos.ftax_sale, 4) AS Tax_Sale
  
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
                                        -- total taxables
                                        (
                                            -- total tax inclusive
                                            (
                                                (
                                                    SELECT SUM(
                                                        ROUND(
                                                            CASE
                                                                WHEN 
                                                                    psd.ftotal_line <> 0
                                                                    AND psd.fstatus_flag IN (0, 1)
                                                                    AND psd.fextprice IS NOT NULL AND psd.fqty IS NOT NULL
                                                                    AND (
                                                                        psd.ftax_type IS NULL
                                                                        OR psd.ftax_type = 0
                                                                        OR (
                                                                            psd.ftax_type = 0
                                                                            AND psd.foriginal_tax_type = 1
                                                                            AND (
                                                                                IFNULL(psd.fsc_discp, 0) > 0 OR
                                                                                IFNULL(psd.fdiscount_percent1, 0) > 0 OR
                                                                                IFNULL(psd.fdiscount_percent2, 0) > 0 OR
                                                                                IFNULL(psd.fdiscount_percent5, 0) > 0
                                                                            )
                                                                        )
                                                                    )
                                                                THEN
                                                                    CASE
                                                                        WHEN (psd.ftax_type IS NULL OR psd.ftax_type = 0) AND psd.foriginal_tax_type = 1
                                                                        THEN
                                                                            psd.fextprice * psd.fqty * 1.12 * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                                        ELSE
                                                                            psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                                    END
                                                                ELSE 0
                                                            END
                                                        , 6)
                                                    )
                                                    FROM pos_sale_product psd
                                                    WHERE psd.frecno = a.frecno
                                                        AND psd.fpubid = a.fpubid
                                                        AND psd.ftermid = a.ftermid
                                                        AND psd.fcompanyid = a.fcompanyid
                                                )
                                            )
                                            
                                            +

                                            -- total tax exclusive
                                            (
                                                (
                                                    SELECT SUM(
                                                        ROUND(
                                                            CASE
                                                                WHEN 
                                                                    psd.ftotal_line <> 0
                                                                    AND psd.fstatus_flag IN (0, 1)
                                                                    AND psd.ftax_type = 1
                                                                    AND IFNULL(psd.fsc_discp, 0) = 0
                                                                    AND IFNULL(psd.fdiscount_percent1, 0) = 0
                                                                    AND IFNULL(psd.fdiscount_percent2, 0) = 0
                                                                    AND IFNULL(psd.fdiscount_percent5, 0) = 0
                                                                THEN
                                                                    (psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount) * 1.12
                                                                ELSE 0
                                                            END,
                                                        2)
                                                    )
                                                    FROM pos_sale_product psd
                                                    WHERE psd.frecno = a.frecno
                                                    AND psd.fpubid = a.fpubid
                                                    AND psd.ftermid = a.ftermid
                                                    AND psd.fcompanyid = a.fcompanyid
                                                )
                                            )
                                        )
                                        / pos.fcustomer_count
                                        * (
                                            pos.fcustomer_count
                                            -- sr. only
                                            - ABS((pos.fscratio * pos.fcustomer_count))
                                            -- regular customers only + nac + mov / taxables
                                            - (
                                                IFNULL(
                                                    (
                                                        SELECT SUM(psi.fint_data)
                                                        FROM pos_sale_info psi
                                                        WHERE psi.frecno = a.frecno
                                                            AND psi.fpubid = a.fpubid
                                                            AND psi.ftermid = a.ftermid
                                                            AND psi.fcompanyid = a.fcompanyid
                                                            AND psi.fcode2 IN ('#PWD', '#DIP', '#SPD')
                                                    )
                                                , 0)
                                            )
                                        )
                                        - ( 
                                            -- total taxables
                                            (
                                                -- total tax inclusive
                                                (
                                                    (
                                                        SELECT SUM(
                                                            ROUND(
                                                                CASE
                                                                    WHEN 
                                                                        psd.ftotal_line <> 0
                                                                        AND psd.fstatus_flag IN (0, 1)
                                                                        AND psd.fextprice IS NOT NULL AND psd.fqty IS NOT NULL
                                                                        AND (
                                                                            psd.ftax_type IS NULL
                                                                            OR psd.ftax_type = 0
                                                                            OR (
                                                                                psd.ftax_type = 0
                                                                                AND psd.foriginal_tax_type = 1
                                                                                AND (
                                                                                    IFNULL(psd.fsc_discp, 0) > 0 OR
                                                                                    IFNULL(psd.fdiscount_percent1, 0) > 0 OR
                                                                                    IFNULL(psd.fdiscount_percent2, 0) > 0 OR
                                                                                    IFNULL(psd.fdiscount_percent5, 0) > 0
                                                                                )
                                                                            )
                                                                        )
                                                                    THEN
                                                                        CASE
                                                                            WHEN (psd.ftax_type IS NULL OR psd.ftax_type = 0) AND psd.foriginal_tax_type = 1
                                                                            THEN
                                                                                psd.fextprice * psd.fqty * 1.12 * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                                            ELSE
                                                                                psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                                        END
                                                                    ELSE 0
                                                                END
                                                            , 6)
                                                        )
                                                        FROM pos_sale_product psd
                                                        WHERE psd.frecno = a.frecno
                                                            AND psd.fpubid = a.fpubid
                                                            AND psd.ftermid = a.ftermid
                                                            AND psd.fcompanyid = a.fcompanyid
                                                    )
                                                )
                                                
                                                +

                                                -- total tax exclusive
                                                (
                                                    (
                                                        SELECT SUM(
                                                            ROUND(
                                                                CASE
                                                                    WHEN 
                                                                        psd.ftotal_line <> 0
                                                                        AND psd.fstatus_flag IN (0, 1)
                                                                        AND psd.ftax_type = 1
                                                                        AND IFNULL(psd.fsc_discp, 0) = 0
                                                                        AND IFNULL(psd.fdiscount_percent1, 0) = 0
                                                                        AND IFNULL(psd.fdiscount_percent2, 0) = 0
                                                                        AND IFNULL(psd.fdiscount_percent5, 0) = 0
                                                                    THEN
                                                                        (psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount) * 1.12
                                                                    ELSE 0
                                                                END,
                                                            2)
                                                        )
                                                        FROM pos_sale_product psd
                                                        WHERE psd.frecno = a.frecno
                                                        AND psd.fpubid = a.fpubid
                                                        AND psd.ftermid = a.ftermid
                                                        AND psd.fcompanyid = a.fcompanyid
                                                    )
                                                )
                                            )
                                            * (pos.fdiscp/100)
                                        )
                                    )
                                , 6)
                            )
                            ELSE NULL
                        END
                    )
                )
                THEN "<- OK ->"
                ELSE "NOT EQUAL"
            END AS "Checker Tax Sale"

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
                            -- total taxables
                            (
                                -- total tax inclusive
                                (
                                    (
                                        SELECT SUM(
                                            ROUND(
                                                CASE
                                                    WHEN 
                                                        psd.ftotal_line <> 0
                                                        AND psd.fstatus_flag IN (0, 1)
                                                        AND psd.fextprice IS NOT NULL AND psd.fqty IS NOT NULL
                                                        AND (
                                                            psd.ftax_type IS NULL
                                                            OR psd.ftax_type = 0
                                                            OR (
                                                                psd.ftax_type = 0
                                                                AND psd.foriginal_tax_type = 1
                                                                AND (
                                                                    IFNULL(psd.fsc_discp, 0) > 0 OR
                                                                    IFNULL(psd.fdiscount_percent1, 0) > 0 OR
                                                                    IFNULL(psd.fdiscount_percent2, 0) > 0 OR
                                                                    IFNULL(psd.fdiscount_percent5, 0) > 0
                                                                )
                                                            )
                                                        )
                                                    THEN
                                                        CASE
                                                            WHEN (psd.ftax_type IS NULL OR psd.ftax_type = 0) AND psd.foriginal_tax_type = 1
                                                            THEN
                                                                psd.fextprice * psd.fqty * 1.12 * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                            ELSE
                                                                psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                        END
                                                    ELSE 0
                                                END
                                            , 6)
                                        )
                                        FROM pos_sale_product psd
                                        WHERE psd.frecno = a.frecno
                                            AND psd.fpubid = a.fpubid
                                            AND psd.ftermid = a.ftermid
                                            AND psd.fcompanyid = a.fcompanyid
                                    )
                                )
                                
                                +

                                -- total tax exclusive
                                (
                                    (
                                        SELECT SUM(
                                            ROUND(
                                                CASE
                                                    WHEN 
                                                        psd.ftotal_line <> 0
                                                        AND psd.fstatus_flag IN (0, 1)
                                                        AND psd.ftax_type = 1
                                                        AND IFNULL(psd.fsc_discp, 0) = 0
                                                        AND IFNULL(psd.fdiscount_percent1, 0) = 0
                                                        AND IFNULL(psd.fdiscount_percent2, 0) = 0
                                                        AND IFNULL(psd.fdiscount_percent5, 0) = 0
                                                    THEN
                                                        (psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount) * 1.12
                                                    ELSE 0
                                                END,
                                            2)
                                        )
                                        FROM pos_sale_product psd
                                        WHERE psd.frecno = a.frecno
                                        AND psd.fpubid = a.fpubid
                                        AND psd.ftermid = a.ftermid
                                        AND psd.fcompanyid = a.fcompanyid
                                    )
                                )
                            )
                            / pos.fcustomer_count
                            * (
                                pos.fcustomer_count
                                -- sr. only
                                - ABS((pos.fscratio * pos.fcustomer_count))
                                -- regular customers only + nac + mov / taxables
                                - (
                                    IFNULL(
                                        (
                                            SELECT SUM(psi.fint_data)
                                            FROM pos_sale_info psi
                                            WHERE psi.frecno = a.frecno
                                                AND psi.fpubid = a.fpubid
                                                AND psi.ftermid = a.ftermid
                                                AND psi.fcompanyid = a.fcompanyid
                                                AND psi.fcode2 IN ('#PWD', '#DIP', '#SPD')
                                        )
                                    , 0)
                                )
                            )
                            - ( 
                                -- total taxables
                                (
                                    -- total tax inclusive
                                    (
                                        (
                                            SELECT SUM(
                                                ROUND(
                                                    CASE
                                                        WHEN 
                                                            psd.ftotal_line <> 0
                                                            AND psd.fstatus_flag IN (0, 1)
                                                            AND psd.fextprice IS NOT NULL AND psd.fqty IS NOT NULL
                                                            AND (
                                                                psd.ftax_type IS NULL
                                                                OR psd.ftax_type = 0
                                                                OR (
                                                                    psd.ftax_type = 0
                                                                    AND psd.foriginal_tax_type = 1
                                                                    AND (
                                                                        IFNULL(psd.fsc_discp, 0) > 0 OR
                                                                        IFNULL(psd.fdiscount_percent1, 0) > 0 OR
                                                                        IFNULL(psd.fdiscount_percent2, 0) > 0 OR
                                                                        IFNULL(psd.fdiscount_percent5, 0) > 0
                                                                    )
                                                                )
                                                            )
                                                        THEN
                                                            CASE
                                                                WHEN (psd.ftax_type IS NULL OR psd.ftax_type = 0) AND psd.foriginal_tax_type = 1
                                                                THEN
                                                                    psd.fextprice * psd.fqty * 1.12 * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                                ELSE
                                                                    psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                            END
                                                        ELSE 0
                                                    END
                                                , 6)
                                            )
                                            FROM pos_sale_product psd
                                            WHERE psd.frecno = a.frecno
                                                AND psd.fpubid = a.fpubid
                                                AND psd.ftermid = a.ftermid
                                                AND psd.fcompanyid = a.fcompanyid
                                        )
                                    )
                                    
                                    +

                                    -- total tax exclusive
                                    (
                                        (
                                            SELECT SUM(
                                                ROUND(
                                                    CASE
                                                        WHEN 
                                                            psd.ftotal_line <> 0
                                                            AND psd.fstatus_flag IN (0, 1)
                                                            AND psd.ftax_type = 1
                                                            AND IFNULL(psd.fsc_discp, 0) = 0
                                                            AND IFNULL(psd.fdiscount_percent1, 0) = 0
                                                            AND IFNULL(psd.fdiscount_percent2, 0) = 0
                                                            AND IFNULL(psd.fdiscount_percent5, 0) = 0
                                                        THEN
                                                            (psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount) * 1.12
                                                        ELSE 0
                                                    END,
                                                2)
                                            )
                                            FROM pos_sale_product psd
                                            WHERE psd.frecno = a.frecno
                                            AND psd.fpubid = a.fpubid
                                            AND psd.ftermid = a.ftermid
                                            AND psd.fcompanyid = a.fcompanyid
                                        )
                                    )
                                )
                                * (pos.fdiscp/100)
                            )
                        )
                    , 6)
                )
                ELSE NULL
            END AS Expected_TaxSale

            -- ----------------------------------------------------------------------------------------------------
    


            ,'' AS "....................1"



            -- Sales Tax ----------------------------------------------------------------------------------------------------
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
                                        -- total taxables
                                        (
                                            -- total tax inclusive
                                            (
                                                (
                                                    SELECT SUM(
                                                        ROUND(
                                                            CASE
                                                                WHEN 
                                                                    psd.ftotal_line <> 0
                                                                    AND psd.fstatus_flag IN (0, 1)
                                                                    AND psd.fextprice IS NOT NULL AND psd.fqty IS NOT NULL
                                                                    AND (
                                                                        psd.ftax_type IS NULL
                                                                        OR psd.ftax_type = 0
                                                                        OR (
                                                                            psd.ftax_type = 0
                                                                            AND psd.foriginal_tax_type = 1
                                                                            AND (
                                                                                IFNULL(psd.fsc_discp, 0) > 0 OR
                                                                                IFNULL(psd.fdiscount_percent1, 0) > 0 OR
                                                                                IFNULL(psd.fdiscount_percent2, 0) > 0 OR
                                                                                IFNULL(psd.fdiscount_percent5, 0) > 0
                                                                            )
                                                                        )
                                                                    )
                                                                THEN
                                                                    CASE
                                                                        WHEN (psd.ftax_type IS NULL OR psd.ftax_type = 0) AND psd.foriginal_tax_type = 1
                                                                        THEN
                                                                            psd.fextprice * psd.fqty * 1.12 * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                                        ELSE
                                                                            psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                                    END
                                                                ELSE 0
                                                            END
                                                        , 6)
                                                    )
                                                    FROM pos_sale_product psd
                                                    WHERE psd.frecno = a.frecno
                                                        AND psd.fpubid = a.fpubid
                                                        AND psd.ftermid = a.ftermid
                                                        AND psd.fcompanyid = a.fcompanyid
                                                )
                                            )
                                            
                                            +

                                            -- total tax exclusive
                                            (
                                                (
                                                    SELECT SUM(
                                                        ROUND(
                                                            CASE
                                                                WHEN 
                                                                    psd.ftotal_line <> 0
                                                                    AND psd.fstatus_flag IN (0, 1)
                                                                    AND psd.ftax_type = 1
                                                                    AND IFNULL(psd.fsc_discp, 0) = 0
                                                                    AND IFNULL(psd.fdiscount_percent1, 0) = 0
                                                                    AND IFNULL(psd.fdiscount_percent2, 0) = 0
                                                                    AND IFNULL(psd.fdiscount_percent5, 0) = 0
                                                                THEN
                                                                    (psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount) * 1.12
                                                                ELSE 0
                                                            END,
                                                        2)
                                                    )
                                                    FROM pos_sale_product psd
                                                    WHERE psd.frecno = a.frecno
                                                    AND psd.fpubid = a.fpubid
                                                    AND psd.ftermid = a.ftermid
                                                    AND psd.fcompanyid = a.fcompanyid
                                                )
                                            )
                                        )
                                        / pos.fcustomer_count
                                        * (
                                            pos.fcustomer_count
                                            -- sr. only
                                            - ABS((pos.fscratio * pos.fcustomer_count))
                                            -- regular customers only + nac + mov / taxables
                                            - (
                                                IFNULL(
                                                    (
                                                        SELECT SUM(psi.fint_data)
                                                        FROM pos_sale_info psi
                                                        WHERE psi.frecno = a.frecno
                                                            AND psi.fpubid = a.fpubid
                                                            AND psi.ftermid = a.ftermid
                                                            AND psi.fcompanyid = a.fcompanyid
                                                            AND psi.fcode2 IN ('#PWD', '#DIP', '#SPD')
                                                    )
                                                , 0)
                                            )
                                        )
                                        - ( 
                                            -- total taxables
                                            (
                                                -- total tax inclusive
                                                (
                                                    (
                                                        SELECT SUM(
                                                            ROUND(
                                                                CASE
                                                                    WHEN 
                                                                        psd.ftotal_line <> 0
                                                                        AND psd.fstatus_flag IN (0, 1)
                                                                        AND psd.fextprice IS NOT NULL AND psd.fqty IS NOT NULL
                                                                        AND (
                                                                            psd.ftax_type IS NULL
                                                                            OR psd.ftax_type = 0
                                                                            OR (
                                                                                psd.ftax_type = 0
                                                                                AND psd.foriginal_tax_type = 1
                                                                                AND (
                                                                                    IFNULL(psd.fsc_discp, 0) > 0 OR
                                                                                    IFNULL(psd.fdiscount_percent1, 0) > 0 OR
                                                                                    IFNULL(psd.fdiscount_percent2, 0) > 0 OR
                                                                                    IFNULL(psd.fdiscount_percent5, 0) > 0
                                                                                )
                                                                            )
                                                                        )
                                                                    THEN
                                                                        CASE
                                                                            WHEN (psd.ftax_type IS NULL OR psd.ftax_type = 0) AND psd.foriginal_tax_type = 1
                                                                            THEN
                                                                                psd.fextprice * psd.fqty * 1.12 * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                                            ELSE
                                                                                psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                                        END
                                                                    ELSE 0
                                                                END
                                                            , 6)
                                                        )
                                                        FROM pos_sale_product psd
                                                        WHERE psd.frecno = a.frecno
                                                            AND psd.fpubid = a.fpubid
                                                            AND psd.ftermid = a.ftermid
                                                            AND psd.fcompanyid = a.fcompanyid
                                                    )
                                                )
                                                
                                                +

                                                -- total tax exclusive
                                                (
                                                    (
                                                        SELECT SUM(
                                                            ROUND(
                                                                CASE
                                                                    WHEN 
                                                                        psd.ftotal_line <> 0
                                                                        AND psd.fstatus_flag IN (0, 1)
                                                                        AND psd.ftax_type = 1
                                                                        AND IFNULL(psd.fsc_discp, 0) = 0
                                                                        AND IFNULL(psd.fdiscount_percent1, 0) = 0
                                                                        AND IFNULL(psd.fdiscount_percent2, 0) = 0
                                                                        AND IFNULL(psd.fdiscount_percent5, 0) = 0
                                                                    THEN
                                                                        (psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount) * 1.12
                                                                    ELSE 0
                                                                END,
                                                            2)
                                                        )
                                                        FROM pos_sale_product psd
                                                        WHERE psd.frecno = a.frecno
                                                        AND psd.fpubid = a.fpubid
                                                        AND psd.ftermid = a.ftermid
                                                        AND psd.fcompanyid = a.fcompanyid
                                                    )
                                                )
                                            )
                                            * (pos.fdiscp/100)
                                        )
                                    ) / 1.12 * 0.12
                                , 6)
                            )
                            ELSE NULL
                        END
                    )
                )
                THEN "<- OK ->"
                ELSE "NOT EQUAL"			 
            END AS "Checker Sales Tax"

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
                            -- total taxables
                            (
                                -- total tax inclusive
                                (
                                    (
                                        SELECT SUM(
                                            ROUND(
                                                CASE
                                                    WHEN 
                                                        psd.ftotal_line <> 0
                                                        AND psd.fstatus_flag IN (0, 1)
                                                        AND psd.fextprice IS NOT NULL AND psd.fqty IS NOT NULL
                                                        AND (
                                                            psd.ftax_type IS NULL
                                                            OR psd.ftax_type = 0
                                                            OR (
                                                                psd.ftax_type = 0
                                                                AND psd.foriginal_tax_type = 1
                                                                AND (
                                                                    IFNULL(psd.fsc_discp, 0) > 0 OR
                                                                    IFNULL(psd.fdiscount_percent1, 0) > 0 OR
                                                                    IFNULL(psd.fdiscount_percent2, 0) > 0 OR
                                                                    IFNULL(psd.fdiscount_percent5, 0) > 0
                                                                )
                                                            )
                                                        )
                                                    THEN
                                                        CASE
                                                            WHEN (psd.ftax_type IS NULL OR psd.ftax_type = 0) AND psd.foriginal_tax_type = 1
                                                            THEN
                                                                psd.fextprice * psd.fqty * 1.12 * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                            ELSE
                                                                psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                        END
                                                    ELSE 0
                                                END
                                            , 6)
                                        )
                                        FROM pos_sale_product psd
                                        WHERE psd.frecno = a.frecno
                                            AND psd.fpubid = a.fpubid
                                            AND psd.ftermid = a.ftermid
                                            AND psd.fcompanyid = a.fcompanyid
                                    )
                                )
                                
                                +

                                -- total tax exclusive
                                (
                                    (
                                        SELECT SUM(
                                            ROUND(
                                                CASE
                                                    WHEN 
                                                        psd.ftotal_line <> 0
                                                        AND psd.fstatus_flag IN (0, 1)
                                                        AND psd.ftax_type = 1
                                                        AND IFNULL(psd.fsc_discp, 0) = 0
                                                        AND IFNULL(psd.fdiscount_percent1, 0) = 0
                                                        AND IFNULL(psd.fdiscount_percent2, 0) = 0
                                                        AND IFNULL(psd.fdiscount_percent5, 0) = 0
                                                    THEN
                                                        (psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount) * 1.12
                                                    ELSE 0
                                                END,
                                            2)
                                        )
                                        FROM pos_sale_product psd
                                        WHERE psd.frecno = a.frecno
                                        AND psd.fpubid = a.fpubid
                                        AND psd.ftermid = a.ftermid
                                        AND psd.fcompanyid = a.fcompanyid
                                    )
                                )
                            )
                            / pos.fcustomer_count
                            * (
                                pos.fcustomer_count
                                -- sr. only
                                - ABS((pos.fscratio * pos.fcustomer_count))
                                -- regular customers only + nac + mov / taxables
                                - (
                                    IFNULL(
                                        (
                                            SELECT SUM(psi.fint_data)
                                            FROM pos_sale_info psi
                                            WHERE psi.frecno = a.frecno
                                                AND psi.fpubid = a.fpubid
                                                AND psi.ftermid = a.ftermid
                                                AND psi.fcompanyid = a.fcompanyid
                                                AND psi.fcode2 IN ('#PWD', '#DIP', '#SPD')
                                        )
                                    , 0)
                                )
                            )
                            - ( 
                                -- total taxables
                                (
                                    -- total tax inclusive
                                    (
                                        (
                                            SELECT SUM(
                                                ROUND(
                                                    CASE
                                                        WHEN 
                                                            psd.ftotal_line <> 0
                                                            AND psd.fstatus_flag IN (0, 1)
                                                            AND psd.fextprice IS NOT NULL AND psd.fqty IS NOT NULL
                                                            AND (
                                                                psd.ftax_type IS NULL
                                                                OR psd.ftax_type = 0
                                                                OR (
                                                                    psd.ftax_type = 0
                                                                    AND psd.foriginal_tax_type = 1
                                                                    AND (
                                                                        IFNULL(psd.fsc_discp, 0) > 0 OR
                                                                        IFNULL(psd.fdiscount_percent1, 0) > 0 OR
                                                                        IFNULL(psd.fdiscount_percent2, 0) > 0 OR
                                                                        IFNULL(psd.fdiscount_percent5, 0) > 0
                                                                    )
                                                                )
                                                            )
                                                        THEN
                                                            CASE
                                                                WHEN (psd.ftax_type IS NULL OR psd.ftax_type = 0) AND psd.foriginal_tax_type = 1
                                                                THEN
                                                                    psd.fextprice * psd.fqty * 1.12 * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                                ELSE
                                                                    psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                            END
                                                        ELSE 0
                                                    END
                                                , 6)
                                            )
                                            FROM pos_sale_product psd
                                            WHERE psd.frecno = a.frecno
                                                AND psd.fpubid = a.fpubid
                                                AND psd.ftermid = a.ftermid
                                                AND psd.fcompanyid = a.fcompanyid
                                        )
                                    )
                                    
                                    +

                                    -- total tax exclusive
                                    (
                                        (
                                            SELECT SUM(
                                                ROUND(
                                                    CASE
                                                        WHEN 
                                                            psd.ftotal_line <> 0
                                                            AND psd.fstatus_flag IN (0, 1)
                                                            AND psd.ftax_type = 1
                                                            AND IFNULL(psd.fsc_discp, 0) = 0
                                                            AND IFNULL(psd.fdiscount_percent1, 0) = 0
                                                            AND IFNULL(psd.fdiscount_percent2, 0) = 0
                                                            AND IFNULL(psd.fdiscount_percent5, 0) = 0
                                                        THEN
                                                            (psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount) * 1.12
                                                        ELSE 0
                                                    END,
                                                2)
                                            )
                                            FROM pos_sale_product psd
                                            WHERE psd.frecno = a.frecno
                                            AND psd.fpubid = a.fpubid
                                            AND psd.ftermid = a.ftermid
                                            AND psd.fcompanyid = a.fcompanyid
                                        )
                                    )
                                )
                                * (pos.fdiscp/100)
                            )
                        ) / 1.12 * 0.12
                    , 6)
                )
                ELSE NULL
            END AS Expected_SalesTax
            -- ----------------------------------------------------------------------------------------------------



            ,'' AS "....................2"


            -- Vat Exempt ----------------------------------------------------------------------------------------------------
            -- --------------------------------------------------
            ,ROUND(pos.fvat_exempt, 4) AS VAT_EXEMPT

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
                                    CASE 
                                        -- gov discounts customers = 0
                                        WHEN (
                                            (
                                                (ABS((pos.fscratio * pos.fcustomer_count)))
                                                + (
                                                    IFNULL(
                                                        (
                                                            SELECT SUM(psi.fint_data)
                                                            FROM pos_sale_info psi
                                                            WHERE psi.frecno = a.frecno
                                                                AND psi.fpubid = a.fpubid
                                                                AND psi.ftermid = a.ftermid
                                                                AND psi.fcompanyid = a.fcompanyid
                                                                AND psi.fcode2 IN ('#PWD', '#DIP', '#SPD')
                                                        )
                                                    , 0)
                                                )
                                            ) = 0
                                        )

                                        THEN (
                                            -- total vat exempt
                                            (
                                                SELECT SUM(
                                                    ROUND(
                                                        CASE
                                                            -- First condition: matches outer IF
                                                            WHEN
                                                                psd.ftotal_line <> 0
                                                                AND psd.fstatus_flag IN (0, 1)
                                                                AND (
                                                                    psd.ftax_type = 4
                                                                    OR (
                                                                        psd.ftax_type = 1 AND (
                                                                            psd.fdiscount_percent1 > 0  -- PWD
                                                                            OR psd.fdiscount_percent2 > 0  -- Diplomat
                                                                            OR psd.fdiscount_percent5 > 0  -- SPD
                                                                        )
                                                                    )
                                                                )
                                                                AND psd.foriginal_tax_type NOT IN (2, 3)
                                                            THEN
                                                                (psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100)) - psd.fdiscount

                                                            -- Else condition: fallback IF from Excel
                                                            WHEN (
                                                                (
                                                                    IFNULL(psd.fsc_discp, 0) > 0
                                                                    OR IFNULL(psd.fdiscount_percent1, 0) > 0
                                                                    OR IFNULL(psd.fdiscount_percent2, 0) > 0
                                                                    OR IFNULL(psd.fdiscount_percent5, 0) > 0
                                                                )
                                                                AND psd.foriginal_tax_type IN (0, 1, 4)
                                                            )
                                                            THEN psd.fextprice * psd.fqty

                                                            ELSE 0
                                                        END,
                                                    2)
                                                )
                                                FROM pos_sale_product psd
                                                WHERE psd.frecno = a.frecno
                                                    AND psd.fpubid = a.fpubid
                                                    AND psd.ftermid = a.ftermid
                                                    AND psd.fcompanyid = a.fcompanyid
                                            ) * (1-(pos.fdiscp/100))
                                        )

                                        ELSE (
                                            (
                                                -- total taxables
                                                (
                                                    -- total tax inclusive
                                                    (
                                                        (
                                                            SELECT SUM(
                                                                ROUND(
                                                                    CASE
                                                                        WHEN 
                                                                            psd.ftotal_line <> 0
                                                                            AND psd.fstatus_flag IN (0, 1)
                                                                            AND psd.fextprice IS NOT NULL AND psd.fqty IS NOT NULL
                                                                            AND (
                                                                                psd.ftax_type IS NULL
                                                                                OR psd.ftax_type = 0
                                                                                OR (
                                                                                    psd.ftax_type = 0
                                                                                    AND psd.foriginal_tax_type = 1
                                                                                    AND (
                                                                                        IFNULL(psd.fsc_discp, 0) > 0 OR
                                                                                        IFNULL(psd.fdiscount_percent1, 0) > 0 OR
                                                                                        IFNULL(psd.fdiscount_percent2, 0) > 0 OR
                                                                                        IFNULL(psd.fdiscount_percent5, 0) > 0
                                                                                    )
                                                                                )
                                                                            )
                                                                        THEN
                                                                            CASE
                                                                                WHEN (psd.ftax_type IS NULL OR psd.ftax_type = 0) AND psd.foriginal_tax_type = 1
                                                                                THEN
                                                                                    psd.fextprice * psd.fqty * 1.12 * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                                                ELSE
                                                                                    psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                                            END
                                                                        ELSE 0
                                                                    END
                                                                , 6)
                                                            )
                                                            FROM pos_sale_product psd
                                                            WHERE psd.frecno = a.frecno
                                                                AND psd.fpubid = a.fpubid
                                                                AND psd.ftermid = a.ftermid
                                                                AND psd.fcompanyid = a.fcompanyid
                                                        ) * (1-(pos.fdiscp/100))
                                                    )
                                                    
                                                    +

                                                    -- total tax exclusive
                                                    (
                                                        (
                                                            SELECT SUM(
                                                                ROUND(
                                                                    CASE
                                                                        WHEN 
                                                                            psd.ftotal_line <> 0
                                                                            AND psd.fstatus_flag IN (0, 1)
                                                                            AND psd.ftax_type = 1
                                                                            AND IFNULL(psd.fsc_discp, 0) = 0
                                                                            AND IFNULL(psd.fdiscount_percent1, 0) = 0
                                                                            AND IFNULL(psd.fdiscount_percent2, 0) = 0
                                                                            AND IFNULL(psd.fdiscount_percent5, 0) = 0
                                                                        THEN
                                                                            (psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount) * 1.12
                                                                        ELSE 0
                                                                    END,
                                                                2)
                                                            )
                                                            FROM pos_sale_product psd
                                                            WHERE psd.frecno = a.frecno
                                                            AND psd.fpubid = a.fpubid
                                                            AND psd.ftermid = a.ftermid
                                                            AND psd.fcompanyid = a.fcompanyid
                                                        )  * (1-(pos.fdiscp/100))
                                                    )
                                                )
                                                / pos.fcustomer_count
                                                * (
                                                    -- sr. only
                                                    ABS((pos.fscratio * pos.fcustomer_count))
                                                    -- gov disc customers
                                                    + (
                                                        IFNULL(
                                                            (
                                                                SELECT SUM(psi.fint_data)
                                                                FROM pos_sale_info psi
                                                                WHERE psi.frecno = a.frecno
                                                                    AND psi.fpubid = a.fpubid
                                                                    AND psi.ftermid = a.ftermid
                                                                    AND psi.fcompanyid = a.fcompanyid
                                                                    AND psi.fcode2 IN ('#PWD', '#DIP', '#SPD')
                                                            )
                                                        , 0)
                                                    )
                                                )
                                                / 1.12
                                                + (
                                                    -- total vat exempt
                                                    (
                                                        SELECT SUM(
                                                            ROUND(
                                                                CASE
                                                                    -- First condition: matches outer IF
                                                                    WHEN
                                                                        psd.ftotal_line <> 0
                                                                        AND psd.fstatus_flag IN (0, 1)
                                                                        AND (
                                                                            psd.ftax_type = 4
                                                                            OR (
                                                                                psd.ftax_type = 1 AND (
                                                                                    psd.fdiscount_percent1 > 0  -- PWD
                                                                                    OR psd.fdiscount_percent2 > 0  -- Diplomat
                                                                                    OR psd.fdiscount_percent5 > 0  -- SPD
                                                                                )
                                                                            )
                                                                        )
                                                                        AND psd.foriginal_tax_type NOT IN (2, 3)
                                                                    THEN
                                                                        (psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100)) - psd.fdiscount

                                                                    -- Else condition: fallback IF from Excel
                                                                    WHEN (
                                                                        (
                                                                            IFNULL(psd.fsc_discp, 0) > 0
                                                                            OR IFNULL(psd.fdiscount_percent1, 0) > 0
                                                                            OR IFNULL(psd.fdiscount_percent2, 0) > 0
                                                                            OR IFNULL(psd.fdiscount_percent5, 0) > 0
                                                                        )
                                                                        AND psd.foriginal_tax_type IN (0, 1, 4)
                                                                    )
                                                                    THEN psd.fextprice * psd.fqty

                                                                    ELSE 0
                                                                END,
                                                            2)
                                                        )
                                                        FROM pos_sale_product psd
                                                        WHERE psd.frecno = a.frecno
                                                            AND psd.fpubid = a.fpubid
                                                            AND psd.ftermid = a.ftermid
                                                            AND psd.fcompanyid = a.fcompanyid
                                                    )  * (1-(pos.fdiscp/100))
                                                )
                                            )
                                        )
                                    END
                                , 6)
                            )
                            ELSE NULL
                        END
                    )
                )
                THEN "<- OK ->"
                ELSE "NOT EQUAL"
            END AS "Checker EVAT"
 
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
                            -- gov discounts customers = 0
                            WHEN (
                                (
                                    (ABS((pos.fscratio * pos.fcustomer_count)))
                                    + (
                                        IFNULL(
                                            (
                                                SELECT SUM(psi.fint_data)
                                                FROM pos_sale_info psi
                                                WHERE psi.frecno = a.frecno
                                                    AND psi.fpubid = a.fpubid
                                                    AND psi.ftermid = a.ftermid
                                                    AND psi.fcompanyid = a.fcompanyid
                                                    AND psi.fcode2 IN ('#PWD', '#DIP', '#SPD')
                                            )
                                        , 0)
                                    )
                                ) = 0
                            )

                            THEN (
                                -- total vat exempt
                                (
                                    SELECT SUM(
                                        ROUND(
                                            CASE
                                                -- First condition: matches outer IF
                                                WHEN
                                                    psd.ftotal_line <> 0
                                                    AND psd.fstatus_flag IN (0, 1)
                                                    AND (
                                                        psd.ftax_type = 4
                                                        OR (
                                                            psd.ftax_type = 1 AND (
                                                                psd.fdiscount_percent1 > 0  -- PWD
                                                                OR psd.fdiscount_percent2 > 0  -- Diplomat
                                                                OR psd.fdiscount_percent5 > 0  -- SPD
                                                            )
                                                        )
                                                    )
                                                    AND psd.foriginal_tax_type NOT IN (2, 3)
                                                THEN
                                                    (psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100)) - psd.fdiscount

                                                -- Else condition: fallback IF from Excel
                                                WHEN (
                                                    (
                                                        IFNULL(psd.fsc_discp, 0) > 0
                                                        OR IFNULL(psd.fdiscount_percent1, 0) > 0
                                                        OR IFNULL(psd.fdiscount_percent2, 0) > 0
                                                        OR IFNULL(psd.fdiscount_percent5, 0) > 0
                                                    )
                                                    AND psd.foriginal_tax_type IN (0, 1, 4)
                                                )
                                                THEN psd.fextprice * psd.fqty

                                                ELSE 0
                                            END,
                                        2)
                                    )
                                    FROM pos_sale_product psd
                                    WHERE psd.frecno = a.frecno
                                        AND psd.fpubid = a.fpubid
                                        AND psd.ftermid = a.ftermid
                                        AND psd.fcompanyid = a.fcompanyid
                                ) * (1-(pos.fdiscp/100))
                            )

                            ELSE (
                                (
                                    -- total taxables
                                    (
                                        -- total tax inclusive
                                        (
                                            (
                                                SELECT SUM(
                                                    ROUND(
                                                        CASE
                                                            WHEN 
                                                                psd.ftotal_line <> 0
                                                                AND psd.fstatus_flag IN (0, 1)
                                                                AND psd.fextprice IS NOT NULL AND psd.fqty IS NOT NULL
                                                                AND (
                                                                    psd.ftax_type IS NULL
                                                                    OR psd.ftax_type = 0
                                                                    OR (
                                                                        psd.ftax_type = 0
                                                                        AND psd.foriginal_tax_type = 1
                                                                        AND (
                                                                            IFNULL(psd.fsc_discp, 0) > 0 OR
                                                                            IFNULL(psd.fdiscount_percent1, 0) > 0 OR
                                                                            IFNULL(psd.fdiscount_percent2, 0) > 0 OR
                                                                            IFNULL(psd.fdiscount_percent5, 0) > 0
                                                                        )
                                                                    )
                                                                )
                                                            THEN
                                                                CASE
                                                                    WHEN (psd.ftax_type IS NULL OR psd.ftax_type = 0) AND psd.foriginal_tax_type = 1
                                                                    THEN
                                                                        psd.fextprice * psd.fqty * 1.12 * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                                    ELSE
                                                                        psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount
                                                                END
                                                            ELSE 0
                                                        END
                                                    , 6)
                                                )
                                                FROM pos_sale_product psd
                                                WHERE psd.frecno = a.frecno
                                                    AND psd.fpubid = a.fpubid
                                                    AND psd.ftermid = a.ftermid
                                                    AND psd.fcompanyid = a.fcompanyid
                                            ) * (1-(pos.fdiscp/100))
                                        )
                                        
                                        +

                                        -- total tax exclusive
                                        (
                                            (
                                                SELECT SUM(
                                                    ROUND(
                                                        CASE
                                                            WHEN 
                                                                psd.ftotal_line <> 0
                                                                AND psd.fstatus_flag IN (0, 1)
                                                                AND psd.ftax_type = 1
                                                                AND IFNULL(psd.fsc_discp, 0) = 0
                                                                AND IFNULL(psd.fdiscount_percent1, 0) = 0
                                                                AND IFNULL(psd.fdiscount_percent2, 0) = 0
                                                                AND IFNULL(psd.fdiscount_percent5, 0) = 0
                                                            THEN
                                                                (psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100) - psd.fdiscount) * 1.12
                                                            ELSE 0
                                                        END,
                                                    2)
                                                )
                                                FROM pos_sale_product psd
                                                WHERE psd.frecno = a.frecno
                                                AND psd.fpubid = a.fpubid
                                                AND psd.ftermid = a.ftermid
                                                AND psd.fcompanyid = a.fcompanyid
                                            )  * (1-(pos.fdiscp/100))
                                        )
                                    )
                                    / pos.fcustomer_count
                                    * (
                                        -- sr. only
                                        ABS((pos.fscratio * pos.fcustomer_count))
                                        -- gov disc customers
                                        + (
                                            IFNULL(
                                                (
                                                    SELECT SUM(psi.fint_data)
                                                    FROM pos_sale_info psi
                                                    WHERE psi.frecno = a.frecno
                                                        AND psi.fpubid = a.fpubid
                                                        AND psi.ftermid = a.ftermid
                                                        AND psi.fcompanyid = a.fcompanyid
                                                        AND psi.fcode2 IN ('#PWD', '#DIP', '#SPD')
                                                )
                                            , 0)
                                        )
                                    )
                                    / 1.12
                                    + (
                                        -- total vat exempt
                                        (
                                            SELECT SUM(
                                                ROUND(
                                                    CASE
                                                        -- First condition: matches outer IF
                                                        WHEN
                                                            psd.ftotal_line <> 0
                                                            AND psd.fstatus_flag IN (0, 1)
                                                            AND (
                                                                psd.ftax_type = 4
                                                                OR (
                                                                    psd.ftax_type = 1 AND (
                                                                        psd.fdiscount_percent1 > 0  -- PWD
                                                                        OR psd.fdiscount_percent2 > 0  -- Diplomat
                                                                        OR psd.fdiscount_percent5 > 0  -- SPD
                                                                    )
                                                                )
                                                            )
                                                            AND psd.foriginal_tax_type NOT IN (2, 3)
                                                        THEN
                                                            (psd.fextprice * psd.fqty * (1 - psd.fdiscp / 100)) - psd.fdiscount

                                                        -- Else condition: fallback IF from Excel
                                                        WHEN (
                                                            (
                                                                IFNULL(psd.fsc_discp, 0) > 0
                                                                OR IFNULL(psd.fdiscount_percent1, 0) > 0
                                                                OR IFNULL(psd.fdiscount_percent2, 0) > 0
                                                                OR IFNULL(psd.fdiscount_percent5, 0) > 0
                                                            )
                                                            AND psd.foriginal_tax_type IN (0, 1, 4)
                                                        )
                                                        THEN psd.fextprice * psd.fqty

                                                        ELSE 0
                                                    END,
                                                2)
                                            )
                                            FROM pos_sale_product psd
                                            WHERE psd.frecno = a.frecno
                                                AND psd.fpubid = a.fpubid
                                                AND psd.ftermid = a.ftermid
                                                AND psd.fcompanyid = a.fcompanyid
                                        )  * (1-(pos.fdiscp/100))
                                    )
                                )
                            )
                        END
                    , 6)
                )
                ELSE NULL
            END AS Expected_VatExempt

            -- ----------------------------------------------------------------------------------------------------

        FROM pos_sale_product a 
            LEFT JOIN pos_sale pos
                ON pos.fpubid = a.fpubid 
                AND pos.frecno = a.frecno
            LEFT JOIN pos_sale_product_discount pspd
                ON pspd.fpubid = pos.fpubid 
                AND pspd.ftermid = pos.ftermid 
                AND pspd.fcompanyid = pos.fcompanyid 
                AND pspd.frecno = pos.frecno
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
    WHERE main.Tax_Sale <> main.Expected_TaxSale     
        OR main.Sales_Tax <> main.Expected_SalesTax   
        OR main.VAT_EXEMPT <> main.Expected_VatExempt;
    -- --------------------------------------------------------------------------------------------------------------