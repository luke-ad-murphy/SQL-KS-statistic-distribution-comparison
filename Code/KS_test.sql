/* ===================================================================================== */
/* APPLYING KOLMOGOROV-SMIRNOV TESTS FOR RSSNR DISTRIBUTIONS */
/* ===================================================================================== */

### Reference materials:
# https://en.wikipedia.org/wiki/Kolmogorov%E2%80%93Smirnov_test
# https://www.youtube.com/watch?v=ZO2RmSkXK3c
# https://towardsdatascience.com/comparing-sample-distributions-with-the-kolmogorov-smirnov-ks-test-a2292ad6fee5


###########################################################################################
###########################################################################################
###########################################################################################

## Compare CDFs of SDK, OS, Model and chipset versus accepted CDF and flag for treatments:
        -- 1 - CDF represents control so no treatment required
        -- 2 - Range compressed to between -2 and +3 so multiplication by 10 required
        -- 3 - Range expanded to -200 to +300 so division by 10 required
CREATE OR REPLACE TABLE `my-project.my-dataset.UK_RSSNR_TREATMENTS` AS (
WITH control AS (
        SELECT * FROM `my-project.my-dataset.UK_EXPECTED_RSSNR_CDF`
        ),

test AS (
        SELECT * FROM `my-project.my-dataset.UK_UNEXPECTED_RSSNR_CDF`
        ),

both AS (
        SELECT  t.Device_SDKVersion
                ,t.Device_OSBrandName
                ,t.Device_ModelBrandName
                ,t.Device_ChipsetBrandName
                ,t.RSSNR
                ,t.cumulative_cnt AS t_cum_cnt
                ,t.cumulative_pct AS t_cum_pct
                ,c.cumulative_cnt AS c_cum_cnt
                ,c.cumulative_pct AS c_cum_pct
                ,c.cumulative_pct - t.cumulative_pct AS Delta
        FROM    test AS t
        LEFT JOIN    control AS c
        ON      t.RSSNR = c.RSSNR
        ORDER BY Device_SDKVersion, Device_OSBrandName, Device_ModelBrandName, Device_ChipsetBrandName, RSSNR
        )

SELECT  *
        -- Flag for no treatment required
        ,CASE WHEN KS_statistic_D <= 0.15 
                AND p_value <=0.05 
                AND t_popn >=500 THEN 1 
                ELSE 0 END AS EST_NO_TREATMENT_REQUIRED 

        -- Flag for applying multiply by 10 rule
        ,CASE WHEN MIN_RSSNR >= -2 
                AND MAX_RSSNR <= 3
                AND t_popn >=500 THEN 1 
                ELSE 0 END AS EST_MULTIPLY_BY_TEN

        -- Flag for applying divide by 10 rule
        ,CASE WHEN MIN_RSSNR = -200 
                AND MAX_RSSNR = 300
                AND t_popn >=500 THEN 1 
                ELSE 0 END AS EST_DIVIDE_BY_TEN

FROM    (
        SELECT  Device_SDKVersion
                ,Device_OSBrandName
                ,Device_ModelBrandName
                ,Device_ChipsetBrandName
                ,MAX(c_cum_cnt) AS c_popn
                ,MAX(t_cum_cnt) AS t_popn
                ,MAX(ABS(Delta)) AS KS_statistic_D
                ,1.63 * (SQRT((MAX(c_cum_cnt) + MAX(t_cum_cnt)) / (MAX(c_cum_cnt) * MAX(t_cum_cnt)))) AS p_value
                ,MIN(RSSNR) AS MIN_RSSNR
                ,MAX(RSSNR) AS MAX_RSSNR

        FROM    both
        GROUP BY Device_SDKVersion, Device_OSBrandName, Device_ModelBrandName, Device_ChipsetBrandName
        ORDER BY t_popn DESC
)
);



## Distribtuion after applying solution: 
        -- 1 leave,
        -- 2 multiply by 10
        -- 3 divide by 10
SELECT  ROUND(RSSNR_CORRECTED, 0) AS RSSNR_CORRECTED
        ,COUNT(*) AS Measurements

FROM    (
        SELECT  Raw.Device_SDKVersion
                ,Raw.Device_OSBrandName
                ,Raw.Device_ModelBrandName
                ,Raw.Device_ChipsetBrandName
                ,Raw.QOS_RSSNR
                ,treatments.EST_NO_TREATMENT_REQUIRED
                ,treatments.EST_MULTIPLY_BY_TEN
                ,treatments.EST_DIVIDE_BY_TEN
                --,CASE WHEN EST_NO_TREATMENT_REQUIRED = 1 THEN QOS_RSSNR
                --        WHEN EST_MULTIPLY_BY_TEN = 1 THEN (QOS_RSSNR * 10) 
                --        WHEN EST_DIVIDE_BY_TEN = 1 THEN (QOS_RSSNR / 10) 
                --                ELSE QOS_RSSNR END AS RSSNR_CORRECTED

                ,CASE WHEN EST_MULTIPLY_BY_TEN = 1 THEN (QOS_RSSNR * 10) 
                        WHEN EST_DIVIDE_BY_TEN = 1 THEN (QOS_RSSNR / 10) 
                        WHEN QOS_RSSNR < -20 THEN -20
                        WHEN QOS_RSSNR > 30 THEN 30
                                ELSE QOS_RSSNR END AS RSSNR_CORRECTED

        FROM    `denseware-prod-1-d7b8.d_tutela_raw_us_prod.t_tutela_UnitedKingdom_202*` AS Raw
        JOIN    `my-project.my-dataset.UK_RSSNR_TREATMENTS` AS treatments
        ON      (Raw.Device_SDKVersion = treatments.Device_SDKVersion
                AND Raw.Device_OSBrandName = treatments.Device_OSBrandName
                AND Raw.Device_ModelBrandName = treatments.Device_ModelBrandName
                AND Raw.Device_ChipsetBrandName = treatments.Device_ChipsetBrandName)
        WHERE   QOS_RSSNR IS NOT NULL
        AND     Connection_Category = '4G'
        AND     (treatments.EST_NO_TREATMENT_REQUIRED = 1 OR treatments.EST_MULTIPLY_BY_TEN = 1 OR treatments.EST_DIVIDE_BY_TEN = 1)
        )
GROUP BY RSSNR_CORRECTED
ORDER BY RSSNR_CORRECTED
;



###########################################################################################
###########################################################################################
###########################################################################################
############################## E N D    OF     P R O G R A M ##############################
###########################################################################################
###########################################################################################
###########################################################################################
