trigger FlowInstanceHistoryTrigger on WR_BPM__Flow_Instance_History__c (after insert,  after update, after delete, after undelete,
                             before insert, before update, before delete) {
		 TriggerFactory.createTriggerDispatcher(WR_BPM__Flow_Instance_History__c.sObjectType);
}