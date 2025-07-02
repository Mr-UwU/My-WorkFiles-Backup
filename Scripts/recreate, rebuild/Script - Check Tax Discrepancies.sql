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
            ,ABS((fscratio * fcustomer_count)) AS Seniors_only
            ,(senior_data.senior_count) - ABS((fscratio * fcustomer_count)) as PWD
            
            ,' ' AS '...'
            ,' ' AS '....'
            ,a.frecno AS frecno
            ,pos.ftrx_no AS ftrx_no

            ,' ' AS '.....'

            -- Tax Sale ----------------------------------------------------------------------------------------------------
            -- --------------------------------------------------
            ,pos.finc_sale AS finc_sale
            ,pos.fexc_sale AS fexc_sale

            ,(pos.finc_sale + pos.fexc_sale) AS "inc + exc"

            ,' ' AS "...................."



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
                                        (
                                            SELECT SUM(
                                                ROUND(
                                                    CASE
                                                        WHEN psd.ftax_type = 0
                                                            AND psd.fstatus_flag IN ('0', '1')
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
                                                            AND psd.fstatus_flag IN ('0', '1')
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
                                                        WHEN psd.fstatus_flag NOT IN ('0', '1') 
                                                            OR ftotal_line = 0
                                                                THEN 0

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
                                        * ((pos.fdiscp / 100) + (IFNULL(pspd.fdiscp, 0) / 100))
                                    )
                                , 4)
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
                            (
                                SELECT SUM(
                                    ROUND(
                                        CASE
                                            WHEN psd.ftax_type = 0
                                                AND psd.fstatus_flag IN ('0', '1')
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
                                                AND psd.fstatus_flag IN ('0', '1')
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
                                            WHEN psd.fstatus_flag NOT IN ('0', '1') 
                                                OR ftotal_line = 0
                                                    THEN 0

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
                            * ((pos.fdiscp / 100) + (IFNULL(pspd.fdiscp, 0) / 100))
                        )
                    , 4)
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
                                        (
                                            (
                                                SELECT SUM(
                                                    ROUND(
                                                        CASE
                                                            WHEN psd.ftax_type = 0
                                                                AND psd.fstatus_flag IN ('0', '1')
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
                                                                AND psd.fstatus_flag IN ('0', '1')
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
                                                            WHEN psd.fstatus_flag NOT IN ('0', '1') 
                                                                OR ftotal_line = 0
                                                                    THEN 0

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
                                            * ((pos.fdiscp / 100) + (IFNULL(pspd.fdiscp, 0) / 100))
                                        )
                                    ) / 1.12 * 0.12
                                , 4)
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
                            (
                                (
                                    SELECT SUM(
                                        ROUND(
                                            CASE
                                                WHEN psd.ftax_type = 0
                                                    AND psd.fstatus_flag IN ('0', '1')
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
                                                    AND psd.fstatus_flag IN ('0', '1')
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
                                                WHEN psd.fstatus_flag NOT IN ('0', '1') 
                                                    OR ftotal_line = 0
                                                        THEN 0

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
                                * ((pos.fdiscp / 100) + (IFNULL(pspd.fdiscp, 0) / 100))
                            )
                        ) / 1.12 * 0.12
                    , 4)
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
                                                            AND psd.fstatus_flag IN ('0', '1')
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
                                                                    AND psd.fstatus_flag IN ('0', '1')
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
                                                                    AND psd.fstatus_flag IN ('0', '1')
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
                                                                AND psd.fstatus_flag IN ('0', '1')
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
                                , 4)
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
                                                AND psd.fstatus_flag IN ('0', '1')
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
                                                        AND psd.fstatus_flag IN ('0', '1')
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
                                                        AND psd.fstatus_flag IN ('0', '1')
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
                                                    AND psd.fstatus_flag IN ('0', '1')
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
                    , 4)
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