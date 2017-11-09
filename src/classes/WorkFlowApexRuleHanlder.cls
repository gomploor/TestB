/*
Created By   : Vijaya Varada
Created Date : 11/08/2017
Description  : This class is a wrapper to perform workrelay apex rules
   
*/
public without sharing class WorkFlowApexRuleHanlder implements WR_BPM.WorkflowCallApexRuleInterface {
    private Change_Request__c changeRequestRecord; 
    public class JsonParamerts{
        String Id;
        String Field_Api_Name;
        String CallType;
    }
    //You must implement this method from WR_BPM.WorkflowCallApexRuleInterface interface
    /*
        String parameters     {
            "Id":"SMM Product Id", 
        	"Field_Api_Name": "copy_instructions__c",
        	"CallType" : "isCopyInstructionsBlank"
        }
    */
    public Boolean run(sObject context, WR_BPM__Flow_Instance_Cursor__c flowInstanceCursor, String parameters){
        this.changeRequestRecord = (Change_Request__c)context; 
       
        //setting jsonParams
        JsonParamerts jsonParams;
        if(parameters != null){
           jsonParams = (JsonParamerts)JSON.deserialize(parameters, JsonParamerts.class);  
        }  
        
        if(jsonParams!=null && String.isNotEmpty(jsonParams.Id) 
                && String.isNotEmpty(jsonParams.Field_Api_Name)
                && String.isNotEmpty(jsonParams.CallType)
                && jsonParams.CallType.equalsIgnoreCase('isCopyInstructionsBlank')){
           String query = 'Select {0} from {1} Where Id = \'\'{2}\'\'';                     
           Id recordId = jsonParams.Id;
           String objectName = recordId.getSObjectType().getDescribe().getName();
           Set<String> fieldSet = recordId.getSObjectType().getDescribe().fields.getMap().KeySet();
    	   String fieldNames = String.Join(new List<String>(fieldSet), ',');
    	   List<sObject> lstObjects = database.query(String.format(query,new String[]{fieldNames, objectName, 
    	   	                                                    recordId}));
    	   
    	   
    	   Boolean isCopyInstructionsBlank = true;
           if(lstObjects!=null && lstObjects.size()>0){
    	       if(fieldSet.Contains(jsonParams.Field_Api_Name) 
    	            && String.isNotEmpty((String)lstObjects[0].get(jsonParams.Field_Api_Name))){
    	            isCopyInstructionsBlank = false;
    	       }
    	   }
    	   return isCopyInstructionsBlank;
        }
        
        //throwing exception if return has not occured yet
        throw new WR_BPM.GenericException('Unknown Call Type >> ' + JSON.SerializePretty(jsonParams));
    }
}