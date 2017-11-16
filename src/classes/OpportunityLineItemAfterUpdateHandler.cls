/**
 *  Class Name          : OpportunityLineItemAfterUpdateHandler
 *  Created By          : Praneeth
 *  Last Modified By    : Vijay Varada
 *  Description         : Opportunity Line item trigger handler to handle the old and new opportunity line items
 *  Modifed History     : 03/12/2015 Refactored OpportunityLineItem After Trigger Handler
 */
public class OpportunityLineItemAfterUpdateHandler extends TriggerHandlerBase{
    
    public override void mainEntry(TriggerParameters tp) {
        if(Functionality.isProjectBlueEnabled() == true){
			this.createCampaignProfileRecord((Map<Id, OpportunityLineItem>)tp.oldMap, (Map<Id, OpportunityLineItem>)tp.newMap);
        	this.updateCentralCampaignProfiles((Map<Id, OpportunityLineItem>)tp.oldMap, (Map<Id, OpportunityLineItem>)tp.newMap);
        }        
        this.CreatePPCOpportunityLineItemSchedule((Map<Id, OpportunityLineItem>)tp.oldMap, (Map<Id, OpportunityLineItem>)tp.newMap);   
        this.updateOpportunityFields((List<OpportunityLineItem>)tp.newList);
        //QUALTRICS: updateActiveOLI governs workflows that send outbound messages to Qualtrics to send out surveys
        this.updateActiveOLI((Map<Id, OpportunityLineItem>)tp.oldMap, (Map<Id, OpportunityLineItem>)tp.newMap);
        //QUALTRICS: defector count used to for Qualtrics
        this.updateDefectorCount((Map<Id, OpportunityLineItem>)tp.oldMap, (Map<Id, OpportunityLineItem>)tp.newMap);
        //need this condition as the reentrant feature is not working for OLI trigger 
        if(!OpportunityLineItemTriggerHelper.isEmailsProcessed){
            this.sendCancelKillFNREmails((Map<Id,OpportunityLineItem>)tp.newMap , (Map<Id,OpportunityLineItem>)tp.oldMap );
        }
        this.getFieldChanges((List<OpportunityLineItem>)tp.newList, (Map<Id,OpportunityLineItem>)tp.oldMap);
        this.insertOrUpdateIntoOpportunityProductHistory((Map<Id, OpportunityLineItem>)tp.oldMap, (Map<Id, OpportunityLineItem>)tp.newMap);
        this.upsertProjectObject((Map<Id, OpportunityLineItem>)tp.oldMap, (Map<Id, OpportunityLineItem>)tp.newMap);
		
        // DEV-8480
        //OpportunityLineItemTriggerHelper.createTasksForOLIStatusChange((Map<Id,OpportunityLineItem>)tp.newMap , (Map<Id,OpportunityLineItem>)tp.oldMap);
        this.addTasksForStatusChange((Map<Id,OpportunityLineItem>)tp.newMap , (Map<Id,OpportunityLineItem>)tp.oldMap);
        this.updateTasksForStatusChange((Map<Id,OpportunityLineItem>)tp.newMap , (Map<Id,OpportunityLineItem>)tp.oldMap);
        
        // Keep this rollup method always last in the execution order
        this.RollupManager((Map<Id, OpportunityLineItem>)tp.newMap, (Map<Id, OpportunityLineItem>)tp.oldMap);
    } 
    
    public override void inProgressEntry(TriggerParameters tp) {
       
       this.updateOpportunityFields((List<OpportunityLineItem>)tp.newList);
       this.insertOrUpdateIntoOpportunityProductHistory((Map<Id, OpportunityLineItem>)tp.oldMap, (Map<Id, OpportunityLineItem>)tp.newMap);
       this.upsertProjectObject((Map<Id, OpportunityLineItem>)tp.oldMap, (Map<Id, OpportunityLineItem>)tp.newMap);
        // Keep this rollup method always last in the execution order
        this.RollupManager((Map<Id, OpportunityLineItem>)tp.newMap, (Map<Id, OpportunityLineItem>)tp.oldMap);
    }
    
    private void addTasksForStatusChange(Map<Id,OpportunityLineItem> newMap, Map<Id,OpportunityLineItem> oldMap){
        
        List<Task> newTaskList = 
             OpportunityLineItemTriggerHelper.createTasksForOLIStatusChange(newMap, oldMap);
        if(newTaskList != null && !newTaskList.isEmpty()){
             sObjectsToInsert.addAll((List<sObject>)newTaskList);
        }
        
    }
    
    // DEV-9598. 'Finalize Renewal Status' Task is automatically set to Status = Completed when the OLI's Status = Fulfilled Renewed OR Fulfilled Non-Renewal.
    private void updateTasksForStatusChange(Map<Id,OpportunityLineItem> newOLIMap, Map<Id,OpportunityLineItem> oldOLIMap){
        Set<Id> opportunityIds = new Set<Id>();

        for(OpportunityLineItem currOLI : newOLIMap.values()){
            if(currOLI.Waiting_Status__c != oldOLIMap.get(currOLI.Id).Waiting_Status__c){
                // Filter 'Fulfilled Renewed' and 'Fulfilled Non-Renewal' Status OLI.
                if(TaskManagementHelper.TM_OLI_RENEWAL_STATUS.contains(currOLI.Waiting_Status__c)){
                    opportunityIds.add(currOLI.OpportunityId);
                }
           }
        }
        
        if(!opportunityIds.isEmpty()){
            for(Task currTask : [SELECT Id, Status, WhatId, Task_Management_Ref__c FROM Task WHERE WhatId != null AND WhatId IN:opportunityIds AND Task_Management_Ref__c != null AND IsClosed = FALSE ORDER BY WhatId]){
                if(currTask.Task_Management_Ref__c.subStringBefore('#') == TaskManagementHelper.TM_FINALIZE_RENEWAL_STATUS_TASKSETTING_NAME){
                    currTask.Status = TaskManagementHelper.TASK_CLOSE_STATUS;
                    sObjectsToUpdate.put(currTask.Id, currTask);
                }
            }
        }
    }
    
