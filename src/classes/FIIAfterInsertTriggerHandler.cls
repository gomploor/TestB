/*
    After Insert Trigger Handler WR Flow Instance Issue
*/
public without sharing class FIIAfterInsertTriggerHandler extends TriggerHandlerBase{

    public static final String campaignProfileObjectType = 'campaign_profile__c';
    public static final String changeRequestObjectType = 'change_request__c';
    public static final String caseObjectType = 'case';
    
    public Map<Id, Campaign_Profile__c> cpMap;
    public Map<Id, WR_BPM__Flow_Instance_Issue__c> issMap;
     
    public override void mainEntry(TriggerParameters tp){  
        
        if(Test.isRunningTest() != true)
			 ChatterIssues ci = new ChatterIssues((List<WR_BPM__Flow_Instance_Issue__c>)tp.newList, null);
        this.getCpMap((Map<Id, WR_BPM__Flow_Instance_Issue__c>)tp.newMap);
        this.createWorkRelayTasks((List<WR_BPM__Flow_Instance_Issue__c>)tp.newList);
    }
 
    public override void inProgressEntry(TriggerParameters tp){
            
    }
    
    public void getCpMap(Map<Id, WR_BPM__Flow_Instance_Issue__c> issueMap){
       
        issMap = new Map<Id, WR_BPM__Flow_Instance_Issue__c>
                ([Select Id, WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c, CampaignProfile__c,
                 WR_BPM__Step__r.Name, Name, WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name
                 from WR_BPM__Flow_Instance_Issue__c
                 where Id IN :issueMap.keySet()]);
       
        Set<Id> cpIdSet = new Set<Id>();
        Map<Id, Id> crIdMap = new Map<Id, Id>();
        
        cpMap = new Map<Id, Campaign_Profile__c>();
        
         if(issMap != null && !issMap.isEmpty()){
            for(WR_BPM__Flow_Instance_Issue__c iss :issMap.values()){
                if(iss.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c == campaignProfileObjectType)
                    cpMap.put(iss.Id, new Campaign_Profile__c(Id = (Id)iss.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c));
                else if(iss.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c == changeRequestObjectType)
                    crIdMap.put((Id)iss.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, iss.Id);
                else if(iss.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c == caseObjectType && iss.CampaignProfile__c != null)
                    cpMap.put(iss.Id, new Campaign_Profile__c(Id = iss.CampaignProfile__c));
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
    
    public void createWorkRelayTasks(List<WR_BPM__Flow_Instance_Issue__c> issueList){
        
        List<Work_Relay_Task__c> wrList = new List<Work_Relay_Task__c>();
        
        for(WR_BPM__Flow_Instance_Issue__c issue :issueList){
            String taskName;
            String processName;
            if(issMap.containsKey(issue.Id) && issMap.get(issue.Id).WR_BPM__Step__r.Name != null)
                taskName = issMap.get(issue.Id).WR_BPM__Step__r.Name;
            else
                taskName = issue.Name;
            if(issMap.containsKey(issue.Id) && issMap.get(issue.Id).WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name != null)
                processName = issMap.get(issue.Id).WR_BPM__Flow_Instance__r.WR_BPM__Flow__r.WR_BPM__Process__r.Name;
             wrList.add(new Work_Relay_Task__c(Campaign_Profile__c = (cpMap.containsKey(issue.Id) ? cpMap.get(issue.Id).Id : null), Task_Name__c = taskName, Process_Name__c = processName,
                                                                  Flow_Instance_Issue__c = issue.Id));
        }
        if(wrList != null && !wrList.isEmpty())
            Database.insert(wrList, false);
   
    }
}