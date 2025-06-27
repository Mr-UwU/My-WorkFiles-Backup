-- Set variables (do not remove)
SET 	
    @companyID := 'SHOST-10050582',
    @pubID := 'SHOST-10050582-0002',
    @termID := '0002',
    @saleDateFrom := '20250301',
    @saleDateTo := '20250325';

UPDATE pos_sale pos
JOIN (
    SELECT 
        a.frecno,
        a.fpubid,
        a.ftermid,
        a.fcompanyid,



        ROUND(
            (
                (
                    (
                        SELECT 
                            SUM(
                                CASE 
                                    WHEN sub.ftax_type = 0 AND sub.fstatus_flag NOT IN ('V','W') 
                                    THEN sub.ftotal_line 
                                    ELSE 0 
                                END
                            )
                        FROM pos_sale_product sub
                        WHERE sub.frecno = a.frecno AND sub.fpubid = a.fpubid 
                            AND sub.ftermid = a.ftermid AND sub.fcompanyid = a.fcompanyid
                    ) 
                    + 
                    (
                        SELECT SUM(
                                    CASE 
                                        WHEN sub.ftax_type = 1 AND sub.fstatus_flag NOT IN ('V','W') 
                                        THEN sub.ftotal_line 
                                        ELSE 0 
                                    END
                                )
                        FROM pos_sale_product sub
                        WHERE sub.frecno = a.frecno AND sub.fpubid = a.fpubid AND sub.ftermid = a.ftermid AND sub.fcompanyid = a.fcompanyid
                    ) * 1.12
                )
                / pos.fcustomer_count
                * (pos.fcustomer_count 
                    -   (
                            CASE 
                                WHEN pos.fcustomer_count > 0 
                                THEN (
                                    SELECT COUNT(*)
                                    FROM pos_sale_senior pss
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
        , 4) AS Expected_TaxSale

        

        ,ROUND(
            (
                (
                    (
                        (
                            SELECT SUM(
                                        CASE 
                                            WHEN sub.ftax_type = 0 AND sub.fstatus_flag NOT IN ('V','W') 
                                            THEN sub.ftotal_line 
                                            ELSE 0 
                                        END
                                    )
                            FROM pos_sale_product sub
                            WHERE sub.frecno = a.frecno AND sub.fpubid = a.fpubid AND sub.ftermid = a.ftermid AND sub.fcompanyid = a.fcompanyid
                        ) 
                        + 
                        (
                            SELECT SUM(
                                        CASE   
                                            WHEN sub.ftax_type = 1 AND sub.fstatus_flag NOT IN ('V','W') 
                                            THEN sub.ftotal_line 
                                            ELSE 0 
                                        END
                                    )
                            FROM pos_sale_product sub
                            WHERE sub.frecno = a.frecno AND sub.fpubid = a.fpubid AND sub.ftermid = a.ftermid AND sub.fcompanyid = a.fcompanyid
                        ) * 1.12
                    )
                    / pos.fcustomer_count
                    * (pos.fcustomer_count 
                        -   (
                                CASE 
                                    WHEN pos.fcustomer_count > 0 
                                    THEN (
                                        SELECT COUNT(*)
                                        FROM pos_sale_senior pss
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
            ) / 1.12 * 0.12
        , 4) AS Expected_SalesTax

        

        ,ROUND(
            (
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
        AND pos.fdiscount2 = 0
        AND pos.fdiscount4 = 0
        AND pos.fdiscount5 = 0
        AND pos.fdiscount6 = 0
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