    //Create PPC Opportunity Line Item Schedule where product waiting status turns to "Live" and Product Category is "PPC"
    private void CreatePPCOpportunityLineItemSchedule(Map<Id, OpportunityLineItem> oldOpportunityLineItems, 
                                                   Map<Id, OpportunityLineItem> newOpportunityLineItems){
       
       System.debug('OpportunityLineItemAfterUpdateHandler.CreatePPCOpportunityLineItemSchedule Method');
       Map<String, Id> onlyLivePPCOppProducts = new Map<String, Id>();
       for(OpportunityLineItem oneOppLineItem : newOpportunityLineItems.Values()){
          if (oneOppLineItem.Waiting_Status__c != oldOpportunityLineItems.get(oneOppLineItem.Id).Waiting_Status__c 
              && oneOppLineItem.Waiting_Status__c == 'Live' && oneOppLineItem.Product_Category__c == 'PPC') {
                onlyLivePPCOppProducts.put(String.ValueOf(oneOppLineItem.Id).substring(0, 15), oneOppLineItem.Id);
          }
       }
        
       if(onlyLivePPCOppProducts.size()>0){
            List<PPCOrderDetail__c>  listPPCOrderDetails = [SELECT Id, OpportunityLineItemId__c FROM PPCOrderDetail__c 
                                                            WHERE FulfillmentStatus__c = 'AMP' and OpportunityLineItemId__c in :onlyLivePPCOppProducts.KeySet()
                                                            and OLI18DigitId__c in : onlyLivePPCOppProducts.Values()];
            if(listPPCOrderDetails != null && listPPCOrderDetails.size()>0){
                Map<Id, OpportunityLineItem> mapOppLineItem = new Map<Id, OpportunityLineItem>(
                                                                [Select Id, Quantity, Live_Date__c, UnitPrice,
                                                                    Opportunity.RecordTypeId,
                                                                    (SELECT Id FROM OpportunityLineItemSchedules)
                                                                    from OpportunityLineItem where Id In : onlyLivePPCOppProducts.Values()]
                                                              );
                                                              
                for(PPCOrderDetail__c onePPCOrder : listPPCOrderDetails){
                    Id oppLineItem18Id = onlyLivePPCOppProducts.get(String.ValueOf(onePPCOrder.OpportunityLineItemId__c));
                    if(oppLineItem18Id!=null){
                        OpportunityLineItem oneOppLineItem = mapOppLineItem.get(oppLineItem18Id);
                        
                        Date oppLineItemLiveDate; 
                        if(oneOppLineItem.Live_Date__c != null){
                            oppLineItemLiveDate = oneOppLineItem.Live_Date__c.Date();
                        }else{                  
                            oppLineItemLiveDate = Date.today();
                        }
                        
                        if(oneOppLineItem != null 
                            && oneOppLineItem.Opportunity.RecordTypeId != RecordTypeCache.getRecordType('Opportunity', 'USCP_Opportunity').Id 
                            && oneOppLineItem.OpportunityLineItemSchedules.size() == 0){
                            //Only if there are no Opp Line Item Schedules, Creates new ones
                            for(Integer i=0; i < oneOppLineItem.Quantity; i++){
                                OpportunityLineItemSchedule newOppLineItemSchedule = new  OpportunityLineItemSchedule();
                                newOppLineItemSchedule.OpportunityLineItemId = oneOppLineItem.Id;
                                newOppLineItemSchedule.ScheduleDate = oppLineItemLiveDate.addMonths(i);
                                newOppLineItemSchedule.Revenue = oneOppLineItem.UnitPrice;
                                newOppLineItemSchedule.Type = 'Revenue';
                                this.sObjectsToInsert.add(newOppLineItemSchedule);
                            }   
                        }
                    }
                }
            }                                                                 
       }                        
   }
   
   //upsert project__c 
    private void upsertProjectObject(Map<Id, OpportunityLineItem> oldOpportunityLineItems,
                                        Map<Id, OpportunityLineItem> newOpportunityLineItems){
        if(UserInfo.GetUserId() != Constants.GANNETT_LOCAL_USER.Id){
            Map<Id, Id> mapOppLineItemIdAndProjectId = new Map<Id,Id>();
            for(Project__c oneProject :[Select Id, Product_Id__c from Project__c Where Product_Id__c in :newOpportunityLineItems.KeySet()]){
                mapOppLineItemIdAndProjectId.put(oneProject.Product_Id__c, oneProject.Id);
            }
            
            List<Project__c> upsertProjects = new List<Project__c>();
            
            for(OpportunityLineItem oneOppLineItem : newOpportunityLineItems.Values()){
                Project__c oneProject = new Project__c();
                if(mapOppLineItemIdAndProjectId.get(oneOppLineItem.Id) != null){
                    oneProject = projectToUpdate(oneOppLineItem, oldOpportunityLineItems.get(oneOppLineItem.Id));
                    if (oneProject != null){
                        oneProject.Id = mapOppLineItemIdAndProjectId.get(oneOppLineItem.Id); 
                        upsertProjects.add(oneProject);
                    }
                } else {
                    oneProject = projectToInsert(oneOppLineItem, oldOpportunityLineItems.get(oneOppLineItem.Id));
                    upsertProjects.add(oneProject);
                }
    
            }
            
            //We have to do an upsert here which is not inline with trigger architecture guideline because
            //Opportunity_Product_History__c is expecting the data to be saved in project__c
            if(upsertProjects.size()>0){
                upsert upsertProjects;
            }
           
        }
    }
    
