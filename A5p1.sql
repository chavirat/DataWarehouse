1.
SELECT CalMonth, AddrCatCode1, SUM(ExtCost) as TotalExtCost, sum(quantity) as TotalQuantity
FROM inventory_fact,date_dim,cust_vendor_dim
WHERE inventory_fact.DateKey = date_dim.DateKey
AND inventory_fact.CustVendorKey = cust_vendor_dim.CustVendorKey
AND CalYear = 2011
AND TransTypeKey = 5
GROUP BY CUBE (CalMonth, AddrCatCode1);
2.
SELECT Name,CalYear, CalQuarter,  SUM(ExtCost) as TotalExtCost, count(TransTypeKey) as NumberInventoryTrans
FROM inventory_fact,date_dim,cust_vendor_dim
WHERE inventory_fact.DateKey = date_dim.DateKey
AND inventory_fact.CustVendorKey = cust_vendor_dim.CustVendorKey
AND CalYear in(2011,2012)
AND TransTypeKey = 5
GROUP BY cube (Name,CalYear,CalQuarter);
3.
SELECT SecondItemId,  SUM(ExtCost) as TotalExtCost,sum(quantity) as TotalQuantity, count(TransTypeKey) as NumberInventoryTrans
FROM inventory_fact,item_master_dim
WHERE inventory_fact.ItemMasterKey = item_master_dim.ItemMasterKey
AND TransTypeKey = 1
GROUP BY cube (SecondItemId)
ORDER BY SecondItemId;
4.
SELECT SecondItemId, BPName, SUM(ExtCost) as TotalExtCost,sum(quantity) as TotalQuantity
FROM inventory_fact,item_master_dim,branch_plant_dim
WHERE inventory_fact.ItemMasterKey = item_master_dim.ItemMasterKey
AND inventory_fact.BranchPlantKey = branch_plant_dim.BranchPlantKey
AND TransTypeKey = 2
GROUP BY ROLLUP (SecondItemId, BPName);
5.
SELECT TransDescription, CompanyName, SUM(ExtCost) as TotalExtCost,count(*) as NumberInventoryTrans
FROM inventory_fact,branch_plant_dim,company_dim,trans_type_dim
WHERE inventory_fact.TransTypeKey = trans_type_dim.TransTypeKey
AND inventory_fact.BranchPlantKey = branch_plant_dim.BranchPlantKey
AND branch_plant_dim.CompanyKey = company_dim.CompanyKey
GROUP BY Rollup (TransDescription, CompanyName);
6.
SELECT CalMonth, AddrCatCode1, SUM(ExtCost) as TotalExtCost, sum(quantity) as TotalQuantity
FROM inventory_fact,date_dim,cust_vendor_dim
WHERE inventory_fact.DateKey = date_dim.DateKey
AND inventory_fact.CustVendorKey = cust_vendor_dim.CustVendorKey
AND CalYear = 2011
AND TransTypeKey = 5
GROUP BY CalMonth, AddrCatCode1
UNION
SELECT CalMonth, 0, SUM(ExtCost) as TotalExtCost, sum(quantity) as TotalQuantity
FROM inventory_fact,date_dim,cust_vendor_dim
WHERE inventory_fact.DateKey = date_dim.DateKey
AND inventory_fact.CustVendorKey = cust_vendor_dim.CustVendorKey
AND CalYear = 2011
AND TransTypeKey = 5
GROUP BY CalMonth
UNION
SELECT 0, AddrCatCode1, SUM(ExtCost) as TotalExtCost, sum(quantity) as TotalQuantity
FROM inventory_fact,date_dim,cust_vendor_dim
WHERE inventory_fact.DateKey = date_dim.DateKey
AND inventory_fact.CustVendorKey = cust_vendor_dim.CustVendorKey
AND CalYear = 2011
AND TransTypeKey = 5
GROUP BY AddrCatCode1
UNION
SELECT 0, 0, SUM(ExtCost) as TotalExtCost, sum(quantity) as TotalQuantity
FROM inventory_fact,date_dim,cust_vendor_dim
WHERE inventory_fact.DateKey = date_dim.DateKey
AND inventory_fact.CustVendorKey = cust_vendor_dim.CustVendorKey
AND CalYear = 2011
AND TransTypeKey = 5;
7.
SELECT SecondItemId,BPName SUM(ExtCost) as TotalExtCost,sum(quantity) as TotalQuantity
FROM inventory_fact,item_master_dim,branch_plant_dim
WHERE inventory_fact.ItemMasterKey = item_master_dim.ItemMasterKey
AND inventory_fact.BranchPlantKey = branch_plant_dim.BranchPlantKey
AND TransTypeKey = 2
GROUP BY SecondItemId,BPName
UNION
SELECT SecondItemId,'0', SUM(ExtCost) as TotalExtCost,sum(quantity) as TotalQuantity
FROM inventory_fact,item_master_dim,branch_plant_dim
WHERE inventory_fact.ItemMasterKey = item_master_dim.ItemMasterKey
AND inventory_fact.BranchPlantKey = branch_plant_dim.BranchPlantKey
AND TransTypeKey = 2
GROUP BY SecondItemId
UNION
SELECT '0','0', SUM(ExtCost) as TotalExtCost,sum(quantity) as TotalQuantity
FROM inventory_fact,item_master_dim,branch_plant_dim
WHERE inventory_fact.ItemMasterKey = item_master_dim.ItemMasterKey
AND inventory_fact.BranchPlantKey = branch_plant_dim.BranchPlantKey
AND TransTypeKey = 2;

