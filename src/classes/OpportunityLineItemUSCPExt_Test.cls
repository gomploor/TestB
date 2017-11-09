/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers.
*
* Unit tests are class methods that verify whether a particular piece
* of code is working properly. Unit test methods take no arguments,
* commit no data to the database, and are flagged with the testMethod
* keyword in the method definition.
*
* All test methods in an organization are executed whenever Apex code is deployed
* to a production organization to confirm correctness, ensure code
* coverage, and prevent regressions. All Apex classes are
* required to have at least 75% code coverage in order to be deployed
* to a production organization. In addition, all triggers must have some code coverage.
* 
* The @isTest class annotation indicates this class only contains test
* methods. Classes defined with the @isTest annotation do not count against
* the organization size limit for all Apex scripts.
*
* See the Apex Language Reference for more information about Testing and Code Coverage.
*/

/* **************************************************************************************************
* Class Name : OpportunityLineItemUSCPExt_Test
* Created By : Infant Karthika
* Created Date : 6/6/2016
* Author : MST
* Description : This class will cover the code coverage for 'OpportunityLineItemUSCPExt' and 
                'OpportunityPaymentEntries' class.
*********************************************************************************************************/
@isTest(SeeAllData = false)
private class OpportunityLineItemUSCPExt_Test {
    
