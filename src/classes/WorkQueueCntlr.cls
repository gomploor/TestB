public without sharing class WorkQueueCntlr extends WorkQueueVir{
   
    public Date inDate {get;set;}
    public Integer pageSize {get; set;}
    public String selTask {get; set;}
    public String selUser {get; set;}
    public String SortBy{get;set;}
    public String SortOrder{get;set;}
    public Boolean renderPrev {get; set;}
    public Boolean renderNext {get; set;}
    public Boolean renderCalendar {get; set;}
    public Map<Id, WR_BPM__Flow_Instance_Cursor__c> allTaskMapWR {get; set;}
    public Map<Id, WR_BPM__Flow_Instance_Issue__c> allIssueMapWR {get; set;}
    public Map<Id, WrTask> allTaskMap {get; set;}
    public List<WrTask> taskList {get; set;}
    public List<WrTask> taskListPage {get; set;}
    public Boolean renderTasks {get;set;}
    public Boolean issueTasks {get; set;}
    public Boolean buildTasks {get; set;}
    public Boolean maintTasks {get; set;}
    public Boolean apprQATasks {get; set;}
    public Boolean expTasks {get; set;}
    public String slds_box {get;set;}
    public Boolean renderReassign {get; set;}
    public Boolean selector {get; set;}
    public Boolean selectTask {get; set;}
    public String baseUrl {get; set;}
    public String currFullUrl {get; set;}
    public String currUrl {get; set;} 
    public Id userId;
    public Integer recNumber;
    public Set<Id> cpIdSet;
    public Set<Id> crIdSet;
    public Campaign_Profile__c campaignProfile {get; set;}
    public Change_Request__c changeRequest {get; set;}
    Boolean cpController {get;set;}
    public Set<Id> activeTaskSet {get;set;}
    Map<String, List<WrTask>> dtTaskMap;
    public Set<String> objectIdSet;
    
    public Map<String, List<WrTask>> dateTaskMap;
    public List<CalendarRow> calendarList {get;set;}
    public Id taskId {get;set;}
    public String linkUrl {get;set;}
    public String taskName {get;set;}
    public Map<Id, User> reqByMap;
    public Map<Id, User> userMap;
    public Map<Id, Group> groupMap;
    public Map<Id, User> userMapSubView;
    public Map<Id, Group> groupMapSubView;
    public static final Double MILLISECONDS_IN_HOURS = (1000*60*60);
    public static  BusinessHours bh = [SELECT Id, SundayStartTime, MondayStartTime, TuesdayStartTime, 
                                            WednesdayStartTime, ThursdayStartTime, FridayStartTime,
                                            SaturdayStartTime, SundayEndTime, MondayEndTime,TuesdayEndTime,
                                            WednesdayEndTime, ThursdayEndTime, FridayEndTime,SaturdayEndTime,
                                            TimeZoneSidKey   
                                        FROM BusinessHours 
                                        WHERE IsDefault=true
                                        AND IsActive = true];
    
    
    public WorkQueueCntlr(ApexPages.StandardController ctl) {
        
        if(Test.isRunningTest() != true)
            ctl.addFields(new List<String>{'Campaign_Profile__c'});
         try{
            campaignProfile = (Campaign_Profile__c)ctl.getRecord();
            cpController = true;
        } catch (Exception e){
            changeRequest = (Change_Request__c)ctl.getRecord();
            campaignProfile = new Campaign_Profile__c(Id = changeRequest.Campaign_Profile__c);
            cpController = false;
        }
        system.debug('---cpController-' + cpController);
        activeTaskSet = getActiveTasks();
        pageSize = 5; 
        getUrl();
        userId = UserInfo.getUserId();
        getAllCpTasks();
    }
    
    public WorkQueueCntlr(){
       
       activeTaskSet = getActiveTasks();
       pageSize = 10; 
       inDate = Date.today();
        
       userId = UserInfo.getUserId();
       objectIdSet = getCpforAM(userId);
       getUserMap();
       renderReassign = false;
       if((userMap != null && userMap.size() > 1) || (groupMap != null && !groupMap.isEmpty())) //user is manager or part of the group
          renderReassign = true; 
       dateTaskMap = new Map<String, List<WrTask>>();
       calendarList = new List<CalendarRow>();
       getUrl();
       getAllTasks();
       issueTasks = false;
       buildTasks = false;
       maintTasks = false;
       apprQATasks = false;
       expTasks = false;
       renderCalendar = false;
       renderPrev = false;
       renderNext = false;
       selector = false;
       selectTask = false;
       renderTasks = true;
       if(taskList != null && taskList.size() > pageSize)
          renderNext = true;
       slds_box = 'slds-box'; 
       
    }
   
    public List<SelectOption> getTaskFilter() {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption(MY_WORK, MY_WORK)); 
            options.add(new SelectOption(MY_TEAM_WORK, MY_TEAM_WORK)); 
            options.add(new SelectOption(REQUESTED_BY_ME, REQUESTED_BY_ME));
            return options;
    }
    
    public List<SelectOption> getAllUser() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('-none-', '-none-')); 
        if(userMap != null && !userMap.isEmpty()){
            for (User usr :userMap.values())
                options.add(new SelectOption(usr.Id, usr.Name));    
        }
        return options;
    }

   private void getUserMap(){
       
       userMap = new Map<Id, User>([Select Id, Name, ManagerId,
                                    (Select Id, User__r.Name, User__c  from User_Delegates__r)  
                                    from User
                                    where isActive = true and (Id = :userId or ManagerId = :userId)
                                    order by LastName]);
       Set<Id> idSet = new Set<Id>();
       List<User> userList;
       
       for(User usr :userMap.values()){
           if(usr.User_Delegates__r != null && !usr.User_Delegates__r.isEmpty())
              for(Delegate_User__c delUsr :usr.User_Delegates__r)
                idSet.add(delUsr.User__c);
       }
       if(!idSet.isEmpty())
          userList = [Select Id, Name, ManagerId
                                    from User
                                    where isActive = true and (Id IN :idSet or ManagerId IN :idSet)
                                    order by LastName];
      if(userList != null && !userList.isEmpty())
          userMap.putAll(new Map<Id,User>(userList));
      
      groupMap = new Map<Id, Group>();    
      List<GroupMember> groupList =  [Select UserOrGroupId, Groupid, Group.Name, Group.DeveloperName 
                                     from GroupMember 
                                     where Group.Type = 'Queue' and UserOrGroupId IN :userMap.keySet()];
      if(groupList != null && !groupList.isEmpty()){
          for(GroupMember gm :groupList)
             groupMap.put(gm.GroupId, new Group(Id=gm.GroupId, Name = gm.Group.Name));
      }
   }    
   
   public PageReference reassignTasks(){
       
       selector = false;
       Boolean err = false;
       List<WR_BPM__Flow_Instance_Cursor__c> tasksToUpdate = new List<WR_BPM__Flow_Instance_Cursor__c>();
       List<WR_BPM__Flow_Instance_Issue__c> issuesToUpdate = new List<WR_BPM__Flow_Instance_Issue__c>();
       system.debug('-----selUser-');
       if(selUser == null || selUser == '-none-'){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select user to Reassign.'));
           err = true;
       }
       if(selUser != null && selUser != '-none-' && taskListPage != null && !taskListPage.isEmpty()){
           for(WrTask ts :taskListPage){
               if(ts.selRecord == true){
                   ts.selRecord = false;
                   if(ts.type == TASK_TYPE){
                        tasksToUpdate.add(new WR_BPM__Flow_Instance_Cursor__c(Id = ts.taskId, WR_BPM__Step_Assigned_To__c = selUser));
                        allTaskMapWR.get(ts.taskId).WR_BPM__Step_Assigned_To__c = selUser;
                   } else if(ts.type == ISSUE_TYPE){
                        issuesToUpdate.add(new WR_BPM__Flow_Instance_Issue__c(Id = ts.taskId, WR_BPM__Assign_To__c = selUser));
                        allIssueMapWR.get(ts.taskId).WR_BPM__Assign_To__c = selUser;
                   }
                   allTaskMap.get(ts.taskId).assignedTo = selUser;
                   allTaskMap.get(ts.taskId).assignedToName = userMap.get(selUser).Name;
               }
           }
       }
       //system.debug('--tasksToUpdate-' + tasksToUpdate);
       if((tasksToUpdate != null && !tasksToUpdate.isEmpty()) || (issuesToUpdate != null && !issuesToUpdate.isEmpty())){
           //system.debug('---unside update-');
           if(tasksToUpdate != null && !tasksToUpdate.isEmpty())
               update tasksToUpdate;
           if(issuesToUpdate != null && !issuesToUpdate.isEmpty())
               update issuesToUpdate;
       } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select Tasks or Issues to Reassign.'));
            err = true;
       }
       if(err == true)
          return null;
       else
         return Filter();
   }
   public PageReference FilterIssues(){
       if(issueTasks == true)
            issueTasks = false;
        else
            issueTasks = true;
        if(issueTasks == true)
            renderCalendar = false;
       return Filter();
   }
   
   public PageReference FilterBuild(){
       if(buildTasks == true)
            buildTasks = false;
        else
            buildTasks = true;
        if(buildTasks == true)
            renderCalendar = false;
       return Filter();
   }
   public PageReference FilterMaint(){
       if(maintTasks == true)
            maintTasks = false;
        else
            maintTasks = true;
        if(maintTasks == true)
            renderCalendar = false;
       return Filter();
   }
   public PageReference FilterApprQA(){
       if(apprQATasks == true)
            apprQATasks = false;
        else
            apprQATasks = true;
       if(apprQATasks == true)
            renderCalendar = false;
       return Filter();
   }
    public PageReference FilterExp(){
       if(expTasks == true)
            expTasks = false;
        else
            expTasks = true;
       if(expTasks == true)
            renderCalendar = false;
       return Filter();
   }
   public PageReference changeCalendarDate(){
        
       refreshCalendar();               
       PageReference ref;
       return ref;
   }
   
   public PageReference viewTasks(){
       
       renderTasks = true;
       PageReference ref;
       system.debug('----renderTasks-after-' + renderTasks);
       
       return ref;
   }
   
   public PageReference viewIssues(){
       renderTasks = false;
       PageReference ref;
       system.debug('----renderTasks-after-' + renderTasks);
       
       return ref;
   }
   
   public PageReference viewCalendar(){
       
       if(renderCalendar == true)
          renderCalendar = false;
       else 
          renderCalendar = true;
       if(renderCalendar == true){
           maintTasks = false;
           apprQATasks = false;
           issueTasks = false;
           buildTasks = false;
           expTasks = false;
           selTask = MY_TEAM_WORK;
       }
       if(renderCalendar == true){
           refreshCalendar();
       }
               
       PageReference ref;
       return ref;
   }
   
   public void  refreshCalendar(){
       if(calendarList == null)
          calendarList = new List<CalendarRow>();
       else
          calendarList.clear();
       if(inDate == null)
         inDate = Date.Today();
       List<String> dateList = getCurrDateRange(inDate);
       if(dateTaskMap != null && !dateTaskMap.isEmpty() && dateList != null && dateList.size() == 5){
           Integer size = 0;
           if (dateTaskMap.containsKey(dateList[0]))
               size = dateTaskMap.get(dateList[0]).size();
           if (dateTaskMap.containsKey(dateList[1]) && dateTaskMap.get(dateList[1]).size() > size)
               size = dateTaskMap.get(dateList[1]).size();  
           if (dateTaskMap.containsKey(dateList[2]) && dateTaskMap.get(dateList[2]).size() > size)
               size = dateTaskMap.get(dateList[2]).size();    
           if (dateTaskMap.containsKey(dateList[3]) && dateTaskMap.get(dateList[3]).size() > size)
               size = dateTaskMap.get(dateList[3]).size();    
           if (dateTaskMap.containsKey(dateList[4]) && dateTaskMap.get(dateList[4]).size() > size)
               size = dateTaskMap.get(dateList[4]).size();    
           for(Integer i=0; i<size; i++){
               CalendarRow cr;
               if(dateTaskMap.containsKey(dateList[0]) && dateTaskMap.get(dateList[0]).size() > i){
                   cr = new CalendarRow();
                   cr.monTaskName = dateTaskMap.get(dateList[0])[i].taskNameAbbr;
                   cr.monCpName = dateTaskMap.get(dateList[0])[i].abbrCpName;
                   cr.monTaskNameFull = dateTaskMap.get(dateList[0])[i].taskName;
                   cr.monCpNameFull = dateTaskMap.get(dateList[0])[i].cpName;
                   cr.monCpId =  dateTaskMap.get(dateList[0])[i].cpId;
                   cr.monProcUrl =  dateTaskMap.get(dateList[0])[i].proceedUrl;
                   cr.monPrior =  dateTaskMap.get(dateList[0])[i].priority;
                   cr.monPriorText =  dateTaskMap.get(dateList[0])[i].priorityText;
               }
               if(dateTaskMap.containsKey(dateList[1]) && dateTaskMap.get(dateList[1]).size() > i){
                   if(cr == null)
                      cr = new CalendarRow();
                   cr.tueTaskName = dateTaskMap.get(dateList[1])[i].taskNameAbbr;
                   cr.tueCpName = dateTaskMap.get(dateList[1])[i].abbrCpName;
                   cr.tueTaskNameFull = dateTaskMap.get(dateList[0])[i].taskName;
                   cr.tueCpNameFull = dateTaskMap.get(dateList[0])[i].cpName;
                   cr.tueCpId =  dateTaskMap.get(dateList[1])[i].cpId;
                   cr.tueProcUrl =  dateTaskMap.get(dateList[1])[i].proceedUrl;
                   cr.tuePrior =  dateTaskMap.get(dateList[1])[i].priority;
                   cr.tuePriorText =  dateTaskMap.get(dateList[0])[i].priorityText;
               }
               if(dateTaskMap.containsKey(dateList[2]) && dateTaskMap.get(dateList[2]).size() > i){
                   if(cr == null)
                      cr = new CalendarRow();
                   cr.wedTaskName = dateTaskMap.get(dateList[2])[i].taskNameAbbr;
                   cr.wedCpName = dateTaskMap.get(dateList[2])[i].abbrCpName;
                   cr.wedTaskNameFull = dateTaskMap.get(dateList[0])[i].taskName;
                   cr.wedCpNameFull = dateTaskMap.get(dateList[0])[i].cpName;
                   cr.wedCpId =  dateTaskMap.get(dateList[2])[i].cpId;
                   cr.wedProcUrl =  dateTaskMap.get(dateList[2])[i].proceedUrl;
                   cr.wedPrior =  dateTaskMap.get(dateList[2])[i].priority;
                   cr.wedPriorText =  dateTaskMap.get(dateList[0])[i].priorityText;
               }
               if(dateTaskMap.containsKey(dateList[3]) && dateTaskMap.get(dateList[3]).size() > i){
                   if(cr == null)
                      cr = new CalendarRow();
                   cr.thuTaskName = dateTaskMap.get(dateList[3])[i].taskNameAbbr;
                   cr.thuCpName = dateTaskMap.get(dateList[3])[i].abbrCpName;
                   cr.thuTaskNameFull = dateTaskMap.get(dateList[0])[i].taskName;
                   cr.thuCpNameFull = dateTaskMap.get(dateList[0])[i].cpName;
                   cr.thuCpId =  dateTaskMap.get(dateList[3])[i].cpId;
                   cr.thuProcUrl =  dateTaskMap.get(dateList[3])[i].proceedUrl;
                   cr.thuPrior =  dateTaskMap.get(dateList[3])[i].priority;
                   cr.thuPriorText =  dateTaskMap.get(dateList[0])[i].priorityText;
               }
               if(dateTaskMap.containsKey(dateList[4]) && dateTaskMap.get(dateList[4]).size() > i){
                   if(cr == null)
                      cr = new CalendarRow();
                   cr.friTaskName = dateTaskMap.get(dateList[4])[i].taskNameAbbr;
                   cr.friCpName = dateTaskMap.get(dateList[4])[i].abbrCpName;
                   cr.friTaskNameFull = dateTaskMap.get(dateList[0])[i].taskName;
                   cr.friCpNameFull = dateTaskMap.get(dateList[0])[i].cpName;
                   cr.friCpId =  dateTaskMap.get(dateList[4])[i].cpId;
                   cr.friProcUrl =  dateTaskMap.get(dateList[4])[i].proceedUrl;
                   cr.friPrior =  dateTaskMap.get(dateList[4])[i].priority;
                   cr.friPriorText =  dateTaskMap.get(dateList[0])[i].priorityText;
               }
               if(cr != null)
                  calendarList.add(cr);
           }
       }
   
   }
    public PageReference Filter(){
        PageReference ref;
        renderCalendar = false;
        if(allTaskMap != null && !allTaskMap.isEmpty()){
            taskList.clear();
            taskListPage.clear();
            for(WrTask tsk :allTaskMap.values()){
                if (((selTask == MY_WORK && tsk.assignedTo == userId) || 
                    (selTask == REQUESTED_BY_ME && tsk.reqById == userId) || 
                    (selTask == MY_TEAM_WORK && (userMap.containsKey(tsk.assignedTo) || groupMap.containsKey(tsk.assignedTo))) ) && 
                     ((buildTasks == true && tsk.isBuild == true) || 
                       (issueTasks == true && tsk.type == ISSUE_TYPE) ||
                       (maintTasks == true && tsk.isMaint == true) ||
                       (apprQATasks == true && tsk.isApprQA == true) || 
                         (expTasks == true && tsk.isExpedited == true) || 
                      (issueTasks == false && buildTasks == false && maintTasks == false && apprQATasks == false && expTasks == false))){
                    taskList.add(tsk);
                    if(taskListPage.size() < pageSize)
                        taskListPage.add(tsk);    
                }
            }
            for(Integer k=0; k<taskList.size(); k++) 
               taskList[k].recNumber = k;
        }
        renderPrev = false;
         if(taskList == null || (taskList != null && taskList.size() <= pageSize))
            renderNext = false;
        else
            renderNext = true;
        return ref;
    }
 
     public PageReference Reset(){
        PageReference ref;
        selTask = MY_WORK;
        selUser = '-none-';
        issueTasks = false;
        buildTasks = false;
        maintTasks = false;
        apprQATasks = false;
        expTasks = false;
        renderCalendar = false;
        renderTasks = true;    
        selector = false;
        if(allTaskMap != null && !allTaskMap.isEmpty()){
            taskList.clear();
            taskListPage.clear();
            for(WrTask tsk :allTaskMap.values()){ //select my tasks
                tsk.selRecord = false;
                if(tsk.assignedTo == userId){
                    taskList.add(tsk);
                }
            }
            for(Integer k=0; k<taskList.size(); k++)
                taskList[k].recNumber = k;
            for(Integer i=0; i< pageSize; i++){
                if(i < taskList.size())
                   taskListPage.add(taskList[i]);   
            }
        }
        renderPrev = false;
        if(taskList == null || (taskList != null && taskList.size() <= pageSize))
            renderNext = false;
        else
            renderNext = true;
      
        return ref;
    }
  
    public PageReference Prev(){
        PageReference ref;
        Integer firstTsk;
        system.debug('----histListPage prev before-' + taskListPage);
        if(taskList != null && !taskList.isEmpty() && taskListPage != null && !taskListPage.isEmpty()){
            firstTsk = taskListPage.get(0).recNumber; 
            taskListPage.clear();
            for(Integer i=firstTsk-pageSize; i < firstTsk; i++){
                taskListPage.add(taskList.get(i));
            }
        }
      
        if(taskListPage.get(0).recNumber == 0)
            renderPrev = false;
        renderNext = true;
        system.debug('----taskListPage prev before-' + taskListPage);
        return ref;
    }
    
    public PageReference Next(){
        PageReference ref;
        Integer lastTsk;
        system.debug('----taskListPage next before-' + taskListPage);
        if(taskList != null && !taskList.isEmpty() && taskListPage != null && !taskListPage.isEmpty()){
            lastTsk = taskListPage.get(taskListPage.size()-1).recNumber; 
            taskListPage.clear();
            for(Integer i=lastTsk+1; i < taskList.size(); i++){
                if(taskListPage.size() < pageSize)
                    taskListPage.add(taskList.get(i));
                else
                    break;
            }
        }
        if(taskListPage.get(taskListPage.size()-1).recNumber >= taskList.size()-1)
            renderNext = false;
        renderPrev = true;
        system.debug('----taskListPage next after-' + taskListPage);
        return ref;
    }
     public void sortTable(){
         
        if(SortOrder == 'ASC')
            SortOrder = 'DESC';
        else
            SortOrder = 'ASC';
        Map<String, List<WrTask>> sortMap = new Map<String, List<WrTask>>();
        if(taskList != null && !taskList.isEmpty()){
            for(WrTask tsk :taskList){
                if(sortMap.containsKey(tsk.fieldValue(sortBy)))
                   sortMap.get(tsk.fieldValue(sortBy)).add(tsk);
                else
                   sortMap.put(tsk.fieldValue(sortBy), new List<WrTask>{tsk});
            }
            taskList.clear();
            List<String> sortList = new List<String>(sortMap.keySet());
            sortList.sort();   
            if(sortOrder == 'ASC'){
                for(Integer i=0; i<sortList.size(); i++)
                    taskList.addAll(sortMap.get(sortList[i]));
            } else {
                for(Integer j = sortList.size()-1; j >=0 ; j--)
                    taskList.addAll(sortMap.get(sortList[j]));
            }
            for(Integer k=0; k<taskList.size(); k++)
                taskList[k].recNumber = k;
            taskListPage.clear();
            for(Integer i=0; i<taskList.size(); i++){
                if(taskListPage.size() < pageSize)
                    taskListPage.add(taskList[i]);
                else
                    break;
            }
            if(taskListPage.get(0).recNumber == 0)
                renderPrev = false;
            if(taskList == null || (taskList != null && taskList.size() <= pageSize))
                renderNext = false;
            else
                renderNext = true;
        }

    }
    
   
    
    //private void getPriorities(){
    //    //code from silver tree
    //    // instantiate WR_BPM.API *
    //    WR_BPM.API API = new WR_BPM.API();
    //    //* this section queries for priorities */
    //    Map<String, Object> parameters = new Map<String, Object> {'cursors' => allTaskMapWR, 'filter' => 'WR_BPM__Type__c = \'Priority\' AND Name = \'Priority\''};
    //    Map<Id, List<WR_BPM__Flow_Step_Property__c>> propertiesMap = (Map<Id, List<WR_BPM__Flow_Step_Property__c>>)API.call('FlowStepPropertiesService', 'getFlowPropertiesByCursors', parameters);
    //    //* end of section */
    //
    //
    //}
    
    private void getUrl(){
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        currFullUrl = URL.getCurrentRequestUrl().toExternalForm();
        currUrl = ApexPages.currentPage().getURL();  
    }
    
    private void getAllCpTasks(){
        cpIdSet = new Set<Id>();
        crIdSet = new Set<Id>();
        
        Map<Id, Work_Relay_Task__c> workRelayTaskMap = getCpTasks(cpController);
        
        if(workRelayTaskMap != null && !workRelayTaskMap.isEmpty()){
               getUserGroupMap(workRelayTaskMap);
               allTaskMap = new Map<Id, WrTask>();
               taskListPage = new List<WrTask>();
               taskList = new List<WrTask>();
               for(Work_Relay_Task__c wrt :workRelayTaskMap.values()){
                   if(wrt.Flow_Instance_Cursor__c != null && includeTask(getFirstUser(wrt.Flow_Instance_Cursor__r.WR_BPM__Step_Assigned_To__c))){
                        WrTask tsk = getTask(wrt.Flow_Instance_Cursor__c, 
                                            wrt.Flow_Instance_Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, 
                                            wrt.Flow_Instance_Cursor__r.WR_BPM__Step__r.Name,  
                                            wrt.Flow_Instance_Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Name__c, 
                                            wrt.Flow_Instance_Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name,
                                            wrt.Flow_Instance_Cursor__r.CreatedBy.Name, 
                                            wrt.Flow_Instance_Cursor__r.WR_BPM__Step_Due_Date__c, 
                                            wrt.Flow_Instance_Cursor__r.WR_BPM__Step_Changed_Date__c, 
                                            wrt.Flow_Instance_Cursor__r.WR_BPM__Step_Assigned_To__c,
                                            wrt.Flow_Instance_Cursor__r.CreatedDate, 
                                            wrt.Flow_Instance_Cursor__r.LastModifiedDate, 
                                            wrt.Flow_Instance_Cursor__r.WR_BPM__Step__r.WR_BPM__Layout_Type__c, 
                                            wrt.Flow_Instance_Cursor__r.WR_BPM__Step__r.WR_BPM__Layout__c, 
                                            wrt.Flow_Instance_Cursor__r.WR_BPM__Step_Type__c, TASK_TYPE, 
                                            wrt.Flow_Instance_Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c, null, 
                                            campaignProfile.Id, 
                                            wrt.Flow_Instance_Cursor__r.WR_BPM__Step__c, wrt.CreatedById,
                                            wrt.Id, true, false, wrt.Flow_Instance_Cursor__r.WR_BPM__Status__c);
                   } else if(wrt.Flow_Instance_Issue__c != null){
                        WrTask is = getTask(wrt.Flow_Instance_Issue__c, 
                                        wrt.Flow_Instance_Issue__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, 
                                        (wrt.Flow_Instance_Issue__r.WR_BPM__Step__r.Name != null ? wrt.Flow_Instance_Issue__r.WR_BPM__Step__r.Name : wrt.Flow_Instance_Issue__r.Name),  
                                        wrt.Flow_Instance_Issue__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Name__c, 
                                        wrt.Flow_Instance_Issue__r.WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name, 
                                        wrt.Flow_Instance_Issue__r.CreatedBy.Name, 
                                        wrt.Flow_Instance_Issue__r.WR_BPM__Due_Date__c, 
                                        wrt.Flow_Instance_Issue__r.LastModifiedDate, 
                                        wrt.Flow_Instance_Issue__r.WR_BPM__Assign_To__c,
                                        wrt.Flow_Instance_Issue__r.CreatedDate,
                                        wrt.Flow_Instance_Issue__r.LastModifiedDate, 
                                        wrt.Flow_Instance_Issue__r.WR_BPM__Layout_Type__c, 
                                        wrt.Flow_Instance_Issue__r.WR_BPM__Layout__c,
                                        wrt.Flow_Instance_Issue__r.Issue_Type__c, ISSUE_TYPE, 
                                        wrt.Flow_Instance_Issue__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c, null, 
                                        campaignProfile.Id, 
                                        wrt.Flow_Instance_Issue__r.WR_BPM__Step__c, wrt.CreatedById,
                                        wrt.Id, true, false, wrt.Flow_Instance_Issue__r.WR_BPM__Status__c);
                   } else if(wrt.Flow_Instance_Cursor__c == null && wrt.Flow_Instance_Issue__c == null){
                       WrTask wrTs = getTask(null, 
                                        campaignProfile.Id, 
                                        wrt.Task_Name__c,  
                                        null, 
                                        wrt.Process_Name__c, 
                                        wrt.CreatedById, 
                                        null, 
                                        null, 
                                        wrt.Task_Assigned_To__c,
                                        wrt.CreatedDate,
                                        null, 
                                        null, 
                                        null,
                                        null, null, 
                                        null, null, 
                                        campaignProfile.Id, 
                                        null, wrt.CreatedById,
                                        wrt.Id, true, false, 'Deleted');
                   }
               }
        }
    }
    
    private Map<Id, Work_Relay_Task__c> getCpTasks(Boolean cpController){
       if(cpController == true){
           return new Map<Id, Work_Relay_Task__c>([Select Id,  CreatedById, Process_Name__c, Task_Assigned_To__c, Task_Name__c, CreatedDate,
                                                                                            Flow_Instance_Cursor__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step__r.Name,  
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Name__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name,
                                                                                            Flow_Instance_Cursor__r.CreatedBy.Name,
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step_Due_Date__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step_Changed_Date__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step_Assigned_To__c,
                                                                                            Flow_Instance_Cursor__r.CreatedDate, 
                                                                                            Flow_Instance_Cursor__r.LastModifiedDate, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step__r.WR_BPM__Layout_Type__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step__r.WR_BPM__Layout__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step_Type__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c,  
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Status__c,
                                                                                            Flow_Instance_Issue__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Step__r.Name, Flow_Instance_Issue__r.Name,  
                                                                                            Flow_Instance_Issue__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Name__c, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name, 
                                                                                            Flow_Instance_Issue__r.CreatedBy.Name, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Due_Date__c, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Assign_To__c,
                                                                                            Flow_Instance_Issue__r.CreatedDate,
                                                                                            Flow_Instance_Issue__r.LastModifiedDate, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Layout_Type__c, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Layout__c,
                                                                                            Flow_Instance_Issue__r.Issue_Type__c, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c,
                                                                                            Flow_Instance_Issue__r.WR_BPM__Step__c, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Status__c,
                                                                                            Flow_Instance_Issue__c
                                                            from Work_Relay_Task__c
                                                             where(
                                                                    (Flow_Instance_Cursor__c = null and Flow_Instance_Issue__c = null and Campaign_Profile__c = :campaignProfile.Id) or
                                                                    (Flow_Instance_Cursor__c <> null and Flow_Instance_Cursor__r.WR_BPM__Flow_Instance__r.Campaign_Profile__c = :campaignProfile.Id and Flow_Instance_Cursor__r.WR_BPM__Step_Assigned_To__c <> 'System') 
                                                                    or (Flow_Instance_Issue__c <> null and 
                                                                            (Flow_Instance_Issue__r.CampaignProfile__c = :campaignProfile.Id or  Flow_Instance_Issue__r.WR_BPM__Flow_Instance__r.Campaign_Profile__c = :campaignProfile.Id)
                                                                            ))
                                                                        
                                                                        ]); 
       } else {
            return new Map<Id, Work_Relay_Task__c>([Select Id,  CreatedById, Process_Name__c, Task_Assigned_To__c, Task_Name__c, CreatedDate,
                                                                                            Flow_Instance_Cursor__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step__r.Name,  
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Name__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name,
                                                                                            Flow_Instance_Cursor__r.CreatedBy.Name,
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step_Due_Date__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step_Changed_Date__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step_Assigned_To__c,
                                                                                            Flow_Instance_Cursor__r.CreatedDate, 
                                                                                            Flow_Instance_Cursor__r.LastModifiedDate, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step__r.WR_BPM__Layout_Type__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step__r.WR_BPM__Layout__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step_Type__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c,  
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Step__c, 
                                                                                            Flow_Instance_Cursor__r.WR_BPM__Status__c,
                                                                                            Flow_Instance_Issue__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Step__r.Name, Flow_Instance_Issue__r.Name,  
                                                                                            Flow_Instance_Issue__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Name__c, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name, 
                                                                                            Flow_Instance_Issue__r.CreatedBy.Name, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Due_Date__c, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Assign_To__c,
                                                                                            Flow_Instance_Issue__r.CreatedDate,
                                                                                            Flow_Instance_Issue__r.LastModifiedDate, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Layout_Type__c, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Layout__c,
                                                                                            Flow_Instance_Issue__r.Issue_Type__c, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c,
                                                                                            Flow_Instance_Issue__r.WR_BPM__Step__c, 
                                                                                            Flow_Instance_Issue__r.WR_BPM__Status__c,
                                                                                            Flow_Instance_Issue__c
                                                            from Work_Relay_Task__c
                                                             where((Flow_Instance_Cursor__c <> null and Flow_Instance_Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c = :changeRequest.Id and Flow_Instance_Cursor__r.WR_BPM__Step_Assigned_To__c <> 'System') 
                                                                    or (Flow_Instance_Issue__c <> null and Flow_Instance_Issue__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c = :changeRequest.Id))
                                                                        ]); 
       }
    }
    private void getUserGroupMap(Map<Id, Work_Relay_Task__c> wrTaskMap){
        Set<Id> idSet = new Set<Id>();
        for(Work_Relay_Task__c ts :wrTaskMap.values()){
            if(ts.Flow_Instance_Cursor__c != null && ts.Flow_Instance_Cursor__r.WR_BPM__Step_Assigned_To__c != null)
                idSet.add(getFirstUser(ts.Flow_Instance_Cursor__r.WR_BPM__Step_Assigned_To__c));
            else if(ts.Flow_Instance_Issue__c != null && ts.Flow_Instance_Issue__r.WR_BPM__Assign_To__c != null)
                idSet.add(ts.Flow_Instance_Issue__r.WR_BPM__Assign_To__c);
            else if(ts.Task_Assigned_To__c != null && !ts.Task_Assigned_To__c.contains(','))
                idSet.add(ts.Task_Assigned_To__c);
        }
        if(idSet != null && !idSet.isEmpty()){
            userMap = new Map<Id, User>([Select Id, Name
                                        from User
                                        where Id IN :idSet
                                        order by LastName]);
             groupMap = new Map<Id, Group>([Select Id, Name, DeveloperName 
                                            from Group 
                                            where Type = 'Queue' and Id IN :idSet]);
        }
        
    }
    
    private void getAllTasks(){
        
        dtTaskMap = new Map<String, List<WrTask>>();
        
        cpIdSet = new Set<Id>();
        crIdSet = new Set<Id>();
        Map<Id, Campaign_Profile__c> cpMap;
        Map<Id, Change_Request__c> crMap;
        List<WR_BPM__Flow_Step_Property__c> propertyList;
        if(allTaskMapWR == null)
            allTaskMapWR = new Map<Id, WR_BPM__Flow_Instance_Cursor__c>([select Id,  WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c,  WR_BPM__Step__r.Name, 
                        WR_BPM__Flow_Instance__r.WR_BPM__Object_Name__c, WR_BPM__Step_Type__c, WR_BPM__Step__c,
                        WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name, 
                        WR_BPM__Step_Due_Date__c, WR_BPM__Step_Changed_Date__c, WR_BPM__Step_Assigned_To__c, WR_BPM__Status__c,
                        WR_BPM__Step__r.WR_BPM__Layout_Type__c, WR_BPM__Step__r.WR_BPM__Layout__c, WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c,
                        CreatedById, CreatedBy.Name, CreatedDate, LastModifiedDate, (Select Id from Work_Relay_Tasks__r)
                        from WR_BPM__Flow_Instance_Cursor__c
                        where (Id IN :activeTaskSet or WR_BPM__Step_Assigned_To__c IN :userMap.keySet() or WR_BPM__Step_Assigned_To__c IN :groupMap.keySet() or 
                               (WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c IN :objectIdSet and WR_BPM__Step_Assigned_To__c <> 'System' and WR_BPM__Step_Assign_Type__c <> 'System')) and 
                              WR_BPM__Is_Completed__c = :NO and WR_BPM__Flow_Instance__r.WR_BPM__Is_Active__c = true and WR_BPM__Status__c <> :PENDING
                        order by WR_BPM__Step_Due_Date__c nulls last, WR_BPM__Step__r.Name]);
       if(allTaskMapWR != null){
           propertyList = new List<WR_BPM__Flow_Step_Property__c>([Select Id, WR_BPM__Cursor__c, Name, WR_BPM__Type__c, WR_BPM__Value__c
                                                                    from WR_BPM__Flow_Step_Property__c
                                                                    where WR_BPM__Cursor__c IN :allTaskMapWR.keySet() and Name = 'Priority' and WR_BPM__Type__c = 'Priority']);
       }
           
       if(allIssueMapWR == null)
            allIssueMapWR = new  Map<Id, WR_BPM__Flow_Instance_Issue__c>([select id, WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, WR_BPM__Step__r.Name,
                        WR_BPM__Flow_Instance__r.WR_BPM__Object_Name__c, Issue_Type__c, CampaignProfile__c, WR_BPM__Step__c,
                        WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name, 
                        WR_BPM__Due_Date__c, WR_BPM__Due_Date_Value__c,  WR_BPM__Assign_To__c, WR_BPM__Layout__c, WR_BPM__Layout_Type__c, 
                        WR_BPM__Type__c,  Name, WR_BPM__Priority__c, WR_BPM__Status__c, WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c,
                        CreatedById, CreatedBy.Name, CreatedDate, LastModifiedDate, (Select Id from Work_Relay_Tasks__r)
                           from WR_BPM__Flow_Instance_Issue__c 
                           where (WR_BPM__Assign_To__c IN :userMap.keySet() or WR_BPM__Assign_To__c IN :groupMap.keySet() or
                                 CreatedById = :userId) and 
                                 WR_BPM__Status__c <> :COMPLETED and WR_BPM__Status__c <> :REJECTED and WR_BPM__Flow_Instance__r.WR_BPM__Is_Active__c = true
                           order by WR_BPM__Due_Date__c]);
       if((allTaskMapWR != null && !allTaskMapWR.isEmpty()) || (allIssueMapWR != null && !allIssueMapWR.isEmpty())){
           allTaskMap = new Map<Id, WrTask>();
           taskListPage = new List<WrTask>();
           taskList = new List<WrTask>();
           getSubUserGroupMap(allTaskMapWR, allIssueMapWR);       
           //get tasks
           if(allTaskMapWR != null && !allTaskMapWR.isEmpty()){
               for(WR_BPM__Flow_Instance_Cursor__c ts :allTaskMapWR.values()){
                   //system.debug('----ts-' + ts);
                   //excluded pending tasks for current user and excluded anythign assigned to group
                   if((ts.WR_BPM__Step_Assigned_To__c != null && getFirstUser(ts.WR_BPM__Step_Assigned_To__c) != userId &&  includeTask(getFirstUser(ts.WR_BPM__Step_Assigned_To__c))) || 
                       (getFirstUser(ts.WR_BPM__Step_Assigned_To__c) == userId && activeTaskSet != null && activeTaskSet.contains(ts.Id)))
                      WrTask tsk = getTask(ts.Id,ts.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, ts.WR_BPM__Step__r.Name, 
                                        ts.WR_BPM__Flow_Instance__r.WR_BPM__Object_Name__c, ts.WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name,
                                        ts.CreatedBy.Name, ts.WR_BPM__Step_Due_Date__c, ts.WR_BPM__Step_Changed_Date__c, ts.WR_BPM__Step_Assigned_To__c,
                                        ts.CreatedDate, ts.LastModifiedDate, ts.WR_BPM__Step__r.WR_BPM__Layout_Type__c, ts.WR_BPM__Step__r.WR_BPM__Layout__c,
                                        ts.WR_BPM__Step_Type__c, TASK_TYPE, ts.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c, getPriority(ts.Id, propertyList), null, ts.WR_BPM__Step__c, 
                                        ts.CreatedById, getChatterId(ts.Id, ts.Work_Relay_Tasks__r), false, false, ts.WR_BPM__Status__c);
                   
               }
           }
           //get issues
           if(allIssueMapWR != null && !allIssueMapWR.isEmpty()){
                for(WR_BPM__Flow_Instance_Issue__c iss :allIssueMapWR.values()){
                    WrTask is = getTask(iss.Id, iss.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, (iss.WR_BPM__Step__r.Name != null ? iss.WR_BPM__Step__r.Name : iss.Name),  
                                        iss.WR_BPM__Flow_Instance__r.WR_BPM__Object_Name__c, iss.WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name,
                                        iss.CreatedBy.Name, iss.WR_BPM__Due_Date__c, iss.LastModifiedDate, iss.WR_BPM__Assign_To__c,
                                        iss.CreatedDate, iss.LastModifiedDate, iss.WR_BPM__Layout_Type__c, iss.WR_BPM__Layout__c,
                                        iss.Issue_Type__c, ISSUE_TYPE, iss.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c, iss.WR_BPM__Priority__c, iss.CampaignProfile__c, iss.WR_BPM__Step__c, 
                                        iss.CreatedById, getChatterId(iss.Id, iss.Work_Relay_Tasks__r), false, false, iss.WR_BPM__Status__c);
                }
           }
       }
       
         
      
       if(!crIdSet.isEmpty()){
          crMap = new Map<Id, Change_Request__c>([Select Id, Campaign_Profile__c, Campaign_Profile__r.Campaign_Profile_Name__c, 
                                                    Campaign_Profile__r.Expedite__c, Campaign_Profile__r.Client_Name__c, Campaign_Profile__r.Client_Name__r.Name,
                                                    Campaign_Profile__r.Estimated_Launch_Date__c, Campaign_Profile__r.Requested_Launch_Date__c
                                                    from Change_Request__c 
                                                    where Id IN :crIdSet]);
          if(crMap != null && !crMap.isEmpty()){
              for(Change_Request__c cr :crMap.values())
                cpIdSet.add(cr.Campaign_Profile__c);
          }
       }     
       if(!cpIdSet.isEmpty())
          cpMap = new Map<Id, Campaign_Profile__c>([Select Id, Campaign_Profile_Name__c, Expedite__c, Client_Name__c, Client_Name__r.Name, Estimated_Launch_Date__c, Requested_Launch_Date__c,
                                                    (Select Id, User__c, User__r.Name from Campaign_Swimlanes_Assignments__r where Role__c = :AMRole)
                                                    from Campaign_Profile__c
                                                    where Id IN :cpIdSet]);
       if(allTaskMap != null && !allTaskMap.isEmpty()){
           for(WrTask ts :allTaskMap.values()){
			   if(crMap != null && !crMap.isEmpty() && crMap.containsKey(ts.objId))
                    ts.cpId = crMap.get(ts.objId).Campaign_Profile__c;	
               if(cpMap != null && !cpMap.isEmpty() && cpMap.containsKey(ts.cpId)){
                   Campaign_Profile__c cp = cpMap.get(ts.cpId);
                   ts.cpId = cp.Id;
                   ts.companyName = cpMap.get(ts.cpId).Client_Name__r.Name;
                   if(cp.Requested_Launch_Date__c != null){
                       ts.prEndDate = String.valueOf(cp.Requested_Launch_Date__c);
                       ts.prEndDateDs = cp.Requested_Launch_Date__c.format();
                   }
                   ts.companyId = cp.Client_Name__c;
                   ts.cpName = cp.Campaign_Profile_Name__c;
                   if (ts.cpName != null && ts.cpName.length() > 25)
                        ts.abbrCpName = ts.cpName.abbreviate(25);
                   else
                        ts.abbrCpName = ts.cpName;
                   if (ts.companyName != null && ts.companyName.length() > 25)
                        ts.abbrCompanyName = ts.companyName.abbreviate(25);
                   else
                        ts.abbrCompanyName = ts.companyName;
                   ts.proceedUrl = WorkRelayUtil.getProceedUrl(ts.type, ts.taskId, ts.stepId);
                   if(cp.Expedite__c == true)
                      ts.isExpedited = true;
                   else
                      ts.isExpedited = false;
                   Date dt = calculateDueDate(ts, cp);
                   if(dt != null){
                       ts.dueDate = String.valueOf(dt);
                       ts.dueDateDs = dt.format();
                   }
                   if(cp.Campaign_Swimlanes_Assignments__r != null && !cp.Campaign_Swimlanes_Assignments__r.isEmpty()){
                        ts.reqById = cp.Campaign_Swimlanes_Assignments__r[0].User__c;
                        ts.reqBy = cp.Campaign_Swimlanes_Assignments__r[0].User__r.Name;
                   }          
               }      
               if(ts.dueDate != null){
                    if(dtTaskMap.containsKey(ts.dueDate))
                        dtTaskMap.get(ts.dueDate).add(ts);
                    else
                        dtTaskMap.put(ts.dueDate, new List<WrTask>{ts});
               }
           }
       }
       procDateMap(dtTaskMap);
     }
    
     private void getSubUserGroupMap(Map<Id, WR_BPM__Flow_Instance_Cursor__c> taskMap, Map<Id, WR_BPM__Flow_Instance_Issue__c> issueMap){
        
        Set<Id> idSet = new Set<Id>();
        Set<Id> idSetDont = new Set<Id>();
        
        if(userMap != null && !userMap.isEmpty())
            idSetDont.addAll(userMap.keySet());
        if(groupMap != null && !groupMap.isEmpty())
            idSetDont.addAll(groupMap.keySet());
            
        if(taskMap != null && !taskMap.isEmpty()){
            for(WR_BPM__Flow_Instance_Cursor__c cur :taskMap.values()){
                if(cur.WR_BPM__Step_Assigned_To__c != null && !idSetDont.contains(getFirstUser(cur.WR_BPM__Step_Assigned_To__c)))
                    idSet.add(getFirstUser(cur.WR_BPM__Step_Assigned_To__c));
            }
        }  
        if(issueMap != null && !issueMap.isEmpty()){
            for(WR_BPM__Flow_Instance_Issue__c iss :issueMap.values()){
                 if(iss.WR_BPM__Assign_To__c != null && !idSetDont.contains(iss.WR_BPM__Assign_To__c))
                    idSet.add(iss.WR_BPM__Assign_To__c);
            }
        }
        
        if(idSet != null && !idSet.isEmpty()){
            userMapSubView = new Map<Id, User>([Select Id, Name
                                        from User
                                        where Id IN :idSet
                                        order by LastName]);
             groupMapSubView = new Map<Id, Group>([Select Id, Name, DeveloperName 
                                            from Group 
                                            where Type = 'Queue' and Id IN :idSet]);
        }
    }
    
     private Boolean includeTask(Id assignedId){
        Boolean include = true;
        if (groupMap != null && groupMap.containsKey(assignedId) && 
            groupMap.get(assignedId).DeveloperName == LAUNCH_SUB_PROCESS_QUEUE)
             include = false;
        else if(groupMapSubView != null && groupMapSubView.containsKey(assignedId) &&
            groupMapSubView.get(assignedId).DeveloperName == LAUNCH_SUB_PROCESS_QUEUE)
            include = false;
        return include;
     }
     
     private WrTask getTask(String tskId, String objectId, String stepName, String objectName, String processName,
                            String createdByName, Datetime dueDate, Datetime changedDate, String stepAssignedTo, Datetime createdDate,
                            Datetime lastModifiedDate, String layoutType, String layout, String stepType, String type, String objectType,
                            String priority, String campaignProfile, Id stepId, Id reqById, Id chatterId, Boolean cpPage, Boolean deleted, String taskStatus){
         WrTask tsk = new WrTask();
         tsk.type = type;
         tsk.taskStatus = taskStatus;
         if(stepAssignedTo != null)
            stepAssignedTo = getFirstUser(stepAssignedTo);
         if(stepAssignedTo == userId || cpPage == true){
            if(recNumber == null)
                recNumber = 0;
            else 
                recNumber = recNumber + 1;
            tsk.recNumber = recNumber;
         } else
            tsk.recNumber = 0; 
        tsk.taskId = tskId;
		tsk.chatterId = chatterId;
        tsk.selRecord = false;
        tsk.stepId = stepId;
        try {
           tsk.cpId = objectId;
           tsk.objId = objectId;
           cpIdSet.add(objectId);
        } catch (Exception e) {}
        if(tsk.type == ISSUE_TYPE && campaignProfile != null){
            tsk.cpId = campaignProfile;
            cpIdSet.add(campaignProfile);
        }
        if(objectType == 'change_request__c'){
            try{
                crIdSet.add(objectId);
            } catch (Exception e) {}   
        }
        if(stepName != null)
            tsk.taskName = stepName;
        else
            tsk.taskName = '';
        if(stepName != null && stepName.length() > 25)
            tsk.taskNameAbbr = stepName.abbreviate(25);
        else        
            tsk.taskNameAbbr = stepName;
        if(!String.isBlank(tsk.taskName))
            tsk.taskNameParm =  EncodingUtil.urlEncode(tsk.taskName, 'UTF-8'); 
        tsk.processName = processName;
        tsk.reqBy = createdByName;
        tsk.reqById = reqById;
        tsk.origDueDate = dueDate;
        try {
          tsk.dueDate = String.valueOf(Date.valueOf(dueDate)); 
          tsk.dueDateDs = Date.valueOf(dueDate).format(); 
        } catch (Exception e){
          tsk.dueDate = String.valueOf(dueDate); 
          tsk.dueDateDs = String.valueOf(dueDate); 
        }
        tsk.subCrtDate = String.valueOf(Date.valueOf(createdDate)); 
        tsk.subCrtDateDs = Date.valueOf(createdDate).format(); 
        tsk.layoutType = layoutType;
        if(layoutType =='Form')
           tsk.formId = layout;
        if(Test.isRunningTest() == true && tsk.dueDate == null)
            tsk.dueDate = String.valueOf(Date.valueOf(changedDate)); 
        tsk.assignedTo = stepAssignedTo;
        if(userMap != null && userMap.containsKey(tsk.assignedTo))
           tsk.assignedToName = userMap.get(tsk.assignedTo).Name;
        else if(userMapSubView != null && userMapSubView.containsKey(tsk.assignedTo))
             tsk.assignedToName = userMapSubView.get(tsk.assignedTo).Name;
        else if(groupMap != null && groupMap.containsKey(tsk.assignedTo))
           tsk.assignedToName = groupMap.get(tsk.assignedTo).Name;
        else if(groupMapSubView != null && groupMapSubView.containsKey(tsk.assignedTo))
           tsk.assignedToName = groupMapSubView.get(tsk.assignedTo).Name;
        tsk.subCrtDate =  String.valueOf(Date.valueOf(createdDate));
        tsk.lastUpdtDate =  String.valueOf(Date.valueOf(lastModifiedDate));
        if(tsk.processName != null && tsk.processName.containsIgnoreCase(BUILD)){
           tsk.isBuild = true;
           tsk.isMaint = false;
        } else {
           tsk.isBuild = false;
           tsk.isMaint = true;
        }
        tsk.isApprQA = false;
        if(stepType != null && stepName != null && (stepType == APPROVAL || stepName.contains(QA)))
           tsk.isApprQA = true;
        //default to normal
        tsk.priority = '2';
        tsk.priorityText = NORMAL;
        if(priority != null){
            tsk.priorityText = priority;
            if(priority == LOW)
                tsk.priority = '1';
            else if(priority == NORMAL)
                    tsk.priority = '2';
            else if (priority == HIGH || priority == URGENT)
                    tsk.priority = '3'; 
            else if (priority == CRITICAL)
                    tsk.priority = '4';
        }
        if(cpPage == true && tsk.taskId != null)
            tsk.proceedUrl = WorkRelayUtil.getProceedUrl(tsk.type, tsk.taskId, tsk.stepId);
        allTaskMap.put(tsk.taskId, tsk);
       //initially only my tasks - if from campaign profile - doesn't matter who its assigned to
        if(tsk.assignedTo == userId || cpPage == true){
          taskList.add(tsk);
          if(taskListPage.size() < pageSize)
             taskListPage.add(tsk);
        }
        
        return tsk;
     }
    
     private Id getChatterId(Id taskId, List<Work_Relay_Task__c> taskList){
        Id rtnId = taskId; // will remove later.
        if(taskList != null && !taskList.isEmpty())
            rtnId = taskList[0].Id;
        return rtnId;
     }
     private String getPriority(Id taskId, List<WR_BPM__Flow_Step_Property__c> propList){
         //default to normal
         String priority = NORMAL;
         if(propList != null && !propList.isEmpty()){
             for(Integer i=0; i<propList.size(); i++){
                 if(propList[i].WR_BPM__Cursor__c == taskId){
                     priority = propList[i].WR_BPM__Value__c;
                 }
             }
         }
         return priority;
     }
     
     private void procDateMap(Map<String, List<WrTask>> dtTaskMap){
         if(dtTaskMap != null && !dtTaskMap.isEmpty()){
            List<String> sortList = new List<String>(dtTaskMap.keySet());
            sortList.sort();
            for(String str :sortList)
                dateTaskMap.put(str, dtTaskMap.get(str));
            
         }
     }
    
      public Date calculateDueDate(WrTask wrTask, Campaign_Profile__c cp){
         
         Date rtnDt;
         //only for task type
         if(wrTask.type == TASK_TYPE && wrTask.origDueDate != null && cp.Estimated_Launch_Date__c != null && cp.Requested_Launch_Date__c != null &&
                cp.Estimated_Launch_Date__c !=  cp.Requested_Launch_Date__c){
             //rtnDate = String.valueOf(Date.valueOf(wrTask.origDueDate).addDays(cp.Estimated_Launch_Date__c.daysBetween(cp.Requested_Launch_Date__c))); - not business hours
             Datetime estDatetime = Datetime.newInstance(cp.Estimated_Launch_Date__c.Year(), cp.Estimated_Launch_Date__c.Month(), cp.Estimated_Launch_Date__c.Day(), 9,0,0);
             Datetime reqDatetime = Datetime.newInstance(cp.Requested_Launch_Date__c.Year(), cp.Requested_Launch_Date__c.Month(), cp.Requested_Launch_Date__c.Day(), 9,0,0);
             Datetime origDatetime = Datetime.newInstance(wrTask.origDueDate.Year(), wrTask.origDueDate.Month(), wrTask.origDueDate.Day(), 9,0,0); //need to add time to date, otherwise math for one day does not work
             Double daysDiff = ((BusinessHours.diff(bh.Id, estDatetime, reqDatetime)/MILLISECONDS_IN_HOURS)/mondayBusinessHours()).setScale(0);
             Double millisecondsToAdd = daysDiff *mondayBusinessHours() * MILLISECONDS_IN_HOURS;
             try{ 
                 rtnDt = Date.valueOf(BusinessHours.add(bh.Id, origDatetime, millisecondsToAdd.longValue()));
             } catch (Exception e) {}
         }
        
         return rtnDt;
     }
     
      // Get Monday Buisness Hours
    public static decimal mondayBusinessHours(){
        Date Monday = Date.newInstance (2014,6,2);
        //Get the Monday Start time and  End time - This will be in the user's time zome
        DateTime MondayBOD = Datetime.newInstance(Monday, bh.MondayStartTime); //Datetime.newInstance(Monday, bh.MondayStartTime);
        DateTime MondayEOD =  Datetime.newInstance(Monday, bh.MondayEndTime); //Datetime.newInstance(Monday, bh.MondayEndTime);
        
        decimal BusHoursDay = Math.Floor((Decimal.valueOf(MondayEOD.getTime()) -  Decimal.valueOf(MondayBOD.getTime()) ) / (MILLISECONDS_IN_HOURS));
        return BusHoursDay;
    }
    
   
   
}