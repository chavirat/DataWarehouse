@@ -0,0 +1,224 @@
-- Assignment2 by chavirat burapadecha
CREATE TABLE Log_Table
( ExcNo		INTEGER 	 PRIMARY KEY,
 ExcTrigger	VARCHAR2(25) NOT NULL,
 ExcTable	VARCHAR2(25) NOT NULL,
 ExcKeyValue	VARCHAR2(15) NOT NULL,
 ExcDate	DATE DEFAULT SYSDATE NOT NULL,
 ExcText	VARCHAR2(255) NOT NULL );
CREATE SEQUENCE Log_Table_seq START WITH 1 INCREMENT BY 1;

--1. Expense Amount Exceeding Limit Trigger:
CREATE OR REPLACE TRIGGER tr_ExpAmtExcLimit
AFTER INSERT OR UPDATE OF ExpAmt ON ExpenseItem
FOR EACH ROW
DECLARE
 anECLimit ExpCat.ECLimit%TYPE;
 Exceeding_Alert EXCEPTION;
BEGIN
	SELECT ECLimit
	INTO anECLimit
	FROM ExpCat
	WHERE ExpCat.ECNo = :NEW.ECNo;

IF INSERTING AND (:NEW.ExpAmt > anECLimit) THEN
	RAISE Exceeding_Alert;
	END IF;
IF UPDATING AND (:NEW.ExpAmt > anECLimit) THEN
	RAISE Exceeding_Alert;
	END IF;
EXCEPTION
WHEN Exceeding_Alert THEN
	INSERT INTO Log_Table 
	(ExcNo,ExcTrigger,ExcTable,ExcKeyValue,ExcDate,ExcText)
	VALUES (Log_Table_seq.NextVal,'tr_ExpAmtExcLimit','ExpCat',to_char(:New.ECNo),SYSDATE,'the expense amount is greater than ' ||to_char(anECLimit));
END;

--2. Check Approving User Trigger
CREATE OR REPLACE TRIGGER tr_CkApprUser
BEFORE UPDATE OF ApprUserNo
ON ExpenseReport
FOR EACH ROW
DECLARE
  c users.userorgNo%TYPE;
  d users.userorgNo%TYPE;
  e orgunit.orgparentno%type;
	NoMatch EXCEPTION;
	ExMassage VARCHAR (200);
BEGIN
  SELECT userorgno
  INTO c
  FROM users
  WHERE users.userno = :new.submituserno;
  
  SELECT orgparentno
  into e
  FROM orgunit
  Where orgunit.orgno = c;
  
  SELECT userorgno
  INTO d
  FROM users
  WHERE users.userno = :new.appruserno;
  
	IF (d <> c) and (d <> e)
  THEN
	RAISE NoMatch;
	
	END IF;
EXCEPTION
	WHEN NoMatch THEN
  --dbms_output.put_line('org no of submit user: ' || To_Char(c));
  --dbms_output.put_line('org no of appr user: ' || To_Char(d));
  --dbms_output.put_line('parent org no of submit user: ' || To_Char(e));
	ExMassage := 'The organization number of the approving user does not match either the organization number or the parent organization number of the submitted user.';
	RAISE_Application_Error(-20001,ExMassage);
END;

--3. Change Case Trigger: Makes the ERStatus column upper case 
CREATE OR REPLACE TRIGGER tr_ChgCse
BEFORE INSERT OR UPDATE OF ERStatus ON ExpenseReport
FOR EACH ROW
BEGIN
:NEW.ERStatus := UPPER(:NEW.ERStatus);
END;

--4. Update Expense Date Trigger
CREATE OR REPLACE TRIGGER tr_UpdExpDate
AFTER INSERT OR UPDATE OF ExpenseDate
ON ExpenseItem
FOR EACH ROW
DECLARE
	aERSubmitDate ExpenseReport.ERSubmitDate%TYPE;
	Exceeding_Alert EXCEPTION;
	ExMassage VARCHAR (200);
BEGIN
	SELECT ERSubmitDate
	INTO aERSubmitDate
	FROM ExpenseReport
	WHERE ExpenseReport.ERNo =:NEW.ERNo;
	
	IF  (:NEW.ExpenseDate > aERSubmitDate) THEN
	RAISE Exceeding_Alert;
	END IF;

	EXCEPTION
	WHEN Exceeding_Alert THEN
	ExMassage := 'The Expense Date exceeds the Submit Date.';
	RAISE_Application_Error(-20001,ExMassage);
END;

