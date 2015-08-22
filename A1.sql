﻿CREATE TABLE Asset
(
AssetNo INTEGER CONSTRAINT AssetNoRequired NOT NULL,
AssetDesc CHAR(255) CONSTRAINT AssetDescRequired NOT NULL,
CONSTRAINT PKAsset PRIMARY KEY (AssetNo)
);	
CREATE TABLE OrgUnit
(
OrgNo INTEGER CONSTRAINT OrgNoRequired NOT NULL,
OrgName VARCHAR(50) CONSTRAINT OrgNameRequired NOT NULL,
OrgParentNo INTEGER,
CONSTRAINT PKOrgUnit PRIMARY KEY (OrgNo)
);	
CREATE TABLE ExpCat
(
ECNo INTEGER CONSTRAINT ECNoRequired NOT NULL,
ECName CHAR(255) CONSTRAINT ECNameRequired NOT NULL,
ECLimit DECIMAL(10,2) DEFAULT 0 CONSTRAINT ECLimitRequired NOT NULL,
CONSTRAINT PKExpCat PRIMARY KEY (ECNo)
);	
CREATE TABLE Users
(
UserNo INTEGER CONSTRAINT UserNoRequired NOT NULL,
UserFirstName VARCHAR(50) CONSTRAINT UserFirstNameRequired NOT NULL,
UserLastName VARCHAR(50) CONSTRAINT UserLastNameRequired NOT NULL,
UserPhone VARCHAR(20),
UserEmail VARCHAR(50) CONSTRAINT UserEmailRequired NOT NULL,
CONSTRAINT UNIQUEEMail UNIQUE (UserEmail),
CONSTRAINT CheckContainEMail CHECK (UserEmail LIKE '%@%'),
UserOrgNo INTEGER CONSTRAINT UserOrgNoRequired NOT NULL,
CONSTRAINT FKUserOrgNo FOREIGN KEY (OrgNo) REFERENCES OrgUnit,
CONSTRAINT PKUsers PRIMARY KEY (UserNo)
  );
CREATE TABLE ExpenseReport
(
ERNo INTEGER CONSTRAINT ERNoRequired NOT NULL,
CONSTRAINT PKExpenseReport PRIMARY KEY (ERNo),
ERDesc CHAR(255)  CONSTRAINT ERDescRequired NOT NULL,
ERSubmitDate DATE DEFAULT sysdate CONSTRAINT ERSubmitDateRequired NOT NULL,
ERStatusDate DATE DEFAULT sysdate CONSTRAINT ERStatusDateRequired NOT NULL,
ERStatus CHAR(50) DEFAULT 'PENDING' CONSTRAINT ERStatusRequired NOT NULL,
CONSTRAINT CheckERStatus CHECK (ERStatus in ('PENDING', 'APPROVED', 'DENIED')), 
SubmitUserNo INTEGER CONSTRAINT SubmitUserNoRequired NOT NULL,
CONSTRAINT FKSubmitUserNo FOREIGN KEY (SubmitUserNo) REFERENCES Users,
ApprUserNo INTEGER,
CONSTRAINT FKApprUserNo FOREIGN KEY (ApprUserNo) REFERENCES Users ON DELETE SET NULL,
CONSTRAINT CheckApprUserNo CHECK (((ERStatus = 'PENDING') AND (ApprUserNo IS NULL)) 
 OR ((ERStatus IN ('APPROVED', 'DENIED')) AND (ApprUserNo IS NOT NULL))),
CONSTRAINT CheckDate CHECK (ERStatusDate >= ERSubmitDate)
);	

