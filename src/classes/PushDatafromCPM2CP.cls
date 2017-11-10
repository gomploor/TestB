/*
Created By   : Vijaya Varada
Created Date : 10/18/2017
Description  : This class is used to transfer change request data to campaign profile 
*/
public without sharing class PushDatafromCPM2CP {

    /*
    adding Info logs
    */
    private void addApplicationLogs(String infoMessage, String infoStackTrace, Id campaignProfileId, String methodName) {
        ApplicationLogsModel.addLogs(
            infoMessage, infoStackTrace, null, campaignProfileId,
            'PushDatafromCPM2CP', methodName,
            false, ApplicationLogsModel.Loglevel.Info
        );
    }

    //Push Data from Campaign Profile Maintenance 2 Campaign Profile that have API Name in Common
    //This method assumes that only desired cpms are passed from trigger to do the transfer
    public  List<Campaign_Profile__c> copyData2ParentCampaignProfile(Set<Id> cpmIds) { 
        // The list of remove keys has standard salesforce fields,  fields copied from parent campaign profile to child maintenance campaign 
        // profile this hardcoded list is derived from CampaignProfileAfterUpdateTriggerHandler.createChildCampaignProfile
        // Also, identified we risky fields that we should not be copying to campaign profile and are removed
        // Campaign_Profile_Strikes_Back__c, Campaign_Profile_Name__c, Begin_Build_Process__c, Interrupt_Build_Process__c, Post_Live_Maintenance__c,Processes_To_Run__c
        // We need to query for Parent_Campaign__c but should be nullified before updating parent campaign profile
        // Please be cautious about this Set
        Set < String > removeKeys = new Set < String > {
            'Campaign_Profile_Name__c',
            'CreatedDate',
            'LastModifiedDate',
            'IsDeleted',
            'Name',
            'attributes',
            'SystemModstamp',
            'OwnerId',
            'CreatedById',
            'CreatedDate',
            'LastModifiedById',
            'LastReferencedDate',
            'LastViewedDate',
            'Campaign_Profile_Strikes_Back__c',
            'RecordTypeId',
            'Begin_Build_Process__c',
            'Interrupt_Build_Process__c',
            'Client_Name__c',
            'Opportunity_Product_ID__c',
            'Account_Tier__c',
            'Account_Primary_Industry__c',
            'Campaign_Type__c',
            'Post_Live_Maintenance__c',
            'Processes_To_Run__c',
            'Facebook_Page_URL__c',
            'Current_Product_Value__c',
            'OLI_Duration__c',
            'ProductName__c',
            'PPC_Destination_URL__c',
            'OLI_ID__c',
            'Related_OLI__c',
            'Request_OLI_ID__c'
        };

        List<String> roleAssignmentFields = CampaignProfileCache.getRole2CPfieldMap().values();
        removeKeys.addall(roleAssignmentFields); // removing role assignment fields
        
        Set<String> fieldSet = Campaign_Profile__c.getSObjectType().getDescribe().fields.getMap().KeySet();  
        
        //Removing query fields from campaign profile
        for(String oneKey: removeKeys){
           fieldSet.remove(oneKey.toLowerCase());
        }
        String fieldNames = String.Join(new List<String>(fieldSet), ','); 
        List<Campaign_Profile__c> lstCampaignMaintenance = database.query('Select '+ fieldNames +' from Campaign_Profile__c Where Id In: cpmIds'); 
        
        List<Campaign_Profile__c> updateParentCampaigns = new List<Campaign_Profile__c>();
        if (lstCampaignMaintenance !=null){
            for(Campaign_Profile__c oneRecord : lstCampaignMaintenance){  
    			Map<String, Object> cObjMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serializePretty(oneRecord)); 
    			//remove false checkboxes values 
    			for(String oneKey: cObjMap.KeySet()){
    			   String objVal = String.ValueOf(cObjMap.get(oneKey));
    			   if(String.IsNotEmpty(objVal) && objVal == 'false'){
    				   cObjMap.remove(oneKey);
    			   }
    			}  
    			Campaign_Profile__c campaignProfile = (Campaign_Profile__c)JSON.deserialize(JSON.serializePretty(cObjMap), 
    			                                        Campaign_Profile__c.class);
    			campaignProfile.Id = oneRecord.Parent_Campaign__c;  
    			campaignProfile.Parent_Campaign__c = null; //updating parent campaign profile
    			updateParentCampaigns.add(campaignProfile); 
    			this.addApplicationLogs('Expected Campaign Profile JSON Data', 
    			                         JSON.serializePretty(campaignProfile), oneRecord.Id, 'copyData2ParentCampaignProfile');  
    		} 
    		
    		if(updateParentCampaigns.size()>0){
    		   this.addApplicationLogs('Updating Parent Campaign Profiles >> ' + updateParentCampaigns.size(), 
    		                            null, null, 'copyData2ParentCampaignProfile');   
    		}
        }
        return updateParentCampaigns;
    }
    
    //Copy data from CPM strikes back to CP Strikes back given the CMP Ids
    public List<Campaign_Profile_Strikes_Back__c> copyData2ParentCampaignProfileStrikesBack(Set<Id> cpmIds) { 
        Map<Id, Campaign_Profile__c> sourceCpm 
            = new  Map<Id, Campaign_Profile__c>([Select Id, Parent_Campaign__c, Campaign_Profile_Strikes_Back__c   
                                                    from Campaign_Profile__c 
                                                    Where Id IN:cpmIds]);
        
         
        Set<Id> cpIds = new Set<Id>();
        for(Campaign_Profile__c oneRecord: sourceCpm.Values()){
            cpIds.add(oneRecord.Parent_Campaign__c); 
        }
        
        Map<Id, Campaign_Profile__c> targetCp 
            = new  Map<Id, Campaign_Profile__c>([Select Id, Campaign_Profile_Strikes_Back__c   
                                                    from Campaign_Profile__c 
                                                    Where Id IN:cpIds]);
        
        // Derive source 2 target mapping of strikes back
        Map<Id,Id> sourceCpm2CpStrikesBack = new Map<Id,Id>();
        for(Campaign_Profile__c oneRecord: sourceCpm.Values()){
            sourceCpm2CpStrikesBack.put(oneRecord.Campaign_Profile_Strikes_Back__c,
                            targetCp.get(oneRecord.Parent_Campaign__c).Campaign_Profile_Strikes_Back__c);
        }
        
    	this.addApplicationLogs('Derive source 2 target mapping of strikes back', 
    	                            JSON.serializePretty(sourceCpm2CpStrikesBack), null, 'copyData2ParentCampaignProfileStrikesBack');  
       
        Set < String > removeKeys = new Set < String > {
            'CreatedDate',
            'LastModifiedDate',
            'IsDeleted',
            'Name',
            'attributes',
            'SystemModstamp',
            'OwnerId',
            'CreatedById',
            'CreatedDate',
            'LastModifiedById',
            'LastReferencedDate',
            'LastViewedDate',
            'RecordTypeId',
            'Campaign_Profile__c',
            'Campaign_Profile_Strikes_Back__c',
            'Version__c',
            'Campaign_Profile_Strikes_Back_Name__c'
        };
        Set<String> fieldSet = Campaign_Profile_Strikes_Back__c.getSObjectType().getDescribe().fields.getMap().KeySet();  
        
        //Removing query fields from campaign profile strikes back
        for(String oneKey: removeKeys){
           fieldSet.remove(oneKey.toLowerCase());
        }
        
        String fieldNames = String.Join(new List<String>(fieldSet), ','); 
        Set<Id> cpmStrikesBackIds = sourceCpm2CpStrikesBack.KeySet();
        List<Campaign_Profile_Strikes_Back__c> lstCpmStrikesBack 
                        = database.query('Select '+ fieldNames 
                                        +' from Campaign_Profile_Strikes_Back__c'
                                        +' Where Id In: cpmStrikesBackIds');  
                                        
        List<Campaign_Profile_Strikes_Back__c> updateParentcpStrikesBack = new List<Campaign_Profile_Strikes_Back__c>();
        if (lstCpmStrikesBack !=null){
            for(Campaign_Profile_Strikes_Back__c oneRecord : lstCpmStrikesBack){  
    			Map<String, Object> cObjMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serializePretty(oneRecord)); 
    			//remove false checkboxes values 
    			for(String oneKey: cObjMap.KeySet()){
    			   String objVal = String.ValueOf(cObjMap.get(oneKey));
    			   if(String.IsNotEmpty(objVal) && objVal == 'false'){
    				   cObjMap.remove(oneKey);
    			   }
    			}  
    			Campaign_Profile_Strikes_Back__c cpStrikesBack 
    			                        = (Campaign_Profile_Strikes_Back__c)JSON.deserialize(JSON.serializePretty(cObjMap), 
    			                                        Campaign_Profile_Strikes_Back__c.class);
    			cpStrikesBack.Id = sourceCpm2CpStrikesBack.get(oneRecord.Id);  // update parent campaign profile strikes back
    			updateParentcpStrikesBack.add(cpStrikesBack); 
    			this.addApplicationLogs('Expected Campaign Profile Strikes Back JSON Data', 
    			                        JSON.serializePretty(cpStrikesBack), oneRecord.Id, 'copyData2ParentCampaignProfileStrikesBack');  
    		} 
    		
    		if(updateParentcpStrikesBack.size()>0){
    		   this.addApplicationLogs('Updating Parent Campaign Profile Strikes Back >> ' + updateParentcpStrikesBack.size(), 
    		                            null, null, 'copyData2ParentCampaignProfileStrikesBack');   
    		}
        }
        return updateParentcpStrikesBack;
    }
}