-- 6. Rollup Expense Item Trigger:
CREATE OR REPLACE TRIGGER tr_RollupExpItem
AFTER DELETE OR UPDATE OF ExpApprAmt
ON ExpenseItem
FOR EACH ROW
DECLARE
amt integer;
aresult BOOLEAN;
BEGIN 

IF UPDATING then amt := (:NEW.ExpApprAmt - :OLD.ExpApprAmt); END IF;
IF DELETING then amt := 0 - :OLD.ExpApprAmt; END IF;
spRollUpExpenseItem (:OLD.ERNo, :OLD.EcNo, amt, aresult);
--dbms_output.put_line('amount: ' || To_Char(amt));
if aresult then
INSERT INTO Log_Table 
	(ExcNo,ExcTrigger,ExcTable,ExcKeyValue,ExcDate,ExcText)
	VALUES (Log_Table_seq.NextVal,'tr_RollupExpItem','ExpenseReport',to_char(:OLD.ERNo),SYSDATE,'the output parameter of spRollUpExpenseItem procedure is true.');
END if;
END;
--------------------------------------------------------------------------------------------------
--1. testing code of expense amount exceeding limit trigger
SET SERVEROUTPUT ON;
--test inserting when the expense amount is greater than the category limit
insert into expenseitem (eino, expdesc, expensedate, expamt, expappramt, erno, ecno, assetno)
values (97,'testing','1-jun-10','1000','10',1,1,1);
--test inserting when the expense amount is lower than the category limit
insert into expenseitem (eino, expdesc, expensedate, expamt, expappramt, erno, ecno, assetno)
values (98,'testing','1-jun-10','10','10',1,1,1);
--test inserting when the expense amount equals the category limit
insert into expenseitem (eino, expdesc, expensedate, expamt, expappramt, erno, ecno, assetno)
values (99,'testing','1-jun-10','50','10',1,1,1);
--test updating when the expense amount is greater than the category limit
update expenseitem
set expamt = 400
where eino = 97;
--test updating when the expense amount is lower than the category limit
update expenseitem
set expamt = 40
where eino = 97;
--test updating when the expense amount equals the category limit
update expenseitem
set expamt = 50
where eino = 97;
--show the result in log table
select * from log_table;
ROLLBACK;
--2. testing code for check approving user trigger
insert into users (userno,userfirstname, userlastname,useremail,userorgno)
values (99,'tester','longdo','test@gmail.com',3);
--2+3. testing upper case of erstatus
insert into expensereport (erno, erdesc, ersubmitdate, erstatusdate, erstatus, submituserno, appruserno)
values (99,'testing', sysdate,sysdate,'pending',1,1);
--test updating when the organization number of approving user matches to the organization number of submit user
update expensereport
set appruserno = 99
where erno = 99;
--test updating when the organization number of approving user does not match to the organization number of submit user
update expensereport
set appruserno = 5
where erno = 99;
--test updating when the organization number of approving user matches to the organization number or the parent organization number of submit user
update expensereport
set submituserno = 2
where erno = 99;
update expensereport
set appruserno = 1
where erno = 99;
update expensereport
set appruserno = 4
where erno = 99;
rollback;
--4. testing code for update expense date trigger
-- inserting when expense date is greater than the submit date
insert into expenseitem (eino, expdesc, expensedate, expamt, expappramt, erno, ecno, assetno)
values (100,'testing','1-jun-15','10','10',1,1,1);
-- inserting when expense date is less than the submit date
insert into expenseitem (eino, expdesc, expensedate, expamt, expappramt, erno, ecno, assetno)
values (101,'testing','1-jun-10','10','10',1,1,1);
-- inserting when expense date equals the submit date
insert into expenseitem (eino, expdesc, expensedate, expamt, expappramt, erno, ecno, assetno)
values (102,'testing','10-aug-11','10','10',1,1,1);
--updating when expense date is greater than the submit date
update expenseitem
set expensedate = '1-jun-15'
where eino = 101;
-- updating when expense date is less than the submit date
update expenseitem
set expensedate = '1-jun-10'
where eino = 102;
-- updating when expense date equals the submit date
update expenseitem
set expensedate = '10-aug-11'
where eino = 102;
rollback;
--6. testing code for roll up expense item trigger
update expenseitem
set expappramt = 10
where eino = 99;
update expenseitem
set expappramt = 40
where eino = 99;
update expenseitem
set expappramt = 50
where eino = 99;
--deleting rows if necessary
delete from expensereport
where erno = 99;
delete from expenseitem
where eino in (97,98,99,100,101,102);
delete from users
where userno = 99;
drop table log_table;
drop sequence log_table_seq;
