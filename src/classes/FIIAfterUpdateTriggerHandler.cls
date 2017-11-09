/*
    After Update Trigger Handler WR Flow Instance Issue
*/
public without sharing class FIIAfterUpdateTriggerHandler extends TriggerHandlerBase{
    
    public override void mainEntry(TriggerParameters tp){  
        this.postToChatter((List<WR_BPM__Flow_Instance_Issue__c>)tp.newList, (Map<Id, WR_BPM__Flow_Instance_Issue__c>)tp.oldMap);
    }
 
    public override void inProgressEntry(TriggerParameters tp){
            
    }
    
    public void postToChatter(List<WR_BPM__Flow_Instance_Issue__c> issueList, Map<Id, WR_BPM__Flow_Instance_Issue__c> oldIssueMap){
        
        List<WR_BPM__Flow_Instance_Issue__c> updatedIssues = new List<WR_BPM__Flow_Instance_Issue__c>();
        List<WR_BPM__Flow_Instance_Issue__c> oldUpdatedIssues = new List<WR_BPM__Flow_Instance_Issue__c>();
        for(WR_BPM__Flow_Instance_Issue__c iss :issueList){
            if(iss.WR_BPM__Status__c != oldIssueMap.get(iss.Id).WR_BPM__Status__c || iss.WR_BPM__Assign_To__c != oldIssueMap.get(iss.Id).WR_BPM__Assign_To__c){
                updatedIssues.add(iss);
                oldUpdatedIssues.add(oldIssueMap.get(iss.Id));
            }
        }
        if(!updatedIssues.isEmpty() && Test.isRunningTest() != true)
            System.enqueueJob(new ChatterIssues(updatedIssues, oldUpdatedIssues));
    }
}