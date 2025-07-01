-- Update --------------------------------------------------------------------------------------------------------------
-- Set variables (do not remove)
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
                (
                    SELECT SUM(
                        ROUND(
                            CASE
                                WHEN psd.ftax_type = 0
                                    AND psd.fstatus_flag IN (0, 1)
                                    AND psd.ftotal_line <> 0
                                THEN
                                    CASE
                                        WHEN psd.fdiscount > 0 THEN
                                            (psd.fextprice * psd.fqty
                                            * (1 - psd.fdiscp / 100)
                                            * (1 - psd.fdiscount_percent4 / 100)
                                            * (1 - psd.fdiscount_percent6 / 100))
                                            - psd.ftotal_discount
                                        ELSE
                                            (psd.fextprice * psd.fqty
                                            * (1 - psd.fdiscp / 100)
                                            * (1 - psd.fdiscount_percent4 / 100)
                                            * (1 - psd.fdiscount_percent6 / 100))
                                    END
                                ELSE 0
                            END,
                        2)
                    )
                    FROM pos_sale_product psd
                    WHERE psd.frecno = a.frecno
                    AND psd.fpubid = a.fpubid
                    AND psd.ftermid = a.ftermid
                    AND psd.fcompanyid = a.fcompanyid
                    AND psd.fstatus_flag NOT IN ('V', 'W')
                )
                +
                (
                    SELECT SUM(
                        ROUND(
                            CASE
                                WHEN psd.ftax_type = 1
                                    AND psd.fstatus_flag IN (0, 1)
                                    AND psd.ftotal_line <> 0
                                THEN
                                    CASE
                                        WHEN psd.fdiscount > 0 THEN
                                            (psd.fextprice * psd.fqty * 1.12
                                            * (1 - psd.fdiscp / 100)
                                            * (1 - psd.fdiscount_percent4 / 100)
                                            * (1 - psd.fdiscount_percent6 / 100))
                                            - psd.ftotal_discount
                                        ELSE
                                            (psd.fextprice * psd.fqty * 1.12
                                            * (1 - psd.fdiscp / 100)
                                            * (1 - psd.fdiscount_percent4 / 100)
                                            * (1 - psd.fdiscount_percent6 / 100))
                                    END
                                ELSE 0
                            END,
                        2)
                    )
                    FROM pos_sale_product psd
                    WHERE psd.frecno = a.frecno
                    AND psd.fpubid = a.fpubid
                    AND psd.ftermid = a.ftermid
                    AND psd.fcompanyid = a.fcompanyid
                    AND psd.fstatus_flag NOT IN ('V', 'W')
                )
            )
            / pos.fcustomer_count
            * (
                pos.fcustomer_count
                - ABS((pos.fscratio * pos.fcustomer_count))
                - (
                    SELECT COUNT(*)
                    FROM pos_sale_info psi
                    WHERE psi.frecno = a.frecno
                        AND psi.fpubid = a.fpubid
                        AND psi.ftermid = a.ftermid
                        AND psi.fcompanyid = a.fcompanyid
                        AND psi.fcode2 IN ('#PWD', '#DIP', 'NAC', '#SPD', 'MOV')
                )
            )
            - (
                (
                    SELECT SUM(
                        ROUND(
                            CASE
                                WHEN psd.fstatus_flag NOT IN (0, 1) THEN 0

                                -- If fdiscount or fdiscp exists
                                WHEN psd.fdiscount > 0 OR psd.fdiscp > 0 THEN
                                    psd.funitprice * psd.fqty
                                    - CASE 
                                        WHEN psd.fdiscount > 0 THEN psd.ftotal_discount
                                        ELSE psd.funitprice * psd.fqty * psd.fdiscp / 100
                                    END

                                -- If all I:N discount fields are zero/null
                                WHEN (
                                    IFNULL(psd.fsc_discp, 0) = 0 AND
                                    IFNULL(psd.fdiscount_percent1, 0) = 0 AND
                                    IFNULL(psd.fdiscount_percent2, 0) = 0 AND
                                    IFNULL(psd.fdiscount_percent4, 0) = 0 AND
                                    IFNULL(psd.fdiscount_percent5, 0) = 0 AND
                                    IFNULL(psd.fdiscount_percent6, 0) = 0
                                ) THEN
                                    psd.funitprice * psd.fqty

                                -- If tax type is 0 and any of SC/PWD/SPD is 20%
                                WHEN psd.ftax_type = 0 AND (
                                    psd.fsc_discp = 20 OR
                                    psd.fdiscount_percent1 = 20 OR
                                    psd.fdiscount_percent5 = 20
                                ) THEN
                                    (psd.funitprice * psd.fqty) / 1.12
                                    * (1 - psd.fsc_discp / 100)
                                    * (1 - psd.fdiscount_percent1 / 100)
                                    * (1 - psd.fdiscount_percent2 / 100)
                                    * (1 - psd.fdiscount_percent4 / 100)
                                    * (1 - psd.fdiscount_percent5 / 100)
                                    * (1 - psd.fdiscount_percent6 / 100)

                                -- All other cases: Apply all % discounts (I:N)
                                ELSE
                                    psd.funitprice * psd.fqty
                                    * (1 - psd.fsc_discp / 100)
                                    * (1 - psd.fdiscount_percent1 / 100)
                                    * (1 - psd.fdiscount_percent2 / 100)
                                    * (1 - psd.fdiscount_percent4 / 100)
                                    * (1 - psd.fdiscount_percent5 / 100)
                                    * (1 - psd.fdiscount_percent6 / 100)
                            END,
                        2)
                    )
                    FROM pos_sale_product psd
                    WHERE psd.frecno = a.frecno
                        AND psd.fpubid = a.fpubid
                        AND psd.ftermid = a.ftermid
                        AND psd.fcompanyid = a.fcompanyid
                )
                * (pos.fdiscp / 100)
            )
        , 4) AS Expected_TaxSale

        ,ROUND(
            (
                (
                    (
                        SELECT SUM(
                            ROUND(
                                CASE
                                    WHEN psd.ftax_type = 0
                                        AND psd.fstatus_flag IN (0, 1)
                                        AND psd.ftotal_line <> 0
                                    THEN
                                        CASE
                                            WHEN psd.fdiscount > 0 THEN
                                                (psd.fextprice * psd.fqty
                                                * (1 - psd.fdiscp / 100)
                                                * (1 - psd.fdiscount_percent4 / 100)
                                                * (1 - psd.fdiscount_percent6 / 100))
                                                - psd.ftotal_discount
                                            ELSE
                                                (psd.fextprice * psd.fqty
                                                * (1 - psd.fdiscp / 100)
                                                * (1 - psd.fdiscount_percent4 / 100)
                                                * (1 - psd.fdiscount_percent6 / 100))
                                        END
                                    ELSE 0
                                END,
                            2)
                        )
                        FROM pos_sale_product psd
                        WHERE psd.frecno = a.frecno
                        AND psd.fpubid = a.fpubid
                        AND psd.ftermid = a.ftermid
                        AND psd.fcompanyid = a.fcompanyid
                        AND psd.fstatus_flag NOT IN ('V', 'W')
                    )
                    +
                    (
                        SELECT SUM(
                            ROUND(
                                CASE
                                    WHEN psd.ftax_type = 1
                                        AND psd.fstatus_flag IN (0, 1)
                                        AND psd.ftotal_line <> 0
                                    THEN
                                        CASE
                                            WHEN psd.fdiscount > 0 THEN
                                                (psd.fextprice * psd.fqty * 1.12
                                                * (1 - psd.fdiscp / 100)
                                                * (1 - psd.fdiscount_percent4 / 100)
                                                * (1 - psd.fdiscount_percent6 / 100))
                                                - psd.ftotal_discount
                                            ELSE
                                                (psd.fextprice * psd.fqty * 1.12
                                                * (1 - psd.fdiscp / 100)
                                                * (1 - psd.fdiscount_percent4 / 100)
                                                * (1 - psd.fdiscount_percent6 / 100))
                                        END
                                    ELSE 0
                                END,
                            2)
                        )
                        FROM pos_sale_product psd
                        WHERE psd.frecno = a.frecno
                        AND psd.fpubid = a.fpubid
                        AND psd.ftermid = a.ftermid
                        AND psd.fcompanyid = a.fcompanyid
                        AND psd.fstatus_flag NOT IN ('V', 'W')
                    )
                )
                / pos.fcustomer_count
                * (
                    pos.fcustomer_count
                    - ABS((pos.fscratio * pos.fcustomer_count))
                    - (
                        SELECT COUNT(*)
                        FROM pos_sale_info psi
                        WHERE psi.frecno = a.frecno
                            AND psi.fpubid = a.fpubid
                            AND psi.ftermid = a.ftermid
                            AND psi.fcompanyid = a.fcompanyid
                            AND psi.fcode2 IN ('#PWD', '#DIP', 'NAC', '#SPD', 'MOV')
                    )
                )
                - (
                    (
                        SELECT SUM(
                            ROUND(
                                CASE
                                    WHEN psd.fstatus_flag NOT IN (0, 1) THEN 0

                                    -- If fdiscount or fdiscp exists
                                    WHEN psd.fdiscount > 0 OR psd.fdiscp > 0 THEN
                                        psd.funitprice * psd.fqty
                                        - CASE 
                                            WHEN psd.fdiscount > 0 THEN psd.ftotal_discount
                                            ELSE psd.funitprice * psd.fqty * psd.fdiscp / 100
                                        END

                                    -- If all I:N discount fields are zero/null
                                    WHEN (
                                        IFNULL(psd.fsc_discp, 0) = 0 AND
                                        IFNULL(psd.fdiscount_percent1, 0) = 0 AND
                                        IFNULL(psd.fdiscount_percent2, 0) = 0 AND
                                        IFNULL(psd.fdiscount_percent4, 0) = 0 AND
                                        IFNULL(psd.fdiscount_percent5, 0) = 0 AND
                                        IFNULL(psd.fdiscount_percent6, 0) = 0
                                    ) THEN
                                        psd.funitprice * psd.fqty

                                    -- If tax type is 0 and any of SC/PWD/SPD is 20%
                                    WHEN psd.ftax_type = 0 AND (
                                        psd.fsc_discp = 20 OR
                                        psd.fdiscount_percent1 = 20 OR
                                        psd.fdiscount_percent5 = 20
                                    ) THEN
                                        (psd.funitprice * psd.fqty) / 1.12
                                        * (1 - psd.fsc_discp / 100)
                                        * (1 - psd.fdiscount_percent1 / 100)
                                        * (1 - psd.fdiscount_percent2 / 100)
                                        * (1 - psd.fdiscount_percent4 / 100)
                                        * (1 - psd.fdiscount_percent5 / 100)
                                        * (1 - psd.fdiscount_percent6 / 100)

                                    -- All other cases: Apply all % discounts (I:N)
                                    ELSE
                                        psd.funitprice * psd.fqty
                                        * (1 - psd.fsc_discp / 100)
                                        * (1 - psd.fdiscount_percent1 / 100)
                                        * (1 - psd.fdiscount_percent2 / 100)
                                        * (1 - psd.fdiscount_percent4 / 100)
                                        * (1 - psd.fdiscount_percent5 / 100)
                                        * (1 - psd.fdiscount_percent6 / 100)
                                END,
                            2)
                        )
                        FROM pos_sale_product psd
                        WHERE psd.frecno = a.frecno
                            AND psd.fpubid = a.fpubid
                            AND psd.ftermid = a.ftermid
                            AND psd.fcompanyid = a.fcompanyid
                    )
                    * (pos.fdiscp / 100)
                )
            ) / 1.12 * 0.12
        , 4) AS Expected_SalesTax

        ,ROUND(
            CASE
                WHEN (
                    (
                        ABS(pos.fscratio * pos.fcustomer_count)
                        + (
                            SELECT COUNT(*)
                            FROM pos_sale_info psi
                            WHERE psi.frecno = a.frecno
                                AND psi.fpubid = a.fpubid
                                AND psi.ftermid = a.ftermid
                                AND psi.fcompanyid = a.fcompanyid
                                AND psi.fcode2 IN ('#PWD', '#DIP', '#SPD')
                        )
                    ) = 0
                )
                THEN (
                    SELECT SUM(
                        ROUND(
                            CASE
                                WHEN psd.ftax_type = 4
                                    AND psd.fstatus_flag IN (0, 1)
                                    AND psd.ftotal_line <> 0
                                THEN
                                    CASE
                                        WHEN psd.fdiscount > 0 THEN
                                            (psd.fextprice * psd.fqty
                                            * (1 - psd.fdiscp / 100)
                                            * (1 - psd.fdiscount_percent4 / 100)
                                            * (1 - psd.fdiscount_percent6 / 100))
                                            - psd.ftotal_discount
                                        ELSE
                                            (psd.fextprice * psd.fqty
                                            * (1 - psd.fdiscp / 100)
                                            * (1 - psd.fdiscount_percent4 / 100)
                                            * (1 - psd.fdiscount_percent6 / 100))
                                    END
                                ELSE 0
                            END,
                        2)
                    )
                    FROM pos_sale_product psd
                    WHERE psd.frecno = a.frecno
                        AND psd.fpubid = a.fpubid
                        AND psd.ftermid = a.ftermid
                        AND psd.fcompanyid = a.fcompanyid
                        AND psd.fstatus_flag NOT IN ('V', 'W')
                )
                ELSE (
                    (
                        (
                            SELECT SUM(
                                ROUND(
                                    CASE
                                        WHEN psd.ftax_type = 0
                                            AND psd.fstatus_flag IN (0, 1)
                                            AND psd.ftotal_line <> 0
                                        THEN
                                            CASE
                                                WHEN psd.fdiscount > 0 THEN
                                                    (psd.fextprice * psd.fqty
                                                    * (1 - psd.fdiscp / 100)
                                                    * (1 - psd.fdiscount_percent4 / 100)
                                                    * (1 - psd.fdiscount_percent6 / 100))
                                                    - psd.ftotal_discount
                                                ELSE
                                                    (psd.fextprice * psd.fqty
                                                    * (1 - psd.fdiscp / 100)
                                                    * (1 - psd.fdiscount_percent4 / 100)
                                                    * (1 - psd.fdiscount_percent6 / 100))
                                            END
                                        ELSE 0
                                    END,
                                2)
                            )
                            FROM pos_sale_product psd
                            WHERE psd.frecno = a.frecno
                            AND psd.fpubid = a.fpubid
                            AND psd.ftermid = a.ftermid
                            AND psd.fcompanyid = a.fcompanyid
                            AND psd.fstatus_flag NOT IN ('V', 'W')
                        )
                        +
                        (
                            SELECT SUM(
                                ROUND(
                                    CASE
                                        WHEN psd.ftax_type = 1
                                            AND psd.fstatus_flag IN (0, 1)
                                            AND psd.ftotal_line <> 0
                                        THEN
                                            CASE
                                                WHEN psd.fdiscount > 0 THEN
                                                    (psd.fextprice * psd.fqty * 1.12
                                                    * (1 - psd.fdiscp / 100)
                                                    * (1 - psd.fdiscount_percent4 / 100)
                                                    * (1 - psd.fdiscount_percent6 / 100))
                                                    - psd.ftotal_discount
                                                ELSE
                                                    (psd.fextprice * psd.fqty * 1.12
                                                    * (1 - psd.fdiscp / 100)
                                                    * (1 - psd.fdiscount_percent4 / 100)
                                                    * (1 - psd.fdiscount_percent6 / 100))
                                            END
                                        ELSE 0
                                    END,
                                2)
                            )
                            FROM pos_sale_product psd
                            WHERE psd.frecno = a.frecno
                            AND psd.fpubid = a.fpubid
                            AND psd.ftermid = a.ftermid
                            AND psd.fcompanyid = a.fcompanyid
                            AND psd.fstatus_flag NOT IN ('V', 'W')
                        )
                    )
                    / pos.fcustomer_count
                    * (
                        ABS((pos.fscratio * pos.fcustomer_count))
                        + (
                            SELECT COUNT(*)
                            FROM pos_sale_info psi
                            WHERE psi.frecno = a.frecno
                                AND psi.fpubid = a.fpubid
                                AND psi.ftermid = a.ftermid
                                AND psi.fcompanyid = a.fcompanyid
                                AND fcode2 IN ('#PWD', '#DIP', '#SPD')
                        )
                    )
                    / 1.12
                    + (
                        SELECT SUM(
                            ROUND(
                                CASE
                                    WHEN psd.ftax_type = 4
                                        AND psd.fstatus_flag IN (0, 1)
                                        AND psd.ftotal_line <> 0
                                    THEN
                                        CASE
                                            WHEN psd.fdiscount > 0 THEN
                                                (psd.fextprice * psd.fqty
                                                * (1 - psd.fdiscp / 100)
                                                * (1 - psd.fdiscount_percent4 / 100)
                                                * (1 - psd.fdiscount_percent6 / 100))
                                                - psd.ftotal_discount
                                            ELSE
                                                (psd.fextprice * psd.fqty
                                                * (1 - psd.fdiscp / 100)
                                                * (1 - psd.fdiscount_percent4 / 100)
                                                * (1 - psd.fdiscount_percent6 / 100))
                                        END
                                    ELSE 0
                                END,
                            2)
                        )
                        FROM pos_sale_product psd
                        WHERE psd.frecno = a.frecno
                            AND psd.fpubid = a.fpubid
                            AND psd.ftermid = a.ftermid
                            AND psd.fcompanyid = a.fcompanyid
                            AND psd.fstatus_flag NOT IN ('V', 'W')
                    )
                )
            END
        , 4) AS Expected_VatExempt

    FROM pos_sale_product a
    JOIN pos_sale pos
        ON pos.frecno = a.frecno
        AND pos.fpubid = a.fpubid
        AND pos.ftermid = a.ftermid
        AND pos.fcompanyid = a.fcompanyid
    WHERE pos.fcompanyid = @companyID
        AND pos.fpubid = @pubID
        AND pos.ftermid = @termID
        AND pos.fsale_date BETWEEN @saleDateFrom AND @saleDateTo
        AND pos.ftrx_no != 0
        AND pos.fcustomer_count <> 0
        AND NOT (pos.fscdiscount <> 0 AND pos.fline_scdiscount <> 0)
    GROUP BY a.frecno
) calc
ON pos.frecno = calc.frecno
    AND pos.fpubid = calc.fpubid
    AND pos.ftermid = calc.ftermid
    AND pos.fcompanyid = calc.fcompanyid
SET 
    pos.ftax_sale = calc.Expected_TaxSale,
    pos.ftax = calc.Expected_SalesTax,
    pos.fvat_exempt = calc.Expected_VatExempt;
