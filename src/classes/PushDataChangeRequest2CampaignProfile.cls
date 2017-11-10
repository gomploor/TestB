/*
Created By   : Vijaya Varada
Created Date : 08/02/2017
Description  : This class is used to transfer change request data to campaign profile 
*/
public without sharing class PushDataChangeRequest2CampaignProfile implements WR_BPM.WorkflowCallApexActionInterface {
    
    private Change_Request__c changeRequest;
    private Set < String > removeKeys = new Set < String > {
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
    /*
    adding Info logs
    */
    private void addApplicationLogs(String infoMessage, String infoStackTrace){
        ApplicationLogsModel.addLogs(
            infoMessage, infoStackTrace, null, this.changeRequest.Id,
            'PushDataChangeRequest2CampaignProfile', 'workrelay run method', 
            false, ApplicationLogsModel.Loglevel.Info
        );
    }
    
    /*
    adding error logs
    */
    private void addErrorApplicationLogs(String infoMessage, String infoStackTrace){
        ApplicationLogsModel.addLogs(
            infoMessage, infoStackTrace, null, this.changeRequest.Id,
            'PushDataChangeRequest2CampaignProfile', 'workrelay run method', 
            false, ApplicationLogsModel.Loglevel.Error
        );
    }
    
    public void run(sObject context, WR_BPM__Flow_Instance_Cursor__c flowInstanceCursor, 
                    String operationType, String parameter) {
        try{ 
            
             this.changeRequest = (Change_Request__c)context;   
             this.addApplicationLogs('Context Change Request Object', JSON.serializePretty(this.changeRequest));
             
             this.pushDatafromCR2CP(this.changeRequest);
             
        }catch (Exception ex){
           this.addErrorApplicationLogs('error encounter from PushDataChangeRequest2CampaignProfile', JSON.serializePretty(ex));
           throw new WR_BPM.GenericException('error encounter from PushDataChangeRequest2CampaignProfile', ex);
        }finally{
			ApplicationLogsModel.insertLogList();    
        }       
    }
    
    //Push Data from Change Request 2 Campaign Profile that have API Name in Common
    private void pushDatafromCR2CP(Change_Request__c varChangeRequest){
        if(!(varChangeRequest!=null && String.isNotEmpty(varChangeRequest.Campaign_Profile__c)
                && String.isNotEmpty(varChangeRequest.Related_Product_Object_Id__c))){
            this.addErrorApplicationLogs('Either ChangeRequest is null or no campaign profile Id or no related product object Id',
                                            JSON.serializePretty(varChangeRequest));
            return;
        }
        
        this.addApplicationLogs('Starting Data Push from Change Request 2 Campaign Profile', 
                                    JSON.serializePretty(varChangeRequest));
                                    
		SObject relatedProductSpecificObject;  
		String objectName, fieldNames; 
		String query = 'Select {0} from {1} Where Id = \'\'{2}\'\''; 
		
												
		Id relatedProductObjectId = varChangeRequest.Related_Product_Object_Id__c; 

 		objectName = relatedProductObjectId.getSObjectType().getDescribe().getName();
		Set<String> fieldSet = relatedProductObjectId.getSObjectType().getDescribe().fields.getMap().KeySet();
		fieldNames = String.Join(new List<String>(fieldSet), ',');
		List<sObject> lstObjects = database.query(String.format(query,new String[]{fieldNames, objectName, 
		                                                    relatedProductObjectId}));
		if(lstObjects !=null && lstObjects.size()>0){
			relatedProductSpecificObject = lstObjects[0];
			this.addApplicationLogs('Related Product Specific Object Data', JSON.serializePretty(relatedProductSpecificObject)); 
			
			Map<String, Object> cObjMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serializePretty(relatedProductSpecificObject));
			for(String oneKey: this.removeKeys){
				cObjMap.remove(oneKey);
			}
			
			this.addApplicationLogs('Removed Standard Fields from Product Specific JSON Data', JSON.serializePretty(cObjMap)); 
			
			//remove false checkboxes values 
			for(String oneKey: cObjMap.KeySet()){
			   String objVal = String.ValueOf(cObjMap.get(oneKey));
			   if(String.IsNotEmpty(objVal) && objVal == 'false'){
				   cObjMap.remove(oneKey);
			   }
			}
			
			this.addApplicationLogs('Removed CheckBox fields with false value from JSON Data', JSON.serializePretty(cObjMap)); 
			Campaign_Profile__c campaignProfile = (Campaign_Profile__c)JSON.deserialize(JSON.serializePretty(cObjMap), 
			                                        Campaign_Profile__c.class);
			this.addApplicationLogs('Expected Campaign Profile JSON Data', JSON.serializePretty(campaignProfile));  
			campaignProfile.Id = varChangeRequest.Campaign_Profile__c;
			update campaignProfile;
			
			this.addApplicationLogs('Updated Campaign Profile Data', JSON.serializePretty(campaignProfile));  
		} 
    }
    
    //Push Data from Change Request 2 Campaign Profile that have API Name in Common (Bulkyfied version)
    public List<Campaign_Profile__c>  copyDatafromCR2CP(List<Change_Request__c> changeRequest){ 
        List<Campaign_Profile__c> retCampaingProfiles = new List<Campaign_Profile__c>();
        Map<String, Set<String>> mapProductObjectFields = new Map<String, Set<String>>();
        Map<String, Set<Id>> mapProductObjectIds = new Map<String, Set<Id>>();
        
        for(Change_Request__c oneRecord: changeRequest){  
            Id relatedProductObjectId = oneRecord.Related_Product_Object_Id__c;
            String objectName = relatedProductObjectId.getSObjectType().getDescribe().getName();
            if(oneRecord.Related_Product_Object_Id__c !=null
                && oneRecord.Campaign_Profile__c !=null
                && mapProductObjectFields.get(objectName)==null){ 
                Set<String> fieldSet = relatedProductObjectId.getSObjectType().getDescribe().fields.getMap().KeySet();
                //Describe field set is in lower case
                for(String oneKey: removeKeys){
                   fieldSet.remove(oneKey.toLowerCase());
                }
                mapProductObjectFields.put(objectName, fieldSet);
                mapProductObjectIds.put(objectName, new Set<Id>());
            }
            mapProductObjectIds.get(objectName).add(relatedProductObjectId);
        }
        
        List<sObject> lstSObjects = new List<sObject>();
        //bulkifying the queries per product specific object
        for(String ObjectName: mapProductObjectFields.KeySet()){
            Set<Id> recordIds = mapProductObjectIds.get(objectName);
            String fieldNames = String.Join(new List<String>(mapProductObjectFields.get(ObjectName)), ',');
            String query = String.format('Select {0} from {1} ', new String[]{fieldNames, objectName}); 
            List<sObject> querySObjects = database.query(query + ' Where Id In:recordIds');
            if(querySObjects !=null){
              lstSObjects.addAll(querySObjects);
            }
        }
        
        Map<Id, sObject> mapProductSobjects = new Map<Id, sObject>(lstSObjects);
        for(Change_Request__c oneRecord: changeRequest){  
            if(oneRecord.Related_Product_Object_Id__c !=null
                && oneRecord.Campaign_Profile__c !=null
                && mapProductSobjects !=null
                && mapProductSobjects.get(oneRecord.Related_Product_Object_Id__c) !=null){    
        			sObject relatedProductSpecificObject = mapProductSobjects.get(oneRecord.Related_Product_Object_Id__c);
        			Map<String, Object> cObjMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serializePretty(relatedProductSpecificObject));
         			//remove false checkboxes values 
        			for(String oneKey: cObjMap.KeySet()){
        			   String objVal = String.ValueOf(cObjMap.get(oneKey));
        			   if(String.IsNotEmpty(objVal) && objVal == 'false'){
        				   cObjMap.remove(oneKey);
        			   }
        			}
        			
        			Campaign_Profile__c campaignProfile = (Campaign_Profile__c)JSON.deserialize(JSON.serializePretty(cObjMap), 
        			                                        Campaign_Profile__c.class);
        			this.changeRequest = oneRecord;
        			this.addApplicationLogs('Expected Campaign Profile JSON Data', JSON.serializePretty(campaignProfile));  
        			campaignProfile.Id = oneRecord.Campaign_Profile__c;
        			retCampaingProfiles.add(campaignProfile);
        		} 
            }
        
        return retCampaingProfiles;
    }
}