    //Create test data
    @testSetup static void testDataSetup(){
        //Creating data for constant variables 
        Constants.loadData(); 
                
        //Get std priceBookId
        Id stdPriceBookId = Test.getStandardPricebookId();
        
        //Create Account
        Id accountRecTypeId = RecordTypeCache.getRecordType('Account', 'PartnerMarket').Id; 
        SmartFactory.overrideFieldsMap.put('Account', new Map<String,String>{'Partner_type__c' => 'GL','Industry'=> 'Auto','RecordtypeId' => accountRecTypeId, 'Phone' => '1234567890','Website' => 'https://www.test.com'});        
        List<Account> accLst = TestDataFactory.createAccounts(1); 

        //Create Contact as Sales Rep
        Id contactRecTypeId = RecordTypeCache.getRecordType('Contact', 'Affiliated').Id;
        SmartFactory.overrideFieldsMap.put('Contact', new Map<String,String>{'FirstName'=>'Contact','LastName'=>'NewTest','Recordtypeid'=>contactRecTypeId,'AccountId'=> accLst[0].Id,'Phone'=>'6024446765','Email'=>'test@sfdc.com'});       
        List<Contact> contLst = TestDataFactory.createContacts(1);
        
        //Create Marketing_Campaign__c
        Marketing_Campaign__c market = TestDataFactory.createMarketinCampaign(accLst[0].Id);
        insert market;
        
        //Create PPC product
        List<Product2> prodLst = new List<Product2>();
        SmartFactory.overrideFieldsMap.put('Product2', new Map<String,String>{'Name'=>'PPC', 'ProductCode'=>'Pro-X', 'RevenueScheduleType'=>'Repeat', 'RevenueInstallmentPeriod'=>'Monthly'}); 
        prodLst = TestDataFactory.createProduct(1, false);
        prodLst[0].HasMediaSpend__c = true;

        //Create Email Blast product
        SmartFactory.overrideFieldsMap.put('Product2', new Map<String,String>{'Name'=>'Email Blast', 'ProductCode'=>'EB-X', 'RevenueScheduleType'=>'Repeat', 'RevenueInstallmentPeriod'=>'Monthly'}); 
        prodLst.addAll(TestDataFactory.createProduct(1, false));
        prodLst[1].Edit_Qty_LineItems__c = true;
        
        //Create Brand Building Custom product
        SmartFactory.overrideFieldsMap.put('Product2', new Map<String,String>{'Name'=>'Brand Building Custom', 'ProductCode'=>'BBC-X', 'RevenueScheduleType'=>'Repeat', 'RevenueInstallmentPeriod'=>'Monthly'}); 
        prodLst.addAll(TestDataFactory.createProduct(1, false));
        prodLst[2].Edit_Qty_ContractMonths__c = true;
        
        for(Product2 currPrd : prodLst){
            currPrd.isActive = true;
            currPrd.Has_Schedule__c = false;
            currPrd.CanUseRevenueSchedule = true;
            currPrd.NumberOfRevenueInstallments = 5;
            currPrd.UseMatrix__c = false;
        }
        
        insert prodLst;
        
        //Create PPC pricebook entry
        List<PricebookEntry> pbEntryLst = new List<PricebookEntry>();
        SmartFactory.overrideFieldsMap.put('PricebookEntry', new Map<String,String>{'UnitPrice' => '100.00'});
        pbEntryLst.add(TestDataFactory.createPriceBookEntry(prodLst[0].Id,stdPriceBookId));
        pbEntryLst[0].Use_Percent_of_Media_Budget__c = true;
        pbEntryLst[0].PriceRangeMin__c = 200;
        pbEntryLst[0].PriceRangeMax__c = 650;
        
        //Create Email Blast pricebook entry
        SmartFactory.overrideFieldsMap.put('PricebookEntry', new Map<String,String>{'UnitPrice' => '100.00'});
        pbEntryLst.add(TestDataFactory.createPriceBookEntry(prodLst[1].Id,stdPriceBookId));
        pbEntryLst[1].Use_Percent_of_Media_Budget__c = false;
        
        //Create Brand Building Custom pricebook entry
        SmartFactory.overrideFieldsMap.put('PricebookEntry', new Map<String,String>{'UnitPrice' => '100.00'});
        pbEntryLst.add(TestDataFactory.createPriceBookEntry(prodLst[2].Id,stdPriceBookId));
        update pbEntryLst;
        
        //Create Automated_Rate_Calculation__c
        SmartFactory.overrideFieldsMap.put('Automated_Rate_Calculation__c', new Map<String,String>{'Price_Book__c'=>stdPriceBookId,'Product__c'=>prodLst[0].Id});       
        List<Automated_Rate_Calculation__c> rateCalcLst = TestDataFactory.createAutomatedRateCalc(1);
        rateCalcLst[0].MatrixResult__c = 10;
        rateCalcLst[0].Unit_Modifier__c = 1;
        rateCalcLst[0].Range_Fixed_Charge__c = 10;

        //Create Automated_Rate_Calculation__c for Email Blast
        SmartFactory.overrideFieldsMap.put('Automated_Rate_Calculation__c', new Map<String,String>{'Price_Book__c'=>stdPriceBookId,'Product__c'=>prodLst[1].Id});       
        rateCalcLst.addAll(TestDataFactory.createAutomatedRateCalc(1));
        rateCalcLst[1].MatrixResult__c = 10;
        rateCalcLst[1].Unit_Modifier__c = 1;
        rateCalcLst[1].Range_Fixed_Charge__c = 10;
        rateCalcLst[1].increasedRate__c = true;

        insert rateCalcLst;
        
        Test.startTest();
        //Create Opportunity with SML opportunity recordtype
        List<Opportunity> oppLst = new List<Opportunity>();
        Id oppRecTypeId = RecordTypeCache.getRecordType('Opportunity', 'SML_Opportunity').Id;          
        SmartFactory.overrideFieldsMap.put('Opportunity', new Map<String,String>{'AccountId'=> accLst[0].Id,'Media_Partner__c'=>accLst[0].Id ,'RecordtypeId' => oppRecTypeId,'Pricebook2Id' => stdPriceBookId});        
        oppLst = TestDataFactory.createOpportunities(3, null, false);
        
        //Create Opportunity with USCP opportunity recordtype
        Id oppUSCPRecTypeId = RecordTypeCache.getRecordType('Opportunity', 'USCP_Opportunity').Id;         
        SmartFactory.overrideFieldsMap.put('Opportunity', new Map<String,String>{'AccountId'=> accLst[0].Id,'Media_Partner__c'=>accLst[0].Id ,'RecordtypeId' => oppUSCPRecTypeId,'Pricebook2Id' => stdPriceBookId, 'StageName' => 'Closed Won'});        
        oppLst.addAll(TestDataFactory.createOpportunities(1, null, false)); 
        insert oppLst;
        
        //Create OpportunityLineItem 'PPC'
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();            
        SmartFactory.IncludedFields.put('OpportunityLineItem', New Set<String>{'TotalPrice','Quantity','ServiceDate','Invoice_ServiceStartDate__c','Live_Date__c'});
        SmartFactory.overrideFieldsMap.put('OpportunityLineItem', new Map<String,String>{'Marketing_Campaign__c'=>market.Id});
        oliList = TestDataFactory.createOpportunityProduct(1, false, oppLst[0].Id,pbEntryLst[0].Id);
        oliList[0].ServiceDate = Date.today().addDays(-10);
        oliList[0].Invoice_ServiceStartDate__c = Date.today().addDays(-10);
        oliList[0].Live_Date__c = Date.today().addDays(-10);
        oliList[0].Qty_ContractMonths__c = 4;
        oliList[0].Media_Budget__c = 10000;
        oliList[0].Mgmt_Fee_Percent__c = 30;
        
        //Create OpportunityLineItem 'Email Blast'
        SmartFactory.IncludedFields.put('OpportunityLineItem', New Set<String>{'TotalPrice','Quantity','ServiceDate','Invoice_ServiceStartDate__c','Live_Date__c'});
        SmartFactory.overrideFieldsMap.put('OpportunityLineItem', new Map<String,String>{'Marketing_Campaign__c'=>market.Id, 'Waiting_Status__c'=>'Cancel Pending', 'Waiting_Status_Descr__c'=>'Test', 'Cancellation_Category__c'=>'Cancelled Before Live', 'Cancellation_Reason__c'=>'Sales'});
        oliList.addAll(TestDataFactory.createOpportunityProduct(1, false, oppLst[0].Id,pbEntryLst[1].Id));
        oliList[1].ServiceDate = Date.today().addDays(-10);
        oliList[1].Invoice_ServiceStartDate__c = Date.today().addDays(-10);
        oliList[1].Live_Date__c = Date.today().addDays(-10);
        oliList[1].Invoice_CancelDate__c = date.today();
        oliList[1].Qty_ContractMonths__c = 4;
        oliList[1].Media_Budget__c = 10000;
        oliList[1].Total_Monthly_Charge__c = 1000;
        oliList[1].Mgmt_Fee_Percent__c = 30;
        oliList[1].Invoice_PriceVariable__c = 1000;
        oliList[1].Email_Blast_Quantity__c = null;
        oliList[1].Email_Recipients_Qty__c = 5;
        oliList[1].NumberOfLocations__c = 3;
        
        
        //Create OpportunityLineItem 'Brand Building Custom'
        SmartFactory.IncludedFields.put('OpportunityLineItem', New Set<String>{'TotalPrice','Quantity','ServiceDate','Invoice_ServiceStartDate__c','Live_Date__c'});
        SmartFactory.overrideFieldsMap.put('OpportunityLineItem', new Map<String,String>{'Marketing_Campaign__c'=>market.Id});
        oliList.addAll(TestDataFactory.createOpportunityProduct(1, false, oppLst[0].Id,pbEntryLst[2].Id));
        oliList[2].ServiceDate = Date.today().addDays(-10);
        oliList[2].Invoice_ServiceStartDate__c = Date.today().addDays(-10);
        oliList[2].Live_Date__c = Date.today().addDays(-10);
        oliList[2].Qty_ContractMonths__c = 4;
        oliList[2].Media_Budget__c = 10000;
        oliList[2].NumberOfLocations__c = 1;
        
        //Create USCP OpportunityLineItem 'PPC'           
        SmartFactory.IncludedFields.put('OpportunityLineItem', New Set<String>{'TotalPrice','Quantity','ServiceDate','Invoice_ServiceStartDate__c','Live_Date__c'});
        SmartFactory.overrideFieldsMap.put('OpportunityLineItem', new Map<String,String>{'Marketing_Campaign__c'=>market.Id});
        oliList.addAll(TestDataFactory.createOpportunityProduct(1, false, oppLst[3].Id,pbEntryLst[0].Id));
        oliList[3].Canceled__c = true;

        //Create OpportunityLineItem 'Email Blast' where not null
        SmartFactory.IncludedFields.put('OpportunityLineItem', New Set<String>{'TotalPrice','Quantity','ServiceDate','Invoice_ServiceStartDate__c','Live_Date__c'});
        SmartFactory.overrideFieldsMap.put('OpportunityLineItem', new Map<String,String>{'Marketing_Campaign__c'=>market.Id, 'Waiting_Status__c'=>'Cancel Pending', 'Waiting_Status_Descr__c'=>'Test', 'Cancellation_Category__c'=>'Cancelled Before Live', 'Cancellation_Reason__c'=>'Sales'});
        oliList.addAll(TestDataFactory.createOpportunityProduct(1, false, oppLst[1].Id,pbEntryLst[1].Id));
        oliList[4].ServiceDate = Date.today().addDays(-10);
        oliList[4].Invoice_ServiceStartDate__c = Date.today().addDays(-10);
        oliList[4].Live_Date__c = Date.today().addDays(-10);
        oliList[4].Invoice_CancelDate__c = date.today();
        oliList[4].Qty_ContractMonths__c = 4;
        oliList[4].Media_Budget__c = 10000;
        oliList[4].Total_Monthly_Charge__c = 1000;
        oliList[4].Mgmt_Fee_Percent__c = 30;
        oliList[4].Invoice_PriceVariable__c = 1000;
        oliList[4].Email_Blast_Quantity__c = 4;
        oliList[4].Email_Recipients_Qty__c = 5;
        oliList[4].NumberOfLocations__c = 3;

        //Create OpportunityLineItem 'Email Blast' where not null and arc is not null
        SmartFactory.IncludedFields.put('OpportunityLineItem', New Set<String>{'TotalPrice','Quantity','ServiceDate','Invoice_ServiceStartDate__c','Live_Date__c'});
        SmartFactory.overrideFieldsMap.put('OpportunityLineItem', new Map<String,String>{'Marketing_Campaign__c'=>market.Id, 'Waiting_Status__c'=>'Cancel Pending', 'Waiting_Status_Descr__c'=>'Test', 'Cancellation_Category__c'=>'Cancelled Before Live', 'Cancellation_Reason__c'=>'Sales'});
        oliList.addAll(TestDataFactory.createOpportunityProduct(1, false, oppLst[2].Id,pbEntryLst[1].Id));
        oliList[5].ServiceDate = Date.today().addDays(-10);
        oliList[5].Invoice_ServiceStartDate__c = Date.today().addDays(-10);
        oliList[5].Live_Date__c = Date.today().addDays(-10);
        oliList[5].Invoice_CancelDate__c = date.today();
        oliList[5].Qty_ContractMonths__c = 4;
        oliList[5].Media_Budget__c = 10000;
        oliList[5].Total_Monthly_Charge__c = 1000;
        oliList[5].Mgmt_Fee_Percent__c = 30;
        oliList[5].Invoice_PriceVariable__c = 1000;
        oliList[5].Email_Blast_Quantity__c = 4;
        oliList[5].Email_Recipients_Qty__c = 5;
        oliList[5].NumberOfLocations__c = 3;
        oliList[5].increasedRate__c = true;
        insert oliList;
        Test.stopTest();
        
        //Create PPCOrderDetail__c        
        SmartFactory.overrideFieldsMap.put('PPCOrderDetail__c', new Map<String,String>{'OpportunityLineItemId__c'=>String.ValueOf(oliList[0].Id).substring(0, 15), 'FulfillmentStatus__c'=>'AMP'});
        PPCOrderDetail__c ppcOrder = (PPCOrderDetail__c)SmartFactory.createSObject('PPCOrderDetail__c');
        insert ppcOrder;

        Project__c project = TestDataFactory.createProject('Test Project');

        //Create Billing Schedule
        List<Billing_Schedule__c> bsList = TestDataFactory.createBillingSched(oliList[1].OpportunityId, oliList[1].Id, project.Id, 1);
    }
    