    private Project__c projectToUpdate(OpportunityLineItem oli, OpportunityLineItem oldOli){
        Project__c project = new Project__c();
        //only update if something changed 
        if(oli.Cancellation_Category__c != oldOli.Cancellation_Category__c || 
           oli.Canceled__c != oli.Canceled__c ||
           oli.Cancellation_Reason__c != oldOli.Cancellation_Reason__c ||
           oli.Cancellation_Detail__c != oldOli.Cancellation_Detail__c ||
           oli.OpportunityId != oldOli.OpportunityId ||
           oli.Account__c != oldOli.Account__c ||
           oli.Product2Id != oldOli.Product2Id ||
           oli.Waiting_Status_Descr__c != oldOli.Waiting_Status_Descr__c ||
           oli.Status_Change_Date__c != oldOli.Status_Change_Date__c ||
           oli.Waiting_Status__c != oldOli.Waiting_Status__c ||
           oli.Product_Name__c != oldOli.Product_Name__c ||
           oli.Notify_Email_1__c != oldOli.Notify_Email_1__c || 
           oli.Notify_Email_2__c != oldOli.Notify_Email_2__c ||
           oli.Notify_Email_3__c != oldOli.Notify_Email_3__c ||
           oli.Affl_Sales_Rep__c != oldOli.Affl_Sales_Rep__c ||
           oli.Dig_Account_Manager__c != oldOli.Dig_Account_Manager__c ||
           oli.Email_Coordinator__c != oldOli.Email_Coordinator__c ||
           oli.Web_Coordinator__c != oldOli.Web_Coordinator__c ||
           oli.Dig_Project_Manager__c != oldOli.Dig_Project_Manager__c ||
           oli.Live_Date__c != oldOli.Live_Date__c ||
           oli.Media_Partner__c != oldOli.Media_Partner__c ||
           oli.Sell_Type__c != oldOli.Sell_Type__c  ||
           oli.Invoice_CancelDate__c != oldOli.Invoice_CancelDate__c ||
           oli.Cancel_Entered_Date__c != oldOli.Cancel_Entered_Date__c  ||
           oli.Invoice_ServiceStartDate__c != oldOli.Invoice_ServiceStartDate__c  ||
           oli.Invoice_ServiceEndDate__c != oldOli.Invoice_ServiceEndDate__c ||
           oli.Qty_ContractMonths__c != oldOli.Qty_ContractMonths__c ||
           oli.UnitPrice != oldOli.UnitPrice ||
           oli.Invoice_Units__c != oldOli.Invoice_Units__c  ||
           oli.Mgmt_Fee_percent__c != oldOli.Mgmt_Fee_percent__c ||
           oli.Invoice_PriceVariable__c != oldOli.Invoice_PriceVariable__c ||
           oli.Total_Monthly_Charge__c != oldOli.Total_Monthly_Charge__c ||
           oli.Notes__c != oldOLi.Notes__c ||
           oli.Waive_Fees__c != oldOli.Waive_Fees__c ||
           oli.Non_Renewal_Reason__c != oldOli.Non_Renewal_Reason__c ||
           oli.Non_Renewal_Details__c != oldOli.Non_Renewal_Details__c ||
           oli.TotalPrice != oldOli.TotalPrice ||
           oli.Invoice_Order_Number__c != oldOli.Invoice_Order_Number__c ||
		   oli.End_Of_Service_Date__c != oldOli.End_Of_Service_Date__c) {
               project = projectToInsert(oli, oldOli);
               return project;
           } else {
               return null;
           }
 
    }
    
    private Project__c projectToInsert(OpportunityLineItem oli, OpportunityLineItem oldOli){
        Project__c project = new Project__c();
        project.Cancellation_Category__c = oli.Cancellation_Category__c;
        project.Cancelled__c = oli.Canceled__c;
        project.Cancellation_Reason__c = oli.Cancellation_Reason__c;
        project.Cancellation_Detail__c = oli.Cancellation_Detail__c;
        project.OppProd__c = String.ValueOf(oli.OpportunityId) + String.ValueOf(oli.Id);
        project.Product_Id__c = oli.Id;
        project.Opportunity__c = oli.OpportunityId;
        project.Account__c = oli.Account__c;
        project.Related_Product__c = oli.Product2Id;
        project.Waiting_Status_Descr_Last_Set__c = oli.Waiting_Status_Descr__c;
        project.Status_Notes__c = oli.Waiting_Status_Descr__c;
                
        if(oli != null && oli.Waiting_Status__c != oldOli.Waiting_Status__c){
             project.Waiting_Since_Date__c = datetime.now();
        }else{
             project.Waiting_Since_Date__c = oli.Status_Change_Date__c;
        }
                                
        project.Project_Status__c = oli.Waiting_Status__c;
        project.Product_Name__c = oli.Product_Name__c;
        project.Notify_Email_1__c = oli.Notify_Email_1__c;
        project.Notify_Email_2__c = oli.Notify_Email_2__c;
        project.Notify_Email_3__c = oli.Notify_Email_3__c;
        project.Affl_Sales_Rep__c = oli.Affl_Sales_Rep__c;
        project.Digital_Account_Manager__c = oli.Dig_Account_Manager__c;
        project.Email_Coordinator__c = oli.Email_Coordinator__c;
        project.Web_Coordinator__c = oli.Web_Coordinator__c;
        project.Dig_Project_Manager__c = oli.Dig_Project_Manager__c;
        project.Live_Date__c = oli.Live_Date__c;
        project.Media_Partner__c = oli.Media_Partner__c;
        project.Sell_Type__c = oli.Sell_Type__c;
        project.Invoice_CancelDate__c = oli.Invoice_CancelDate__c;
        project.Cancel_Entered_Date__c = oli.Cancel_Entered_Date__c;
        project.Invoice_ServiceStartDate__c = oli.Invoice_ServiceStartDate__c;
        project.Invoice_ServiceEndDate__c = oli.Invoice_ServiceEndDate__c;
        project.Qty_ContractMonths__c = oli.Qty_ContractMonths__c;
        project.UnitPrice__c = oli.UnitPrice;
        project.Invoice_Units__c = oli.Invoice_Units__c;
        project.Mgmt_Fee_Percent__c = oli.Mgmt_Fee_percent__c;
        project.Invoice_PriceVariable__c = oli.Invoice_PriceVariable__c;
        project.TotalMonthlyCharge__c = oli.Total_Monthly_Charge__c;
        project.Notes__c = oli.Notes__c;
        project.Waive_Fees__c = oli.Waive_Fees__c;
		project.Expiration_Date__c = oli.End_Of_Service_Date__c;
		project.Non_Renewal_Reason__c = oli.Non_Renewal_Reason__c;
		project.Non_Renewal_Details__c = oli.Non_Renewal_Details__c;
		project.TotalPrice__c = oli.TotalPrice;
		project.TM_Acct_ID__c = oli.TM_Acct_ID__c;
		project.TM_Opp_ID__c = oli.TM_Opp_ID__c;
		project.TM_OBFM_ID__c = oli.TM_OBFM_ID__c;
		project.Invoice_Order_Number__c = oli.Invoice_Order_Number__c;
		
        return project;
    }
    //This methods is called to insert records in to Opportunity_Product_History__c Object
    private void insertOrUpdateIntoOpportunityProductHistory(Map<Id, OpportunityLineItem> oldOpportunityLineItems, 
                                                        Map<Id, OpportunityLineItem> newOpportunityLineItems){
        // Adding Debug Info Logs to ApplicationLogs Object
        for (OpportunityLineItem oneOppLineItem: newOpportunityLineItems.Values()){
            String errorMsg = ' OLI ID: ' + oneOppLineItem.Id + 
                               '; Old status: ' + oldOpportunityLineItems.get(oneOppLineItem.Id).Waiting_Status__c + 
                               '; New Status: ' + oneOppLineItem.Waiting_Status__c ;
            ApplicationLogsModel.AddLogs(errorMsg, 'OpportunityLineItemAfterUpdateHandler.insertIntoOpportunityProductHistory, line 148', '148', 
                                            oneOppLineItem.ID, 'OpportunityLineItemAfterUpdateHandler', 'insertIntoOpportunityProductHistory', false, ApplicationLogsModel.Loglevel.Info);
        }
        
        if (ApplicationLogsModel.numUnCommittedLogs>0){
            ApplicationLogsModel.InsertLogList(); //Insert uncommitted logs
        }
        // Adding Debug Info Logs to ApplicationLogs Object
                                                                    
        List<Opportunity_Product_History__c> newListOppProdHistory = 
                    OpportunityLineItemServices.ManageStatusChange(newOpportunityLineItems.Values(), oldOpportunityLineItems);
        for(Opportunity_Product_History__c oneOppProdHistory :newListOppProdHistory){
            if(oneOppProdHistory.Id == null){
                this.sObjectsToInsert.add(oneOppProdHistory);
            }else{
                //These Opportunity Product History Objects are updated later by the trigger architecture framework
                this.addSObjectForUpdate(oneOppProdHistory.Id, oneOppProdHistory);
            }
        }
    }
    
