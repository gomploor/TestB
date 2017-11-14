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
* Class Name : QAResultsFormRenderer_Test
* Created By : Vijay Varada
* Created Date : 11/14/2017
* Description : This class will cover the code coverage for 'QAResultsFormRenderer' class.
*********************************************************************************************************/
@isTest(SeeAllData = false) 
public class QAResultsFormRenderer_Test {

	//Create test data
    @testSetup 
    static void testDataSetup(){
        Test.startTest();   
        //Insert smm campaign profile
        Campaign_Profile__c newCp = new Campaign_Profile__c(Campaign_Profile_Name__c='Test SMM', Campaign_Type__c='Social Media Management',
                                                            RecordTypeId = CampaignProfileCache.getRecordType('Social Media Management').Id);
        insert newCp; 
        
        //insert qa result for smm cp
        QA_Result__c newQaResult = new QA_Result__c(Campaign_Profile__c=newCp.Id); 
        insert newQaResult; 
        
        Test.stopTest();
    }
    
     @isTest 
     static void testShowQAResultsLinkedToCp(){
        QA_Result__c queryQaResult  = [Select Id from QA_Result__c Limit 1]; 
        
        Test.startTest();
        PageReference pageref = Page.QAResultsFormRenderer; 
        Test.setCurrentPage(pageref);
        ApexPages.StandardController stdController = new ApexPages.StandardController(queryQaResult);
        QAResultsFormRenderer controller = new QAResultsFormRenderer(stdController); 
        Test.stopTest();
	 }
	 
	 
     @isTest 
     static void testShowQAResultsWithNoLinkToCp(){
        QA_Result__c queryQaResult  = [Select Id from QA_Result__c Limit 1];
        queryQaResult.Campaign_Profile__c = null;
        update queryQaResult;
        
        Test.startTest();
        PageReference pageref = Page.QAResultsFormRenderer; 
        Test.setCurrentPage(pageref);
        ApexPages.StandardController stdController = new ApexPages.StandardController(queryQaResult);
        QAResultsFormRenderer controller = new QAResultsFormRenderer(stdController);
        Test.stopTest();
	 }

}