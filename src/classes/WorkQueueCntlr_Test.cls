/*
* Created By   : Anna Courtney
* Created Date : 06/13/2017
* Desciption : Test Class to Cover WorkQueueCntlr class.
*/

@isTest
public class WorkQueueCntlr_Test {
    //Create test data to perform testmethods
	@testSetup 
	static void testDataSetup(){
	    
	    List<User> usrList = [select Id, ManagerId
	                    from User 
	                    where Id <> :UserInfo.getUserId() and isActive = true limit 3];
	    usrList[0].ManagerId = UserInfo.getUserId();
	    
	    update usrList;
	    List<Delegate_User__c> delUserList = new List<Delegate_User__c>();
	    delUserList.add(new Delegate_User__c(User__c = usrList[2].Id, User_Delegate__c = UserInfo.getUserId()));
	    insert delUserList;
	    
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
	    
	    WR_BPM__Process__c process = new WR_BPM__Process__c(Name = 'Build Test Process');
        insert process;
        WR_BPM__Flow__c flow = new WR_BPM__Flow__c
                              (Name = 'Test Flow', WR_BPM__Type__c = 'One Time', WR_BPM__Is_Template__c = false, WR_BPM__Object_Type__c = 'Campaign_Profile__c');
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
	    List<WR_BPM__Flow_Instance_Cursor__c> cursorList = new List<WR_BPM__Flow_Instance_Cursor__c>();
	    for (Integer i=0; i<25; i++){
	        WR_BPM__Flow_Instance_Cursor__c cursor = new WR_BPM__Flow_Instance_Cursor__c
	         (WR_BPM__Flow_Instance__c = flowInst.Id, WR_BPM__Step__c = step.Id, WR_BPM__Status__c = 'In Progress',
	          WR_BPM__Step_Assigned_To__c = UserInfo.getUserId(), WR_BPM__Step_Changed_Date__c = todayDt.addDays(i));
	       cursorList.add(cursor);
	    }
	    insert cursorList;
	    
	    List<WR_BPM__Flow_Instance_Issue__c> issueList = new List<WR_BPM__Flow_Instance_Issue__c>();
	    issueList.add(new WR_BPM__Flow_Instance_Issue__c(WR_BPM__Flow_Instance__c = flowInst.Id, WR_BPM__Step__c = step.Id, WR_BPM__Status__c = 'In Progress',
	          WR_BPM__Assign_To__c = UserInfo.getUserId(), CampaignProfile__c = cp.Id));
	    insert issueList;
	    
	    List<WR_BPM__Flow_Step_Property__c> propList = new List<WR_BPM__Flow_Step_Property__c>();
	    for(Integer p=1; p<5; p++){
	        WR_BPM__Flow_Step_Property__c prop = new WR_BPM__Flow_Step_Property__c
	          (Name = 'Priority', WR_BPM__Type__c = 'Priority',  WR_BPM__Flow_Step__c = step.Id,
	            WR_BPM__Cursor__c = cursorList[p].Id);
	            if(p==1)
	                prop.WR_BPM__Value__c = 'Low';
	            else if(p==2)
	                prop.WR_BPM__Value__c = 'Normal';
	            else if(p==3)
	                prop.WR_BPM__Value__c = 'High';
	            else if(p==4)
	                prop.WR_BPM__Value__c = 'Critical';
	            propList.add(prop);
	    }
	    insert propList;
	}
	
	@isTest 
	static void testWorkQueue() {
	    PageReference pageref = Page.WorkQueue; 
        Test.setCurrentPage(pageref);
        Test.startTest();
        WorkQueueCntlr wupage = new WorkQueueCntlr();
        //WorkQueueCntlr.WrTask  task = new WorkQueueCntlr.WrTask();
        //WorkQueueCntlr.CalendarRow cal = new WorkQueueCntlr.CalendarRow();
        wupage.inDate = null;
        wupage.calendarList = null;
        wupage.viewCalendar();
        wupage.viewCalendar();
        wupage.inDate = Date.Today();
        wupage.inDate = wupage.inDate.addDays(5);
        wupage.changeCalendarDate();
        wupage.Reset();
        List<SelectOption> selOption = wupage.getTaskFilter();
        Test.stopTest();
	}  
	