    private void updateOpportunityFields(List<OpportunityLineItem> newOpportunityLineItems){
        for(OpportunityLineItem oneOppLineItem : newOpportunityLineItems){
             Opportunity updateOpportunity = (Opportunity)this.getReferenceToSobjectsToUpdateRecord(oneOppLineItem.OpportunityId);  
             Opportunity opp = OpportunityLineItemTriggerDispatcher.opportunityMap.get(oneOppLineItem.OpportunityId);   
             updateOpportunity.Product_List__c = OpportunityLineItemServices.formatOpportunityProductNames(opp.OpportunityLineItems);
        }    
    } 

    /* QUALTRICS: updateActiveOLI governs workflows that send outbound messages to Qualtrics to send out surveys
     * Update the Active OLI count on the Account & Opp when an OLI move into Live statuses or move out of Live statuses
     */
    Private void updateActiveOLI(Map<Id, OpportunityLineItem> oldOpportunityLineItems, 
                                 Map<Id, OpportunityLineItem> newOpportunityLineItems){

      // Live like Status map 
      Map<String, Product_SLA_Status__mdt> livestatusMap = new Map<String, Product_SLA_Status__mdt>();
      Map<String, Product_SLA_Status__mdt> nonLiveStatusMap = new Map<String, Product_SLA_Status__mdt>();
      List<Product_SLA_Status__mdt> StatusList = [select id, DeveloperName, MasterLabel, isGoLive__c from Product_SLA_Status__mdt];
      if(StatusList != null){
          for(Product_SLA_Status__mdt statusMdt : StatusList){
              if(statusMdt.isGoLive__c ==true){
                  livestatusMap.put(statusMdt.MasterLabel, statusMdt);
              }
              else if(statusMdt.isGoLive__c == false){
                  nonLiveStatusMap.put(statusMdt.MasterLabel, statusMdt);
              }
          }
      }
            

      // Construct the Map of Account Id and list of OLI's
      // Construct the Map of Opp Id and the list of OLI's 
      Map<Id, list<opportunityLineItem>> mapAccountOLIs = new Map<ID, list<opportunityLineItem>>();
      Map<Id, list<opportunityLineItem>> mapOppOLIs = new Map<ID, list<opportunityLineItem>>();                        
      

      // Compare OLIs before update to after update.
      // Has OLI status changed? 
      //  If yes, 
      //    mapAccountOLI : [ KEY : OLI.Account__c,    VALUE : empty OLI List ]
      //    mapOppOLIs    : [ KEY : OLI.OpportunityId, Value : empty OLI List ] 
      for(OpportunityLineItem oneOppLineItem : newOpportunityLineItems.Values()){
          
          if (oneOppLineItem.Waiting_Status__c != oldOpportunityLineItems.get(oneOppLineItem.Id).Waiting_Status__c 
              && oneOppLineItem.Account__c != null &&  oneOppLineItem.OpportunityId != null
                      && (livestatusMap.containsKey(oneOppLineItem.Waiting_Status__c)
                        || livestatusMap.containsKey(oldOpportunityLineItems.get(oneOppLineItem.Id).Waiting_Status__c)
                 )
             ) {

                  mapAccountOLIs.put(oneOppLineItem.Account__c,new List<opportunityLineItem>());
                  mapOppOLIs.put(oneOppLineItem.OpportunityId,new List<opportunityLineItem>());
                  system.debug('**************List of Accounts::-------------'+mapAccountOLIs.keySet());
                  system.debug('**************List of Opportunities::'+mapOppOLIs.keySet());
         }

      }


      // Query for OLI records that have Account__c value in mapAccountOLIs' key parameter and assign returned query to statChangedList.
            List<OpportunityLineItem> statChangedList = statusChangedOLIs(mapAccountOLIs);

      // Of the returned query, statChangedList, map the key value pairs. 
      //  mapAccountOLIs: [ KEY : OLI.Account__c, VALUE : Respective OLI with an active status]
            for(Opportunitylineitem OLI : statChangedList){

                if(mapAccountOLIs.containsKey(OLI.Account__c) && livestatusMap.containsKey(OLI.Waiting_Status__c)){
                    mapAccountOLIs.get(OLI.Account__c).add(OLI);
              }
      }
      system.debug('Accounts with Active OLIs::-------'+mapAccountOLIs.keySet());


      // Query for OLI records that have OpportunityId value in mapOppOLIs' key parameter.
      // Of the returned query, map the key value pairs.
      //   mapOppOLIs: [ KEY : OLI.OpportunityID, VALUE : Respective OLI with an active status]
      for(Opportunitylineitem OLI : [SELECT Id, Waiting_status__c, Account__c, OpportunityId 
                                     FROM OpportunityLineItem where OpportunityId  IN :mapOppOLIs.keySet()]){
          if(mapOppOLIs.containsKey(OLI.OpportunityId) && livestatusMap.containsKey(OLI.Waiting_Status__c)){
             mapOppOLIs.get(OLI.OpportunityId).add(OLI);
          }                     
      }
      system.debug('Opportunities with Active OLIs::-------'+mapAccountOLIs.keySet());

      //DEV-7583: Using OppIds in mapOppOLIs, do SOQL query on Opps to get value of Active_OLI_Count__c before Opp update
      List<Opportunity> opportunitiesToUpdate = [SELECT Id, Active_OLI_Count__c from Opportunity where Id IN :mapOppOLIs.keySet()];
      Map<Id, Opportunity> mapOppsToUpdate = new Map<Id, Opportunity>(opportunitiesToUpdate);

      // Compare OLIs before update to after update.
      // Has OLI status changed? 
      //  If yes, 
      //    Assign the OLIs' related Account and Opportunity to newAccount and newOpp objects respectively
      //    AND update  Active_OLI_Count__c on Account and Opp record
      for(OpportunityLineItem oneOppLineItem : newOpportunityLineItems.Values()){
         
          if(oneOppLineItem.Waiting_Status__c != oldOpportunityLineItems.get(oneOppLineItem.Id).Waiting_Status__c 
             && oneOppLineItem.Account__c != null && oneOppLineItem.OpportunityId != null) {
                
              Account newAccount =(Account)this.getReferenceToSobjectsToUpdateRecord(oneOppLineItem.Account__c);
              Opportunity newOpp =(Opportunity)this.getReferenceToSobjectsToUpdateRecord(oneOppLineItem.OpportunityId);
                
              //update the Last Live Date field when an OLI moves to Live status
                        if(oneOppLineItem.Waiting_Status__c == constants.OLI_STAGE_LIVE){
                  newAccount.Last_Live_Date_1__c = datetime.now();
              }
                        //Update the Last Blast Date when an OLI moves to Fulfilled Complete status <comment: Is this okay?>
                else if(oneOppLineItem.Waiting_Status__c == constants.OLI_STAGE_FULFILLED_COMPLETE){
                            newAccount.Last_Blast_Date_1__c = datetime.now();
              }

             Boolean nonlive2Live = livestatusMap.containsKey(oneOppLineItem.Waiting_Status__c) && 
                                    nonLivestatusMap.containsKey(oldOpportunityLineItems.get(oneOppLineItem.Id).Waiting_Status__c);
          
             Boolean live2Nonlive = nonLivestatusMap.containsKey(oneOppLineItem.Waiting_Status__c) &&
                                    livestatusMap.containsKey(oldOpportunityLineItems.get(oneOppLineItem.Id).Waiting_Status__c);

             ID oppIDofOLI = oneOppLineItem.OpportunityId; 
             Integer activeOLICountSize;

             //If OLI status changed from live to non-live OR non-live to live, assign Active_OLI_Count__c on related Account and Opp record
             if(live2Nonlive || nonlive2Live) {

                if(mapAccountOLIs.get(oneOppLineItem.Account__c).size()>0){
                   newAccount.Active_OLI_Count__c = mapAccountOLIs.get(oneOppLineItem.Account__c).size();
                }
                  
                activeOLICountSize         = mapOppOLIs.get(oppIDofOLI).size();   
                newOpp.Active_OLI_Count__c = activeOLICountSize;
             }

             //DEV-7583: Identify Product that triggered Qualtrics Survey
             if(activeOLICountSize != null && activeOLICountSize == 1 && mapOppsToUpdate.get(oppIDofOLI).Active_OLI_Count__c == 0) {
                newOpp.OLI_To_Trigger_Qualtrics_Channel_Survey__c = oneOppLineItem.Product_Name__c;
                
			if(OpportunityLineItemTriggerDispatcher.oliIdWithProductValues != null
				 && OpportunityLineItemTriggerDispatcher.oliIdWithProductValues.get(oneOppLineItem.Id)!=null
				 && OpportunityLineItemTriggerDispatcher.oliIdWithProductValues.get(oneOppLineItem.Id).Product2.Send_Onboard_Survey_Only__c == true){
                 newOpp.CSAT_Survey_Sent__c = true;
                 newOpp.First_Loyalty_Survey_Sent__c = true;
                 newOpp.Loyalty_Survey_Sent__c = true;
                }
             }

          }
      }
  }
  
