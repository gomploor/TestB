/**
 *  Class Name          : QAResultsFormRenderer
 *  Created By          : Vijay Varada
 *  Created Date        : 11/10/2017
 *  Description         : QAResultsFormRenderer is Visual force controller for QAResultsFormRenderer (View)
 *  View Mode: This is used to render VF section in QA Results Page Layout
 */
 
public without sharing class QAResultsFormRenderer {
    private final QA_Result__c qaResult;
    private Pagereference currentPage;
    public Id workRelayFormId {get;set;}
    public Boolean showError {get;set;}
    
    public QAResultsFormRenderer(ApexPages.StandardController stdController){
        currentPage = ApexPages.currentPage();
        List<QA_Result__c> queryQaResults = [Select Id, Campaign_Record_Type_Name__c from QA_Result__c Where Id =: stdcontroller.getRecord().Id]; 
        if(queryQaResults!= null && queryQaResults.Size()>0){
            qaResult = queryQaResults[0];
        }
        
        System.debug('QA Result Record >> ' + JSON.serializePretty(qaResult));
        String campaignRecordTypeName; 
        
        showError = false;
        if(!(qaResult !=null && String.IsNotEmpty(qaResult.Campaign_Record_Type_Name__c))){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'QA Result Record is not associated to either campaign profile nor change request'));
            showError = true;
            return;
        }
        
        workRelayFormId = this.getWorkRelayFormId();  
        
        if(String.IsEmpty(workRelayFormId)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please enter work relay form mapping in Custom Metadata'));
            showError = true;
        }
    }
    
    private Id getWorkRelayFormId (){
        
        List<QA_Results_Work_Relay_Forms__mdt> wrFormMappings 
                    = [Select Id, WorkRelay_Form_Name__c from QA_Results_Work_Relay_Forms__mdt
                         Where Campaign_Record_Type__c=:qaResult.Campaign_Record_Type_Name__c];
        if(wrFormMappings!=null && wrFormMappings.size()>0){                 
            List<WR_BPM__Form__c> wrForms = [SELECT Id from WR_BPM__Form__c where Name =: wrFormMappings[0].WorkRelay_Form_Name__c];
            System.debug ('Work Relay Change Request form with name >> ' + wrFormMappings[0].WorkRelay_Form_Name__c );
            System.debug(JSON.serializePretty(wrForms));
            if(wrForms!=null && wrForms.size()>0){
                return wrForms[0].Id;
            }
        }
        return null;
    }
}