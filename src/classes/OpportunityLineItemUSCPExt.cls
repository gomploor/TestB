/*This class is used on OpportunityLineItemUSCP.page and OpportunityLineItemUSCPEdit.pages
Sadie[12/11/2015] DEV-3658 Updated PageReference redirectSysAdmin() and PageReference editOpportunityProduct() include new profile "Finance"
Sadie[9/01/2016] DEV-7288 removed references to SML Customer Care /Encrypted Field Access
Shiner[9/23/2016] DEV-7754 Add check to see if Has_ILI__c is true, which does not render input fields for Price Calculation Information
*/
public class OpportunityLineItemUSCPExt{
    
   public OpportunityLineItem controllerOli {set;get;}
   public OpportunityLineItem oli {set;get;}
   public OpportunityLineItem spikeOli {set;get;}
   public Billing_Schedule__c spikeBs {set;get;}
   public String subtxt {set;get;}
   public String ProdName {set;get;}
   public String LastMod  {set;get;}
   public string creatdBy {set;get;}
   public Boolean disableInvoiceMakeGood {get; set;}
   public Boolean disableSchedule {get; set;}
   public Boolean disableBsSchedule {get; set;}
   public Boolean renderCancelationEdit {get; set;}
   public Boolean renderStatusChange {get; set;}
   public Boolean renderSaleType {get; set;}
   public Boolean renderQtyContractMonths {get; set;}
   public Boolean renderUnitPrice {get; set;}
   public Boolean renderMediaBudget {get; set;}
   public Boolean renderTotalMothlyCharge {get; set;}
   public Boolean renderMgmtFeePercent {get; set;}
   public Boolean renderEmailRecipQty {get; set;}
   public Boolean renderNumberofLocations {get; set;}
   public Boolean renderPeriodDates {get; set;}
   public Boolean isBeforeClosedWon {get; set;}
   public Boolean disableMarketingCampaign {get; set;}
   public Boolean renderDelete {get;set;}
   public Boolean enableRenewed {get; set;}
   public Boolean enableSpike {get; set;}
   public Boolean renderRevertOli {get; set;}
   public Boolean renderRenewal {get; set;}
   public Boolean createCampaignProfile {get; set;}
   public Campaign_Profile__c cp {get; set;}
   public OpportunityLineItemChartServices oliChartServices {get; set;}
   public List<Opportunity_Product_History__c> HistoryTrack {get; set;}
   public List<OpportunityLineItemChartServices.OppProductHistoryRecord> HistoryTrackRecords {get; set;}
   public String renewalLabel{get; set;}
   public List<Billing_Schedule__c> bsList;
   public User loggedInUser {get; set;}
   public List<Change_Status_Access__mdt> statusAccess {get; set;} 
   public  List<Automated_Rate_Calculation__c> arcList = new List<Automated_Rate_Calculation__c>();
   public Boolean hasEditInvoiceField {get; set;}
   public Boolean isBBProduct {get; set;} //DEV-8819
   private Boolean profileAccessNumofLoc; //DEV-7950 
   public static final String Standard = 'Standard';
   public Boolean canCancelOli {get; set;}
   public Boolean canMigrateOli {get; set;}
   public Boolean disableMigrateOli {get; set;}
   public Set<String> stoppedStatus;
   public Set<String> liveStatus;
   public Set<String> canCreateCampaignProfile;
   public Id originalOli;
   