  /* QUALTRICS: defector count used to for Qualtrics
   * Update the Defector counter on the Account when an OLI move into Defector statuses 
   */
  Private void updateDefectorCount(Map<Id, OpportunityLineItem> oldOpportunityLineItems, 
                                     Map<Id, OpportunityLineItem> newOpportunityLineItems){

            //dstatMap = Defector Statuses map; nondstatMap = Non-Defector Statuses map
            Map<String, Product_SLA_Status__mdt> dstatMap = new Map<String, Product_SLA_Status__mdt>();
            Map<String, Product_SLA_Status__mdt> nondstatMap = new Map<String, Product_SLA_Status__mdt>();
            List<Product_SLA_Status__mdt> statusList = [select id, DeveloperName, MasterLabel, isDefector__c 
                                                        from Product_SLA_Status__mdt];
            if(statusList != null){
                for(Product_SLA_Status__mdt statusMdt : statusList){
                    if(statusMdt.isDefector__c == true){
                      dstatMap.put(statusMdt.MasterLabel, statusMdt);  
                    }
                    else if(statusMdt.isDefector__c == false){
                      nondstatMap.put(statusMdt.MasterLabel, statusMdt);  
                    }
                    
                }
            }
            //Map of Accounts with related OLI's who's OLIs do not have a defector type status
            Map<Id, list<opportunityLineItem>> mapAccountOLIs = new Map<ID, list<opportunityLineItem>>();
            for(OpportunityLineItem oneOppLineItem : newOpportunityLineItems.Values()){
                if (oneOppLineItem.Waiting_Status__c != oldOpportunityLineItems.get(oneOppLineItem.Id).Waiting_Status__c 
                    && oneOppLineItem.Account__c != null && dstatMap.containsKey(oneOppLineItem.Waiting_Status__c))
                mapAccountOLIs.put(oneOppLineItem.Account__c,new List<opportunityLineItem>());
            }
                List<OpportunityLineItem> statChangedList = statusChangedOLIs(mapAccountOLIs);
                for(Opportunitylineitem OLI : statchangedList){
                    if(mapAccountOLIs.containsKey(OLI.Account__c) && nondstatMap.containsKey(OLI.Waiting_Status__c)){
                        mapAccountOLIs.get(OLI.Account__c).add(OLI);
                    }  
                }

       //Update account's defector count if the account has had one or more OLIs go into a defector status.
       for(OpportunityLineItem oneOppLineItem : newOpportunityLineItems.Values()){
          if (oneOppLineItem.Waiting_Status__c != oldOpportunityLineItems.get(oneOppLineItem.Id).Waiting_Status__c 
          && oneOppLineItem.Account__c != null && dstatMap.containsKey(oneOppLineItem.Waiting_Status__c)){
              Account newAccount =(Account)this.getReferenceToSobjectsToUpdateRecord(oneOppLineItem.Account__c);
                                newAccount.Defector_Counter__c = mapAccountOLIs.get(oneOppLineItem.Account__c).size();
          }

       }                                  
    }
    /* QUALTRICS: Used to get OLIs relating to specific accounts.
     * To get all OLI's related to the Account 
     */
    private list<opportunityLineItem> statusChangedOLIs(Map<Id, list<opportunityLineItem>> acctOLIMap){
           Map<Id, list<opportunityLineItem>> mapAccountOLIs = acctOLIMap;
            list<opportunityLineItem> statuschangedList = [SELECT Id,Waiting_status__c, Account__c FROM OpportunityLineItem where Account__c IN :mapAccountOLIs.keySet()];
                return statuschangedList;
    }
    
