//DEV-11918 - Creates recurring maintenance campaign every 30 days after campaign goes live
global class RecurringMaintenanceCampaign implements Database.Batchable<sobject> {
    String BRANDBUILDING = 'Brand_Building';
    ID History_Record_Type_Id     = RecordTypeCache.getRecordType('Campaign_Profile__c', Constants.HISTORY_RECORD_TYPE_NAME).Id;
    ID BrandBuilding_RecordTypeId = RecordTypeCache.getRecordType('Campaign_Profile__c', BRANDBUILDING).Id;
    List<String> roleAssignmentFields = CampaignProfileCache.getRole2CPfieldMap().values();
    
    //Probably do not need to sync these fields except for Campaign_Type__c.  Probably only need to sync roleAssignmentFields
    Set<String> fieldsToSync = new Set<String>{'Client_Name__c','Opportunity_Product_ID__c','Account_Tier__c',
                                               'Account_Primary_Industry__c','Campaign_Type__c','Facebook_Page_URL__c'};
    //update fieldsToSync
    Boolean fieldsToSyncUpdated = fieldsToSync.addAll(roleAssignmentFields);  
    Boolean result2 = fieldsToSync.addAll(RecurMaintDateConfigCntrl.getCPfields()); 

    string query;
    string fields2query = getFields2query();
    
    public String getFields2query(){
        fields2query = '';
        for(String field : fieldsToSync){
        	fields2query += field + ',';
    	}
        return fields2query;
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        //select all Campaign Profiles that qualify for having a recurring maintnenance and are not history records
        date qualifyDate = date.today();
        query = 'SELECT Id,Campaign_Profile_Name__c,' + fields2query + 'Recurring_Maintenance_Date__c '+ 
                'from Campaign_Profile__c '+ 
            	'WHERE (RecordTypeId != :History_Record_Type_Id OR RecordTypeId != :BrandBuilding_RecordTypeId) '+
                'AND Parent_Campaign__c = null '+
                'AND Recurring_Maintenance_Date__c = '+String.valueOf(qualifyDate);    
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        List<Campaign_Profile__c> existingCPlist = new List<Campaign_Profile__c>();
        List<Campaign_Profile__c> maintenanceCPlist = new List<Campaign_Profile__c>();
        
        for(sObject sobj : scope){
            Campaign_Profile__c oneCP =(Campaign_Profile__c)sobj;
            
            //Set the date to do the next recurring maintenance on the parent campaign profile.
            oneCP.Recurring_Maintenance_Date__c = RecurMaintDateConfigCntrl.getNextMaintenanceDate(oneCP);
            existingCPlist.add(oneCP);
            
            //Create a Maintenance Campaign Profile for this Campaign Profile
            Campaign_Profile__c maintenanceCP = new Campaign_Profile__c();
            
            maintenanceCP.Parent_Campaign__c = oneCP.Id;
            
            //Give maintenance ticket an initial name.  Name will be redefined in maintenance process.   
            String cpName = oneCP.Campaign_Profile_Name__c + ' - Recurring Maintenance';
            maintenanceCP.Campaign_Profile_Name__c = StringFormatter.autoTruncate(cpName);
            
            //As per AC of DEV-11523, Record Type is the same as parent, but this will change in new story.  
            //Update parameter in getRecordType to change to appropriate Record Type.
            if(oneCP.Campaign_Type__c != null) {
            	maintenanceCP.RecordTypeId = CampaignProfileCache.getRecordType(oneCP.Campaign_Type__c).Id;
            }
            
            maintenanceCP.Processes_To_Run__c = 'Recurring Maintenance';
            
            //Inherit field values from parent campaign profile
            for(String field : fieldsToSync){
            	maintenanceCP.put(field, oneCP.get(field));
            }
            
            maintenanceCPlist.add(maintenanceCP);
        }
        
        if(!existingCPlist.isEmpty() && existingCPlist != null){
            Database.update(existingCPlist, false); 
        }
        
        if(!maintenanceCPlist.isEmpty() && maintenanceCPlist != null){
            Database.insert(maintenanceCPlist, false);
        }
    }
    
    global void finish(Database.BatchableContext BC){
        //schedule new batch to run after current one finishes-
        Scheduler__mdt scheduler = new Scheduler__mdt();
        String currentClassName = String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
        //should only return one record - Developer name is unique
        scheduler = [Select  id, DeveloperName, Minutes_to_wait__c,  Schedule__c, Job_Name_Prefix__c, Batch_Size__c from Scheduler__mdt where DeveloperName = :currentClassName];
        if (Test.isRunningTest() != true && scheduler != null){
            if(scheduler.Schedule__c == true){
                //schedule job with params defined in scheduler
                String cronID = System.scheduleBatch(new RecurringMaintenanceCampaign(), scheduler.Job_Name_Prefix__c.trim() + System.now().format(), 
                                                        scheduler.Minutes_to_wait__c.intValue(), scheduler.Batch_Size__c.intValue());
            }
        }
    }

}