    //Common method to call the Controller
    private static OpportunityLineItemUSCPExt initOpportunityLineItemUSCPExt(OpportunityLineItem oppInst){
        ApexPages.StandardController controller = new ApexPages.StandardController(oppInst);         
        OpportunityLineItemUSCPExt oliUSCPExtension = new OpportunityLineItemUSCPExt(controller);
        return oliUSCPExtension;
    }
    
    //Common method to check error
    private static boolean hasErrorCheck(String errMsg) {
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        
        // Check that the error message you are expecting is in pageMessages
        Boolean messageFound = false;
        for(ApexPages.Message message : pageMessages) {
            if(message.getDetail().contains(errMsg) || message.getSummary().contains(errMsg)) {
                messageFound = true;        
            }
        }
        return messageFound;
    }
    
    //Verify that the Opportunity Line Item is updated for the given values.  
    @isTest static void testOLI_Updation() {        
        //Query the database for newly inserted Opportunity Line Item records
        List<OpportunityLineItem> oliList = [SELECT Id, Name FROM OpportunityLineItem WHERE Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 PPC'];
        oliList[0].Waiting_Status_Options__c = 'Live'; 
        oliList[0].Waiting_Status_Options_Before__c = 'Closed Won';
        oliList[0].Waiting_Status__c = Null;
        oliList[0].Media_Budget__c = 300;
        oliList[0].Total_Monthly_Charge__c = 1000;
        oliList[0].Mgmt_Fee_Percent__c = 30;
        oliList[0].Qty_ContractMonths__c = 4;
        oliList[0].Invoice_ServiceStartDate__c = Date.today().addDays(-10);
        
        Test.startTest();
        OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliList[0]);
        oliUSCPExtension.save();
        Test.stopTest();
        
        //Test that OLI is upadated for the given values
        System.assertEquals('Closed Won', [SELECT Id, Waiting_Status__c FROM OpportunityLineItem WHERE Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 PPC'].Waiting_Status__c);
        System.assert(oliUSCPExtension.disableWaiveFees == true);
        
        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliUSCPInst = [SELECT Id FROM OpportunityLineItem Where Record_Type_Name__c = 'USCP Opportunity' AND Name = 'Test Opportunity 0 PPC']; 
        oliUSCPInst.Waiting_Status_Options__c = ''; 
        oliUSCPInst.Waiting_Status_Options_Before__c = 'Closed Won';
        oliUSCPInst.Waiting_Status__c = 'Closed Won';
        oliUSCPInst.Invoice_ServiceStartDate__c = Date.today();
        
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliUSCPInst);
        PageReference savePage = oliUSCPExtension.save();
        String saveURL = savePage.getUrl();               
        //Test that the page is redirected to the corresponding page based on the record type
        System.assert(saveURL.contains('/apex/OpportunityLineItemUSCP?id='+oliUSCPInst.Id));
    }
    
    //Verify that the OLI is not updated for the given Waiting_Status_Options__c value.
    @isTest static void testChangeStatus() {        
        //Update contact
        Contact contInst = [SELECT Id FROM Contact WHERE FirstName = 'Contact'];
        contInst.Email = 'testuser@testmail.com';
        update contInst;
        
        Test.startTest();
        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliInst = [SELECT Id FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 PPC'];
        oliInst.Waiting_Status__c = 'Cancel Pending';
        update oliInst;
        
        oliInst.Waiting_Status_Options__c = 'Paused:Billing';
        oliInst.Waiting_Status_Options_Before__c = 'Cancel Pending';
        oliInst.Waiting_Status__c = null;
        oliInst.Invoice_CancelDate__c = date.today();
        oliInst.Media_Budget__c = 10;
        oliInst.Mgmt_Fee_Percent__c = 50;
        Test.stopTest();

        OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);
        oliUSCPExtension.save();
        
        //Test that diableRescueOLI is false for the given values
        System.assert(oliUSCPExtension.diableRescueOLI == false);
    }
    
    //Verify that the Payment Entries is not created for the given values.
    @isTest static void testSchedules() {        
        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliInst = [SELECT Id, OpportunityId FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 PPC'];
        
        //Create Payment_Processing__c        
        SmartFactory.overrideFieldsMap.put('Payment_Processing__c', new Map<String,String>{'Opportunity__c'=>oliInst.OpportunityId});
        Payment_Processing__c payment = (Payment_Processing__c)SmartFactory.createSObject('Payment_Processing__c');
        insert payment; 
        
        Test.startTest();
        //Set the OpportunityLineItemExt page as the current page
        PageReference pageref = Page.OpportunityLineItemExt; 
        Test.setCurrentPage(pageref);
        pageref.getHeaders().put('Referer','OpportunityLineItemExt');
        
        OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);
        oliUSCPExtension.createPaymentEntries();
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);
        Test.stopTest();
        
        //Test that the Payment Entries is not created for the given values
        System.assertEquals('Please create Schedules', pageref.getParameters().get('hasError'));
    }
    
