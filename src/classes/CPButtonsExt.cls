public without sharing class CPButtonsExt {
    
    public Campaign_Profile__c cp {get; set;}
    public Boolean renderBegin {get; set;}
    public Boolean renderMaint {get; set;}
    public Id recordId {get;set;}
    ApexPages.StandardController stdController;
    public String errorText{get;set;}
    public Boolean renderError {get;set;} 
    public Boolean shouldRedirect {get;set;} 
    public String redirectUrl{get;set;}
    public Change_Request__c preLiveChangeRequest{get; set;}
    //These are GUIDs for the form.  It will not change between orgs. SilverTree recommends using to query for specific forms.
    private final String requestEscalationGUID = '00Dg0000001qKtZEAU604fd1d625f4e4ca8f8f4cdb602a9806'; 
    private final String respondToEscalationGUID = '00Dg0000001qKtZEAU4bc564195aeb993b7d5847a99f9ae568';
    private final String escalationProcessName = 'Work Relay Escalations Controller';
    public WR_BPM__Flow_Instance__c escalationFlowInstance;
    public Map<String, String> guid2formID;
    public Map<String, Product_SLA_Status__mdt> statusMap;
    public OpportunityLineItem oli; 
    public Boolean renderChangeRequest {get;set;}
    public CPButtonsExt(ApexPages.StandardController stdController){
        recordId = stdController.getId();
        this.stdController = stdController;
        getStatusMap();
        cp = [Select Id, Name, Begin_Build_Process__c, Post_Live_Maintenance__c, Opportunity_Product_ID__c, RecordTypeId,
                RecordType.DeveloperName, RecordType.Name, Strategy_Session__c, Campaign_Type__c, AM__c, PM__c, PPC_Specialist__c,
                Campaign_Profile_Strikes_Back__c
                from Campaign_Profile__c
                where Id = :recordId];
        if(cp.Opportunity_Product_ID__c != null)
            oli = [select Id, Waiting_Status__c, Live_Date__c
                   from OpportunityLineItem
                   where Id = :cp.Opportunity_Product_ID__c];
        
        getRenderMaint();
          /* Set renderChangeRequest flag */
        renderChangeRequest=false;
        if (renderBegin == false && renderMaint == false){
            renderChangeRequest = new ChangeRequestModel().showPreLiveChangeRequestButton(cp);
        }      
        //do not show button if post live
        if(renderChangeRequest == true && oli != null && oli.Live_Date__c != null &&
            statusMap.containsKey(oli.Waiting_Status__c) && statusMap.get(oli.Waiting_Status__c).isLive__c == true)
              renderChangeRequest = false;

        List<WR_BPM__Form__c> wrFormList = [SELECT ID, WR_BPM__Guid__c FROM WR_BPM__Form__c WHERE WR_BPM__Guid__c IN (:requestEscalationGUID, :respondToEscalationGUID)];
        guid2formID = new Map<String, String>();
        
        for(WR_BPM__Form__c form : wrFormList){
            guid2formID.put(form.WR_BPM__Guid__c, form.Id);
        }

        try{
            escalationFlowInstance = [SELECT ID, Name FROM  WR_BPM__Flow_Instance__c WHERE WR_BPM__Object_Name__c = :escalationProcessName LIMIT 1];
        } catch (Exception E) {
            system.debug(E);
        }
        
    }
    
     public PageReference beginProcess(){
        
        cp.Begin_Build_Process__c = true;
        renderBegin = false;
        try{
            update cp;
        } catch (Exception e){
            renderError = true;
            errorText = 'Unable to Begin Process. Please populate all required information.';
        }
        return null;

     }
     
     public PageReference postLiveMaint(){
        
        try{
            if(cp.RecordTypeId == CampaignProfileCache.getRecordType('Social Media Management').Id){
                renderMaint = false;
                Campaign_Profile__c campaignProfile = [Select Id, Name, Begin_Build_Process__c, Post_Live_Maintenance__c, Opportunity_Product_ID__c, RecordTypeId,
                                                        RecordType.DeveloperName, RecordType.Name, Strategy_Session__c, 
                                                        Campaign_Type__c, AM__c, PM__c, PPC_Specialist__c,
                                                        Campaign_Profile_Strikes_Back__c
                                                        from Campaign_Profile__c
                                                        where Id = :cp.Id];
                Change_Request__c changeRequest = new ChangeRequestModel().createChangeRequest(campaignProfile, ChangeRequestModel.CRTYPE.PostLive);
                System.debug(JSON.SerializePretty(changeRequest));
                String urlFormat = '/apex/WorkRelayFormRenderer?' +  
                                   'Id=' + changeRequest.Id +
                                   '&viewMode=Edit'+ 
                                   '&retURL=%2F' + cp.Id;
                redirectUrl = urlFormat; 
                shouldRedirect=true; 
                return null;
            }else{
                cp.Post_Live_Maintenance__c = true;
                renderMaint = false;
                update cp;
            }
            
        } catch (Exception e){
            renderError = true;
            errorText = 'Unable to start Post-Live Maintenance. Please populate all required information.';
        }
        return null;

     }  
     
     private void getRenderMaint(){
        
        renderMaint = false;
        renderBegin = false;
    
        if(oli != null && statusMap.containsKey(oli.Waiting_Status__c)){
           if(oli.Live_Date__c != null && statusMap.get(oli.Waiting_Status__c).post_live_maintenance__c == true)
                renderMaint = true;
           if(cp.Begin_Build_Process__c != true && oli.Live_Date__c == null && statusMap.get(oli.Waiting_Status__c).isLive__c != true)
                renderBegin = true;
        }
        
     }
        
    //Change Request Initiator
    public PageReference invokeChangeRequest(){ 
        Change_Request__c changeRequest = new ChangeRequestModel().createChangeRequest(cp, ChangeRequestModel.CRTYPE.PreLive);
        //Open the URL with the Change Request Id
        String urlFormat = '/apex/WorkRelayFormRenderer?' +  
                           'Id=' + changeRequest.Id +
                           '&viewMode=Edit'+ 
                           '&retURL=%2F' + cp.Id;
        redirectUrl = urlFormat; 
        shouldRedirect=true; 
        return null;
    }

    //New Issue Initiator
    public PageReference newIssue(){
        //Open newIssue page
        if(!guid2formID.isEmpty() && escalationFlowInstance!=null){
            String urlFormat = '/apex/WR_BPM__DataEdit?' +
                               'formId=' + guid2formID.get(requestEscalationGUID) +
                               '&Flow_Instance__c_lkid=' + escalationFlowInstance.Id + 
                               '&Flow_Instance__c=' + EncodingUtil.urlEncode(escalationFlowInstance.Name, 'UTF-8') + 
                               '&CampaignProfile__c_lkid=' + cp.Id + 
                               '&CampaignProfile__c=' + EncodingUtil.urlEncode(cp.Name, 'UTF-8') +
                               '&Layout_Type__c=Form&Layout_Mode__c=Edit&Layout__c=' + guid2formID.get(respondToEscalationGUID) +
                               '&retURL=%2F' + cp.Id;
            redirectUrl = urlFormat;
            shouldRedirect = true;
        } else {
            shouldRedirect = false;
        }
        
        return null;
    }
    
    private void getStatusMap(){
        List<Product_SLA_Status__mdt> prodSlaList = [select Id, isLive__c, isGoLive__c, isStopped__c, MasterLabel, post_live_maintenance__c 
                            from Product_SLA_Status__mdt];
        statusMap = new Map<String, Product_SLA_Status__mdt>();
        if(prodSlaList != null && !prodSlaList.isEmpty()){
            for(Product_SLA_Status__mdt prodStat :prodSlaList)
                statusMap.put(prodStat.MasterLabel, prodStat);
        }
        
    }

}