    /*this method sends email to affl sales rep and media partner contacts when OLI moved to Cancel/KILL/FNR statuses*/
    //DEV-4973
    private void sendCancelKillFNREmails(Map<Id,OpportunityLineItem> newOliMap , Map<Id,OpportunityLineItem> oldOliMap){
        Map<Id,Contact> contactMap = New Map<Id,Contact>();
        for(Contact cnt : OpportunityLineItemTriggerDispatcher.contactList){
            //even though this condition is added in query still checking here to not to fail in future 
            if(cnt.Auto_Email_Status_Alert_Option__c){
                contactMap.put(cnt.Id, cnt); //contact map with Auto Email - Status Alert Option checked
            }   
        }
        Map<Id,OpportunityLineItem> oliMap = New Map<Id,OpportunityLineItem>();
        Set<Id> userIds = New Set<Id>();
        for(OpportunityLineItem newOLI : newOliMap.values()){
            OpportunityLineItem oldOLI = oldOliMap.get(newOLI.Id);//get before update OLI
            //check whether OLI is updated to Cancel/KILL/FNR statuses
            if(newOLI.Waiting_Status__c != oldOLI.Waiting_Status__c && OpportunityLineItemTriggerDispatcher.opportunityMap.get(newOLI.OpportunityId).Opportunity_IsReplicated__c == false &&
			  OpportunityLineItemTriggerDispatcher.statusMap.containsKey(newOLI.Waiting_Status__c) &&
              OpportunityLineItemTriggerDispatcher.statusMap.get(newOLI.Waiting_Status__c).isEmailEnabled__c){
                 oliMap.put(newOLI.Id,newOLI) ;
                 userIds.add(OpportunityLineItemTriggerDispatcher.opportunityMap.get(newOLI.OpportunityId).OwnerId);
            }
        }
        if(!oliMap.isEmpty()){
            Map<Id,User> userMap = New Map<Id,User>([select id,name,Email from user where ID IN : userIds]);
            OpportunityLineItemTriggerHelper.sendEmail(oliMap,contactMap,OpportunityLineItemTriggerDispatcher.emailTemplateMap.get(OpportunityLineItemTriggerHelper.TEMPLATE_OLI_CANCEL_KILL_FNR).Id,userMap);//send the email
        }
    }
    
     public void getFieldChanges(List<OpportunityLineItem> newOliList, Map<Id, OpportunityLineItem> oldOliMap){
           
        for(OpportunityLineItem oli :newOliList){
            OpportunityLineItem oldOli = oldOliMap.get(oli.Id);
            List<String> fieldNameList = new List<String>(OpportunityLineItemTriggerDispatcher.fieldAuditMap.keySet());
            for (String str : fieldNameList) {
                //system.debug('------------------------------------OpportunityLineItemAfterUpdateHandler-str-' + str);
                try { 
                    //if keeping history and field have changed
                    if(oli.get(str) != oldOli.get(str)){ 
                       //system.debug('------------------------------------OpportunityLineItemAfterUpdateHandler-found diff-str-' + str); 
                       OpportunityLineItem_History_Detail__c oliHd = new OpportunityLineItem_History_Detail__c();
                       Boolean isCurrency = OpportunityLineItemTriggerDispatcher.fieldAuditMap.get(str).isCurrencyField__c;
                       oliHd.Action__c = formatActionString(OpportunityLineItemTriggerDispatcher.fieldAuditMap.get(str).MasterLabel, 
                                           String.valueOf(oldOli.get(str)), String.valueOf(oli.get(str)), isCurrency);
                       oliHd.Date__c = System.now();
                       oliHd.OpportunityLineItem_Id__c = oli.Id;
                       oliHd.User__c = UserInfo.getUserId();
                       sObjectsToInsert.add((sObject)oliHd);
                       //system.debug('------------------------------------OpportunityLineItemAfterUpdateHandler-added ti sobj-' + str); 
                    }
                } catch (Exception e) { 
                    System.debug('OpportunityLineItemAfterUpdateHandler.getFieldChanges Error: ' + e); } 
        } 
        }
    }
    
