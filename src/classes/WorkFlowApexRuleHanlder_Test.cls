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
* Class Name : WorkFlowApexRuleHanlder_Test
* Created By : Vijay Varada
* Created Date : 11/08/2017
* Description : This class will cover the code coverage for 'WorkFlowApexRuleHanlder' class.
*********************************************************************************************************/
@isTest(SeeAllData = false) 
public class WorkFlowApexRuleHanlder_Test {
	//Create test data
    @testSetup 
    static void testDataSetup() {
        
        SMM_Product__c testSmm = new SMM_Product__c(copy_instructions__c = '');
        insert testSmm;
        
    	Change_Request__c testCr = new Change_Request__c(SMM_Product__c= testSmm.Id, Additional_Posts__c = true);
      	insert testCr;

    }

    //{"Id":"SMM Product Id","Field_Api_Name":"unknownfield","CallType" : "isCopyInstructionsBlank"}
	private static testMethod void testRunWithUnknowField() {
	    Change_Request__c queryCr = [Select Id from Change_Request__c];
	    SMM_Product__c querySmm = [Select Id, copy_instructions__c from SMM_Product__c];
        String jsonString = '{"Id": "'+ querySmm.Id + '", "Field_Api_Name":"some_unknow_field", "CallType" : "isCopyInstructionsBlank"}';
        
        WorkFlowApexRuleHanlder wfApexRuleHandler = new WorkFlowApexRuleHanlder();
        Boolean retValue =  wfApexRuleHandler.run(queryCr,null, jsonString);
        
        System.assertEquals(true, retValue, 'we passed unknown field hence retvalu is true');
	}

    //{"Id":"SMM Product Id","Field_Api_Name":"copy_instructions__c","CallType" : "isCopyInstructionsBlank"} 
	private static testMethod void testRunFieldWithEmptyValue() {
	    Change_Request__c queryCr = [Select Id from Change_Request__c];
	    SMM_Product__c querySmm = [Select Id, copy_instructions__c from SMM_Product__c];
        String jsonString = '{"Id": "'+ querySmm.Id + '", "Field_Api_Name":"copy_instructions__c", "CallType" : "isCopyInstructionsBlank"}';
        
        WorkFlowApexRuleHanlder wfApexRuleHandler = new WorkFlowApexRuleHanlder();
        Boolean retValue =  wfApexRuleHandler.run(queryCr,null, jsonString);
        
        System.assertEquals(true, retValue, 'we passed field with empty value hence retvalue is true');
	}
	
	//{"Id":"SMM Product Id","Field_Api_Name":"copy_instructions__c","CallType" : "isCopyInstructionsBlank"} 
	private static testMethod void testRunFieldWithValue() {
	    Change_Request__c queryCr = [Select Id from Change_Request__c];
	    SMM_Product__c querySmm = [Select Id, copy_instructions__c from SMM_Product__c];
	    querySmm.copy_instructions__c = 'some value';
	    update querySmm;
	    
        String jsonString = '{"Id": "'+ querySmm.Id + '", "Field_Api_Name":"copy_instructions__c", "CallType" : "isCopyInstructionsBlank"}';
        
        WorkFlowApexRuleHanlder wfApexRuleHandler = new WorkFlowApexRuleHanlder();
        Boolean retValue =  wfApexRuleHandler.run(queryCr,null, jsonString);
        
        System.assertEquals(false, retValue, 'we passed field with value hence retvalue is falsery');
	}
	
	//{"Id":"SMM Product Id","Field_Api_Name":"copy_instructions__c","CallType" : "unknowncalltype"} 
	private static testMethod void testRunWithUnknowCallType() {
	    Change_Request__c queryCr = [Select Id from Change_Request__c];
	    SMM_Product__c querySmm = [Select Id, copy_instructions__c from SMM_Product__c];
	    querySmm.copy_instructions__c = 'some value';
	    update querySmm;
	    
        String jsonString = '{"Id": "'+ querySmm.Id + '", "Field_Api_Name":"copy_instructions__c", "CallType" : "unknowncalltype"}';
        Boolean expectedExceptionThrown =false;
        try{
            WorkFlowApexRuleHanlder wfApexRuleHandler = new WorkFlowApexRuleHanlder();
            Boolean retValue =  wfApexRuleHandler.run(queryCr,null, jsonString);
        }catch(Exception e){
            expectedExceptionThrown =  (e.getMessage().contains('Unknown Call Type') ? true : false);
        } 
        System.assertEquals(true, expectedExceptionThrown, 'WorkFlowApexRuleHanlder run method is called without CallType');
	}
}