    //Verify that the Payment Entries is created for the given values.
    @isTest static void testPaymentEntries_Creation() {        
        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliInst = [SELECT Id, OpportunityId FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 PPC'];
        
        //Update contact
        Contact contInst = [SELECT Id FROM Contact WHERE FirstName = 'Contact'];
        contInst.Email = 'testuser@testmail.com';
        update contInst;       
        
        //Create Payment_Processing__c        
        SmartFactory.overrideFieldsMap.put('Payment_Processing__c', new Map<String,String>{'Opportunity__c'=>oliInst.OpportunityId});
        Payment_Processing__c payment = (Payment_Processing__c)SmartFactory.createSObject('Payment_Processing__c');
        insert payment;        
        
        //Update OLI
        oliInst.Payment_Processing__c = payment.Id;
        oliInst.Waiting_Status__c = 'Live';
        oliInst.Affl_Sales_Rep__c = contInst.Id;
        update oliInst;   
        
        Test.startTest();
        //Set the OpportunityLineItemExt page as the current page
        PageReference pageref = Page.OpportunityLineItemExt; 
        Test.setCurrentPage(pageref);
        pageref.getHeaders().put('Referer','OpportunityLineItemExt');
        
        OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);
        oliUSCPExtension.createPaymentEntries();
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);
        Test.stopTest();
        
