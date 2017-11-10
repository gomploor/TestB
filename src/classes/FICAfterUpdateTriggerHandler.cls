/*
    After Update 
*/
public without sharing class FICAfterUpdateTriggerHandler extends TriggerHandlerBase{
	
    public static final String campaignProfileObjectType = 'campaign_profile__c';
    public static final String changeRequestObjectType = 'change_request__c';
    public static final String caseObjectType = 'case';
    public static final String SystemType = 'System';
    public static Map<Id, Campaign_Profile__c> cpMap;
    public Map<Id, WR_BPM__Flow_Instance_Cursor__c> curMap;
    
    public override void mainEntry(TriggerParameters tp){  
        
        this.getCpMap((Map<Id, WR_BPM__Flow_Instance_Cursor__c>)tp.newMap);
        if(curMap != null && !curMap.isEmpty())
     	    this.createWorkRelayTasks();
     	this.postToChatter((List<WR_BPM__Flow_Instance_Cursor__c>)tp.newList, (Map<Id, WR_BPM__Flow_Instance_Cursor__c>)tp.oldMap);
    }
 
    public override void inProgressEntry(TriggerParameters tp){
        
        this.getCpMap((Map<Id, WR_BPM__Flow_Instance_Cursor__c>)tp.newMap);
        if(curMap != null && !curMap.isEmpty())
     	    this.createWorkRelayTasks();
    }
    
    public void getCpMap(Map<Id, WR_BPM__Flow_Instance_Cursor__c> cursorMap){
        
        curMap = new Map<Id, WR_BPM__Flow_Instance_Cursor__c> ([Select Id, WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c, WR_BPM__Step_Assign_Type__c, WR_BPM__Step__r.Name,
                                                                 WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name, (Select Id from Work_Relay_Tasks__r)
                                                                from WR_BPM__Flow_Instance_Cursor__c
                                                                where Id IN :cursorMap.keySet() and ID Not In (select Flow_Instance_Cursor__c  from Work_Relay_Task__c ) and 
                                                                    WR_BPM__Step_Assign_Type__c <> :SystemType and WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c <> null]);
        
        Set<Id> cpIdSet = new Set<Id>();
        Map<Id, Id> crIdMap = new Map<Id, Id>();
        
        cpMap = new Map<Id, Campaign_Profile__c>();
        
        if(curMap != null && !curMap.isEmpty()){
            for(WR_BPM__Flow_Instance_Cursor__c cur :curMap.values()){
               
                if(cur.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c == campaignProfileObjectType)
                    cpMap.put(cur.Id, new Campaign_Profile__c(Id = (Id)cur.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c));
                else if(cur.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c == changeRequestObjectType)
                    crIdMap.put((Id)cur.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, cur.Id);
                
            }
            if(crIdMap != null && !crIdMap.isEmpty()){
             	List<Change_Request__c> crList = new List<Change_Request__c>([Select Id, Campaign_Profile__c
                                                                              from Change_Request__c
                                                                               where Id IN :crIdMap.keySet()]);  
                if(crList != null && !crList.isEmpty()){
                    for(Change_Request__c cr :crList)
                        cpMap.put(crIdMap.get(cr.Id), new Campaign_Profile__c(Id = cr.Campaign_Profile__c));
                }
            }
        }
    }
    
    public void createWorkRelayTasks(){
        
        List<Work_Relay_Task__c> wrList = new List<Work_Relay_Task__c>();
        
        for(WR_BPM__Flow_Instance_Cursor__c cur :curMap.values()){
            if(cur.Work_Relay_Tasks__r == null || cur.Work_Relay_Tasks__r.isEmpty()){
                String taskName;
                String processName;
                if(cur.WR_BPM__Step__r.Name != null)
                    taskName = cur.WR_BPM__Step__r.Name;
                if(cur.WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name != null)
                    processName = cur.WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name;
                wrList.add(new Work_Relay_Task__c(Campaign_Profile__c = (cpMap.containsKey(cur.Id) ? cpMap.get(cur.Id).Id : null), Task_Name__c = taskName, Process_Name__c = processName,
                                                                        Flow_Instance_Cursor__c = cur.Id));
            }
        }
        if(wrList != null && !wrList.isEmpty())
            Database.insert(wrList, false);
        
    }
    
    public void postToChatter(List<WR_BPM__Flow_Instance_Cursor__c> cursorList, Map<Id, WR_BPM__Flow_Instance_Cursor__c> oldCursorMap){
        
        List<WR_BPM__Flow_Instance_Cursor__c> curList = new List<WR_BPM__Flow_Instance_Cursor__c>();
        List<WR_BPM__Flow_Instance_Cursor__c> oldCurList = new List<WR_BPM__Flow_Instance_Cursor__c>();
        
        for(WR_BPM__Flow_Instance_Cursor__c cur :cursorList){
            if(cur.WR_BPM__Step_Assigned_To__c != oldCursorMap.get(cur.Id).WR_BPM__Step_Assigned_To__c){
                curList.add(cur);
                oldCurList.add(oldCursorMap.get(cur.Id));
            }
        }
        if(!curList.isEmpty() && Test.isRunningTest() != true)
             ChatterIssues ci = new ChatterIssues(curList, oldCurList);
    }
}