   public OpportunityLineItemUSCPExt(ApexPages.StandardController stdController) {
      
      //adding fields to controller so if nothing changes it does not throw error
       if(Test.isRunningTest() != true){
        List<String> fieldNames = new List<String>();
        fieldNames.add('Mgmt_Fee_Percent__c');
        fieldNames.add('Media_Budget__c');
        fieldNames.add('Total_Monthly_Charge__c');
        stdController.addFields(fieldNames);
      } 
       
      if (loggedInUser == null)
          loggedInUser  = [Select Id, Profile.Name, Username from User Where Id =: Userinfo.getUserId()];
      if (statusAccess == null)
          statusAccess = [select MasterLabel, DeveloperName, Profile_Name__c from Change_Status_Access__mdt];    
      
       controllerOli = (OpportunityLineItem) stdController.getRecord();
       
       //DEV-7754 Added Has_ILI__c to select statement 
       oli = [select id,name,opportunity.name,Project__r.Max_ILIScheduledDate__c,opportunity.stagename,OpportunityId,Product2.Name, 
              LastModifiedBy.Name,CreatedBy.Name,Mgmt_Fee_Percent__c,Invoice_CancelDate__c,Waiting_Status_Options__c,Affl_Sales_Rep__r.Email,
              Waiting_Status_Options_Before__c,Active_Product__c,Fulfillment_Specialist__c,CancelType__c, Invoice_ServiceStartDate__c, Invoice_ServiceEndDate__c,
              Waiting_Status__c,Record_Type_Name__c, Product2.HasMediaSpend__c, Marketing_Campaign__c, Cancellation_Category__c,
              Cancellation_Reason__c, Cancellation_Detail__c, Lost_To_Competitor__c, Other_Competitor__c,
              Canceled__c, Qty_ContractMonths__c, Media_Budget__c,PricebookEntry.Product2.Has_Schedule__c,
              Rescue_Status__c, PricebookEntry.Use_Percent_of_Media_Budget__c, Product2.UseMatrix__c, Total_Monthly_Charge__c,
              PricebookEntry.Product2Id, PricebookEntry.Pricebook2Id, PriceBookEntry.Product2.Edit_Qty_LineItems__c, 
              PriceBookEntry.Min_Number_of_Recipients__c, PriceBookEntry.Max_Number_of_Recipients__c, Email_Recipients_Qty__c,
              PricebookEntry.Product2.Edit_Qty_ContractMonths__c, PriceBookEntry.Product2.Edit_Email_Recipients__c,
              PriceBookEntry.Product2.Edit_NumberOfLocations__c, Email_Blast_Quantity__c, PricebookEntry.PriceRangeMin__c, PricebookEntry.PriceRangeMax__c,
              Invoice_PriceVariable__c, PriceBookEntry.Product2.Do_Not_Multiply_Number_of_Locations__c, NumberOfLocations__c, Has_ILI__c, Variable_Billing__c,
              Opportunity.RecordType.DeveloperName, Account__c, Opp_Owner__c, Sell_Type__c, Percent_of_Media_Budget__c, Percent_of_Total__c,
              Product2.Has_variable_budget__c, Migration_Date__c, Live_Date__c, increasedRate__c, Package__c, PriceBookEntry.Product2.Family,
              Opportunity.AccountId, Original_Related_OLI__c, PricebookEntry.Product2.Create_Campaign_Profile__c, Opportunity.PriceBook2.isStandard
              from opportunityLineItem where id =:controllerOli.id];
      
       if(oli.Opportunity.PriceBook2.isStandard == true)
          renewalLabel = 'Clone Opportunity and Renew';
       else
          renewalLabel = 'Renew';
          
       getStatusInfo();
	   
	   getBsList();
	        
	   renderPeriodDates = getRenderPeriodDate();
	   disableBsSchedule = getDisableBs();
	   renderRevertOli = geRevertOli();
	   
	   if (oli.Waiting_Status__c == null || String.isBlank(oli.Waiting_Status__c))
         isBeforeClosedWon = true;
       else
        isBeforeClosedWon = false;
        
        //field access
       String controllerName = String.valueOf(this).substring(0,String.valueOf(this).indexOf(':')); 
       
       if(oli.Product2.HasMediaSpend__c != true || oli.Sell_Type__c == Constants.OLI_SELL_TYPE_SPIKE || stoppedStatus.contains(oli.Waiting_Status__c))
          enableSpike = false;
       else
          enableSpike = !VfPageFieldAccess.disableFieldAccess(controllerName,'Add_Spike', loggedInUser.Profile.Name, loggedInUser.Username);
         
       //DEV-7950 Enable NumberOfLocations__c field to be editable by "Finance/Intake" profile users
       profileAccessNumofLoc = !VfPageFieldAccess.disableFieldAccess(controllerName,'NumberOfLocations__c', loggedInUser.Profile.Name, loggedInUser.Username);
	   
	   //DEV-8819 Get the record if it matches the product name of OLI
       List<Edit_Number_Of_Locations_Access__mdt> bbProductList = [SELECT Id, Product_Name__c FROM Edit_Number_Of_Locations_Access__mdt WHERE Product_Name__c = :oli.Product2.Name];
       
       if(bbProductList.size() > 0){
           isBBProduct = true; 
       }else {
           isBBProduct = false;
       }  
       
       enableRenewed = !VfPageFieldAccess.disableFieldAccess(controllerName,'Renewed__c', loggedInUser.Profile.Name, loggedInUser.Username);
       
       renderTotalMothlyCharge = !VfPageFieldAccess.disableFieldAccess(controllerName,'Total_Monthly_Charge__c', loggedInUser.Profile.Name, loggedInUser.Username, isBeforeClosedWon);
       renderMediaBudget = false;
       renderMgmtFeePercent = false;  
       renderEmailRecipQty = oli.PriceBookEntry.Product2.Edit_Email_Recipients__c;
       //DEV-7950
       if(oli.PriceBookEntry.Product2.Edit_NumberOfLocations__c || (profileAccessNumofLoc && isBBProduct)) //DEV-8819
       renderNumberofLocations = true;
       //if user has access to render - then check

       //DEV-7754 checkIfPriceCalcIsEditable function is used to check if the fields in Price Calculation Information should be editable.
       checkIfPriceCalcIsEditable(oli.Has_ILI__c);
       
       disableMarketingCampaign = checkSchedules(oli.Marketing_Campaign__c, oli.Id);
       renderDelete = false;
       if(disableMarketingCampaign != true && oli.Waiting_Status__c == null)
          renderDelete = true;
       renderStatusChange = false;
       if (oli.Waiting_Status__c != null && canChangeStatus(oli.Waiting_Status__c))
         renderStatusChange = true;
       subtxt = oli.name;
       ProdName = oli.Product2.Name;
       LastMod = oli.LastModifiedBy.Name;
       creatdBy = oli.CreatedBy.Name;
       this.oliChartServices = new OpportunityLineItemChartServices();
        
        this.HistoryTrackRecords = new List<OpportunityLineItemChartServices.OppProductHistoryRecord>();
        this.HistoryTrack = [Select     Id, 
                                        Opportunity__c, 
                                        Opportunity_Product__c, 
                                        OLI_Stage__c, 
                                        Notes__c,
                                        Duration__c, 
                                        Time_In__c, 
                                        Time_Out__c,
                                        CreatedBy.Name,
                                        LastModifiedBy.Name
                            From Opportunity_Product_History__c 
                            Where Opportunity_Product__c = :controllerOli.Id 
                            Order By Time_In__c];
        
        Map<String, Integer> dataFieldIndex = new Map<String, Integer>(); 
        
        Integer i = 0;
        for (Opportunity_Product_History__c oppProdHist : HistoryTrack){
            OpportunityLineItemChartServices.OppProductHistoryRecord hRecord = new OpportunityLineItemChartServices.OppProductHistoryRecord(oppProdHist);
            
            String stage = hRecord.record.OLI_Stage__c != null ? hRecord.record.OLI_Stage__c : OpportunityLineItemServices.CREATED_STAGE_NAME;

            hRecord.backtrack = false;
            
            hRecord.orderOfOccurence = ++i;

            if (!dataFieldIndex.containsKey(stage)){
                dataFieldIndex.put(stage, 1);
            } 
            else {
                dataFieldIndex.put(stage, dataFieldIndex.get(stage)+1);
                hRecord.backtrack = true;
            }
            
           if (oliChartServices.chartDataMap.containsKey(stage)){
                oliChartServices.chartDataMap.get(stage).setDataPoint(dataFieldIndex.get(stage), hRecord.getDuration);
            }
            
            HistoryTrackRecords.add(hRecord);   
        }
        String errorMessage = '' + ApexPages.CurrentPage().GetParameters().Get('haserror');
        String Message = '' + ApexPages.CurrentPage().GetParameters().Get('success');
        String pageHeaderReferer = ApexPages.currentPage().getHeaders().get('Referer');
       if(pageHeaderReferer != null && pageHeaderReferer.containsIgnoreCase('OpportunityLineItemExt') && errorMessage != 'null')
        {
               ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.error, errorMessage)); 
        }else if(pageHeaderReferer != null && pageHeaderReferer.containsIgnoreCase('OpportunityLineItemExt') && Message != 'null')
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.info, Message));  
       
        //for products that have schedule only? 
        disableInvoiceMakeGood = VfPageFieldAccess.disableFieldAccess(controllerName,'invoiceMakeGood', loggedInUser.Profile.Name, loggedInUser.Username);
         if (oli.PricebookEntry.Product2.Has_Schedule__c == false)
            disableSchedule = true;
        else      
            disableSchedule = VfPageFieldAccess.disableFieldAccess(controllerName,'scheduleOLI', loggedInUser.Profile.Name, loggedInUser.Username);    
         //Cancellation fields       
        if (oli.Canceled__c == false){
            renderCancelationEdit = false;         
        }else{
            renderCancelationEdit = !VfPageFieldAccess.disableFieldAccess(controllerName,'Cancellation', loggedInUser.Profile.Name, loggedInUser.Username);    
        }
        //check if fields editable
        renderSaleType = !VfPageFieldAccess.disableFieldAccess(controllerName,'Sell_Type__c', loggedInUser.Profile.Name, loggedInUser.Username, isBeforeClosedWon);  
        renderQtyContractMonths = false;
        if (oli.Product2.HasMediaSpend__c == true || oli.PriceBookEntry.Product2.Edit_Qty_LineItems__c == true)
            renderUnitPrice = false;
        else
            renderUnitPrice = !VfPageFieldAccess.disableFieldAccess(controllerName,'UnitPrice', loggedInUser.Profile.Name, loggedInUser.Username, isBeforeClosedWon); 
        //automated rate calculation 
        arcList = [select id, Column_End_Range__c, Column_Start_Range__c, MatrixResult__c, Name, Percent_of_Media_Budget__c, 
                   Percent_of_Total__c, Price_Book__c, Product__c, Range_Fixed_Charge__c, Row_End_Range__c, Row_Start_Range__c, Unit_Modifier__c 
                   from Automated_Rate_Calculation__c 
                   where Product__c =  :oli.PricebookEntry.Product2Id and Price_Book__c = :oli.PricebookEntry.Pricebook2Id and 
                   	increasedRate__c = :oli.increasedRate__c
                   order by Product__c, Price_Book__c, Row_Start_Range__c, Row_End_Range__c, Column_Start_Range__c, Column_End_Range__c nulls first];   
    
   //DEV-7952
       List<FieldPermissions> invoiceOrderNumberFLS = [SELECT SobjectType, Field, PermissionsRead, PermissionsEdit, Parent.ProfileId FROM FieldPermissions where SobjectType = 'OpportunityLineItem' and Field='OpportunityLineItem.Invoice_Order_Number__c' AND Parent.ProfileId =:Userinfo.getProfileId()];
       if(!invoiceOrderNumberFLS.isEmpty()){
           hasEditInvoiceField = invoiceOrderNumberFLS[0].PermissionsEdit;
       canCancelOli = getCanCancelOli();   
       migrateSetup();
       renderRenewal = isRenewable(oli.Id, oli.Opportunity.AccountId, oli.Waiting_Status__c);
       
       createCampaignProfile = getCreateCampaignProfile();
   }
   }
    
    Public PageReference redirectOLI(){
        //redirect to correct URL from old URL  
       PageReference ref;
       ref = new PageReference('/apex/OpportunityLineItemExt?id='+controllerOli.id);
       ref.setRedirect(true);
       return ref;
    }
    
    Public PageReference redirectSysAdmin(){
       //Re-directing Sys Admins to OpportunityLineItemUSCPEditSysAdmin.page incase if they land on OpportunityLineItemUSCPEdit.page
       
       PageReference ref;
       if(loggedInUser.Profile.Name == 'System Administrator' || loggedInUser.Profile.Name == 'Finance' ){
            ref = new PageReference('/apex/OpportunityLineItemUSCPEditSysAdmin?id='+controllerOli.id);
            ref.setRedirect(true);
       }
       return ref;
    }
    public PageReference editOpportunityProduct()
    {
        PageReference ref;
        if(loggedInUser.Profile.Name == 'System Administrator' || loggedInUser.Profile.Name == 'Finance' ){
            ref = new PageReference('/apex/OpportunityLineItemUSCPEditSysAdmin?id='+controllerOli.id);
        }else{
            ref = new PageReference('/apex/OpportunityLineItemUSCPEdit?id='+controllerOli.id);
        }
        ref.setRedirect(true);
        
        return ref;
    }
    
    public PageReference cancelInvoiceLineItems()
    {
        PageReference ref = new PageReference('/apex/OpportunityLineItemUSCP_Cancelled?id='+controllerOli.id);
        ref.setRedirect(true);
        
        return ref;
    }
    
    public PageReference rescueOLI()
    {
        PageReference ref = new PageReference('/apex/OLI_RescuePage?id='+controllerOli.id);
        ref.setRedirect(true);
        
        return ref;
    }
    
    public PageReference updateBs()
    {
        PageReference ref = new PageReference('/apex/BillingScheduleUpdate?oliid='+controllerOli.id);
        ref.setRedirect(true);
        
        return ref;
    }
    
    public PageReference updateAgreement()
    {
        PageReference ref = new PageReference('/apex/UpdateAgreement?id='+controllerOli.id);
        ref.setRedirect(true);
        
        return ref;
    }
    
    public PageReference oliDelete()
    {
        
        PageReference ref = new PageReference('/'+controllerOli.opportunityid);
         ref.setRedirect(true);
         try{
            OpportunityLineItem oli = new OpportunityLineItem(id=controllerOli.id);
            delete oli;
            }catch(DmlException ex){
                 System.debug('Update OLI exception details from OpportunityLineItemUSCPCancelController Controller >> ' + ex);
                 if(ex.getDmlStatusCode(0) !=null && ex.getDmlFields(0) == null){
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
                 }
                 ref = null;
             }    
        return ref;
    }
    
    public PageReference createPaymentEntries()
    {
        PageReference ref = null;
       try
       {
         String res = OpportunityPaymentEntries.createPaymentEntries(controllerOli.id);
          if(res == 'Created')
          {
           ref = apexpages.Currentpage();
           ref.setRedirect(true);
           ref.getParameters().put('success','Payment Entry created Succesfully');
          }
           else if(res == 'payments')
           {
               ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.error,'Please create payment processing');
           ApexPages.addMessage(msg);  
           }
           else if(res == 'Schedules')
           {
                ref = apexpages.Currentpage();
                ref.getParameters().put('hasError','Please create Schedules');
                ref.setRedirect(true);  
           }
           else if(res == 'both')
           {
               ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.error,'Please create Payment Processing and Schedules');
           ApexPages.addMessage(msg);  
           }
           
       }catch(Exception e)
       {
           ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
           ApexPages.addMessage(msg); 
       }
        return ref;
        
    }

    public PageReference save()
    {
        PageReference ref =  null;
        ref = new PageReference(getPageRef() +controllerOli.id);
        ref.setRedirect(true); 
        
        if (!canChangeStatus(controllerOli.Waiting_Status_Options__c)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Save. Only Finance has access to change ' + controllerOli.Waiting_Status_Options__c + ' status.')); 
            ref = null;
        }
        
        if(ref != null){    
            if((controllerOli.Waiting_Status__c == null || controllerOli.Waiting_Status__c == '') && 
                controllerOli.Waiting_Status_Options_Before__c!= null){
                    controllerOli.Waiting_Status__c = controllerOli.Waiting_Status_Options_Before__c;
            } else if(controllerOli.Waiting_Status_Options__c!= null){
                controllerOli.Waiting_Status__c = controllerOli.Waiting_Status_Options__c;
            }
        }
        if(ref != null && controllerOli.Waiting_Status__c == 'Live' && oli.Affl_Sales_Rep__r.Email == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to Save. Please enter Affiliated Sales Rep Email.')); 
            ref = null;   
        }
        if(ref != null && controllerOli.Email_Recipients_Qty__c != oli.Email_Recipients_Qty__c){
            if(oli.PriceBookEntry.Min_Number_of_Recipients__c!=null && oli.PriceBookEntry.Max_Number_of_Recipients__c!=null && 
              (controllerOli.Email_Recipients_Qty__c < oli.PriceBookEntry.Min_Number_of_Recipients__c || controllerOli.Email_Recipients_Qty__c > oli.PriceBookEntry.Max_Number_of_Recipients__c)){
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                'Email - Recipients Qty : Must be within range :' + oli.PriceBookEntry.Min_Number_of_Recipients__c + ' to ' + oli.PriceBookEntry.Max_Number_of_Recipients__c + '.'));
               ref = null;    
            }
            if(oli.PriceBookEntry.Min_Number_of_Recipients__c==null && oli.PriceBookEntry.Max_Number_of_Recipients__c!=null && controllerOli.Email_Recipients_Qty__c > oli.PriceBookEntry.Max_Number_of_Recipients__c){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                'Email - Recipients Qty : Must be less than or equal to : ' + oli.PriceBookEntry.Max_Number_of_Recipients__c + '.'));
               ref = null;  
            }
            if(oli.PriceBookEntry.Min_Number_of_Recipients__c!=null && oli.PriceBookEntry.Max_Number_of_Recipients__c==null && controllerOli.Email_Recipients_Qty__c < oli.PriceBookEntry.Min_Number_of_Recipients__c){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                'Email - Recipients Qty : Must be greater than or equal to :' + oli.PriceBookEntry.Min_Number_of_Recipients__c + '.'));
                ref = null; 
            }
            
        }
        if(controllerOli.Qty_ContractMonths__c <> oli.Qty_ContractMonths__c){
            if (controllerOli.Qty_ContractMonths__c== null){
                ref = null;  
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Qty Contract Months : Must enter value.'));
            }
            if (controllerOli.Qty_ContractMonths__c== 0 || controllerOli.Qty_ContractMonths__c == 0.00){
                ref = null;  
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Qty Contract Months : Must be nonzero.'));
            }
        }
        
        if(controllerOli.NumberOfLocations__c <> oli.NumberOfLocations__c){
            if (controllerOli.NumberOfLocations__c== null){
                ref = null;  
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Number of Locations : Must enter value.'));
            }
            if (controllerOli.NumberOfLocations__c== 0 || controllerOli.NumberOfLocations__c == 0.00){
                ref = null;  
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Number of Locations : Must be nonzero.'));
            }
        }
        
        if (ref != null && (controllerOli.Mgmt_Fee_Percent__c != oli.Mgmt_Fee_Percent__c || 
             controllerOli.Media_Budget__c != oli.Media_Budget__c ||
             controllerOli.Total_Monthly_Charge__c != oli.Total_Monthly_Charge__c || 
             controllerOli.Email_Recipients_Qty__c != oli.Email_Recipients_Qty__c) ||
             controllerOli.NumberOfLocations__c != oli.NumberOfLocations__c){
                this.recalculateCharges(); 
        }
        
        if(oli.Sell_Type__c == Constants.OLI_SELL_TYPE_SPIKE){
            if(validatePeriodDates() != true){
                //system.debug('----------------------------------controllerOli.Waiting_Status__c-' + controllerOli.Waiting_Status__c);
                if (oli.Waiting_Status__c != controllerOli.Waiting_Status__c && controllerOli.Waiting_Status__c == Constants.OLI_STAGE_LIVE){  //update dates when goes live
                    controllerOli.Invoice_ServiceStartDate__c = Date.Today();
                    if(bsList != null && bsList.size() == 1 && controllerOli.Invoice_ServiceEndDate__c == null)  //only update if null
                        controllerOli.Invoice_ServiceEndDate__c = bsList[0].Period_End__c; 
                }
            } else {
                ref = null;
            }
        }
        
        if(ref != null){
        try
        { 
            update controllerOli;
        }catch(DmlException ex){
           System.debug('Update OLI exception details from Edit Controller >> ' + ex);
           if(ex.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY'))
           {
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Insufficient Privileges You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.'));
           }
           else if(ex.getDmlStatusCode(0) !=null && ex.getDmlFields(0) == null){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
           }
           ref = null;
        }
        catch(Exception e)
        {
           System.debug('Update OLI exception details from Edit Controller >> ' + e);
           ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()); 
           ApexPages.addMessage(myMsg);
           ref = null;
        }
        }  
        if(ref != null){ //update billing schedule for emails
                if(controllerOli.Email_Recipients_Qty__c !=  oli.Email_Recipients_Qty__c && 
                   controllerOli.Total_Monthly_Charge__c != oli.Total_Monthly_Charge__c){
                    updateBillingSchedule();
                }
                if(oli.Invoice_ServiceStartDate__c != controllerOli.Invoice_ServiceStartDate__c || 
                    oli.Invoice_ServiceEndDate__c != controllerOli.Invoice_ServiceEndDate__c && bsList != null && bsList.size() == 1){
                      bsList[0].Period_Start__c = controllerOli.Invoice_ServiceStartDate__c;
                      bsList[0].Period_End__c = controllerOli.Invoice_ServiceEndDate__c;
                      try{
                          update bsList;
                      } catch (Exception e){
                          System.debug('OpportunityLineItemUSCPExt failed to update Spike Billing Schedule ' + e.getMessage());    
                      }
                }
        }
        return ref; 
    }
    Public PageReference cancel()
    {
        //PageReference ref = new PageReference('/apex/OpportunityLineItemUSCPEdit?id='+controllerOli.id);
        String oppType = ApexPages.currentPage().getParameters().get('type');
        system.debug('val::'+oppType);
        PageReference ref =  null;
        if(oppType != null && oppType == 'opp')
            ref = new PageReference('/'+controllerOli.opportunityid);
        //else if(Oli.Record_Type_Name__c != 'USCP Opportunity')
        else 
           ref = new PageReference(getPageRef() + controllerOli.id);
       
        ref.setRedirect(true);
        
        return ref;
    }
    
    Public PageReference invoiceAdjustment()
    {
      PageReference ref = new PageReference('/apex/InvoiceAdjustment?oliid='+controllerOli.id);
        
       return ref; 
        
    }
     public PageReference cancelUSCPOli()
    {
        PageReference ref = new PageReference('/apex/OpportunityLineItemUSCPMigrate?id='+controllerOli.id);
        ref.setRedirect(true);
        
        return ref;
    }
    
    Public PageReference invoiceMakeGood()
    {
      PageReference ref = new PageReference('/apex/InvoiceMakeGood?oliid='+controllerOli.id);
        
       return ref; 
        
    }
    
    Public PageReference scheduleOLI()
    {
      PageReference ref = new PageReference('/apex/ScheduleOLI?oliid='+controllerOli.id+'&mcid='+controllerOli.Marketing_Campaign__c);
        
       return ref; 
        
    }
    
    public PageReference renewal(){
        
        PageReference ref;
        //double check to make sure it's still renewable
        if(isRenewable(oli.Id, oli.Opportunity.AccountId, oli.Waiting_Status__c) != true){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'OLI has been renewed.'));
            return null;
        } else {
            Id oppId;
            if(oli.Opportunity.Pricebook2.isStandard == true){
                Opportunity opp = getOpp(oli.OpportunityId);
                Opportunity newOpp = opp.clone(false, true, false, false);
                newOpp.OwnerId = UserInfo.getUserId();
                try{
                    insert newOpp;
                } catch (Exception e){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to renew from Standard Pricebook. Please create new Opportunity. ' + e.getMessage()));
                    return null;
                }
                oppId = newOpp.Id;
            } else 
                oppId = oli.OpportunityId;
            ref = new PageReference('/apex/OpportunityPriceBook?oppId=' + oppId + '&oliId='+oli.id + '&family=' + oli.PriceBookEntry.Product2.Family + '&origOli=' + originalOli);
            return ref;
        }

    }
   
   private Opportunity getOpp(Id oppId){
       Map<String, Schema.SObjectField> fieldMapCp = Schema.SObjectType.Opportunity.fields.getMap();
        String query;
        for(Schema.SObjectField fld :fieldMapCp.values()){
            Schema.DescribeFieldResult dfr = fld.getDescribe(); 
            if(dfr.isCreateable() == true){
                if(query == null)
                    query = 'Select ' + dfr.getName();
                else 
                    query = query + ',' + dfr.getName();
            }
        }
        query = query + ' from Opportunity where Id = ' + '\'' + oppId + '\'';
        return Database.query(query);
   }
    
    public PageReference addSpike(){
        
        spikeOli = new OpportunityLineItem();
        spikeOli.OpportunityId = oli.OpportunityId;
        spikeOli.Account__c = oli.Account__c;
        spikeOLi.Opp_Owner__c = oli.Opp_Owner__c;
        spikeOli.PricebookEntryId = oli.PricebookEntryId;
        spikeOli.Project__c = null;
        spikeOli.Mgmt_Fee_Percent__c = oli.Mgmt_Fee_Percent__c;
        spikeOli.Variable_Billing__c = false;
        spikeOli.Sell_Type__c = Constants.OLI_SELL_TYPE_SPIKE;
        spikeOli.Related_OLI__c = oli.Id;
        spikeOli.Percent_of_Media_Budget__c = oli.Percent_of_Media_Budget__c;
        spikeOli.Percent_of_Total__c = oli.Percent_of_Total__c;
        spikeBs = new Billing_Schedule__c();
        spikeBs.Management_Fee_percent__c = oli.Mgmt_Fee_Percent__c;
        spikeBs.Opportunity__c = oli.OpportunityId;
        spikeBs.Percent_of_Media_Budget__c = oli.Percent_of_Media_Budget__c;
        spikeBs.Percent_of_Total__c = oli.Percent_of_Total__c;
        spikeBs.Related_OLI__c = oli.Id;
		spikeBs.isSpike__c = true;
        PageReference ref;
        ref = new PageReference('/apex/OpportunityLineItemSpike?id='+controllerOli.id);
        return ref;
    }
    
    public PageReference saveSpike()
    {

        PageReference ref;
        
        Boolean err = validateInsertSpike();
        
        if(err != true){
             ref = new PageReference(getPageRef() + spikeOli.Id);
             insertBs();
             ref.setRedirect(true);
        } else {
            ref = null;
        }
        return ref;
    }  
    
    public void insertBs(){
        //should be inserted at this point
        List<Project__c> projectList = [Select Id
                                        from Project__c
                                        where Product_Id__c = :spikeOli.Id];  
        if(projectList != null)
            spikeBs.Project__c = projectList[0].Id;
        spikeBs.Opportunity_Product__c = spikeOli.Id;
        system.debug('------------------------------------spikeBs-' + spikeBs);
        if(oli.PricebookEntry.Use_Percent_of_Media_Budget__c == true){
            spikeBs.Management_Fee__c = (spikeBs.Media_Budget__c * spikeBs.Management_Fee_percent__c/100).setScale(2);
            spikeBs.Total_Amount__c = spikeBs.Management_Fee__c + spikeBs.Media_Budget__c;
        } else {
            spikeBs.Management_Fee__c = (spikeBs.Total_Amount__c * spikeBs.Management_Fee_percent__c/100).setScale(2);
            spikeBs.Media_Budget__c = spikeBs.Total_Amount__c - spikeBs.Management_Fee__c;
        }
        spikeBs.Type__c = Standard;
        spikeBs.Period_Number__c = 1;
        insert spikeBs;
    }
    
    public Boolean validateInsertSpike(){
        Boolean err = false;
        if(spikeBs.Period_Start__c == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Period Start - Must Enter Value.'));
            err = true;
        }
        if(spikeBs.Period_End__c == null){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Period End - Must Enter Value.'));
            err = true;
        }
        if(spikeBs.Period_Start__c != null && spikeBs.Period_End__c != null){  
            if(spikeBs.Period_Start__c.daysBetween(spikeBs.Period_End__c) >= 28){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Period End must be less then 28 days from Period Start.'));
                err = true;
            }
            if(spikeBs.Period_Start__c > spikeBs.Period_End__c){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Period End is less then Period Start.'));
                err = true;
            }
        }
        if(oli.PricebookEntry.Use_Percent_of_Media_Budget__c == true && (spikeBs.Media_Budget__c == null || spikeBs.Media_Budget__c == 0)){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Media Budget - Must Enter Value.'));
           err = true;
        }
        if(oli.PricebookEntry.Use_Percent_of_Media_Budget__c != true && (spikeBs.Total_Amount__c == null || spikeBs.Total_Amount__c == 0)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Total Amount - Must Enter Value.'));
            err = true;
        }
        if(err != true){
            try{
				spikeOli.ServiceDate = spikeBs.Period_Start__c;
				spikeOli.Invoice_ServiceStartDate__c = spikeBs.Period_Start__c;
				spikeOli.Invoice_ServiceEndDate__c = spikeBs.Period_End__c;
                insert spikeOli;
            } catch (Exception e) {
                if(spikeOli.Id == null){
                     err = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error createing spike OLI. ' + e.getMessage()));
                }
            }
        }
        return err;
    }
    
    public Boolean validatePeriodDates(){
        Boolean err = false;
        if(controllerOli.Invoice_ServiceStartDate__c <> oli.Invoice_ServiceStartDate__c || 
                controllerOli.Invoice_ServiceEndDate__c <> oli.Invoice_ServiceEndDate__c){
            if(controllerOli.Invoice_ServiceStartDate__c == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Product Start of Service Date - Must Enter Value.'));
                err = true;
            }
            if(controllerOli.Invoice_ServiceEndDate__c == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Product End of Service Date - Must Enter Value.'));
                err = true;
            } 
            if(controllerOli.Invoice_ServiceStartDate__c != null && controllerOli.Invoice_ServiceEndDate__c != null){  
                if(controllerOli.Invoice_ServiceStartDate__c.daysBetween(controllerOli.Invoice_ServiceEndDate__c) >= 28){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Product End of Service Date must be less then 28 days from Period Start of Service Date.'));
                    err = true;
                }
                if(controllerOli.Invoice_ServiceStartDate__c > controllerOli.Invoice_ServiceEndDate__c){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Product End of Service Date is less then Product Start of Service Date.'));
                    err = true;
                }
            }
        }
        return err;
    }
    public static Boolean getCanCancelOLI() {
       
            Map<String, Set<String>> permissionSet2Profiles = new Map<String,Set<String>>();
            //Finance, Client Services and Admin Profiles
            permissionSet2Profiles.put('canCancelOLI', new set<String>{
                                                  'SML Customer Care',
                                                  'Finance',
                                                  'System Administrator',
                                                  'SML Accounts - Jump Start Managers',
                                                  'Digital Account Manager',
                                                  'Digital AM Team Manager',
                                                  'Digital Project Manager'}); 
                                                  
            List<User> loggedInUser = [Select Id, Profile.Name from User Where Id =: Userinfo.getUserId()];
            if(loggedInUser!=null && loggedInUser.size()>0 && String.IsNotBlank(loggedInUser[0].Profile.Name) &&
                permissionSet2Profiles.get('canCancelOLI').contains(loggedInUser[0].Profile.Name)){ 
                return true;
            }           
            return false;
    }
    
    public Boolean canUpdateAgreement{
       get{
          return this.canAdjustInvoice;
       }
    }
    
    public Boolean canAdjustInvoice {
        get
        { 
            Map<String, Set<String>> permissionSet2Profiles = new Map<String,Set<String>>();
            //Finance and Admin Profiles
            permissionSet2Profiles.put('canAdjustInvoice', new set<String>{
                                                  'SML Customer Care',
                                                  'Finance',
                                                  'System Administrator'}); 
                                                  
            List<User> loggedInUser = [Select Id, Profile.Name from User Where Id =: Userinfo.getUserId()];
            if(loggedInUser!=null && loggedInUser.size()>0 && String.IsNotBlank(loggedInUser[0].Profile.Name) &&
                permissionSet2Profiles.get('canAdjustInvoice').contains(loggedInUser[0].Profile.Name)){ 
                return true;
            }           
            return false;
        }
    }

  public boolean disableCancelOLI{
   get{
      if(oli.opportunity.stagename != 'Closed Won' 
        || (oli.opportunity.stagename == 'Closed Won' && oli.Invoice_CancelDate__c != null && oli.Invoice_CancelDate__c <= date.today())
        || (oli.Invoice_ServiceEndDate__c != null && oli.Invoice_ServiceEndDate__c <= date.today())){
            return true;
        }
    
        return false;
    }
  }
      public boolean diableRescueOLI{
          get{
              if(oli.Waiting_Status__c != 'Cancel Pending' && oli.Waiting_Status__c != 'Kill Pending'){
                  return true;
              } else 
                  if (canChangeStatus(oli.Rescue_Status__c) == false)
                      return true;
              return false;
          }
          
      }
      
      public boolean canChangeStatus(String statusName){
        Boolean changeStatus = true;
        List<Change_Status_Access__mdt> statusList = new List<Change_Status_Access__mdt>();
        for(Change_Status_Access__mdt sa :statusAccess){
            if(sa.MasterLabel == statusName){
                 statusList.add(sa);
                 changeStatus = false;  
            }   
        }
        
        for(Change_Status_Access__mdt sa :statusList){
           if(sa.Profile_Name__c == loggedInUser.Profile.Name){
               changeStatus = true;     
               break;
            }   
        }
        
        return changeStatus; 
    }
    
    public boolean disableWaiveFees{
        get{
            list<Invoice_LineItem__c> ILIlist = [SELECT Id, isLocked__c, isWaived__c FROM Invoice_lineItem__c 
                                                 where ProjectRef__c =: oli.Project__c 
                                                 AND (Invoice_LineItemType__c =: constants.CANCEL_TYPE_CANCEL OR Invoice_LineItemType__c =: constants.CANCEL_TYPE_KILL)
                                                 AND isLocked__c = true
                                                 AND isWaived__c = true];
            if(ILIlist.size()>0){
                return false;
            }
            return true;
        } 
        
    }
    
    public static Boolean checkSchedules(Id oliMc, Id oliId){
        Boolean disable = false;       
        //if no marketing campaign - should be able to add 
        if ( oliMc != null){
            Integer oisCount = [SELECT COUNT() from Order_Item_Schedule__c where 
                                        Marketing_Campaign__c = :oliMc and Opportunity_Product__c = :oliId];          

                if (oisCount > 0)
                    disable = true;
        }
        
        return disable;
    }
    public void recalculateCharges(){
        Automated_Rate_Calculation__c arc;
        
         if (oli.PriceBookEntry.Product2.Edit_Qty_LineItems__c == true){
            if (oli.Email_Blast_Quantity__c == null){
                oli.Email_Blast_Quantity__c = getArcEmailBlast(oli.Email_Recipients_Qty__c, oli.Invoice_PriceVariable__c);
            }
            if(oli.Email_Blast_Quantity__c != null){
                arc = getArcEmail(controllerOli.Email_Recipients_Qty__c, oli.Email_Blast_Quantity__c);
                if (arc != null){
					if (arc.MatrixResult__c != null && controllerOli.Email_Recipients_Qty__c != null){
						controllerOli.Total_Monthly_Charge__c = controllerOli.Email_Recipients_Qty__c * arc.MatrixResult__c;
						controllerOli.Invoice_PriceVariable__c = arc.MatrixResult__c;
					}
                } else {//didn't find arc
                    if(controllerOli.Email_Recipients_Qty__c != null && oli.Invoice_PriceVariable__c != null)
                        controllerOli.Total_Monthly_Charge__c = controllerOli.Email_Recipients_Qty__c * oli.Invoice_PriceVariable__c;
                }
            } else {
                //didn't find anything - so use current Cpm
                if(controllerOli.Email_Recipients_Qty__c != null && oli.Invoice_PriceVariable__c != null)
                    controllerOli.Total_Monthly_Charge__c = controllerOli.Email_Recipients_Qty__c * oli.Invoice_PriceVariable__c;
            }
        } 
    } 
    
     public Automated_Rate_Calculation__c getArcNumberOfLoc(Decimal numberOfLocations){
        
        Automated_Rate_Calculation__c arc;
        Decimal numberOfBlasts = 1;
        
        if(!arcList.isEmpty()){
            for(Integer i=0; i< arcList.size(); i++){
                if((arcList[i].Row_Start_Range__c== null || numberOfLocations >= arcList[i].Row_Start_Range__c) &&
                    (arcList[i].Row_End_Range__c== null || numberOfLocations <= arcList[i].Row_End_Range__c) &&
                    (arcList[i].Column_Start_Range__c == null || numberOfBlasts >= arcList[i].Column_Start_Range__c) &&
                    (arcList[i].Column_End_Range__c == null || numberOfBlasts <= arcList[i].Column_End_Range__c)){
                      arc = arcList[i];
                      break;
                }       
            }
        }
        return arc;
    }
    
    public Automated_Rate_Calculation__c getMgmtFeePercent(Decimal amount){
        
        Automated_Rate_Calculation__c arc;
        
        if(!arcList.isEmpty()){
            for(Integer i=0; i< arcList.size(); i++){
                if((arcList[i].Row_Start_Range__c== null || amount >= arcList[i].Row_Start_Range__c) &&
                    (arcList[i].Row_End_Range__c== null || amount <= arcList[i].Row_End_Range__c)){
                      arc = arcList[i];
                      break;
                 }       
            }
        }
        return arc;
    }
    
    public Automated_Rate_Calculation__c getArcEmail(Decimal numberOfRecipients, Decimal numberOfBlasts){
        
        Automated_Rate_Calculation__c arc;
        
        if(!arcList.isEmpty()){
            for(Integer i=0; i< arcList.size(); i++){
                if((arcList[i].Row_Start_Range__c == null || numberOfRecipients >= arcList[i].Row_Start_Range__c) &&
                    (arcList[i].Row_End_Range__c == null || numberOfRecipients <= arcList[i].Row_End_Range__c) && 
                   (arcList[i].Column_Start_Range__c == null || numberOfBlasts >= arcList[i].Column_Start_Range__c) &&
                    (arcList[i].Column_End_Range__c == null || numberOfBlasts <= arcList[i].Column_End_Range__c)){
                     arc = arcList[i];
                     break;
                 }       
            }
        }
        return arc;
    }
    
    public Decimal getArcEmailBlast(Decimal numberOfRecipients, Decimal cpm){
        
        Decimal emailBlastQty;
        
        if(!arcList.isEmpty()){
            for(Integer i=0; i< arcList.size(); i++){
                if((arcList[i].Row_Start_Range__c == null || numberOfRecipients >= arcList[i].Row_Start_Range__c) &&
                   (arcList[i].Row_End_Range__c == null || numberOfRecipients <= arcList[i].Row_End_Range__c) && 
                   (arcList[i].MatrixResult__c == cpm)){
                     emailBlastQty = arcList[i].Column_Start_Range__c;
                     break;
                 }       
            }
        }
        return emailBlastQty;
    }
    //DEV-7754 Add a check to see if Has_ILI__c = True and set all renders for Price Calculation Information to False else Check remainder fields if they are editable.
    public void checkIfPriceCalcIsEditable(Boolean HasIli){
        if (HasIli == true){
            renderTotalMothlyCharge = false;
            renderMediaBudget = false;
            renderMgmtFeePercent = false;  
            renderEmailRecipQty = false;
            if(!(profileAccessNumofLoc && isBBProduct)) //DEV-7950, DEV-8819
            renderNumberofLocations = false;
       } else if (renderTotalMothlyCharge == true){
            if (oli.Product2.HasMediaSpend__c == true){
                if(oli.Product2.UseMatrix__c == false)
                    renderMgmtFeePercent = true;
                if(oli.PricebookEntry.Use_Percent_of_Media_Budget__c == true){
                    renderMediaBudget = true;    
                    renderTotalMothlyCharge = false;
                }  else {
                    renderTotalMothlyCharge = true; 
                }  
            } else if(oli.PriceBookEntry.Product2.Edit_Qty_LineItems__c == true || oli.PriceBookEntry.Product2.Edit_NumberOfLocations__c == true){
                renderTotalMothlyCharge = false; 
            }
       }
    }
    
    public void updateBillingSchedule(){
        
        if(bsList != null && bsList.size() == 1){
            bsList[0].Management_Fee__c = controllerOli.Total_Monthly_Charge__c;
            bsList[0].Total_Amount__c = controllerOli.Total_Monthly_Charge__c;
            try{
                update bsList;
            } catch (Exception e){
                System.debug('OpportunityLineItemUSCPExt failed to update Billing Schedule ' + e.getMessage());
            }
            
        }
                                            
    }
    
    public Boolean getRenderPeriodDate(){
        
        Boolean renderDate = false;
        
        if(oli.Sell_Type__c == Constants.OLI_SELL_TYPE_SPIKE){
           if(bsList != null && bsList.size() == 1 && 
                (bsList[0].Invoice_Line_Items__r == null || bsList[0].Invoice_Line_Items__r.isEmpty())){
               renderDate = true;        
           }       
	   }
	   return renderDate;
    }
	
	public void getStatusInfo(){
    
        stoppedStatus = new Set<String>();
        liveStatus = new Set<String>();
        canCreateCampaignProfile = new Set<String>();
        
        List <Product_SLA_Status__mdt> prodList = [select DeveloperName, MasterLabel, isLive__c, isStopped__c, isGoLive__c, Create_Campaign_Profile__c  
                                           from  Product_SLA_Status__mdt];
        if(prodList != null && !prodList.isEmpty()){
            for(Product_SLA_Status__mdt ps :prodList){
                if(ps.isStopped__c == true)
                    stoppedStatus.add(ps.MasterLabel);
                if(ps.isGoLive__c == true)
                    liveStatus.add(ps.MasterLabel);
                if(ps.Create_Campaign_Profile__c == true)
                    canCreateCampaignProfile.add(ps.MasterLabel);
            }
                
        }
    }
	
    public String getPageRef(){
        String pageRef;
        if(oli.Opportunity.RecordType.DeveloperName == Constants.OPPORTUNITY_RECORD_TYPE_USCP_OPPORTUNITY)
        //if(Oli.Record_Type_Name__c == 'USCP Opportunity')
            pageRef = '/apex/OpportunityLineItemUSCP?id=';
        else
            pageRef = '/apex/OpportunityLineItemExt?id=';
        return pageRef;
    }
    
    public Boolean getDisableBs(){
        
        Boolean disableBs = true;
        
        Map<Id, Billing_Schedule__c> bsMap = new Map<Id, Billing_Schedule__c>(bsList);
        List<AddOn__c> addOnList = [Select Id 
                                    from AddOn__c
                                    where Billing_Schedule__c IN :bsMap.keySet()];
                                    
        if(oli.Product2.Has_variable_budget__c == true || (addOnList != null && !addOnList.isEmpty())){
           if(bsList != null && !bsList.isEmpty()){
               for(Billing_Schedule__c bs :bsList){
                    if(bs.Invoice_Line_Items__r == null || bs.Invoice_Line_Items__r.isEmpty() ||
                      (bs.Invoice_Line_Items__r != null && !bs.Invoice_Line_Items__r.isEmpty() &&
                       bs.Invoice_Line_Items__r[0].Invoice_Schedule_Date__c > Date.Today() &&
                       bs.Invoice_Line_Items__r[0].isLocked__c != true))
                      disableBs = false;
               }       
           }       
	   }
	   return disableBs;
    }
    
    public void getBsList(){
        
        bsList = [Select Management_Fee__c, Total_Amount__c, Period_Start__c, Period_End__c,
	                    (Select Id, Invoice_Schedule_Date__c, isLocked__c
	                        from Invoice_Line_Items__r)
                     from Billing_Schedule__c
                     where Opportunity_Product__c = :oli.Id
                     order by Period_Number__c];
     
    }
    
    public Boolean geRevertOli(){
        
        String controllerName = String.valueOf(this).substring(0,String.valueOf(this).indexOf(':')); 
        Boolean rndr = !VfPageFieldAccess.disableFieldAccess(controllerName,'revertOLI', loggedInUser.Profile.Name, loggedInUser.Username);
        system.debug('---------rndr-' + rndr);
        if(!liveStatus.contains(oli.Waiting_Status__c) || oli.Live_Date__c == null)
            rndr = false;
        if(rndr == true && bsList != null && !bsList.isEmpty()){
            for(Billing_Schedule__c bs :bsList){
                if(bs.Invoice_Line_Items__r != null && !bs.Invoice_Line_Items__r.isEmpty() &&
                   bs.Invoice_Line_Items__r[0].isLocked__c == true)
                      rndr = false;
            }
        }
        return rndr;
    }
    
    public void migrateSetup(){
        
        canMigrateOli = false;
        disableMigrateOli = disableCancelOLI;
        //enable OLI  migrate button
        if(canCancelOLI == true && oli.Live_Date__c != null && oli.Migration_Date__c != null){
            canMigrateOli = true;
        } 
        //disable until migration date
        if(oli.Migration_Date__c > Date.Today() && disableMigrateOli != true)
            disableMigrateOli = true;
            
        if(oli.Live_Date__c != null && oli.Migration_Date__c != null && oli.Migration_Date__c <= Date.Today()){
            canCancelOli = false;
            disableMigrateOli = false;
        }
        if(oli.Waiting_Status__c == 'Migrated'){
            canCancelOli = false;
            canMigrateOli = false;
        }    
    }
    
    public PageReference submitCreateCp(){
        
        system.debug('---inside submit cp');
        system.debug('createCampaignProfile-' + createCampaignProfile);
        if(createCampaignProfile == true){
            try{
                //createCp(new Set<Id>{oli.Id});
                Id batchInstanceId = Database.executeBatch(new AA_ProjectBlueLaunch_BulkCreateCPs(new Set<Id>{oli.Id}), 1);
                 system.debug('---calling submit cp');
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.info, 'Campaign Profile Creation Submitted.'));
                createCampaignProfile = false;
            } catch (Exception e){
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Campaign Profile Creation failed. ' + e.getMessage())); 
            }
        }    
        return null;
    }
    
    
    public PageReference revertOli(){
        String PENDING_STATUS = 'Pending';
        List<Invoice_lineItem__c> iliDelete = new List<Invoice_LineItem__c>();
        if(bsList != null && !bsList.isEmpty()){
            for(Billing_Schedule__c bs :bsList){
                bs.Period_Start__c = null;
                bs.Period_End__c = null;
                if(bs.Invoice_Line_Items__r != null && !bs.Invoice_Line_Items__r.isEmpty())
                    iliDelete.addAll(bs.Invoice_Line_Items__r);
            }
        }
        oli.Invoice_ServiceEndDate__c = null;
        oli.Invoice_ServiceStartDate__c = null;
        oli.Live_Date__c = null;
        oli.Waiting_Status_Descr__c = 'Reverted from ' + oli.Waiting_Status__c;
        oli.Waiting_Status__c = PENDING_STATUS;
       
        Savepoint SP = Database.setSavepoint();
         try {
            update bsList;
            if(!iliDelete.isEmpty())
                delete iliDelete;
            update oli;
        } catch(Exception e){
            ApexPages.addMessages(e);
            system.debug('Error reverting OLI - ' + e.getMessage());
            Database.rollback(SP);
            return null;
       } 
       PageReference ref;
       ref = new PageReference('/apex/OpportunityLineItemExt?id='+controllerOli.id);
       ref.setRedirect(true);
       return ref;
        
    }
    
     public Boolean isRenewable(Id oliId, Id acctId, String waitingStatus){
        Boolean rtn = false;
         //check if status can be renewed
        List<Product_SLA_Status__mdt> prodSlaList = [select MasterLabel 
                                                    from Product_SLA_Status__mdt 
                                                    where isRenewable__c = true and MasterLabel = :waitingStatus];
        if(prodSlaList != null && !prodSlaList.isEmpty()){
           
            List<OpportunityLineItem> oliList = [Select Id, Related_OLI__c
                                                from OpportunityLineItem
                                                where Opportunity.AccountId = :acctId];
            //should at least be one record - itself
            rtn = true;
            for(OpportunityLineItem oli :oliList){
                if(oli.Related_OLI__c == oliId) //found related oli - no good
                    rtn = false;
            }
            if(rtn == true) //need to get original oli
                originalOli = getRelatedOli(oliId, oliList);
        } 
        
        return rtn;
    }
    
    public Id getRelatedOli(Id oliId, List<OpportunityLineItem> oliList){
        
        Id orId;
       
        Map<Id, OpportunityLineItem> oliMap = new Map<Id, OpportunityLineItem>(oliList);
        OpportunityLineItem oli = oliMap.remove(oliId);
        if(oli.Related_OLI__c == null)
            orId = oliId;
        else {
            Id currId = oli.Related_OLI__c;
            Integer i = 0;
            while (orId == null || i < 20){ // do 20 times - in case of bad data and we don't find original id
                if(oliMap.get(currId).Related_OLI__c == null)
                    orId = currId;
                else
                    currId = oliMap.get(currId).Related_OLI__c;
                i++;
            } 
        }
        
        return orId;
    }
    
    public Boolean getCreateCampaignProfile(){
        Id historyId = CampaignProfileCache.getRecordType('History').Id;
        Boolean rtn = false;
        List<Campaign_Profile__c> cpList = new List<Campaign_Profile__c>([Select Id, Campaign_Profile_Name__c 
                                                                            from Campaign_Profile__c 
                                                                            where RecordTypeId <> :historyId and 
                                                                                (Opportunity_Product_ID__c = :oli.Id or OLI_ID__c = :oli.Id)]);
        //only for one product family
        if(oli.PricebookEntry.Product2.Create_Campaign_Profile__c == true && canCreateCampaignProfile.contains(oli.Waiting_Status__c)){
            if(cpList == null || cpList.isEmpty())
                rtn = true;
        }
        if(cpList != null && !cpList.isEmpty())
            cp = cpList[0];
        else
            cp = new Campaign_Profile__c();
        return rtn;
    }
    
    @future 
    static void createCp(Set<Id> oliId){
          OpportunityLineItem oliCp = [Select Id, Account__c, Account__r.Tier__c, Account__r.Account_Primary_Industry__c,  Account__r.Account_Primary_Focus__c, 
                    Product2.Name, Affl_Sales_Rep__r.Name, Affl_Sales_Rep__r.Email, Project__c, AccountAsText__c,
                    Opportunity.Notify_Email_1__c, Opportunity.Notify_Email_2__c, Opportunity.Notify_Email_3__c, Qty_ContractMonths__c, 
                    Current_Product_Value_VB__c, Package__c, Product2.Campaign_Type__c, Marketing_Campaign__c,
                    Original_Related_OLI__c
          from OpportunityLineItem where Id IN :oliId];
        	Campaign_Profile__c newCampaignProfileRecord = new Campaign_Profile__c();
				if(oliCp.Account__c != null){
					newCampaignProfileRecord.Client_Name__c = oliCp.Account__c;
					newCampaignProfileRecord.Account_Tier__c = oliCp.Account__r.Tier__c;
					newCampaignProfileRecord.Account_Primary_Industry__c = oliCp.Account__r.Account_Primary_Industry__c;
					newCampaignProfileRecord.Customer_Primary_Focus__c = oliCp.Account__r.Account_Primary_Focus__c;
					String cpName = oliCp.AccountAsText__c  + ' - ' + oliCp.Product2.Name;
			    	newCampaignProfileRecord.Campaign_Profile_Name__c = StringFormatter.autoTruncate(cpName);
				}
				if(oliCp.Affl_Sales_Rep__c != null){
					newCampaignProfileRecord.Affl_Sales_Rep__c = oliCp.Affl_Sales_Rep__r.Name;
					newCampaignProfileRecord.Affl_Sales_Rep_Email__c = oliCp.Affl_Sales_Rep__r.Email;
				}
				newCampaignProfileRecord.Project__c = oliCp.Project__c;
			    newCampaignProfileRecord.ProductName__c = oliCp.Product2.Name;
			    newCampaignProfileRecord.Contract_Length_Months__c = oliCp.Qty_ContractMonths__c;
			    newCampaignProfileRecord.Notify_Email_1__c = oliCp.Opportunity.Notify_Email_1__c;
				newCampaignProfileRecord.Notify_Email_2__c = oliCp.Opportunity.Notify_Email_2__c;
				newCampaignProfileRecord.Notify_Email_3__c = oliCp.Opportunity.Notify_Email_3__c;
				newCampaignProfileRecord.OLI_Duration__c =oliCp.Qty_ContractMonths__c;
				newCampaignProfileRecord.Current_Product_Value__c = oliCp.Current_Product_Value_VB__c;
				newCampaignProfileRecord.Package__c = oliCp.Package__c;
				newCampaignProfileRecord.Campaign_Type__c = oliCp.Product2.Campaign_Type__c;
				if(oliCp.Product2.Campaign_Type__c != null){
					newCampaignProfileRecord.RecordTypeId = CampaignProfileCache.getRecordType(newCampaignProfileRecord.Campaign_Type__c).Id;
				}
				newCampaignProfileRecord.Marketing_Campaign__c = oliCp.Marketing_Campaign__c;
			
				//Setting fields to manage OLI life cycle and renewals.
				//If OLI is a renewal, then it will get marked as fullfilled-complete in Work Relay Post Live Renewal Process; Else, it will work itself out with new Renewal Process functionality.
				if(oliCp.Original_Related_OLI__c != null && oliCp.Related_OLI__c != null){
					newCampaignProfileRecord.Opportunity_Product_ID__c = oliCp.Original_Related_OLI__c;
				} else {
					newCampaignProfileRecord.Opportunity_Product_ID__c = oliCp.Id;
				}
				newCampaignProfileRecord.Related_OLI__c = oliCp.Original_Related_OLI__c;
				newCampaignProfileRecord.OLI_ID__c = oliCp.Id;
			    insert newCampaignProfileRecord;
    }

}