    public static String formatActionString(String fieldName, String oldValue, String newValue, Boolean isCurrency){
        if(isCurrency && oldValue != null) 
           try {
            oldValue = StringFormatter.formatCurrencyField(oldValue);
           } catch (Exception E) {
               oldValue = '$'+oldValue;
           }    
        if(isCurrency && newValue != null)
           try {
           	newValue = StringFormatter.formatCurrencyField(newValue);
           } catch (Exception E) {
           		newValue = '$'+newValue;    
           }    
 
        String rtnString = 'Changed ';
        
        if(oldValue == null && newValue != null)
            rtnString = rtnString  + fieldName + ' to ' + newValue + '.';
        else if(oldValue != null && newValue == null)
            rtnString = rtnString  + fieldName + ' from ' + oldValue + '.'; 
        else if(oldValue != null && newValue != null)
            rtnString = rtnString  + fieldName + ' from ' + oldValue + ' to ' + newValue + '.'; 
        return rtnString;    
    }
    
    
    //Need to roll up a formula field which is referring Project__c object. We cannot achieve this through standard rollup.
    private void RollupManager(Map<Id,OpportunityLineItem> newMap, Map<Id,OpportunityLineItem> oldMap){
        List<OpportunityLineItem> OLIs = New List<OpportunityLineItem>();
        for(OpportunityLineItem newOLI : newMap.values()){
            OpportunityLineItem oldOLI = oldMap.get(newOLI.Id);
            if(newOLI.Waiting_Status__c != oldOLI.Waiting_Status__c || 
              newOLI.Current_Product_Value_VB__c != oldOLI.Current_Product_Value_VB__c ){
                OLIs.add(newOLI);
            }
        }
        
            
        if(!OLIs.isEmpty()){
            LREngine.Context ctx = new LREngine.Context(Opportunity.SobjectType, // parent object
                                                OpportunityLineItem.SobjectType,  // child object
                                                Schema.SObjectType.OpportunityLineItem.fields.OpportunityId // relationship field name
                                                
                                                       );
            ctx.add(
                new LREngine.RollupSummaryField(
                                                Schema.SObjectType.Opportunity.fields.OpportunityCurrentContractValue__c,
                                                Schema.SObjectType.OpportunityLineItem.fields.Current_Product_Value_VB__c,
                                                LREngine.RollupOperation.SUM 
                                             )); 
            
           Sobject[] masters = LREngine.rollUp(ctx, OLIs);
		   if(masters != null && !masters.isEmpty()){
               for(Opportunity updOpp :(List<Opportunity>)masters){
                   Opportunity opp = (Opportunity)this.getReferenceToSobjectsToUpdateRecord(updOpp.Id);
                   opp.OpportunityCurrentContractValue__c = updOpp.OpportunityCurrentContractValue__c;
               }
           }
           //this.sObjectsToUpdate.putAll(masters); - this overrides all prev changes to opportunity - not good
       }
    }
	
