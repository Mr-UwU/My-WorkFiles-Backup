SET 	
    @companyID := 'SHOST-10050582',
	@pubID := 'SHOST-10050582-0002',
	@termID := '0002',
	@saleDateFrom := '20250101',
	@saleDateTo := '20250510';

UPDATE pos_sale pos
JOIN(
    SELECT
        a.frecno
        ,a.fpubid
        ,a.ftermid
        ,a.fcompanyid

        ,ROUND(
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
        , 6) AS Expected_TaxSale

        ,ROUND(
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
        , 6) AS Expected_SalesTax

        ,ROUND(
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
        , 6)  AS Expected_VatExempt

    FROM pos_sale_product a
        LEFT JOIN pos_sale pos
            ON pos.frecno = a.frecno
            AND pos.fpubid = a.fpubid
            AND pos.ftermid = a.ftermid
            AND pos.fcompanyid = a.fcompanyid
        LEFT JOIN pos_sale_product_discount pspd
                ON pspd.fpubid = pos.fpubid 
                AND pspd.ftermid = pos.ftermid 
                AND pspd.fcompanyid = pos.fcompanyid 
                AND pspd.frecno = pos.frecno
    WHERE pos.fcompanyid = @companyID
        AND pos.fpubid = @pubID
        AND pos.ftermid = @termID
        AND pos.fsale_date BETWEEN @saleDateFrom AND @saleDateTo
        AND pos.ftrx_no != 0
        AND pos.fcustomer_count <> 0
        AND NOT (pos.fscdiscount <> 0 AND pos.fline_scdiscount <> 0)
    GROUP BY a.frecno
) main
ON pos.frecno = main.frecno
    AND pos.fpubid = main.fpubid
    AND pos.ftermid = main.ftermid
    AND pos.fcompanyid = main.fcompanyid
SET 
    pos.ftax_sale = main.Expected_TaxSale,
    pos.ftax = main.Expected_SalesTax,
    pos.fvat_exempt = main.Expected_VatExempt;
