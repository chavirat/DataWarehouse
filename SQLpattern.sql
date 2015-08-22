--SQL pattern matching case of Stock Market Analysis
--2.	The query shows stocks where the current price is more than a specific percentage as 3% below the prior day's closing price. The stock normally changes less than 1% for a week, therefore, the drop of 3% is significantly high.
SELECT * FROM STOCK MATCH_RECOGNIZE (
PARTITION BY symbol
ORDER BY tstamp
MEASURES B.tstamp AS timestamp,
A.price AS Aprice,
B.price AS Bprice,
((B.price - A.price)*100) / A.price AS PctDrop
ONE ROW PER MATCH
AFTER MATCH SKIP TO B
PATTERN (A B)
DEFINE
B AS (B.price - A.price) / A.price  < - 0.03  );
 
--3.	The query finds a stock with a price drop of more than 3% (extends from query 2). It also seeks zero or more additional days when the stock price remains below the original price. Then, it identifies when the stock has risen in price to equal or exceed its initial value. Because it can be useful to know the number of days that the pattern occurs, it is included here. The start_price column is the starting price of a match and the end_price column is the end price of a match, when the price is equal to or greater than the start price. 
SELECT * FROM stock MATCH_RECOGNIZE (
PARTITION BY symbol 
ORDER BY tstamp 
MEASURES
A.tstamp      as start_timestamp,
A.price       as start_price,
B.price       as drop_price, 
COUNT(C.*)+1  as cnt_days,
D.tstamp      as end_timestamp, 
D.price       as end_price  
ONE ROW PER MATCH 
AFTER MATCH SKIP PAST LAST ROW 
PATTERN (A B C* D) 
DEFINE
B as (B.price - A.price)/A.price < - 0.03, 
C as C.price < A.price, 
D as D.price >= A.price  );
 

--4.	The query demonstrates pattern match for a Simple V-Shape with 1 row output per Match
SELECT * FROM stock MATCH_RECOGNIZE (
PARTITION BY symbol
ORDER BY tstamp
MEASURES STRT.tstamp AS start_tstamp, 
DOWN.tstamp AS bottom_tstamp, 
UP.tstamp AS end_tstamp
ONE ROW PER MATCH
AFTER MATCH SKIP TO LAST UP
PATTERN (STRT DOWN+ UP+)
DEFINE DOWN AS DOWN.price < PREV(DOWN.price),
UP AS UP.price > PREV(UP.price)
) MR
ORDER BY MR.symbol, MR.start_tstamp; 

--5.	The query demonstrates pattern match for a Simple V-Shape with all rows output per match.
SELECT * FROM stock MATCH_RECOGNIZE ( 
PARTITION BY symbol 
ORDER BY tstamp 
MEASURES STRT.tstamp AS start_tstamp, 
FINAL LAST (DOWN.tstamp) AS bottom_tstamp, 
FINAL LAST (UP.tstamp) AS end_tstamp, 
MATCH_NUMBER () AS match_num, 
CLASSIFIER () AS var_match 
ALL ROWS PER MATCH 
AFTER MATCH SKIP TO LAST UP 
PATTERN (STRT DOWN+ UP+)
DEFINE
DOWN AS DOWN.price < PREV (DOWN.price), 
UP AS UP.price > PREV (UP.price) ) MR 
ORDER BY MR.symbol, MR.match_num, MR.tstamp;
 

--6.	The query shows a simple version of a class of stock price patterns referred to as the Elliott Wave, which has multiple consecutive patterns of inverted V-shapes.
SELECT MR_ELLIOTT.*
FROM stock MATCH_RECOGNIZE (
     PARTITION BY symbol
     ORDER BY tstamp
     MEASURES
              COUNT (*) as CNT,
              COUNT (P.*) AS CNT_P,
              COUNT (Q.*) AS CNT_Q,
              COUNT (R.*) AS CNT_R,
              COUNT (S.*) AS CNT_S,
              COUNT (T.*) AS CNT_T,
              COUNT (U.*) AS CNT_U,
              COUNT (V.*) AS CNT_V,
              COUNT (W.*) AS CNT_W,
              COUNT (X.*) AS CNT_X,
              COUNT (Y.*) AS CNT_Y,
              CLASSIFIER() AS CLS,
     MATCH_NUMBER() AS MNO
     ALL ROWS PER MATCH
     AFTER MATCH SKIP TO LAST y
     PATTERN (P Q+ R+ S+ T+ U+ V+ W+ X+ Y+)
     DEFINE
        Q AS Q.price > PREV (Q.price),
        R AS R.price < PREV (R.price),
        S AS S.price > PREV (S.price),
        T AS T.price < PREV (T.price),
        U AS U.price > PREV (U.price),
        V AS V.price < PREV (V.price),
        W AS W.price > PREV (W.price),
        X AS X.price < PREV (X.price),
        Y AS Y.price > PREV (Y.price)
   ) MR_ELLIOTT
ORDER BY symbol, tstamp;
 
--7.	The query shows W-shaped pattern
SELECT *
FROM stock MATCH_RECOGNIZE (
PARTITION BY symbol
ORDER BY tstamp
MEASURES STRT.tstamp AS start_tstamp,
UP.tstamp AS end_tstamp
ONE ROW PER MATCH
AFTER MATCH SKIP TO LAST UP
PATTERN (STRT DOWN+ UP+ DOWN+ UP+)
DEFINE
DOWN AS DOWN.price < PREV (DOWN.price),
UP AS UP.price > PREV (UP.price)
) MR
ORDER BY MR.symbol, MR.start_tstamp;

 
--8.	The query shows W-shaped pattern by using the power of the AFTER MATCH SKIP TO clause to find overlapping matches. It has a simple pattern that seeks a W-shape made up of pattern variables Q, R, S, and T. For each leg of the W, the number of rows can be one or more.
SELECT MR_W.*
FROM stock MATCH_RECOGNIZE (
     PARTITION BY symbol
     ORDER BY tstamp
     MEASURES 
        MATCH_NUMBER() AS MNO,
        P.tstamp AS START_T,
        T.tstamp AS END_T,
        MAX (P.price) AS TOP_L,
        MIN (Q.price) AS BOTT1,
        MAX (R.price) AS TOP_M,
        MIN (S.price) AS BOTT2,
        MAX (T.price) AS TOP_R
     ALL ROWS PER MATCH
     AFTER MATCH SKIP TO LAST R
     PATTERN (P Q+ R+ S+ T+)
     DEFINE
        Q AS Q.price < PREV (Q.price),
        R AS R.price > PREV (R.price),
        S AS S.price < PREV (S.price),
        T AS T.price > PREV (T.price)
) MR_W
ORDER BY symbol, mno, tstamp;

 

