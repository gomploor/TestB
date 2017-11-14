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
* Class Name : CPButtonsExt_Test
* Created By : Anna Courtney
* Created Date : 5/30/2017
* Description : This class will cover the code coverage for 'CPButtonsExt' class.
*********************************************************************************************************/
@isTest(SeeAllData = false) 
public class CPButtonsExt_Test {
    
    //Create test data
    @testSetup 
    static void testDataSetup(){
        Test.startTest();
        SandboxRefresh.loadData();
         //Get std priceBookId
        Id stdPriceBookId = Test.getStandardPricebookId();
        Opportunity opp = [Select Id, Pricebook2Id from Opportunity limit 1];
        
         //Create product
        SmartFactory.overrideFieldsMap.put('Product2', new Map<String,String>{'Name' => 'Test_Product'}); 
        List<Product2> prodLst = TestDataFactory.createProduct(1);
        
        //Create pricebook entry
        SmartFactory.overrideFieldsMap.put('PricebookEntry', new Map<String,String>{'UnitPrice' => '100.00'});
        PricebookEntry pbe = TestDataFactory.createPriceBookEntry(prodLst[0].Id,stdPriceBookId);
        PricebookEntry pbe2 = TestDataFactory.createPriceBookEntry(prodLst[0].Id,opp.Pricebook2Id);
        
        //Create OpportunityLineItem              
        SmartFactory.IncludedFields.put('OpportunityLineItem', New Set<String>{'ServiceDate','TotalPrice','Quantity','Waiting_Status__c'});
        TestDataFactory.createOpportunityProduct(opp.Id, pbe2.Id); 
        OpportunityLineItem oli = [Select Id, Waiting_Status__c
                                    from OpportunityLineItem limit 1];
        Campaign_Profile__c cp = new Campaign_Profile__c(Campaign_Profile_Name__c = 'Test', Opportunity_Product_ID__c=oli.Id,
                                                Begin_Build_Process__c = true);
        insert cp;

        //Set up 2 WR_BPM__Stub__c records. One as context and one as parent.
        WR_BPM__Stub__c parentStub = new WR_BPM__Stub__c(WR_BPM__Area__c = 'testString', WR_BPM__Email__c = 'email@test.com');
        insert parentStub;
        
        WR_BPM__Stub__c contextStub = new WR_BPM__Stub__c(WR_BPM__Child_Stub__c = parentStub.Id, WR_BPM__Curency__c = 10, WR_BPM__url__c = 'www.test.com',
                                                         WR_BPM__Check__c = false, WR_BPM__String__c = 'testString', WR_BPM__Picklist__c = 'One',
                                                         WR_BPM__Number__c = 2);
        insert contextStub;
        
        WR_BPM__Process__c process = new WR_BPM__Process__c(Name = 'Clear Conditional Fields Test');
        insert process;
        
        WR_BPM__Flow__c flow = new WR_BPM__Flow__c
            (Name = 'Test Flow', WR_BPM__Type__c = 'One Time', WR_BPM__Is_Template__c = false, WR_BPM__Object_Type__c = 'WR_BPM__Stub__c');
        insert flow;
        
        WR_BPM__Flow_Instance__c flowInst = new WR_BPM__Flow_Instance__c
                (WR_BPM__Is_Active__c = true, WR_BPM__Flow__c = flow.Id, WR_BPM__Object_Id__c = contextStub.Id, 
                 WR_BPM__Object_Name__c = contextStub.Name, WR_BPM__Reference_To_Process__c = process.Id);
        insert flowInst;
        Test.stopTest();
    }
    
     @isTest 
     static void testCpButtons(){
        
        PageReference pageref = Page.CPButtons; 
        Test.setCurrentPage(pageref);
        Campaign_Profile__c cp = [Select Id, Name, Begin_Build_Process__c, Post_Live_Maintenance__c, Opportunity_Product_ID__c
                                    from Campaign_Profile__c limit 1];
        OpportunityLineItem oli = [Select Id, Waiting_Status__c
                                    from OpportunityLineItem limit 1];
        oli.Waiting_Status__c = 'Live';
        update oli;
        
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(cp);
        CPButtonsExt cpExtPage = new CPButtonsExt(stdController);
        PageReference pf;
        pf = cpExtPage.beginProcess();
        pf = cpExtPage.postLiveMaint();
        pf = cpExtPage.recurMaint();
        cpExtPage.renderError = false;
        cpExtPage.errorText = 'Error';
        cpExtPage.guid2formID.put('x','y');
        cpExtPage.escalationFlowInstance = [SELECT ID, Name FROM WR_BPM__Flow_Instance__c LIMIT 1];
        pf = cpExtPage.newIssue();
        pf = cpExtPage.invokeChangeRequest();
        System.assert(cpExtPage.renderMaint == false);
        System.assert(cpExtPage.renderBegin == false);
        Test.stopTest();
     }
}