        //Test that the Payment Entry was created for the given values
        System.assertEquals('Payment Entry created Succesfully', pageref.getParameters().get('success'));
    } 
    
    @isTest static void testRecalculateCharges() {

        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliBBInst = [SELECT Id FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 Brand Building Custom'];
        oliBBInst.Waiting_Status_Options__c = 'Paused:Billing';
        oliBBInst.Waiting_Status_Options_Before__c = 'Cancel Pending';
        oliBBInst.Waiting_Status__c = null;
        
        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliPPCInst = [SELECT Id FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 PPC'];
        oliPPCInst.Waiting_Status_Options__c = 'Paused:Billing';
        oliPPCInst.Waiting_Status_Options_Before__c = 'Cancel Pending';
        oliPPCInst.Waiting_Status__c = null;
        
        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliEBInst = [SELECT Id, Email_Recipients_Qty__c FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 Email Blast'];
        oliEBInst.Waiting_Status_Options__c = 'Paused:Billing';
        oliEBInst.Waiting_Status_Options_Before__c = 'Cancel Pending';
        oliEBInst.Waiting_Status__c = null;
        oliEBInst.Media_Budget__c = 5000;

        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliEB1Inst = [SELECT Id, Email_Recipients_Qty__c FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 1 Email Blast'];
        oliEB1Inst.Waiting_Status_Options__c = 'Paused:Billing';
        oliEB1Inst.Waiting_Status_Options_Before__c = 'Cancel Pending';
        oliEB1Inst.Waiting_Status__c = null;
        oliEB1Inst.Media_Budget__c = 5000;

        //Query the database for newly inserted Opportunity Line Item records where Email Blast Quantity is not null and arc is not null
        OpportunityLineItem oliEB2Inst = [SELECT Id, Email_Recipients_Qty__c FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 2 Email Blast'];
        oliEB2Inst.Waiting_Status_Options__c = 'Paused:Billing';
        oliEB2Inst.Waiting_Status_Options_Before__c = 'Cancel Pending';
        oliEB2Inst.Waiting_Status__c = null;
        oliEB2Inst.Media_Budget__c = 5000;
        
        Test.startTest();
        OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliEBInst);       
        oliUSCPExtension.save();

        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliPPCInst);       
        oliUSCPExtension.save();
        
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliBBInst);       
        oliUSCPExtension.save();

        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliEB1Inst);       
        oliUSCPExtension.save();

        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliEB2Inst);       
        oliUSCPExtension.save();
        Test.stopTest();
        
        //System.assert([SELECT Percent_of_Total__c FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity'].Percent_of_Total__c == oliInst.Mgmt_Fee_Percent__c);
        System.assertEquals('Cancel Pending', [SELECT Id, Waiting_Status__c FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 Email Blast'].Waiting_Status__c);
    }
    
    //Verify that the Billing Schedule is Created.  
    @isTest static void testSpike() {        
        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliInst = [SELECT Id, Name FROM OpportunityLineItem WHERE Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 PPC'];
        oliInst.Waiting_Status_Options__c = 'Live'; 
        oliInst.Waiting_Status_Options_Before__c = 'Closed Won';
        oliInst.Waiting_Status__c = Null;
        oliInst.Media_Budget__c = 300;
        oliInst.Total_Monthly_Charge__c = 1000;
        oliInst.Mgmt_Fee_Percent__c = 30;
        oliInst.Qty_ContractMonths__c = 4;
        
        Test.startTest();
        OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);
        oliUSCPExtension.addSpike();
        oliUSCPExtension.spikeBs.Period_Start__c = Date.today();
        oliUSCPExtension.spikeBs.Period_End__c = Date.today().addDays(5);
        oliUSCPExtension.spikeBs.Media_Budget__c = 1000;
        oliUSCPExtension.saveSpike();
        Test.stopTest();
        
        //Test that Billing Schedule is created
        System.assert([SELECT Id FROM Billing_Schedule__c].size() != 0);
    }
    
    //Verify that the Opportunity Line Item Spike's Exception.  
    @isTest static void testSpikeException() { 
        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliInst = [SELECT Id, Name FROM OpportunityLineItem WHERE Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 PPC'];
        oliInst.Waiting_Status_Options__c = 'Live'; 
        oliInst.Waiting_Status_Options_Before__c = 'Closed Won';
        oliInst.Waiting_Status__c = Null;
        oliInst.Media_Budget__c = 300;
        oliInst.Total_Monthly_Charge__c = 1000;
        oliInst.Mgmt_Fee_Percent__c = 30;
        oliInst.Qty_ContractMonths__c = 4;
        
        OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);
        oliUSCPExtension.addSpike();
        oliUSCPExtension.spikeBs.Period_Start__c = null;
        oliUSCPExtension.spikeBs.Period_End__c = Date.today().addDays(30);
        oliUSCPExtension.spikeBs.Media_Budget__c = 1000;
        oliUSCPExtension.saveSpike();
        
        Boolean hasErrorStartDate = hasErrorCheck('Period Start - Must Enter Value.');
        System.assertEquals(true, hasErrorStartDate);
        
        oliUSCPExtension.spikeBs.Period_Start__c = Date.today();
        oliUSCPExtension.spikeBs.Period_End__c = null;
        oliUSCPExtension.spikeBs.Media_Budget__c = 1000;
        oliUSCPExtension.saveSpike();
        
        Boolean hasErrorEndDate = hasErrorCheck('Period End - Must Enter Value.');
        System.assertEquals(true, hasErrorEndDate);
        
        Test.startTest();
        oliUSCPExtension.spikeBs.Period_Start__c = Date.today();
        oliUSCPExtension.spikeBs.Period_End__c = Date.today().addDays(30);
        oliUSCPExtension.spikeBs.Media_Budget__c = 1000;
        oliUSCPExtension.saveSpike();
        
        Boolean hasErrorDateLimt = hasErrorCheck('Period End must be less then 28 days from Period Start.');
        System.assertEquals(true, hasErrorDateLimt);
        
        oliUSCPExtension.spikeBs.Period_Start__c = Date.today();
        oliUSCPExtension.spikeBs.Period_End__c = Date.today().addDays(-1);
        oliUSCPExtension.spikeBs.Media_Budget__c = 1000;
        oliUSCPExtension.saveSpike();
        
        Boolean hasErrorPriorDate = hasErrorCheck('Period End is less then Period Start.');
        System.assertEquals(true, hasErrorPriorDate);
        
        oliUSCPExtension.spikeBs.Period_Start__c = Date.today();
        oliUSCPExtension.spikeBs.Period_End__c = Date.today().addDays(5);
        oliUSCPExtension.spikeBs.Media_Budget__c = null;
        oliUSCPExtension.saveSpike();
        
        Boolean hasErrorMBNull = hasErrorCheck('Media Budget - Must Enter Value.');
        System.assertEquals(true, hasErrorPriorDate);
        Test.stopTest();
    }
    
    //Verify that the OLI's Exceptions.
    @isTest static void testExceptionHandling() { 
        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliEBInst = [SELECT Id, Email_Recipients_Qty__c FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 Email Blast'];
        
        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliInst = [SELECT Id FROM OpportunityLineItem WHERE Record_Type_Name__c = 'USCP Opportunity' AND Name = 'Test Opportunity 0 PPC'];
        oliInst.Waiting_Status_Options__c = 'Live';
        oliInst.Waiting_Status__c = 'Live';
        oliInst.Waiting_Status_Options_Before__c = 'Closed Won';
        
        OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);       
        oliUSCPExtension.save();
        
        Boolean hasErrorAfflSalesRep = hasErrorCheck('Unable to Save. Please enter Affiliated Sales Rep Email.');
        System.assertEquals(true, hasErrorAfflSalesRep); 
        
        oliUSCPExtension.createPaymentEntries();
        
        Boolean hasErrorCreatePay = hasErrorCheck('Please create payment processing');
        System.assertEquals(true, hasErrorCreatePay);

        Test.startTest();
        
        oliEBInst.Qty_ContractMonths__c = null;
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliEBInst);       
        oliUSCPExtension.save();
        
        Boolean hasErrorQCM = hasErrorCheck('Qty Contract Months : Must enter value.');
        System.assertEquals(true, hasErrorQCM);
        
        oliEBInst.Qty_ContractMonths__c = 0;
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliEBInst);       
        oliUSCPExtension.save();
        
        Boolean hasErrorQCMZero = hasErrorCheck('Qty Contract Months : Must be nonzero.');
        System.assertEquals(true, hasErrorQCMZero);
        Test.stopTest();
    }
    
    //Verify that the OLI is not updated for the given Waiting_Status_Options__c value.
    @isTest static void testNOLExceptionHandling() { 
        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliBBInst = [SELECT Id FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 Brand Building Custom'];
        
        oliBBInst.NumberOfLocations__c = null;
        OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliBBInst);       
        oliUSCPExtension.save();
        
        Boolean hasErrorNOL = hasErrorCheck('Number of Locations : Must enter value.');
        System.assertEquals(true, hasErrorNOL);

        Test.startTest();
        oliBBInst.NumberOfLocations__c = 0;
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliBBInst);       
        oliUSCPExtension.save();
        
        Boolean hasErrorNOLZero = hasErrorCheck('Number of Locations : Must be nonzero.');
        System.assertEquals(true, hasErrorNOLZero);
        Test.stopTest();
    }
    
    //Verify that the page is redirected to the corresponding page on button click. 
    @isTest static void testRedirectionLogic() {        
        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliInst = [SELECT Id, Marketing_Campaign__c, OpportunityId FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 PPC'];
        
        /*Test that the page is redirected to the OpportunityLineItemExt page*/
        OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);
        PageReference redirectPage = oliUSCPExtension.redirectOLI();
        String redirectURL = redirectPage.getUrl();
        
        System.assert(redirectURL.contains('/apex/OpportunityLineItemExt?id='+oliInst.Id));       
        
        /*Test that the page is redirected to the OpportunityLineItemUSCP Cancelled page*/
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);
        PageReference cancelILIPage = oliUSCPExtension.cancelInvoiceLineItems();
        String cancelILIURL = cancelILIPage.getUrl();        
        
        System.assert(cancelILIURL.contains('/apex/OpportunityLineItemUSCP_Cancelled?id='+oliInst.Id));
        System.assert(oliUSCPExtension.canCancelOLI == true);
        System.assert(oliUSCPExtension.disableCancelOLI == true);
        
        /*Test that the page is redirected to the OLI RescuePage page*/
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);
        PageReference rescuePage = oliUSCPExtension.rescueOLI();
        String rescueURL = rescuePage.getUrl();               
        
        System.assert(rescueURL.contains('/apex/OLI_RescuePage?id='+oliInst.Id));
        System.assert(oliUSCPExtension.diableRescueOLI == true); 
        
        /*Test that the page is redirected to the UpdateAgreement page*/
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);      
        PageReference agreePage = oliUSCPExtension.updateAgreement();
        String agreeURL = agreePage.getUrl();                       
        
        System.assert(agreeURL.contains('/apex/UpdateAgreement?id='+oliInst.Id));
        System.assert(oliUSCPExtension.canUpdateAgreement == true);

        Test.startTest();
        /*Test that the page is redirected to the InvoiceAdjustment page*/
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);        
        PageReference adjustPage = oliUSCPExtension.invoiceAdjustment();
        String adjustURL = adjustPage.getUrl();                               
        
        System.assert(adjustURL.contains('/apex/InvoiceAdjustment?oliid='+oliInst.Id));
        System.assert(oliUSCPExtension.canAdjustInvoice == true);
        
        /*Test that the page is redirected to the InvoiceMakeGood page*/
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);        
        PageReference makeGoodPage = oliUSCPExtension.invoiceMakeGood();
        String makeGoodURL = makeGoodPage.getUrl();                                      
        
        System.assert(makeGoodURL.contains('/apex/InvoiceMakeGood?oliid='+oliInst.Id));
        
        /*Test that the page is redirected to the ScheduleOLI page*/
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);        
        PageReference schedulePage = oliUSCPExtension.scheduleOLI();
        String scheduleURL = schedulePage.getUrl();       
        
        System.assert(scheduleURL.contains('/apex/ScheduleOLI?mcid='+oliInst.Marketing_Campaign__c+'&oliid='+oliInst.Id));
        
        /*Test redirectiion to billing schedule update*/
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);        
        PageReference bsPage = oliUSCPExtension.updateBs();
        
         /*Test redirectiion to cancel uscp oli*/
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);        
        PageReference cancelUscpPage = oliUSCPExtension.cancelUscpOli();
        
         /*Test redirectiion to renewal*/
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);        
        PageReference renewPage = oliUSCPExtension.renewal();
        
        /*Test that the OLI is Delete and the page is redirected to the corresponding page*/
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);
        PageReference deletePage = oliUSCPExtension.oliDelete();
        String deleteURL = deletePage.getUrl();
        
        System.assert([SELECT Id FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 PPC'].size() == 0);
        System.assert(deleteURL.contains('/'+oliInst.opportunityId));
        
        
        Test.stopTest();
    }
    
    //Verify that the page is redirected to the corresponding page based on Logged in User. 
    @isTest static void testPageAccessibilityByUsers() {  
        Test.startTest();
        //Query the profile
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Profile jumpStartProfile = [SELECT Id FROM Profile WHERE Name = 'SML Accounts - Jump Start Managers' LIMIT 1];
        
        //Query the UserRole
        List<UserRole> ExeDirRoleLst = [SELECT Id, Name FROM UserRole WHERE Name = 'Executive Director' LIMIT 1];
        List<UserRole> jssTeamRoleLst = [SELECT Id, Name FROM UserRole WHERE Name = 'JSS Team' LIMIT 1];
        
        //Create User
        List<User> userList = new List<User>();
        User adminUser = TestDataFactory.createTestUser(ExeDirRoleLst[0].Id, sysAdminProfile.Id, 'System', 'Admin');
        userList.add(adminUser);
        User jumpStartUser = TestDataFactory.createTestUser(jssTeamRoleLst[0].Id, jumpStartProfile.Id, 'JumpStart', 'Manager');
        userList.add(jumpStartUser);    
        insert userList;       
        
        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliInst = [SELECT Id FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 PPC'];
        Test.stopTest();
        
        /*Test that the page is redirected to the OpportunityLineItemUSCPEditSysAdmin page when logged in as Sys Admin*/
        System.runAs(userList[0]){
            OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);
            PageReference editAdminPage = oliUSCPExtension.redirectSysAdmin();
            String editAdminURL = editAdminPage.getUrl();
            System.assert(editAdminURL.contains('/apex/OpportunityLineItemUSCPEditSysAdmin?id='+oliInst.Id));
        }
        
        /*Test that the page is redirected to the OpportunityLineItemUSCPEditSysAdmin page when logged in as Sys Admin*/
        System.runAs(userList[0]){
            OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);
            PageReference editAdminPage = oliUSCPExtension.editOpportunityProduct();
            String editAdminURL = editAdminPage.getUrl();
            
            System.assert(editAdminURL.contains('/apex/OpportunityLineItemUSCPEditSysAdmin?id='+oliInst.Id));
        }
        
        /*Test that the page is redirected to the OpportunityLineItemUSCPEdit page when logged in as Jump Start Manager*/
        System.runAs(userList[1]){
            OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);
            PageReference editOppPage = oliUSCPExtension.editOpportunityProduct();
            String editOppURL = editOppPage.getUrl();
            
            System.assert(editOppURL.contains('/apex/OpportunityLineItemUSCPEdit?id='+oliInst.Id));
        }
        
        /*Test that the page changes are only accessible to Finance Profile Users*/
        OpportunityLineItem oliEBInst = [SELECT Id, Email_Recipients_Qty__c FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 Email Blast'];
        oliEBInst.Waiting_Status_Options__c = 'Paused:Billing';
        oliEBInst.Waiting_Status_Options_Before__c = 'Cancel Pending';
        oliEBInst.Waiting_Status__c = null;
        
        System.runAs(userList[1]){
            OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliEBInst);
            oliUSCPExtension.save();
            oliUSCPExtension.createPaymentEntries();
            oliUSCPExtension.oliDelete();
            
            Boolean hasErrorNotFinance = hasErrorCheck('Unable to Save. Only Finance has access to change ' + oliEBInst.Waiting_Status_Options__c + ' status.');
            System.assertEquals(true, hasErrorNotFinance);
        }
    }   
    
    //Verify that the page is redirected to the corresponding page when Cancel button is clicked.
    @isTest static void testCancel() {        
        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliInst = [SELECT Id, Marketing_Campaign__c FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 PPC'];        
        OpportunityLineItem oliUSCPInst = [SELECT Id, opportunityId, Marketing_Campaign__c FROM OpportunityLineItem Where Record_Type_Name__c = 'USCP Opportunity' AND Name = 'Test Opportunity 0 PPC'];
        
        Test.startTest();
        /*Test that the page is redirected to the OpportunityLineItemExt page based on the record type*/
        OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliInst);     
        PageReference cancelSMLPage = oliUSCPExtension.cancel();
        String cancelSMLURL = cancelSMLPage.getUrl();       
        
        System.assert(cancelSMLURL.contains('/apex/OpportunityLineItemExt?id='+oliInst.Id));
        
        //Test that the page is redirected to the corresponding page based on the record type
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliUSCPInst);     
        PageReference cancelUSCPPage = oliUSCPExtension.cancel();
        String cancelUSCPURL = cancelUSCPPage.getUrl();       
        
        System.assert(cancelUSCPURL.contains('/apex/OpportunityLineItemUSCP?id='+oliUSCPInst.Id));
        
        /*Test that the page is redirected to opportunity detail page from OLI Related List*/
        //Set the USCPOLIRelatedList page as the current page
        PageReference pageref = Page.USCPOLIRelatedList; 
        Test.setCurrentPage(pageref);
        
        //Assinging the OpportunityLineItem Id to oliId
        pageref.getParameters().put('type','opp');
        
        oliUSCPExtension = initOpportunityLineItemUSCPExt(oliUSCPInst);       
        PageReference cancelPage = oliUSCPExtension.cancel();
        String cancelURL = cancelPage.getUrl();       
        
        System.assert(cancelURL.contains('/'+oliUSCPInst.opportunityId));
        Test.stopTest();
    } 

    //Verify that update billing schedule is updating properly.
    @isTest static void testUpdateBillingSchedule() {     
        //Query the database for newly inserted Opportunity Line Item records
        OpportunityLineItem oliEBInst = [SELECT Id, Email_Recipients_Qty__c, Total_Monthly_Charge__c,Qty_ContractMonths__c,NumberOfLocations__c FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 Email Blast'];
        oliEBInst.Waiting_Status_Options__c = 'Paused:Billing';
        oliEBInst.Waiting_Status_Options_Before__c = 'Cancel Pending';
        oliEBInst.Email_Recipients_Qty__c = 7;
        oliEBInst.Total_Monthly_Charge__c = 5000;

        Test.startTest();
        OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliEBInst);       
        oliUSCPExtension.save();
        Test.stopTest();

        System.assertEquals(7000, [Select Id, Management_Fee__c from Billing_Schedule__c Where Opportunity_Product__c = :oliEBInst.Id].Management_Fee__c);
    }    
    
    //Verify that update billing schedule is updating properly.
    @isTest static void testRevertOli() {     
        //Query the database for newly inserted Opportunity Line Item records
        Test.startTest();
        OpportunityLineItem oliEBInst = [SELECT Id, Email_Recipients_Qty__c, Total_Monthly_Charge__c,Qty_ContractMonths__c,NumberOfLocations__c FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 Email Blast'];
       
        OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliEBInst);       
        oliUSCPExtension.revertOli();
        Test.stopTest();

    }
    
      //Verify that update billing schedule is updating properly.
    @isTest static void testSubmitCp() {     
        //Query the database for newly inserted Opportunity Line Item records
        Test.startTest();
        OpportunityLineItem oliEBInst = [SELECT Id, Email_Recipients_Qty__c, Total_Monthly_Charge__c,Qty_ContractMonths__c,NumberOfLocations__c, 
                                        OpportunityId, Invoice_ServiceStartDate__c, Invoice_ServiceEndDate__c 
                                            FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 Email Blast'];
       
        OpportunityLineItemUSCPExt oliUSCPExtension = initOpportunityLineItemUSCPExt(oliEBInst);       
        oliUSCPExtension.submitCreateCp();
        Opportunity opp = oliUSCPExtension.getOpp(oliEBInst.OpportunityId);
        Boolean valDates = oliUSCPExtension.validatePeriodDates();
        Test.stopTest();

    }  
    
    @isTest 
    static void testFutureCp() {
        OpportunityLineItem oliEBInst = [SELECT Id, Email_Recipients_Qty__c, Total_Monthly_Charge__c,Qty_ContractMonths__c,NumberOfLocations__c, 
                                        OpportunityId, Invoice_ServiceStartDate__c, Invoice_ServiceEndDate__c 
                                            FROM OpportunityLineItem Where Record_Type_Name__c = 'SML Opportunity' AND Name = 'Test Opportunity 0 Email Blast'];
       
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Set<Id> idSet = new Set<Id>();
        idSet.add(oliEBInst.Id);
       // System.runAs() allows mixed DML operations in test context
        System.runAs(thisUser) {
            // startTest/stopTest block to run future method synchronously
            Test.startTest();        
            OpportunityLineItemUSCPExt.createCp(idSet);
            Test.stopTest();
        }
        // The future method will run after Test.stopTest();
    
     
    }
}