CREATE TABLE ExpenseItem
(
EINo INTEGER CONSTRAINT ElNoRequired NOT NULL,
CONSTRAINT PKExpenseItem PRIMARY KEY (EINo),
ExpDesc CHAR(255) CONSTRAINT ExpDescRequired NOT NULL,
ExpenseDate DATE DEFAULT sysdate,
ExpAmt DECIMAL(10,2) DEFAULT 0 CONSTRAINT ExpAmtRequired NOT NULL,
ExpApprAmt DECIMAL(10,2) DEFAULT 0,
CONSTRAINT CheckExp CHECK (ExpApprAmt <= ExpAmt),
ERNo INTEGER CONSTRAINT EIERNoRequired NOT NULL,
CONSTRAINT FKERNo FOREIGN KEY (ERNo) REFERENCES ExpenseReport ON DELETE CASCADE,
ECNo INTEGER CONSTRAINT EIECNoRequired NOT NULL,
CONSTRAINT FKECNo FOREIGN KEY (ECNo) REFERENCES ExpCat,
AssetNo INTEGER,
CONSTRAINT FKAssetNo FOREIGN KEY (AssetNo) REFERENCES Asset
);	
CREATE TABLE BudgetItem
(
BINo INTEGER CONSTRAINT BINoRequired NOT NULL,
CONSTRAINT PKBudgetItem PRIMARY KEY (BINo),
BIYear FLOAT(4) DEFAULT 2005 CONSTRAINT BIYearRequired NOT NULL,
CONSTRAINT CheckBIYear CHECK(BIYear >=1900) ,
BIAmt DECIMAL(10,2) DEFAULT 0 CONSTRAINT BIAmtRequired NOT NULL,
BIActual DECIMAL(10,2) DEFAULT 0,
OrgNo INTEGER CONSTRAINT BIOrgNoRequired NOT NULL,
CONSTRAINT FKOrgNo FOREIGN KEY (OrgNo) REFERENCES OrgUnit,
ECNo INTEGER CONSTRAINT BIECNoRequired NOT NULL,
CONSTRAINT FKBIECNo FOREIGN KEY (ECNo) REFERENCES ExpCat,
CONSTRAINT UNIQUEkeys UNIQUE (BIYear, OrgNo, ECNo)
);	
--create view
CREATE VIEW ERClerkView AS
SELECT ExpenseReport.*, EINo, ExpDesc, ExpenseDate, ExpAmt, ExpApprAmt, ECNo, AssetNo 
FROM ExpenseReport, ExpenseItem
WHERE ExpenseReport.ERNo = ExpenseItem.ERNo
AND ERStatus = ‘PENDING’;

CREATE VIEW Org1SummaryView AS
SELECT BIYear, ECNo, Sum(BIActual)AS SumOfBIActual, Sum(BIAmt) AS SumOfBIAmt
FROM BudgetItem
WHERE OrgNo = 1
GROUP BY BIYear, ECNo;
--create roles
CREATE ROLE ERClerk;
CREATE ROLE Org1Mgr;
--create users
CREATE USER ERClerk1 
identified by ERClerk1;
CREATE USER Org1Mgr1
identified by Org1Mgr1;
-- Grant object privileges to roles
GRANT SELECT ON ERClerkView TO ERClerk;
GRANT SELECT ON Org1SummaryView TO Org1Mgr;
-- Grant roles to users
GRANT ERClerk TO ERClerk1;
GRANT Org1Mgr TO Org1Mgr1; 
--create sequence
CREATE SEQUENCE asset_seq INCREMENT BY  1;
CREATE SEQUENCE orgunit_seq INCREMENT BY  1;
CREATE SEQUENCE expcat_seq INCREMENT BY  1;
CREATE SEQUENCE users_seq INCREMENT BY  1;
CREATE SEQUENCE expensereport_seq INCREMENT BY  1;
CREATE SEQUENCE expenseitem_seq INCREMENT BY  1;
CREATE SEQUENCE budgetitem_seq INCREMENT BY  1;
-- Drop objects
DROP USER ERClerk1;
DROP USER Org1Mgr1;
DROP ROLE ERClerk;
DROP ROLE Org1Mgr;
DROP VIEW ERClerkView;
DROP VIEW Org1SummaryView;
DROP TABLE BudgetItem;
DROP TABLE ExpenseItem;
DROP TABLE ExpenseReport;
DROP TABLE Users;
DROP TABLE ExpCat;
DROP TABLE OrgUnit;
DROP TABLE Asset;
DROP SEQUENCE budgetitem_seq;
DROP SEQUENCE expenseitem_seq;
DROP SEQUENCE expensereport_seq;
DROP SEQUENCE users_seq;
DROP SEQUENCE expcat_seq;
DROP SEQUENCE orgunit_seq;
DROP SEQUENCE asset_seq;
