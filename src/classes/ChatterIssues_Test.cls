/*
    Created By   : Anna Courtney
    Created Date : 09/27/2017
    Desciption : Test Class to Cover ChatterIssues class
    Making this test class - see all data = true, otherwise getting system exception.
    System.UnsupportedOperationException: ConnectApi methods are not supported in data siloed tests. Please use @IsTest(SeeAllData=true). 
*/
@IsTest(SeeAllData=true)
public class ChatterIssues_Test {
    
    @isTest 
	static void testChatter(){
	    
	    User usr = [Select Id from User where Id <> :UserInfo.getUserId() and isActive = true Limit 1];
	    
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
	    List<Campaign_Role_Assignment__c> caList = new List<Campaign_Role_Assignment__c>();
	    caList.add(new Campaign_Role_Assignment__c(User__c = UserInfo.getUserId(), Role__c = 'AM', Campaign_Profile__c = cp.Id));
	    caList.add(new Campaign_Role_Assignment__c(User__c = usr.Id, Role__c = 'Email Coordinator', Campaign_Profile__c = cp.Id));
	    insert caList;
	    
	    WR_BPM__Process__c process = new WR_BPM__Process__c(Name = 'Build Test Process');
        insert process;
        
        WR_BPM__Flow__c flow = new WR_BPM__Flow__c
                              (Name = 'Test Flow', WR_BPM__Type__c = 'One Time', WR_BPM__Is_Template__c = false, WR_BPM__Object_Type__c = 'case');
        insert flow;
        
         WR_BPM__Flow_Instance__c flowInst = new WR_BPM__Flow_Instance__c
	            (WR_BPM__Is_Active__c = true, WR_BPM__Flow__c = flow.Id, WR_BPM__Object_Id__c = cp.Id, WR_BPM__Object_Name__c = cp.Name,
	            WR_BPM__Reference_To_Process__c = process.Id);
	    insert flowInst;
	    
	    WR_BPM__Form__c form = new WR_BPM__Form__c(Name = 'Test Form');
        insert form;
        WR_BPM__Flow_Step_Junction__c step = new WR_BPM__Flow_Step_Junction__c
            (Name = 'Test Step 1234567890123456789012345', WR_BPM__Layout_Type__c='Form', WR_BPM__Layout__c=form.Id, WR_BPM__Flow__c=flow.Id, WR_BPM__Duration__c = 1440, 
             WR_BPM__Duration_String__c = '1440', WR_BPM__Type__c = 'Approval');
	    insert step;
	    
	    Datetime todayDt = System.now().addDays(-10);
	    List<WR_BPM__Flow_Instance_Issue__c> issueList = new List<WR_BPM__Flow_Instance_Issue__c>();
	    for (Integer i=0; i<3; i++){
	        WR_BPM__Flow_Instance_Issue__c issue = new WR_BPM__Flow_Instance_Issue__c
	         (WR_BPM__Flow_Instance__c = flowInst.Id, WR_BPM__Step__c = step.Id, CampaignProfile__c = cp.Id, 
	          WR_BPM__Assign_To__c = UserInfo.getUserId());
	       issueList.add(issue);
	    }
	    insert issueList;
	    
	    Test.startTest();        
        ChatterIssues ci1 = new ChatterIssues(issueList, null);
	    for(WR_BPM__Flow_Instance_Issue__c iss :issueList)
	        iss.WR_BPM__Status__c = 'Completed';
	    update issueList;
	    ChatterIssues ci2 = new ChatterIssues(issueList, issueList);
	    
	    List<WR_BPM__Flow_Instance_Cursor__c> cursorList = new List<WR_BPM__Flow_Instance_Cursor__c>();
	    
	    for (Integer i=0; i<25; i++){
	        WR_BPM__Flow_Instance_Cursor__c cursor = new WR_BPM__Flow_Instance_Cursor__c
	         (WR_BPM__Flow_Instance__c = flowInst.Id, WR_BPM__Step__c = step.Id, WR_BPM__Status__c = 'In Progress',
	          WR_BPM__Step_Assigned_To__c = UserInfo.getUserId(), WR_BPM__Step_Changed_Date__c = todayDt.addDays(i));
	       cursorList.add(cursor);
	    }
	    insert cursorList;
	    List<WR_BPM__Flow_Instance_Cursor__c> newCurList = cursorList.clone();
	    
	    for(WR_BPM__Flow_Instance_Cursor__c cur :newCurList){
	        cur.WR_BPM__Status__c = 'Completed';
	        cur.WR_BPM__Step_Assigned_To__c = usr.Id;
	        update newCurList;
	    }

	    ChatterIssues ci3 = new ChatterIssues(newCurList, cursorList);
	    
	    List<WR_BPM__Flow_Instance_History__c> histList = [Select Id from WR_BPM__Flow_Instance_History__c limit 5];
	    ChatterIssues ci4 = new ChatterIssues(histList, null);
	    
        Test.stopTest();
	    
	}    

}