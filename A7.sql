--1. Create Materialized Views 
DROP MATERIALIZED VIEW  MV1;
CREATE MATERIALIZED VIEW MV1
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE AS
SELECT CustVendorKey, inventory_fact.DateKey, SUM(ExtCost) AS TotalExtCost, SUM(quantity) AS TotalQuantity, COUNT(*) AS NumberInventoryTrans
 FROM inventory_fact, date_dim
 WHERE inventory_fact.DateKey = date_dim.DateKey
      AND TransTypeKey = 5
      AND CalYear = 2011
 GROUP BY CustVendorKey, inventory_fact.DateKey;
 DROP MATERIALIZED VIEW  MV2;
CREATE MATERIALIZED VIEW MV2
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE AS
SELECT CustVendorKey, inventory_fact.DateKey, SUM(ExtCost) AS TotalExtCost, SUM(quantity) AS TotalQuantity, COUNT(*) AS NumberInventoryTrans
 FROM inventory_fact, date_dim
 WHERE inventory_fact.DateKey = date_dim.DateKey
      AND TransTypeKey = 5
      AND CalYear = 2012
 GROUP BY CustVendorKey, inventory_fact.DateKey;

2. Use Meterialized Views to Rewrite Queires
2.1 QUERY 1
SELECT CalMonth, AddrCatCode1, SUM(TotalExtCost) AS SumTotalExtCost, SUM(TotalQuantity) AS SumTotalQuantity
FROM MV1, date_dim, cust_vendor_dim
WHERE MV1.DateKey = date_dim.DateKey
AND MV1.CustVendorKey = cust_vendor_dim.CustVendorKey
GROUP BY CUBE (CalMonth, AddrCatCode1);

2.2 QUERY 2
SELECT Name, CalYear, CalQuarter,  SUM(TotalExtCost) AS TotalExtCost, SUM(NumberInventoryTrans) AS NumberInventoryTrans
FROM 
(SELECT Name, CalYear, CalQuarter,  SUM(TotalExtCost) AS TotalExtCost, SUM(NumberInventoryTrans) AS NumberInventoryTrans
FROM 
MV1, date_dim, cust_vendor_dim
WHERE MV1.DateKey = date_dim.DateKey
AND MV1.CustVendorKey = cust_vendor_dim.CustVendorKey
GROUP BY  Name, CalYear, CalQuarter
UNION
SELECT Name, CalYear, CalQuarter,  SUM(TotalExtCost) AS TotalExtCost, SUM(NumberInventoryTrans) AS NumberInventoryTrans
FROM MV2, date_dim, cust_vendor_dim
WHERE MV2.DateKey = date_dim.DateKey
AND MV2.CustVendorKey = cust_vendor_dim.CustVendorKey
GROUP BY Name, CalYear, CalQuarter) 
GROUP BY CUBE (Name, CalYear, CalQuarter);
