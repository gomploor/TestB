/*
    After Update Trigger Handler WR Flow Instance History
*/
public without sharing class FIHAfterUpdateTriggerHandler extends TriggerHandlerBase{
    
    public override void mainEntry(TriggerParameters tp){  
        this.postToChatter((List<WR_BPM__Flow_Instance_History__c>)tp.newList, (Map<Id, WR_BPM__Flow_Instance_History__c>)tp.oldMap);
    }
 
    public void postToChatter(List<WR_BPM__Flow_Instance_History__c> historyList, Map<Id, WR_BPM__Flow_Instance_History__c> oldHistoryMap){
        
        List<WR_BPM__Flow_Instance_History__c> updatedHist = new List<WR_BPM__Flow_Instance_History__c>();
        List<WR_BPM__Flow_Instance_History__c> oldUpdatedHist = new List<WR_BPM__Flow_Instance_History__c>();
        for(WR_BPM__Flow_Instance_History__c hist :historyList){
            if(hist.WR_BPM__Completed_Date__c != null && hist.WR_BPM__Completed_Date__c != oldHistoryMap.get(hist.Id).WR_BPM__Completed_Date__c){ updatedHist.add(hist); oldUpdatedHist.add(oldHistoryMap.get(hist.Id)); }
        }
        if(!updatedHist.isEmpty() && Test.isRunningTest() != true)
            System.enqueueJob(new ChatterIssues(updatedHist, oldUpdatedHist));
    }
}