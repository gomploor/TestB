/*
* Created By   : Anna Courtney
* Created Date : 09/27/2017
* Desciption : Test Class to Cover FIIAfterInsertTriggerHandler class
*/

@isTest
public class FIIAfterInsertTriggerHandler_Test {
    //Create test data to perform testmethods
	@isTest 
	static void testFIAInsert(){
	
	    Account acct = new Account(Name = 'Test');
	    insert acct;
	    
	    //Constants.loadData();      
	    Campaign_Profile__c cp = new Campaign_Profile__c();
	    cp.RecordTypeId = RecordTypeCache.getRecordType('Campaign_Profile__c', 'PPC').Id;
	    cp.Call_Tracking_Adjustment__c = true;
	    cp.Budget_Adjustment__c = true;
	    cp.Campaign_Profile_Name__c = '1234567890123456789012345678';
	    cp.Expedite__c = true;
	    cp.Client_Name__c = acct.Id;
	    insert cp;
	    
	    Change_Request__c cr = new Change_Request__c();
	    cr.Campaign_Profile__c = cp.Id;
	    insert cr;
	    
	    WR_BPM__Process__c process = new WR_BPM__Process__c(Name = 'Build Test Process');
        insert process;
        WR_BPM__Flow__c flow = new WR_BPM__Flow__c
                              (Name = 'Test Flow', WR_BPM__Type__c = 'One Time', WR_BPM__Is_Template__c = false, WR_BPM__Object_Type__c = 'campaign_profile__c');
        insert flow;
        
        WR_BPM__Flow__c flowCr = new WR_BPM__Flow__c
                              (Name = 'Test Flow', WR_BPM__Type__c = 'One Time', WR_BPM__Is_Template__c = false, WR_BPM__Object_Type__c = 'change_request__c');
        insert flowCr;
        
        WR_BPM__Flow__c flowCs = new WR_BPM__Flow__c
                              (Name = 'Test Flow', WR_BPM__Type__c = 'One Time', WR_BPM__Is_Template__c = false, WR_BPM__Object_Type__c = 'case');
        insert flowCs;
        
	    WR_BPM__Flow_Instance__c flowInst = new WR_BPM__Flow_Instance__c
	            (WR_BPM__Is_Active__c = true, WR_BPM__Flow__c = flow.Id, WR_BPM__Object_Id__c = cp.Id, WR_BPM__Object_Name__c = cp.Name,
	            WR_BPM__Reference_To_Process__c = process.Id);
	    insert flowInst;
	    
	    WR_BPM__Flow_Instance__c flowInstCr = new WR_BPM__Flow_Instance__c
	            (WR_BPM__Is_Active__c = true, WR_BPM__Flow__c = flowCr.Id, WR_BPM__Object_Id__c = cr.Id, WR_BPM__Object_Name__c = cr.Name,
	            WR_BPM__Reference_To_Process__c = process.Id);
	    insert flowInstCr;
	    
	    WR_BPM__Form__c form = new WR_BPM__Form__c(Name = 'Test Form');
        insert form;
        WR_BPM__Flow_Step_Junction__c step = new WR_BPM__Flow_Step_Junction__c
            (Name = 'Test Step 1234567890123456789012345', WR_BPM__Layout_Type__c='Form', WR_BPM__Layout__c=form.Id, WR_BPM__Flow__c=flow.Id, WR_BPM__Duration__c = 1440, 
             WR_BPM__Duration_String__c = '1440', WR_BPM__Type__c = 'Approval');
	    insert step;
	    
	    WR_BPM__Flow_Step_Junction__c stepCR = new WR_BPM__Flow_Step_Junction__c
            (Name = 'Test Step 1234567890123456789012345', WR_BPM__Layout_Type__c='Form', WR_BPM__Layout__c=form.Id, WR_BPM__Flow__c=flowCr.Id, WR_BPM__Duration__c = 1440, 
             WR_BPM__Duration_String__c = '1440', WR_BPM__Type__c = 'Approval');
	    insert stepCr;
	    
	    Datetime todayDt = System.now().addDays(-10);
	    List<WR_BPM__Flow_Instance_Issue__c> issueList = new List<WR_BPM__Flow_Instance_Issue__c>();
	    for (Integer i=0; i<3; i++){
	        WR_BPM__Flow_Instance_Issue__c issue = new WR_BPM__Flow_Instance_Issue__c
	         (WR_BPM__Flow_Instance__c = flowInst.Id, WR_BPM__Step__c = step.Id,  
	          WR_BPM__Assign_To__c = UserInfo.getUserId());
	       issueList.add(issue);
	    }
	    for (Integer j=0; j<3; j++){
	        WR_BPM__Flow_Instance_Issue__c issue = new WR_BPM__Flow_Instance_Issue__c
	         (WR_BPM__Flow_Instance__c = flowInstCr.Id, WR_BPM__Step__c = stepCr.Id,  
	          WR_BPM__Assign_To__c = UserInfo.getUserId());
	       issueList.add(issue);
	    }
	    insert issueList;
	    
	    Test.startTest();        
	    for(WR_BPM__Flow_Instance_Issue__c iss :issueList)
	        iss.WR_BPM__Status__c = 'Completed';
	    update issueList;
        Test.stopTest();
        
	    delete issueList;
	}    

}