	@isTest 
	static void testSort(){
	    PageReference pageref = Page.WorkQueue; 
        Test.setCurrentPage(pageref);
        Test.startTest();
        WorkQueueCntlr wupage = new WorkQueueCntlr();
        wupage.sortBy = 'taskName';
        wuPage.sortTable();
        wupage.sortBy = 'cpName';
        wuPage.sortTable();
        wupage.sortBy = 'processName';
        wuPage.sortTable();
        wupage.sortBy = 'reqBy';
        wuPage.sortTable();
        wupage.sortBy = 'dueDate';
        wuPage.sortTable();
        wupage.sortBy = 'subCrtDate';
        wuPage.sortTable();
        wupage.sortBy = 'lastUpdtDate';
        wuPage.sortTable();
        wupage.sortBy = 'priority';
        wuPage.sortTable();
        wupage.sortBy = 'assignedToName';
        wuPage.sortTable();
        wupage.sortBy = 'companyName';
        wuPage.sortTable();
        //wuPage.Next();
        //wuPage.Prev();
        Test.stopTest();
	}
	
	@isTest
	static void testReassign(){
	    PageReference pageref = Page.WorkQueue; 
        Test.setCurrentPage(pageref);
        Test.startTest();
        WorkQueueCntlr wupage = new WorkQueueCntlr();
        List<SelectOption> selUsers = wupage.getAllUser();
        wuPage.reassignTasks();
        wuPage.selUser = UserInfo.getUserId();
        //wuPage.taskListPage[0].selRecord = true;
        wuPage.reassignTasks();
        wuPage.viewTasks();
        wuPage.viewIssues();
        Test.stopTest();
	}
	
	@isTest
	static void testFilter(){
	    PageReference pageref = Page.WorkQueue; 
        Test.setCurrentPage(pageref);
        Test.startTest();
        WorkQueueCntlr wupage = new WorkQueueCntlr();
        wupage.FilterIssues();
        wupage.Filter();
        wupage.FilterBuild();
        wupage.Filter();
        wupage.FilterBuild();
        wupage.Filter();
        wupage.FilterMaint();
        wupage.Filter();
        wupage.FilterMaint();
        wupage.Filter();
        wupage.FilterApprQA();
        wupage.Filter();
        wupage.FilterApprQA();
        wupage.Filter();
        wupage.FilterExp();
        wupage.Filter();
        wupage.FilterExp();
        wupage.Filter();
        wuPage.buildTasks = false;
        wupage.maintTasks = false;
        wupage.apprQaTasks = false;
        wupage.exptasks = false;
        wupage.Filter();
        Test.stopTest();
	}
	
    @isTest
	static void testDateRange(){
	    PageReference pageref = Page.WorkQueue; 
        Test.setCurrentPage(pageref);
        Test.startTest();
        WorkQueueCntlr wupage = new WorkQueueCntlr();
        Date dt = Date.today();
        wupage.getCurrDateRange(dt);
        wupage.getCurrDateRange(dt.addDays(1));
        wupage.getCurrDateRange(dt.addDays(2));
        wupage.getCurrDateRange(dt.addDays(3));
        wupage.getCurrDateRange(dt.addDays(4));
        wupage.getCurrDateRange(dt.addDays(5));
        wupage.getCurrDateRange(dt.addDays(6));
        Test.stopTest();
	}
	
	@isTest
	static void testCpWorkQ(){
	    
	    Campaign_Profile__c cp = [Select Id from Campaign_Profile__c limit 1];
	    PageReference pageref = Page.WorkQueueCp; 
	    Test.setCurrentPage(pageref);
	     
	    Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(cp);
        WorkQueueCntlr wuPage = new WorkQueueCntlr(stdController);

        Test.stopTest();
	}
}