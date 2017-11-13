/**
 *  Class Name          : CampaignProfileAfterUpdateTriggerHandler
 *  Created By          : Paul Juneau
 *  Last Modified By    : Paul Juneau
 *  Description         : Campaign Profile trigger handler to handle afterUpdate actions
 *  Modifed History     : 01/30/2017 updating updateCursorAssigneesBasedOnFieldUpdate method to handle swimlane assignee field change
 */
public class CampaignProfileAfterUpdateTriggerHandler extends TriggerHandlerBase{ 
    
    public static User userOwner;
    
    public override void mainEntry(TriggerParameters tp) {  
        this.updateCursorAssigneesBasedOnFieldUpdate((Map<Id, Campaign_Profile__c>)tp.oldMap, (Map<Id, Campaign_Profile__c>)tp.newMap);
        this.createCampaignProfileHistory((Map<Id, Campaign_Profile__c>)tp.oldMap, (Map<Id, Campaign_Profile__c>)tp.newMap);
    }    
      
    public override void inProgressEntry(TriggerParameters tp) {
        
    }

    //Updating swimlane assignee value does not change active task assignees.  This method updates active task assignees to reflect swimlane value.
    private void updateCursorAssigneesBasedOnFieldUpdate(Map<Id, Campaign_Profile__c> oldCPmap, Map<Id, Campaign_Profile__c> newCPmap) {
      //Initialize variables to be used later
      Map<String, Map<String, String>> campaignIdsToChangedFieldsMap = new Map<String, Map<String, String>>();
      Set<String> targetFields = new Set<String>(CampaignProfileCache.getRole2CPfieldMap().values());
      Set<String> changedFields = new Set<String>();
        
      //Loop through trigger.new of Campaign Profile records
      for(Campaign_Profile__c updatedCampaignProfile : newCPmap.values()){
          //exclude history records and when Campaign_Profile_Strikes_Back__c is updated
          //Campaign_Profile_Strikes_Back__c only updates when Campaign_Profile__c created
         if(updatedCampaignProfile.RecordTypeId != CampaignProfileTriggerDispatcher.History_Record_Type_Id && 
            (updatedCampaignProfile.Campaign_Profile_Strikes_Back__c == oldCPmap.get(updatedCampaignProfile.Id).Campaign_Profile_Strikes_Back__c || Test.isRunningTest())){  
            
            Campaign_Profile__c oldCampaignProfile = oldCPmap.get(updatedCampaignProfile.Id);
            //Creating changedFieldsMap = [Campaign Profile field API name : new field value (i.e. new Campaign Role Assignee ID stored in text field)]
            Map<String, String> changedFieldsMap = new Map<String, String>();
            
            for(String field: targetFields){
              
              //If field value changed, then store new field's value and flag that field as being changed by adding it to changedFields set
              if(oldCampaignProfile.get(field) != updatedCampaignProfile.get(field)){
                changedFieldsMap.put(field, (String)updatedCampaignProfile.get(field));
                changedFields.add(field);
              }
    
            }
            
            //Flagging all the fields that changed for this Campaign Profile and what those field's new values are. 
            campaignIdsToChangedFieldsMap.put(updatedCampaignProfile.Id, changedFieldsMap);
        }

      }
        
      /*If any of the Role Assignee Text fields had any of their values change for any
       * of the Campaign Profiles in Trigger.new,
       * then update all active WorkRelay task assignees to the new Role Assignee */
      if(!changedFields.isEmpty()){
        //Get a list of active cursors that need user reassignment
        //FYI: WR_BPM__Step_Assigned_To__c holds User, Group, Queue, Role, Profile, or Chatter Group ID.
        //FYI: WR_BPM__Assign_To__c will hold the field API name in lowercase if  WR_BPM_Flow_Swimlane__r.WR_BPM__Assign_Type__c = 'Field'
        List <WR_BPM__Flow_Instance_Cursor__c> cursorsToUpdate = 
                                          [SELECT WR_BPM__Step_Assigned_To__c,
                                                  WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, 
                                                  WR_BPM__Step__r.WR_BPM__Flow_Swimlane__r.WR_BPM__Assign_To__c
                                             FROM WR_BPM__Flow_Instance_Cursor__c 
                                            WHERE WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c IN :campaignIdsToChangedFieldsMap.keySet()
                                              AND WR_BPM__Step__r.WR_BPM__Flow_Swimlane__r.WR_BPM__Assign_To__c IN :changedFields];
                                         
          for (WR_BPM__Flow_Instance_Cursor__c cursor : cursorsToUpdate) {
              //Associating appropriate changedFieldsMap of related Campaign Profile to cursorIdMap
			Map<String,String> cursorIdMap = campaignIdsToChangedFieldsMap.get(cursor.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c);
               //Assign Flow Step to new swimlane owner, only if Step has NOT already been reassigned - i.e. if the current
               //owner is the same as the old swimlane owner
			if (cursorIdMap != null && cursorIdMap.get(cursor.WR_BPM__Step__r.WR_BPM__Flow_Swimlane__r.WR_BPM__Assign_To__c) != null){
                if(oldCPmap.get(cursor.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c).get(cursor.WR_BPM__Step__r.WR_BPM__Flow_Swimlane__r.WR_BPM__Assign_To__c) == cursor.WR_BPM__Step_Assigned_To__c){
                  cursor.WR_BPM__Step_Assigned_To__c = cursorIdMap.get(cursor.WR_BPM__Step__r.WR_BPM__Flow_Swimlane__r.WR_BPM__Assign_To__c);
                }
			}
          }
                
        update cursorsToUpdate;
      }
      

    }


    private void createCampaignProfileHistory(Map<Id, Campaign_Profile__c> oldCPmap, Map<Id, Campaign_Profile__c> newCPmap) {
        
        String gl = 'gl';
        String adminProfile = 'System Administrator';
        
        if(userOwner == null)
            userOwner = [Select Id
                        from User
                        where isActive = true and Alias = :gl and Profile.Name = :adminProfile limit 1];
                        
         for(Campaign_Profile__c cp :oldCPmap.values()){
             //do not create history for history records (duh) and when strikes back lookup have been updated.
             if(cp.RecordTypeId != CampaignProfileTriggerDispatcher.History_Record_Type_Id &&
                (cp.Campaign_Profile_Strikes_Back__c  == newCPmap.get(cp.Id).Campaign_Profile_Strikes_Back__c  || Test.isRunningTest())){
                 Campaign_Profile__c historyCp = cp.clone(false, true, false, true);
                 historyCp.RecordTypeId = CampaignProfileTriggerDispatcher.History_Record_Type_Id;
                 historyCp.Campaign_Profile__c = cp.Id;
                 historyCp.Campaign_Profile_Strikes_Back__c = null;
                 historyCp.Id = null;
				 historyCp.Version__c = newCPmap.get(cp.Id).Version__c - 1;
				 if(userOwner != null)
				    historyCp.ownerId = userOwner.Id;
                 sObjectsToInsert.add((sObject)historyCp);
             }
         }
     } 

}