	 // Project Blue DEV-9624
    private void createCampaignProfileRecord(Map<Id, OpportunityLineItem> oldOLImap, Map<Id,OpportunityLineItem> newOLImap){
        for(OpportunityLineItem newOLI : newOLImap.values()){

            OpportunityLineItem oldOLI = oldOLImap.get(newOLI.Id);

            //Determine if okay to create Campaign Profile
            if(createCampaignProfile(newOli) == true &&
                newOLI.Waiting_Status__c == Constants.OLI_STAGE_CLOSED_WON && oldOLI.Waiting_Status__c != Constants.OLI_STAGE_CLOSED_WON && 
                OpportunityLineItemTriggerDispatcher.oliIdWithProductValues.get(newOLI.Id).Product2.Create_Campaign_Profile__c == true) {
     		  //Create the new Campaign Profile and assign it values
                if(OpportunityLineItemTriggerDispatcher.sellTypeToCreateCP.contains(newOLI.Sell_Type__c)){
                      Campaign_Profile__c newCampaignProfileRecord = new Campaign_Profile__c();
                      //define objects here that are used to populate fields on the new Campaign Profile
                      String campaignType = OpportunityLineItemTriggerDispatcher.oliIdWithProductValues.get(newOLI.Id).Product2.Campaign_Type__c;
                      Id cpRecordTypeID = CampaignProfileCache.getRecordType(campaignType).Id;
                      String oli_Acc_fk_API = OpportunityLineItemTriggerDispatcher.OLI_ACC_FK_API;
                      String oli_Opp_fk_API = OpportunityLineItemTriggerDispatcher.OLI_OPP_FK_API;
                      Set<String> acc_fk_set = OpportunityLineItemTriggerDispatcher.fk_IDsMap.get(oli_Acc_fk_API);
                      Set<String> opp_fk_set = OpportunityLineItemTriggerDispatcher.fk_IDsMap.get(oli_Opp_fk_API);
                      
                        
                      if(acc_fk_set != null && !acc_fk_set.isEmpty()){
                      	
                        Account relatedAccount = 
                          OpportunityLineItemTriggerDispatcher.getRelatedAccounts(acc_fk_set).get(newOLI.Account__c);
                             
                        if(relatedAccount.Tier__c != null) newCampaignProfileRecord.Account_Tier__c = relatedAccount.Tier__c;
                      	if(relatedAccount.Account_Primary_Industry__c != null)
                        newCampaignProfileRecord.Account_Primary_Industry__c = relatedAccount.Account_Primary_Industry__c;
                        //DEV-13654 mapped the Account's Account Primary Focus field with Campaign Profile's Customer Primary Focus field
                        if(relatedAccount.Account_Primary_Focus__c!= null)
                        newCampaignProfileRecord.Customer_Primary_Focus__c = relatedAccount.Account_Primary_Focus__c;                        
                       }
                        
                      //newOLI.Name returns null value, so need to retrieve name from dispatcher.
                      String cpName = newOLI.AccountAsText__c  + ' - ' + OpportunityLineItemTriggerDispatcher.oliIdWithProductValues.get(newOLI.Id).Product2.Name;
                      newCampaignProfileRecord.Campaign_Profile_Name__c = StringFormatter.autoTruncate(cpName);
                      newCampaignProfileRecord.Client_Name__c = newOLI.Account__c;
        		      newCampaignProfileRecord.Opportunity_Product_ID__c = newOLI.Id;
                      newCampaignProfileRecord.ProductName__c = OpportunityLineItemTriggerDispatcher.oliIdWithProductValues.get(newOLI.Id).Product2.Name; //DEV-9990                
                      newCampaignProfileRecord.Affl_Sales_Rep__c = OpportunityLineItemTriggerDispatcher.oliIdWithProductValues.get(newOLI.Id).Affl_Sales_Rep__r.Name; //DEV-12246
                      newCampaignProfileRecord.Affl_Sales_Rep_Email__c = OpportunityLineItemTriggerDispatcher.oliIdWithProductValues.get(newOLI.Id).Affl_Sales_Rep__r.Email; //DEV-12246
                      //DEV-10450
                      newCampaignProfileRecord.Contract_Length_Months__c = newOLI.Qty_ContractMonths__c ; 
					  //DEV-13200
					  newCampaignProfileRecord.Notify_Email_1__c = OpportunityLineItemTriggerDispatcher.opportunityMap.get(newOLI.OpportunityId).Notify_Email_1__c;
					  newCampaignProfileRecord.Notify_Email_2__c = OpportunityLineItemTriggerDispatcher.opportunityMap.get(newOLI.OpportunityId).Notify_Email_2__c;
					  newCampaignProfileRecord.Notify_Email_3__c = OpportunityLineItemTriggerDispatcher.opportunityMap.get(newOLI.OpportunityId).Notify_Email_3__c;
                      //DEV-11991
                      newCampaignProfileRecord.OLI_Duration__c = newOLI.Qty_ContractMonths__c ;
                      newCampaignProfileRecord.Current_Product_Value__c = newOLI.Current_Product_Value_VB__c ;
                      newCampaignProfileRecord.Package__c = newOli.Package__c;
                      if(campaignType != null ) newCampaignProfileRecord.Campaign_Type__c = campaignType;
                      if(cpRecordTypeID != null) newCampaignProfileRecord.RecordTypeId = cpRecordTypeID;
                      
                      //DEV-11383 - put ID of latest submitted OBFM that is related to OLI's Opp
                      if(opp_fk_set != null && !opp_fk_set.isEmpty()){
                             
                      	OnBoardFormModel__c[] relatedOBFMS = OpportunityLineItemTriggerDispatcher.getOppID2obfmsMap(opp_fk_set).get(newOLI.OpportunityId);
                        
                        if(relatedOBFMS != null && relatedOBFMS.size()>0){
                             	
                        	newCampaignProfileRecord.OnboardForm_Model__c = relatedOBFMS[0].ID;
                             
                      	}
                      }  
                      //DEV-10939
					  //Commented as per DEV-13614.
                      //if(newOLI.CPV__c != null) newCampaignProfileRecord.CPV__c = newOLI.CPV__c;
                      //DEV-12210 
                      if(newOLI.Marketing_Campaign__c != null) newCampaignProfileRecord.Marketing_Campaign__c = newOLI.Marketing_Campaign__c;
                      //DEV-14748
                      newCampaignProfileRecord.Project__c = newOLI.Project__c;
                        
                      sObjectsToInsert.add((sObject)newCampaignProfileRecord);
                } else {
                    //do not create new campaign profile - update existing one - only if found
                    updateCampaignProfile(newOli);
                }
            }
        }
    }
    
    
    private Boolean createCampaignProfile(OpportunityLineItem oli){
        
        Boolean create = true;
         if(OpportunityLineItemTriggerDispatcher.relatedCentralCampaignProfiles != null && !OpportunityLineItemTriggerDispatcher.relatedCentralCampaignProfiles.isEmpty()){
            for(Campaign_Profile__c cp : OpportunityLineItemTriggerDispatcher.relatedCentralCampaignProfiles.values()){
                //found campaign profile - do not create another one.
                if(cp.Opportunity_Product_ID__c == oli.Id)
                    create = false;  
            }
         }     
        return create;
    } 
    private void updateCampaignProfile(OpportunityLineItem oli){
         if(OpportunityLineItemTriggerDispatcher.relatedCentralCampaignProfiles != null && !OpportunityLineItemTriggerDispatcher.relatedCentralCampaignProfiles.isEmpty()){
            for(Campaign_Profile__c cp : OpportunityLineItemTriggerDispatcher.relatedCentralCampaignProfiles.values()){
                //found campaign profile to update based on Original Related OLI
                if(cp.Opportunity_Product_ID__c == oli.Original_Related_OLI__c){
                    Campaign_Profile__c cp2update = (Campaign_Profile__c)this.getReferenceToSobjectsToUpdateRecord(cp.Id);
                    cp2Update.Related_OLI__c = oli.Related_OLI__c;
                    cp2Update.OLI_ID__c = oli.Id;
                    //DEV-14748
                    cp2Update.Project__c = oli.Project__c;
                }
            }
         }     
    } 
    
    private void updateCentralCampaignProfiles(Map<Id, OpportunityLineItem> oldOLImap, Map<Id,OpportunityLineItem> newOLImap){
       //Sanity check to see if relatedCentralCampaignProfiles has been populated
       if(OpportunityLineItemTriggerDispatcher.relatedCentralCampaignProfiles != null && !OpportunityLineItemTriggerDispatcher.relatedCentralCampaignProfiles.isEmpty()){
           //Loop through all central campaign profiles
           for(Campaign_Profile__c centralCP : OpportunityLineItemTriggerDispatcher.relatedCentralCampaignProfiles.values()){
              //sanity check
              if(newOLImap.containsKey(centralCP.Opportunity_Product_ID__c)){
                  //DEV-12210 >> if Marketing_Campaign__c value changed, update related Central Campaign Profile
                  if(oldOLImap.get(centralCP.Opportunity_Product_ID__c).Marketing_Campaign__c != newOLImap.get(centralCP.Opportunity_Product_ID__c).Marketing_Campaign__c){
                    Campaign_Profile__c cp2update = (Campaign_Profile__c)this.getReferenceToSobjectsToUpdateRecord(centralCP.ID);
					cp2update.Marketing_Campaign__c = newOLImap.get(centralCP.Opportunity_Product_ID__c).Marketing_Campaign__c;
				  }
			  }
           }
       }
    }
}