Part2. Analytic Functions
--1.
SELECT Name, SUM(ExtCost) as TotalExtCost, 
RANK() OVER (ORDER BY SUM(ExtCost) DESC) AS ExtCostRank
FROM inventory_fact,cust_vendor_dim
WHERE inventory_fact.CustVendorKey = cust_vendor_dim.CustVendorKey
AND TransTypeKey = 5
GROUP BY Name;
--2.
SELECT state, Name, SUM(ExtCost) as TotalExtCost, 
RANK() OVER (PARTITION BY state 
ORDER BY SUM(ExtCost) DESC) AS ExtCostRank
FROM inventory_fact,cust_vendor_dim
WHERE inventory_fact.CustVendorKey = cust_vendor_dim.CustVendorKey
AND TransTypeKey = 5
GROUP BY state, Name;
--3.
SELECT Name, count(TransTypeKey) as NumberInventoryTrans,
RANK() OVER (ORDER BY SUM(TransTypeKey) DESC) AS Rank_InventoryTrans,
DENSE_RANK() OVER (ORDER BY SUM(TransTypeKey) DESC) AS DenseRank_InventoryTrans
FROM inventory_fact,cust_vendor_dim
WHERE inventory_fact.CustVendorKey = cust_vendor_dim.CustVendorKey
AND TransTypeKey = 5
GROUP BY Name;
--4.
SELECT Zip, CalYear, CalMonth,SUM(ExtCost) as TotalExtCost,
SUM(SUM(ExtCost)) OVER 
   (ORDER BY Zip, CalYear, CalMonth ROWS UNBOUNDED PRECEDING ) AS CumSumExtCost
FROM inventory_fact,date_dim,cust_vendor_dim
WHERE inventory_fact.DateKey = date_dim.DateKey
AND inventory_fact.CustVendorKey = cust_vendor_dim.CustVendorKey
GROUP BY Zip, CalYear, CalMonth ;
--5.
SELECT Zip, CalYear, CalMonth,SUM(ExtCost) as TotalExtCost,
SUM(SUM(ExtCost)) OVER (PARTITION BY Zip, CalYear
    ORDER BY Zip, CalYear, CalMonth ROWS UNBOUNDED PRECEDING ) AS CumSumExtCost 
FROM inventory_fact,date_dim,cust_vendor_dim
WHERE inventory_fact.DateKey = date_dim.DateKey
AND inventory_fact.CustVendorKey = cust_vendor_dim.CustVendorKey
GROUP BY Zip, CalYear, CalMonth ;
--6.
SELECT SecondItemId,SUM(ExtCost) as TotalExtCost,
RATIO_TO_REPORT(SUM(ExtCost)) OVER () AS Ratio_To_Report 
FROM inventory_fact,item_master_dim
WHERE inventory_fact.ItemMasterKey = item_master_dim.ItemMasterKey
AND TransTypeKey = 1
GROUP BY SecondItemId 
ORDER BY SUM(ExtCost)DESC;
--7.
SELECT CalYear,SecondItemId,SUM(ExtCost) as TotalExtCost,
RATIO_TO_REPORT(SUM(ExtCost)) OVER (PARTITION BY CalYear)  AS Ratio_To_Report 
FROM inventory_fact,item_master_dim,date_dim
WHERE inventory_fact.ItemMasterKey = item_master_dim.ItemMasterKey
AND inventory_fact.DateKey = date_dim.DateKey
AND TransTypeKey = 1
GROUP BY CalYear, SecondItemId 
ORDER BY CalYear DESC, SUM(ExtCost)DESC;
--8.
SELECT BPName, CompanyKey, CarryingCost,
RANK () OVER (ORDER BY CarryingCost) AS Rank_CarryingCost,
PERCENT_RANK() OVER (ORDER BY CarryingCost) AS PercentRank_CarryingCost,
CUME_DIST() OVER (ORDER BY CarryingCost) As CumDist_CarryingCost
FROM branch_plant_dim;
--9.
SELECT BPName, CompanyKey, CarryingCost, CumDist_CarryingCost
FROM ( SELECT BPName, CompanyKey, CarryingCost, CUME_DIST() OVER (ORDER BY CarryingCost) As CumDist_CarryingCost
FROM branch_plant_dim 
ORDER BY CarryingCost DESC)
WHERE ROWNUM <=15;
--10.
SELECT DISTINCT ExtCost, CUME_DIST() OVER (ORDER BY ExtCost) As CumDist_ExtCost
FROM inventory_fact, cust_vendor_dim
WHERE inventory_fact.CustVendorKey = cust_vendor_dim.CustVendorKey
AND State = 'CO'
ORDER BY ExtCost;
