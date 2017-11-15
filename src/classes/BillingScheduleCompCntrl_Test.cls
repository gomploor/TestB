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
* Class Name   : BillingScheduleCompCntrl_Test
* Created By   : Paul Juneau
* Created Date : 8/3/2016
* Author       : Paul Juneau
* Description  : This class will cover the code coverage for 'BillingScheduleCompCntrl' class.
*********************************************************************************************************/
@isTest(SeeAllData = false)
private class BillingScheduleCompCntrl_Test {
	//Create test data
    @testSetup static void testDataSetup(){
        //Calls the "Constants" Class to load Test Data
        constants.loadData();        
        //Get standard price book ID
        Id pricebookId = Test.getStandardPricebookId();        
        //Create product 
        Product2 prod = (Product2)SmartFactory.createSObject('Product2');
        prod.ProductCode = 'Pro-X';
        prod.isActive = true;
        insert prod;    
        //Create pricebook entry
        PricebookEntry pbEntry = (PricebookEntry)SmartFactory.createSObject('PricebookEntry');
        pbEntry.Pricebook2Id = pricebookId;
        pbEntry.Product2Id = prod.Id;
        pbEntry.UnitPrice = 100.00;
        pbEntry.IsActive = true;
        insert pbEntry;        
        //Create Account
        Id accountRecTypeId = RecordTypeCache.getRecordType('Account', 'PartnerMarket').Id;   
        SmartFactory.overrideFieldsMap.put('Account', new Map<String,String>{'Name'=>'test','Industry'=> 'Auto','Recordtypeid' => accountRecTypeId, 'Phone' => '1234567890','Website' => 'https://www.test.com','Account_Primary_Industry__c'=>'Auto','Account_Primary_Focus__c'=>'Auto Auction'});        
        Account newAccount = (Account)SmartFactory.createSObject('Account'); 
        insert newAccount;
        //Create Lead
        Id leadRecTypeId = RecordTypeCache.getRecordType('Lead', 'SML_Lead').Id;        
        SmartFactory.overrideFieldsMap.put('Lead', new Map<String,String>{'Related_Company__c'=>newAccount.Id,'LastName'=>'test1','Company'=> 'test','Status'=> 'New Suspect Validation', 'Recordtypeid' => leadRecTypeId, 'Phone' => '1234567890','Website' => 'https://www.test.com'});        
        Lead newLead = (Lead)SmartFactory.createSObject('Lead'); 
        insert newLead;
        //Create Opportunity with USCP_Opportunity
        Id oppRecTypeId = RecordTypeCache.getRecordType('Opportunity', 'SML_Opportunity').Id;          
        SmartFactory.overrideFieldsMap.put('Opportunity', new Map<String,String>{'Name'=>'test','Accountid'=> newAccount.id,'Media_Partner__c'=> newAccount.id,'Recordtypeid' => oppRecTypeId,'Pricebook2id'=>pricebookId});        
        List<Opportunity> newOpportunity = (List<Opportunity>)SmartFactory.createSObjectList('Opportunity',false,1); 
        insert newOpportunity; 
        //Create Project__c
        Project__c project = (Project__c)SmartFactory.createSObject('Project__c');
        insert project;    
        //Create Marketing_Campaign__c
        SmartFactory.overrideFieldsMap.put('Marketing_Campaign__c', new Map<String,String>{'Company__c'=>newAccount.Id});
        Marketing_Campaign__c market = (Marketing_Campaign__c)SmartFactory.createSObject('Marketing_Campaign__c');
        insert market; 
        //Create Opportunity Line Item
        SmartFactory.overrideFieldsMap.put('OpportunityLineItem', new Map<String,String>{'OpportunityId'=>newOpportunity[0].Id,'Project__c'=>project.Id,'PricebookEntryId'=>pbEntry.Id});
        List<OpportunityLineItem> oppLineItem = (List<OpportunityLineItem>)SmartFactory.createSObjectList('OpportunityLineItem',false,1);
        oppLineItem[0].Quantity = 5;
        oppLineItem[0].TotalPrice = oppLineItem[0].Quantity * pbEntry.UnitPrice;
        oppLineItem[0].ServiceDate = date.today();
        insert oppLineItem;
        system.debug('-------------->'+oppLineItem);
        //Create Billing_Schedule__c 
        SmartFactory.overrideFieldsMap.put('Billing_Schedule__c', new Map<String,String>{'Opportunity_Product__c'=>oppLineItem[0].Id,'Opportunity__c'=>newOpportunity[0].Id});
        List<Billing_Schedule__c> billingschedule = (List<Billing_Schedule__c>)SmartFactory.createSObjectList('Billing_Schedule__c',false,1);
        billingschedule[0].Period_Start__c = System.today();
        billingschedule[0].Period_End__c = System.today();
        billingschedule[0].Media_Budget__c = 99999999;
        insert billingschedule;
        }
    //this method populates the opportunityLineItem to the ComponentController
    @isTest static void testBillingSchedulePopulation(){ 
        //Query the database for newly inserted OpportunityLineItem records
        opportunityLineItem oli = [select id,name,opportunity.name,OpportunityId from opportunityLineItem WHERE OpportunityId != NULL ];
        //Pass OpportunityLineItem to the ComponentController(OrderItemComp)
        BillingScheduleCompCntrl bsc = new BillingScheduleCompCntrl();
        bsc.oliId = oli.id;
        //bsc.getOrderItemList();
        //Test that OpportunityLineItem is not null
        System.assert(bsc.getBillingScheduleList().size()>0);
    }
}