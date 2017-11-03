/* 
This class is used by OnBoardForm.Page.  This is an intake form that the salesrep fills.  This form has about 200++ fields on the page
All the fields are not displayed upfront. However, depending on the selection criteria the intake fields are visible/hidden on the UI accordingly.

TODO:  UI design is not intutive and we are following the existing page design. We need to revisit the design aspect of site forms.
*/

/**
       
    Last Modified by : Paul Juneau
    Date             : 6/7/2016

*/
public without sharing class OnBoardFormControllerExt {

    public OnBoardFormModel__c newOnBoardFormModel {get; set;}  
    public String selectSubmitType {get;set;}
    public String includenotify {get;set;} 
    public String includeClientInfo {get; set;}
    public String includerepdash {get;set;}
    public string showPreviousAddress{get;set;}
    public Contact newContact {get; set;}
    public List<Contact> contactList {get; set;}
    public RecordType rt {get; set;}
    public String saveContactId {get; set;}
   
    public String sessionId {get; set;}
    public String searchString {get; set;}
    public String errorMessage {get; set;}
    public String Message {get; set;}
    public String contactName {get; set;}
     //contants so it's not hardcoded 10 times everywhere
    public final String strNotInList = 'Not In List';
    public final String strChoseOne = '--Choose One--';
    public final String strSearchRep = 'Search for Sales Rep';
     //error messages - will put here for now
    public final String errNoSearchValue = 'Please enter value to search';
    public final String errSearchValue2char = 'Search value must be at least 2 char';
    public final String errNoContactsFound = 'No contacts found. Select \'Not In List\' to create a new contact';
    
    public List<SelectOption> ContactNames{get;set;}
    public List<SelectOption> mediaPartnerList{get; set;} //DEV-6940
    public Boolean boolShowContacts {get;set;}
    public Map<Integer, String> ppcBudgetFieldsMap{get; set;} //DEV-8585.
    public Map<Integer, String> socAdBudgetFieldsMap{get; set;} //DEV-8584
    
    public Map<String, Contact> contactMap = new Map<String, Contact>();
    
    //Excluding ClipperPartnerType, CLP, as per requirements of Sprint 2.16.12, Story DEV-5252, "Inactivate Clipper Partner companies"
    public static final String ClipperPartnerType = 'CLP';
	public static final String RLPartnerType = 'RL';
	public static final String GannetPartnerType = 'GNT';
    //DEV-5253
    public Boolean isContractRequired{get;set;}
    public Set<Id> goDigitalcontractIds = new Set<Id>();
    public Boolean hasOppId{get;set;} 
    public Boolean emailOnly{get;set;} 
    public Boolean optEmailOnly{get;set;} 
    public Id oppId{get;set;}
    public String rlEmail{get;set;}
    private final OnBoardFormModel__c webOnBoardFormModel;
    public AccountContactRole cont {get; set;}
    public Boolean isValid = true;
    public String primaryIndustryError = 'The Company attributed to this Onboard Form is missing Primary Industry information. Please update the Company record and resubmit the Onboard Form.';
    public String primaryFocusError = 'The Company attributed to this Onboard Form is missing Primary Focus information. Please update the Company record and resubmit the Onboard Form.';
    public String mediaPartnerError = 'The Company attributed to this Onboard Form is missing Media Partner information. Please update the Company record and resubmit the Onboard Form.';
    public String webAddressError1 = 'The Company attributed to this Onboard Form is missing Website information. Please update the Company record and resubmit the Onboard Form.';
    public String webAddressError2 = 'The Company attributed to this Onboard Form has invalid Website information (Website must be in https://website.com OR http://website.com format). ' + 
                                        'Please update the Company record and resubmit the Onboard Form.';
    public String phoneError = 'The Company attributed to this Onboard Form is missing or has invalid Phone. (Phone must be in (999) 999-9999 format).' + 
                                    'Please update the Company record and resubmit the Onboard Form.';
    public String nameError = 'The Company attributed to this Onboard Form is missing Name. Please update the Company record and resubmit the Onboard Form.';
    public String streetError = 'The Company attributed to this Onboard Form is missing Billing Street. Please update the Company record and resubmit the Onboard Form.';
    public String cityError = 'The Company attributed to this Onboard Form is missing Billing City. Please update the Company record and resubmit the Onboard Form.';
    public String postalError1 = 'The Company attributed to this Onboard Form is missing Postal Code. Please update the Company record and resubmit the Onboard Form.';
    public String postalError2 = 'The Company attributed to this Onboard Form has invalid Postal Code information (Postal Code must be in 99999 or 99999-9999 format). ' + 
                                        'Please update the Company record and resubmit the Onboard Form.';
                                        
//DEV-8915
    public Set<String> deactivatePartnerMarket; 
    
    //SEO Budget Map
    public static final Map<String, integer> SEO_BUDGET_BY_SEO_PACKAGE = new Map<String, integer> { 
         'Tier 1' => 7500,
         'Tier 2'=> 4999,
         'Tier 3'=> 2499,
         'Tier 4'=> 999
    };
    
    //SEO Budget Map
    public static final Map<String, integer> SOCIAL_BUDGET_BY_MGMT_OPTIONS = new Map<String, integer> { 
         'Social Management Launch' => 999,
         'Social Management Engage'=> 1699,
         'Social Management Expand'=> 2999,
         'Social Media Weekend Coverage'=> 1200
    };
    
        
    public PageReference searchContacts(){
          boolShowContacts = false;
          errorMessage = validateString(searchString);
          List<Contact> contList;
         
          if(contactList == null){
              contactList = new List<Contact>();
          } else {
              contactList.clear();
          }
          //String strX = ApexPages.currentPage().getParameters().get('sessionId');
          //System.debug('------------------------ session id--' + sessionId);
          if (errorMessage == null){
              ContactNames.clear();
              
          ContactNames.add(new SelectOption(strChoseOne, strChoseOne));
          ContactNames.add(new SelectOption(strNotInList, strNotInList)); 
              contactName = strChoseOne;
              if(emailOnly == true)
                contactList = searchContactsRl(searchString);
              else
                contactList = DigitalFormUtil.searchContacts(searchString);
              if (!contactList.isEmpty()){
                    for (Contact cnt : contactList){  
                         if(cnt.Account.Name != null){
                            ContactNames.add(new SelectOption(cnt.Name + ' - ' + cnt.Account.Name, cnt.Name + ' - ' + cnt.Account.Name));  
                                 contactMap.put(cnt.Name + ' - ' + cnt.Account.Name, cnt);
                                } else {
                                 ContactNames.add(new SelectOption(cnt.Name, cnt.Name)); 
                                contactMap.put(cnt.Name, cnt); 
                            }
                 
                            }
                  
              } else {
                 errorMessage = errNoContactsFound;
              }
              
          }
          
          return null;
      }
      
      public Void getContact(){
           
          
          if(contactName == strChoseOne ){
              boolShowContacts = false;
          }else{
              if(contactName == strNotInList){
                  
              Message = 'Sales Rep will be saved with the following information';
                   newContact = new Contact();
                  saveContactId = null; 
              }  else{
              Message = 'Sales Rep will be saved with Selected Media Partner. If you need to create new Sales Rep select \'Not In List\'';
                  newContact = contactMap.get(contactName);
                   saveContactId = newContact.Id;
                   newContact.Id = null;
          }  
            boolShowContacts = true;   
          } 
        
          
           
      }
      public String validateString(String str){
      //just check for null string and should be 2 char or more
          String err = null;
          if (str == null){
              err = errNoSearchValue;
          } else if (str.length() < 2) {
              err = errSearchValue2char;  
          }
          return err;
      }
    
    public void resetDefaultBusinessHours(){
        if(this.webOnBoardFormModel.Current_Customer__c == false){
            this.webOnBoardFormModel.Sunday_Start_Hour__c ='00';
            this.webOnBoardFormModel.Sunday_Start_Min__c ='00';
            this.webOnBoardFormModel.Sunday_End_Hour__c ='23';
            this.webOnBoardFormModel.Sunday_End_Min__c ='45';
            this.webOnBoardFormModel.Monday_Start_Hour__c ='00';
            this.webOnBoardFormModel.Monday_Start_Min__c ='00';
            this.webOnBoardFormModel.Monday_End_Hour__c ='23';
            this.webOnBoardFormModel.Monday_End_Min__c ='45';
            this.webOnBoardFormModel.Tuesday_Start_Hour__c ='00';
            this.webOnBoardFormModel.Tuesday_Start_Min__c ='00';
            this.webOnBoardFormModel.Tuesday_End_Hour__c ='23';
            this.webOnBoardFormModel.Tuesday_End_Min__c ='45';
            this.webOnBoardFormModel.Wednesday_Start_Hour__c ='00';
            this.webOnBoardFormModel.Wednesday_Start_Min__c ='00';
            this.webOnBoardFormModel.Wednesday_End_Hour__c ='23';
            this.webOnBoardFormModel.Wednesday_End_Min__c ='45';
            this.webOnBoardFormModel.Thursday_Start_Hour__c ='00';
            this.webOnBoardFormModel.Thursday_Start_Min__c ='00';
            this.webOnBoardFormModel.Thursday_End_Hour__c ='23';
            this.webOnBoardFormModel.Thursday_End_Min__c ='45';
            this.webOnBoardFormModel.Friday_Start_Hour__c ='00';
            this.webOnBoardFormModel.Friday_Start_Min__c ='00';
            this.webOnBoardFormModel.Friday_End_Hour__c ='23';
            this.webOnBoardFormModel.Friday_End_Min__c ='45';
            this.webOnBoardFormModel.Saturday_Start_Hour__c ='00';
            this.webOnBoardFormModel.Saturday_Start_Min__c ='00';
            this.webOnBoardFormModel.Saturday_End_Hour__c ='23';
            this.webOnBoardFormModel.Saturday_End_Min__c ='45';

        }
    }
    
    
    //setdefaultbusinesshoursmins
    public void setdefaultbusinesshoursmins(){
        if(this.webOnBoardFormModel.Sunday_Closed__c){
            this.webOnBoardFormModel.Sunday_Start_Hour__c ='00';
            this.webOnBoardFormModel.Sunday_Start_Min__c ='00';
            this.webOnBoardFormModel.Sunday_End_Hour__c ='00';
            this.webOnBoardFormModel.Sunday_End_Min__c ='00';
        }
        if(this.webOnBoardFormModel.Monday_Closed__c){
            this.webOnBoardFormModel.Monday_Start_Hour__c ='00';
            this.webOnBoardFormModel.Monday_Start_Min__c ='00';
            this.webOnBoardFormModel.Monday_End_Hour__c ='00';
            this.webOnBoardFormModel.Monday_End_Min__c ='00';
        }
        if(this.webOnBoardFormModel.Tuesday_Closed__c){
            this.webOnBoardFormModel.Tuesday_Start_Hour__c ='00';
            this.webOnBoardFormModel.Tuesday_Start_Min__c ='00';
            this.webOnBoardFormModel.Tuesday_End_Hour__c ='00';
            this.webOnBoardFormModel.Tuesday_End_Min__c ='00';
        }
        if(this.webOnBoardFormModel.Wednesday_Closed__c){
            this.webOnBoardFormModel.Wednesday_Start_Hour__c ='00';
            this.webOnBoardFormModel.Wednesday_Start_Min__c ='00';
            this.webOnBoardFormModel.Wednesday_End_Hour__c ='00';
            this.webOnBoardFormModel.Wednesday_End_Min__c ='00';
        }
        if(this.webOnBoardFormModel.Thursday_Closed__c){
            this.webOnBoardFormModel.Thursday_Start_Hour__c ='00';
            this.webOnBoardFormModel.Thursday_Start_Min__c ='00';
            this.webOnBoardFormModel.Thursday_End_Hour__c ='00';
            this.webOnBoardFormModel.Thursday_End_Min__c ='00';
        }
        if(this.webOnBoardFormModel.Friday_Closed__c){
            this.webOnBoardFormModel.Friday_Start_Hour__c ='00';
            this.webOnBoardFormModel.Friday_Start_Min__c ='00';
            this.webOnBoardFormModel.Friday_End_Hour__c ='00';
            this.webOnBoardFormModel.Friday_End_Min__c ='00';
        }
        if(this.webOnBoardFormModel.Saturday_Closed__c){
            this.webOnBoardFormModel.Saturday_Start_Hour__c ='00';
            this.webOnBoardFormModel.Saturday_Start_Min__c ='00';
            this.webOnBoardFormModel.Saturday_End_Hour__c ='00';
            this.webOnBoardFormModel.Saturday_End_Min__c ='00';
        }
    }
    
    public boolean hasIndustryPicklistChanged{
       get;
       set;
    }      
    
    public String selectedIndustryId {
        get
        { 
            if( selectedIndustryId == NULL ) 
                selectedIndustryId = NONE; 
            return selectedIndustryId; 
        }
        set{
            if(selectedIndustryId<>value){
                this.hasIndustryPicklistChanged = true;
            }
            selectedIndustryId = value;
        }
    }
    
    public String selectedIndustryFocusId{
        get
        { 
            if( selectedIndustryFocusId == NULL ) 
                selectedIndustryFocusId = NONE; 
            return selectedIndustryFocusId; 
        }
        set;
    }
    
    public String selectedSalesRepLetter
    {
        get
        { 
            if( selectedSalesRepLetter == NULL ) 
                selectedSalesRepLetter = '-'; 
            return selectedSalesRepLetter; 
        }
        set;
    }
    
    //Formula for SEO Budget depending on Selected SEO Package
    public void seoFormulaBudget(){ 
        //Disabled = true/false
        //Determining the $ amount
        if(this.webOnBoardFormModel.Brand_Building__c){
            if(SEO_BUDGET_BY_SEO_PACKAGE.get(this.webOnBoardFormModel.SEO_Package__c)<>null){
                this.webOnBoardFormModel.SEO_Budget__c = SEO_BUDGET_BY_SEO_PACKAGE.get(this.webOnBoardFormModel.SEO_Package__c);
            }else{
                this.webOnBoardFormModel.SEO_Budget__c = null;
            }
        }
    }
    
    //Total Budget Formula for Retargeting Section
    public String siteBudget{get;set;}
    public String searchBudget{get;set;}
    public void totalBudgetCalculate() {
        if(this.webOnBoardFormModel.GOO_Retargeting__c){
            if( (String.isNotEmpty(siteBudget) && !siteBudget.isNumeric()) || (String.isNotEmpty(searchBudget) && !searchBudget.isNumeric()) ){
                return;
            }
            if(String.isNotEmpty(siteBudget) && String.isNotEmpty(searchBudget)){
                this.webOnBoardFormModel.Site_Budget__c = Decimal.valueOf(siteBudget);
                this.webOnBoardFormModel.Search_Budget__c = Decimal.valueOf(searchBudget);
                this.webOnBoardFormModel.Total_Budget__c = this.webOnBoardFormModel.Site_Budget__c+this.webOnBoardFormModel.Search_Budget__c;
            }
            else if(String.isEmpty(siteBudget) && String.isNotEmpty(searchBudget)) {
                this.webOnBoardFormModel.Search_Budget__c = Decimal.valueOf(searchBudget);
                this.webOnBoardFormModel.Total_Budget__c = this.webOnBoardFormModel.Search_Budget__c;
            }
            else if(String.isNotEmpty(siteBudget) && String.isEmpty(searchBudget)) {
                this.webOnBoardFormModel.Site_Budget__c = Decimal.valueOf(siteBudget);
                this.webOnBoardFormModel.Total_Budget__c = this.webOnBoardFormModel.Site_Budget__c;
            }
            else {
                this.webOnBoardFormModel.Total_Budget__c = null;
            }
        }
    }
    
    //DEV-5253 , Contract Required if Media partner does not contains G/O Digital
    public void makeContractRequired() {
        if(goDigitalcontractIds.contains(this.webOnBoardFormModel.Media_Partner__c)){
            isContractRequired = false;
        }else {
            isContractRequired = true;
        }
    }
    
    //PPC ppcBudgetAmountEntered 
    public void ppcBudgetAmountEntered(){
        String ppcBudgetValue = String.ValueOf(this.webOnBoardFormModel.PPC_Budget__c);
        System.debug('I am in ppcBudgetAmountEntered');
        
        if(this.webOnBoardFormModel.PPC__c){
            if(String.IsBlank(ppcBudgetValue)){
                this.webOnBoardFormModel.PPC_Budget__c = 0;
            }
            
            if(this.webOnBoardFormModel.PPC_Budget__c > 2499){
                // Allow Picklist selection
                this.webOnBoardFormModel.Target_Geographical_Location__c = '';
                this.ppcTargetGeoPickListDisabled = false;
            }else{
                //default to radius
                this.ppcTargetGeoPickListDisabled = true;
                this.webOnBoardFormModel.Target_Geographical_Location__c = 'Radius';
            }
        }
    }
    
    //Formula for Targetted Email Budget 
    // Calculating currency for both standard email and reminder email blasts
    //Currency field with calculated value as follows:  
    //If Email receipients ranges between 10000 - 14999 then Cost per Reminder Blast = ((Email Recipients/1000)*Rate)
    public void targettedEmailFormulaBudget(){ 
        if(this.webOnBoardFormModel.Targeted_Email__c){
            this.targettedEmailHtmlFee(); // Calling HTML as its dependent on Quantity_of_Email_Blasts_per_60_Days__c
            Double roundingValue = 0.01;
            if(String.IsNotBlank(this.webOnBoardFormModel.Quantity_of_Email_Blasts_per_60_Days__c)
                && this.webOnBoardFormModel.Email_Recipients_per_Blast__c != null){
                Integer quantity = Integer.valueOf(this.webOnBoardFormModel.Quantity_of_Email_Blasts_per_60_Days__c);
                //Integer amountBasedOnQty;
                
                Integer emailBlasts = Integer.valueOf(this.webOnBoardFormModel.Email_Recipients_per_Blast__c);
                
                // DEV-6026 Starts.
                Integer amountBasedOnEmailBlasts = automatedRateCalculationUtil.getMatrixPrice('Email Blast Standard', 'Retail Price Book', emailBlasts, quantity);
                // DEV-6026 Ends.
                    
                if( amountBasedOnEmailBlasts > 0){
                    //System.debug('What am i getting out >> ' + emailBlasts + '  >> ' + amountBasedOnQty + ' >> ' + amountBasedOnEmailBlasts);
                    //System.debug(' Math >> ' + ((emailBlasts/1000) * (amountBasedOnEmailBlasts)));
                    this.webOnBoardFormModel.Targeted_Email_Budget__c = Math.round(roundingValue + (emailBlasts/1000.00) * (amountBasedOnEmailBlasts) );
                }else{
                    this.webOnBoardFormModel.Targeted_Email_Budget__c=null;
                }
            }else{
                this.webOnBoardFormModel.Targeted_Email_Budget__c=null;
            }
            if(this.webOnBoardFormModel.TargetedEmail_BlastReminder__c != null
                && this.webOnBoardFormModel.Email_Recipients_per_Blast__c != null){
                Integer reminderBlastquantity = Integer.valueOf(this.webOnBoardFormModel.TargetedEmail_BlastReminder__c);
                Integer amountBasedOnQty1;
                
                Integer reminderEmailBlasts = Integer.valueOf(this.webOnBoardFormModel.Email_Recipients_per_Blast__c);
                Integer amountBasedOnReminderEmailBlasts;
                
                   if(reminderBlastquantity > 0){
                       // DEV-6026 Starts.
                       amountBasedOnReminderEmailBlasts = automatedRateCalculationUtil.getMatrixPrice('Email Blast Reminder', 'Retail Price Book', reminderEmailBlasts, reminderBlastquantity);
                       // DEV-6026 Ends.
                   }  
                   if(amountBasedOnReminderEmailBlasts > 0){
                     this.webOnBoardFormModel.TargetedEMail_BlastReminderBudget__c = Math.roundToLong(roundingValue + (reminderEmailBlasts/1000.00) * (amountBasedOnReminderEmailBlasts));
                   }else{
                    this.webOnBoardFormModel.TargetedEMail_BlastReminderBudget__c=null;
                   }
              }else{
                     this.webOnBoardFormModel.TargetedEMail_BlastReminderBudget__c=null;
               }
        }
    }
    
    /*
     *  Calculation:
     *  IF "Email Creative Option" IN ("G/O Digital Design (5-Day)") THEN "$250"
     *  IF "Email Creative Option" IN ("Client Provided HTML (2-Day)") THEN "$0"
     *  IF "Email Creative Option" IN ("Client Provided Non-HTML (2-Day)") THEN "$200"
     *  IF "Email Creative Option" IN ("Automotive Template (1-Day)") THEN "$200"
     *  IF "Email Creative Option" IN ("Automotive Client Provided HTML (1-Day)") THEN "$0"
     *  IF "Email Creative Option" IN ("Automotive Client Provided Non-HTML (1-Day)") THEN "$200"
    */
    public void targettedEmailHtmlFee(){ 
        if(this.webOnBoardFormModel.Targeted_Email__c){
            if(String.IsNotBlank(this.webOnBoardFormModel.Quantity_of_Email_Blasts_per_60_Days__c)
                && String.IsNotBlank(this.webOnBoardFormModel.TargetedEmail_CreativeOption__c)){
                    
               
               Integer htmlFee = 0;
               
               
                   if(this.webOnBoardFormModel.TargetedEmail_CreativeOption__c == 'G/O Digital Design (5-Day)'){
                      htmlFee = 250;
                   }               
                   else if(this.webOnBoardFormModel.TargetedEmail_CreativeOption__c == 'Client Provided HTML (2-Day)'){
                      htmlFee = 0;
                   }
                   else if(this.webOnBoardFormModel.TargetedEmail_CreativeOption__c == 'Client Provided Non-HTML (2-Day)'){
                      htmlFee = 200;
                   }
                   else if(this.webOnBoardFormModel.TargetedEmail_CreativeOption__c == 'Automotive Template (1-Day)'){
                      htmlFee = 200;
                   }
                   else if(this.webOnBoardFormModel.TargetedEmail_CreativeOption__c == 'Automotive Client Provided HTML (1-Day)'){
                      htmlFee = 0;
                   }
                   else if(this.webOnBoardFormModel.TargetedEmail_CreativeOption__c == 'Automotive Client Provided Non-HTML (1-Day)'){
                      htmlFee = 200;
                   }
               
               this.webOnBoardFormModel.TargetedEmail_HTMLFee__c=htmlFee;
            }else{
                this.webOnBoardFormModel.TargetedEmail_HTMLFee__c=0;
            }
        }
    }
    
    public Boolean ppcTargetGeoPickListDisabled {
        get;
        set;
    }
   
    //Local_Places_Reputation_Budget_c is populated based on following formula
    //IF Number_of_Locations_c IN (2-14) THEN Local_Places_Reputation_Budget_c = ((Number_of_Locationsc - 1)*200) 
    //IF Number_of_Locations_c IN (15-49) THEN Local_Places_Reputation_Budget_c = ((Number_of_Locationsc - 1)*175)
    //IF Number_of_Locations_c >= (50) THEN Local_Places_Reputation_Budget_c = ((Number_of_Locationsc - 1)*150) 
      public void setLPRBudgetFormula(){
       if(this.webOnBoardFormModel.Local_Places_Reputation__c){
         if(this.webOnBoardFormModel.Number_of_Locations__c != null){
           Integer LPRBudget = 0;
           Integer FirstLocationBudget = null;
           Integer numberOfLocations = Integer.valueOf(this.webOnBoardFormModel.Number_of_Locations__c);
           if(numberOfLocations >= 2 && numberOfLocations <= 16){
             LPRBudget = ((numberOfLocations-1)*200);
           }else if(numberOfLocations >= 17 && numberOfLocations <= 49){
              LPRBudget = ((numberOfLocations-1)*175);
           }else if(numberOfLocations >= 50){
              LPRBudget = ((numberOfLocations-1)*150); 
           }
            if(numberOfLocations > 0){
                FirstLocationBudget = 349 ;// For any number of locations 1st Location Budget is $349
            }
            }
        }
       }
    //setLCPFormulaBudget
    //Auto filled in by option picked above; Premium: $129, Signature: $199, Single: $299: 
    public void setLCPFormulaBudget(){
        if(this.webOnBoardFormModel.Lead_Capture_Pages__c){
            if(String.isNotBlank(this.webOnBoardFormModel.Lead_Capture_Page_Option__c)){
                this.webOnBoardFormModel.Contract_Length_Months_LCP__c = '';
                if(this.webOnBoardFormModel.Lead_Capture_Page_Option__c == 'Premium'){
                    this.webOnBoardFormModel.Lead_Capture_Page_Budget__c = 129;
                }else if (this.webOnBoardFormModel.Lead_Capture_Page_Option__c == 'Signature'){
                    this.webOnBoardFormModel.Lead_Capture_Page_Budget__c = 199;
                }else if (this.webOnBoardFormModel.Lead_Capture_Page_Option__c == 'Single'){
                    this.webOnBoardFormModel.Lead_Capture_Page_Budget__c = 299;
                    this.webOnBoardFormModel.Contract_Length_Months_LCP__c = '1';
                }else{
                    this.webOnBoardFormModel.Lead_Capture_Page_Budget__c = 0;
                }
            }else{
                this.webOnBoardFormModel.Lead_Capture_Page_Budget__c = 0;
            }
        }
    }
    
    public Boolean seoFormulaBudgetDisabled {
        get{
            if(this.webOnBoardFormModel.SEO_Package__c == 'Custom' || this.webOnBoardFormModel.SEO_Package__c == null){
                return true;
            }else{
                return false;
            }
        }
    }
    
    //SetWebSiteBudgetAndQuote
    //Auto filled in with Premium $249, Signature $399, Mobile Only $69, Custom $25.
    //Start Template (5 Page Website), Professional Template (15 Page Website), Mobile Only, Custom Website, Website Maintenance.
    //Auto filled in with Website Maintenance $999, but allow write-in of $5000 minimum if Custom Website selected in Row 59.
    public void SetWebSiteBudgetAndQuote(){
        if(this.webOnBoardFormModel.Websites__c && String.isNotBlank(this.webOnBoardFormModel.Website_Option__c)){
            if(this.webOnBoardFormModel.Website_Option__c == 'Start Template (5 Page Website)'){
                this.webOnBoardFormModel.Website_Quote_Cost_Custom__c = null;
            }else if(this.webOnBoardFormModel.Website_Option__c == 'Professional Template (15 Page Website)'){
                this.webOnBoardFormModel.Website_Quote_Cost_Custom__c = null;
            }else if (this.webOnBoardFormModel.Website_Option__c == 'Mobile Only'){
                this.webOnBoardFormModel.Website_Quote_Cost_Custom__c = null;
            }else if (this.webOnBoardFormModel.Website_Option__c == 'Custom Website'){
                this.webOnBoardFormModel.Website_Quote_Cost_Custom__c = null;
            }else if (this.webOnBoardFormModel.Website_Option__c == 'Website Maintenance'){
                this.webOnBoardFormModel.Website_Quote_Cost_Custom__c = 999;
            }else if (this.webOnBoardFormModel.Website_Option__c == 'Website Hosting Only'){ //DEV-8927
                this.webOnBoardFormModel.Website_Hosting_Only_for_GO_Built_Sites__c = 25.00;
                this.webOnBoardFormModel.Website_Quote_Cost_Custom__c = null;
            }else{
                this.webOnBoardFormModel.Website_Quote_Cost_Custom__c = null;
            }
        }else{
            this.webOnBoardFormModel.Website_Quote_Cost_Custom__c = null;
        }
    }
    
    //Validation >= 5000 for custom website
    private boolean customWebsiteQuote(){
        if(this.webOnBoardFormModel.Websites__c && String.isNotBlank(this.webOnBoardFormModel.Website_Option__c)){
            if (this.webOnBoardFormModel.Website_Option__c == 'Custom Website'){
                if(this.webOnBoardFormModel.Website_Quote_Cost_Custom__c == null ||
                      this.webOnBoardFormModel.Website_Quote_Cost_Custom__c < 5000){
                     ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Website Quote Cost (custom): You must enter minimum of 5000',''));
                     return false;
                }
            }
        }
        return true;
    }
    
    public String selectedSalesRep {get;set;} 
    
    //Media Kit >> logoUploadAttachment
    public AttachmentsExt logoUploadAttachment {
        get {
            if(logoUploadAttachment == NULL){
                logoUploadAttachment=new AttachmentsExt();
                logoUploadAttachment.AttachmentDescription = AttachmentTypes.MEDIAKIT_LOGO.name();
            }
            return logoUploadAttachment;
        }
        set;
    }
    
    //Media Kit >> imagesCreativeFile
    public AttachmentsExt imagesCreativeFileAttachment {
        get {
            if(imagesCreativeFileAttachment == NULL){
                imagesCreativeFileAttachment=new AttachmentsExt();
                imagesCreativeFileAttachment.AttachmentDescription = AttachmentTypes.MEDIAKIT_IMAGES.name();
            }
            return imagesCreativeFileAttachment;
        }
        set;
    }
    
    //Contract Information >> ContractFile
    public AttachmentsExt contractFileAttachment {
        get {
            if(contractFileAttachment == NULL){
                contractFileAttachment=new AttachmentsExt();
                contractFileAttachment.AttachmentDescription = AttachmentTypes.CONTRACT_INFO.name();
            }
            return contractFileAttachment;
        }
        set;
    }
    //Managed Email>> Database list upload (in excel or csv) >> DatabaselistFileAttachment
    public AttachmentsExt DatabaselistFileAttachment {
        get {
            if(DatabaselistFileAttachment == NULL){
                DatabaselistFileAttachment=new AttachmentsExt();  
                DatabaselistFileAttachment.AttachmentDescription = AttachmentTypes.DATABASE_LIST.name();
            }
            return DatabaselistFileAttachment;
        }
        set;
    }
    
    //Managed Email>> Attach signed Opt-in Liability Form >> LiabilityFormFileAttachment
    public AttachmentsExt LiabilityFormFileAttachment {
        get {
            if(LiabilityFormFileAttachment == NULL){
                LiabilityFormFileAttachment=new AttachmentsExt();
                LiabilityFormFileAttachment.AttachmentDescription = AttachmentTypes.LIABILITY_FORM.name();
            }
            return LiabilityFormFileAttachment;
        }
        set;
    }
    
    //Social Media Management>> Asset/Image/Logo Upload(1 of 4) >> AssetImageLogo1FileAttachment
    public AttachmentsExt AssetImageLogo1FileAttachment {
        get {
            if(AssetImageLogo1FileAttachment == NULL){
                AssetImageLogo1FileAttachment=new AttachmentsExt();
                AssetImageLogo1FileAttachment.AttachmentDescription = AttachmentTypes.ASSET_IMAGE_LOGO_1.name();
            }
            return AssetImageLogo1FileAttachment;
        }
        set;
    }
    
    //Social Media Management>> Asset/Image/Logo Upload(1 of 4) >> AssetImageLogo2FileAttachment
    public AttachmentsExt AssetImageLogo2FileAttachment {
        get {
            if(AssetImageLogo2FileAttachment == NULL){
                AssetImageLogo2FileAttachment=new AttachmentsExt();
                AssetImageLogo2FileAttachment.AttachmentDescription = AttachmentTypes.ASSET_IMAGE_LOGO_2.name();
            }
            return AssetImageLogo2FileAttachment;
        }
        set;
    }
    
    //Social Media Management>> Asset/Image/Logo Upload(1 of 4) >> AssetImageLogo3FileAttachment
    public AttachmentsExt AssetImageLogo3FileAttachment {
        get {
            if(AssetImageLogo3FileAttachment == NULL){
                AssetImageLogo3FileAttachment=new AttachmentsExt();
                AssetImageLogo3FileAttachment.AttachmentDescription = AttachmentTypes.ASSET_IMAGE_LOGO_3.name();
            }
            return AssetImageLogo3FileAttachment;
        }
        set;
    }
    
    //Social Media Management>> Asset/Image/Logo Upload(1 of 4) >> AssetImageLogo4FileAttachment
    public AttachmentsExt AssetImageLogo4FileAttachment {
        get {
            if(AssetImageLogo4FileAttachment == NULL){
                AssetImageLogo4FileAttachment=new AttachmentsExt();
                AssetImageLogo4FileAttachment.AttachmentDescription = AttachmentTypes.ASSET_IMAGE_LOGO_4.name();
            }
            return AssetImageLogo4FileAttachment;
        }
        set;
    }
     public AttachmentsExt LocationsUploadAttachment {
        get {
            if(LocationsUploadAttachment == NULL){
                LocationsUploadAttachment=new AttachmentsExt();
                LocationsUploadAttachment.AttachmentDescription = AttachmentTypes.Locations_attachment.name();
            }
            return LocationsUploadAttachment;
        }
        set;
    }
    public AttachmentsExt EventCalendarUploadAttachment {
        get {
            if(EventCalendarUploadAttachment == NULL){
                EventCalendarUploadAttachment=new AttachmentsExt();
                EventCalendarUploadAttachment.AttachmentDescription = AttachmentTypes.Event_Calendar.name();
            }
            return EventCalendarUploadAttachment;
        }
        set;
    }
    public AttachmentsExt ProductsServicesUploadAttachment {
        get {
            if(ProductsServicesUploadAttachment == NULL){
                ProductsServicesUploadAttachment=new AttachmentsExt();
                ProductsServicesUploadAttachment.AttachmentDescription = AttachmentTypes.Products_Services.name();
            }
            return ProductsServicesUploadAttachment;
        }
        set;
    }
    //DEV-6211 Opt-In Email Section Attachment.
    public AttachmentsExt highResolutionLogoAttachment{
        get {
            if(highResolutionLogoAttachment == NULL){
                highResolutionLogoAttachment = new AttachmentsExt();
                highResolutionLogoAttachment.AttachmentDescription = AttachmentTypes.High_Resolution_Logo.name();
            }
            return highResolutionLogoAttachment;
        }
        set;
    }
    
    //DEV-6211 Opt-In Email Section Attachment.
    public AttachmentsExt imageCopyAttachment{
        get {
            if(imageCopyAttachment == NULL){
                imageCopyAttachment = new AttachmentsExt();
                imageCopyAttachment.AttachmentDescription = AttachmentTypes.FirstEmail_ImageCopy.name();
            }
            return imageCopyAttachment;
        }
        set;
    }
    
    //DEV-6211 Opt-In Email Section Attachment.
    public AttachmentsExt marketingPiecesAttachment {
        get {
            if(marketingPiecesAttachment == NULL){
                marketingPiecesAttachment = new AttachmentsExt();
                marketingPiecesAttachment.AttachmentDescription = AttachmentTypes.Marketing_Piece.name();
            }
            return marketingPiecesAttachment;
        }
        set;
    }
    public String NONE {get{return '--None--';} private set;}
    public String OTHER {get{return 'Other';} private set;}
    
    public final String RECTYPE_AFFILIATED = 'Affiliated';
    public final String RECTYPE_PARTNER_MARKET = 'PartnerMarket';
    public String Target_Email_Link { get{ return 'http://gannettlocal.force.com/digitalaudit'; } private set; }
    public Id DEFAULT_CONTACT_ID { get{ return '003F000000y4o1V'; } private set; }
    //This is just a dummy Id so that its different from DEFAULT_CONTACT_ID which is used for 'Not In List'
    //This is used for NONE or CHOOSE ONE
    public Id NONE_CONTACT_ID { get{ return '003F000000y4o2V'; } private set; }
    public Id GANNETT_LOCAL_ACCOUNT_ID { get{ return '001A000000QTk0g'; } private set; }
    
    public enum AttachmentTypes {MEDIAKIT_LOGO, MEDIAKIT_IMAGES, CONTRACT_INFO, CLIENT_UPLOAD, DATABASE_LIST, LIABILITY_FORM, ASSET_IMAGE_LOGO_1, ASSET_IMAGE_LOGO_2, ASSET_IMAGE_LOGO_3, ASSET_IMAGE_LOGO_4,Locations_attachment,Event_Calendar,Products_Services, High_Resolution_Logo, FirstEmail_ImageCopy, Marketing_Piece}
    
    private Pagereference currentPage;
    
    public OnBoardFormControllerExt(){
        
    }
    
    public OnBoardFormControllerExt ( ApexPages.StandardController stdController )
    {
        currentPage = ApexPages.currentPage();
        webOnBoardFormModel = (OnBoardFormModel__c)stdcontroller.getRecord(); 
        newContact = new Contact();
        boolShowContacts = false;
        ContactName = strSearchRep;
        ContactNames = new List<SelectOption>();  
        ContactNames.add(new SelectOption(strSearchRep,strSearchRep));
        //DEV-5253
        isContractRequired = true;
        loadMediaPartnerList();
        hasOppId = false;
        oppId = ApexPages.currentPage().getParameters().get('oppId');
        getEmailOnly();
        if(emailOnly == true)
            webOnBoardFormModel.Targeted_Email__c = true;
        if(optEmailOnly == true)
            webOnBoardFormModel.Opt_In_Email__c = true;
        if(oppId!=null){
           hasOppId = true;
           Opportunity opp = [select Id, Media_Partner__c, AccountId, Account.Name, Account.Phone, Account.Website, Account.BillingStreet, Account.BillingCity, Account.BillingState,
                              Account.BillingPostalCode,  Account.Account_Primary_Industry__c,  Account.Account_Primary_Focus__c from Opportunity where Id = :oppId ];
            webOnBoardFormModel.Opportunity__c = opp.Id;
            webOnBoardFormModel.Media_Partner__c = opp.Media_Partner__c;
            webOnBoardFormModel.Select_if_G_O_Outside_Direct_Rep__c = 'Yes';
            webOnBoardFormModel.Advertiser_Company_Name__c = opp.Account.Name;
            webOnBoardFormModel.Advertiser_Contact_Phone__c = opp.Account.Phone;
            webOnBoardFormModel.Location_Name__c = opp.Account.Name;
            webOnBoardFormModel.Address_1__c = opp.Account.BillingStreet;
            webOnBoardFormModel.City__c = opp.Account.BillingCity;
            webOnBoardFormModel.State__c = opp.Account.BillingState;
            webOnBoardFormModel.Postal_Code__c = opp.Account.BillingPostalCode;
            webOnBoardFormModel.Phone__c = opp.Account.Phone;
            if (opp.Account.Website != null){
                if (opp.Account.Website.startsWith('http://') || opp.Account.Website.startsWith('https://')  )
                    webOnBoardFormModel.Advertiser_Web_Address__c = opp.Account.Website;
                else
                    webOnBoardFormModel.Advertiser_Web_Address__c = 'http://' + opp.Account.Website;
            }    
            webOnBoardFormModel.Advertiser_Industry__c = opp.Account.Account_Primary_Industry__c;
            webOnBoardFormModel.Advertiser_Primary_Focus__c = opp.Account.Account_Primary_Focus__c;
            
            validateOppFields();
            List<OpportunityContactRole> contList = new List<OpportunityContactRole>([select Id, Contact.LastName, Contact.FirstName from OpportunityContactRole where IsPrimary = true and OpportunityId = :opp.Id]);
            if(contList != null && !contList.isEmpty()){
                webOnBoardFormModel.Advertiser_Contact_First_Name__c = contList[0].Contact.FirstName;
                webOnBoardFormModel.Advertiser_Contact_Last_Name__c = contList[0].Contact.LastName;
            }
            
            makeContractRequired(); //DEV-6940
        }
           
    }
   
    public void getEmailOnly(){
         emailOnly = false;
         optEmailOnly = false;
         rlEmail = ApexPages.currentPage().getParameters().get('email');
         if(rlEmail != null){
            if(rlEmail == RLPartnerType)
              emailOnly = true;
            if(rlEmail == GannetPartnerType)
              optEmailOnly = true;
         }
    }
   //DEV-5325 Start
    public void clearValue(){
		if(this.webOnBoardFormModel.PPC__c == false){
			this.webOnBoardFormModel.SellType_PPC__c = Null;
			this.webOnBoardFormModel.Contract_Length_Months_PPC__c = Null;
			this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c = Null;
			this.webOnBoardFormModel.Is_This_a_Variable_Budget_PPC__c = False;
			this.webOnBoardFormModel.PPC_BudgetAdj_Effective_Month__c = Null;
			this.webOnBoardFormModel.PPC_Budget__c = Null;
			this.webOnBoardFormModel.PPC_Budget_2__c = Null;
			this.webOnBoardFormModel.PPC_Budget_3__c = Null;
			this.webOnBoardFormModel.PPC_Budget_4__c = Null;
			this.webOnBoardFormModel.PPC_Budget_5__c = Null;
			this.webOnBoardFormModel.PPC_Budget_6__c = Null;
			this.webOnBoardFormModel.PPC_Budget_7__c = Null;
			this.webOnBoardFormModel.PPC_Budget_8__c = Null;
			this.webOnBoardFormModel.PPC_Budget_9__c = Null;
			this.webOnBoardFormModel.PPC_Budget_10__c = Null;
			this.webOnBoardFormModel.PPC_Budget_11__c = Null;
			this.webOnBoardFormModel.PPC_Budget_12__c = Null;
			this.webOnBoardFormModel.Does_this_order_include_a_spike_PPC__c = False;
			this.webOnBoardFormModel.Requested_Start_Date_PPC__c = Null;
			this.webOnBoardFormModel.Requested_End_Date_PPC__c = Null;
		    this.webOnBoardFormModel.PPC_Spike_Budget_PPC__c = Null;			
		}
        if(this.webOnBoardFormModel.Websites__c == false){ //DEV-9397
            this.webOnBoardFormModel.WEB_Product_Order_Id__c = null;
            this.webOnBoardFormModel.Website_Option__c = null;
            this.webOnBoardFormModel.Website_Hosting_Only_for_GO_Built_Sites__c = null;
            this.webOnBoardFormModel.Link_to_Proposal__c = null;
            this.webOnBoardFormModel.Website_Quote_Cost_Custom__c = null;
            this.webOnBoardFormModel.Contract_Length_Months_Websites__c = null;
            this.webOnBoardFormModel.TWDesired_URL_Domain_Name__c = null;
            this.webOnBoardFormModel.Use_Existing_URL__c = null;
            this.webOnBoardFormModel.Domain_Registrar__c = null;
            this.webOnBoardFormModel.Domain_Registrar_Other__c = null;         
            this.webOnBoardFormModel.Domain_Registrar_Username__c = null;
            this.webOnBoardFormModel.Domain_Registrar_Password__c = null;
            this.webOnBoardFormModel.Notes_Websites__c = null;
            this.webOnBoardFormModel.Domain_Name__c = null;
        }    
        if(this.webOnBoardFormModel.Social_Advertising__c == false){
            this.webOnBoardFormModel.Social_Ads_Package__c = null;
            this.webOnBoardFormModel.SellType_SocialAds__c = null;
            this.webOnBoardFormModel.Is_This_a_Variable_Budget_SocAd__c = false;
            this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c = null;
            this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c = null;
            this.webOnBoardFormModel.Does_this_order_include_a_spike_SocAd__c = false;
            this.webOnBoardFormModel.SocialAds_BudgetAdj_Effective_Month__c = null;
            this.webOnBoardFormModel.Social_Ads_Spike_Budget__c= null;
            this.webOnBoardFormModel.Social_Ads_Event_Budget__c = null;
            this.webOnBoardFormModel.Requested_Start_Date_SocAd__c = null;
            this.webOnBoardFormModel.Requested_End_Date_SocAd__c = null;
            this.webOnBoardFormModel.Social_Ads_Budget_Month_2__c = null;
            this.webOnBoardFormModel.Social_Ads_Budget_Month_3__c = null;
            this.webOnBoardFormModel.Social_Ads_Budget_Month_4__c = null;
            this.webOnBoardFormModel.Social_Ads_Budget_Month_5__c = null;
            this.webOnBoardFormModel.Social_Ads_Budget_Month_6__c = null;
            this.webOnBoardFormModel.Social_Ads_Budget_Month_7__c = null;
            this.webOnBoardFormModel.Social_Ads_Budget_Month_8__c = null;
            this.webOnBoardFormModel.Social_Ads_Budget_Month_9__c = null;         
            this.webOnBoardFormModel.Social_Ads_Budget_Month_10__c = null;
            this.webOnBoardFormModel.Social_Ads_Budget_Month_11__c = null;
            this.webOnBoardFormModel.Social_Ads_Budget_Month_12__c = null;
        }
        if(this.webOnBoardFormModel.Social_Media_Management__c == false){ //DEV-9396
            this.webOnBoardFormModel.SocMgmt_Product_Order_Id__c = null;
            this.webOnBoardFormModel.Social_Option__c = null;
            this.webOnBoardFormModel.SocialMediaMgmt_Spend_Budget__c = null;
            this.webOnBoardFormModel.Social_Budget__c = null;
            this.webOnBoardFormModel.Contract_Length_Months_SocialMedia__c = null;
            this.webOnBoardFormModel.Has_Facebook_Page__c = null;
            this.webOnBoardFormModel.Current_Facebook_URL__c = null;
            this.webOnBoardFormModel.Confirm_Manager_Level_Admin_Access__c= false;
            this.webOnBoardFormModel.Has_Twitter_Profile__c = false;
            this.webOnBoardFormModel.Twitter_Username__c = null;
            this.webOnBoardFormModel.Twitter_Password__c = null;
            this.webOnBoardFormModel.Campaign_Contact_Email__c = null;
            this.webOnBoardFormModel.Campaign_Goal__c = null;
            this.webOnBoardFormModel.Notes_SMM__c = null;
            this.AssetImageLogo1FileAttachment = new AttachmentsExt();
            this.AssetImageLogo2FileAttachment = new AttachmentsExt();
            this.AssetImageLogo3FileAttachment = new AttachmentsExt();
            this.AssetImageLogo4FileAttachment = new AttachmentsExt();
        }
        //DEV-10995
        if(this.webOnBoardFormModel.Video_Advertising__c == false){
            this.webOnBoardFormModel.VA_YouTube_Total_Budget__c = null;
            this.webOnBoardFormModel.Contract_Length_Months_VA__c = null;
            this.webOnBoardFormModel.Video_Ads_Objective__c = null;
            this.webOnBoardFormModel.VA_Products_Services_to_Advertise_for__c = null;
            this.webOnBoardFormModel.VA_Target_Geographical_Location__c = null;
            this.webOnBoardFormModel.VA_Target_Radius_miles__c = null;
            this.webOnBoardFormModel.VA_Target_State__c = null;
            this.webOnBoardFormModel.VA_hasYouTubeAccount__c = null;
            this.webOnBoardFormModel.VA_YouTube_Username__c = null;
            this.webOnBoardFormModel.VA_YouTube_Password__c = null;
            this.webOnBoardFormModel.VA_YouTube_Channel_Address__c = null;
            this.webOnBoardFormModel.VA_Purchasing_Video_Production__c = false;
            this.webOnBoardFormModel.VA_Create_YouTube_Channel__c = false;
            this.webOnBoardFormModel.VA_AdditionalNotesYouTube__c = null;
        }
		//DEV-9914
        if(this.webOnBoardFormModel.Video_Production__c == false){
            this.webOnBoardFormModel.VP_How_Many_Orders__c = null;
            this.webOnBoardFormModel.VP_Address_for_Video_Shoot__c = null;
            this.webOnBoardFormModel.VP_Voice_Over_Talent_Preference__c = null;
            this.webOnBoardFormModel.VP_Music_Preference__c = null;
            this.webOnBoardFormModel.VP_Script_Requirements__c = null;
            this.webOnBoardFormModel.VP_Comments_on_Script_Requirements__c = null;
            this.webOnBoardFormModel.VP_1st_Date__c = null;
            this.webOnBoardFormModel.VP_2nd_Date__c = null;
            this.webOnBoardFormModel.VP_3rd_Date__c = null;
            this.webOnBoardFormModel.VP_DateTBDinOnboardCallwithAM__c = false;
            this.webOnBoardFormModel.VP_Additional_Production_Information__c = null;
            this.webOnBoardFormModel.VP_Video_1_60_sec__c = null;
            this.webOnBoardFormModel.VP_Video_2_15_30_sec__c = null;
            this.webOnBoardFormModel.VP_Video_3_15_30_sec__c = null;
            this.webOnBoardFormModel.VP_Video_4_15_30_sec__c = null;
            this.webOnBoardFormModel.VP_Video_Types_Notes__c = null;
        }
    }
   //DEV-5325 End
   
    private void validateOppFields(){
            if (webOnBoardFormModel.Media_Partner__c == null){
                isValid = false;    
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Media Partner :' + mediaPartnerError ,''));
                webOnBoardFormModel.Media_Partner__c.addError(mediaPartnerError);
            }
            if(webOnBoardFormModel.Advertiser_Company_Name__c == null || String.isBlank(webOnBoardFormModel.Advertiser_Company_Name__c)){
                isValid = false;  
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Advertiser Company Name :' + nameError ,''));
                webOnBoardFormModel.Advertiser_Company_Name__c.addError(nameError);
            }
            if(webOnBoardFormModel.Location_Name__c == null || String.isBlank(webOnBoardFormModel.Location_Name__c)){
                isValid = false;  
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Location Name :' + nameError ,''));
                webOnBoardFormModel.Location_Name__c.addError(nameError);
            }
            if(webOnBoardFormModel.Address_1__c == null || String.isBlank(webOnBoardFormModel.Address_1__c)){
                isValid = false;  
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Address 1 :' + streetError ,''));
                webOnBoardFormModel.Address_1__c.addError(streetError);
            }
            if(webOnBoardFormModel.City__c == null || String.isBlank(webOnBoardFormModel.City__c)){
                isValid = false;  
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Address 1 :' + cityError ,''));
                webOnBoardFormModel.City__c.addError(cityError);
            }
            if(webOnBoardFormModel.Postal_Code__c == null || String.isBlank(webOnBoardFormModel.Postal_Code__c)){
                isValid = false;  
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Postal Code :' + postalError1 ,''));
                webOnBoardFormModel.Postal_Code__c.addError(postalError1);
            }
            if(webOnBoardFormModel.Postal_Code__c != null && !Pattern.matches('\\d{5}(-\\d{4})?', webOnBoardFormModel.Postal_Code__c)){
                isValid = false;  
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Postal Code :' + postalError2 ,''));
                webOnBoardFormModel.Postal_Code__c.addError(postalError2);
            } 
            if(webOnBoardFormModel.Advertiser_Contact_Phone__c != null && !Pattern.matches('(^\\(?(\\d{3})\\)?[- ]?(\\d{3})[- ]?(\\d{4})$)', webOnBoardFormModel.Advertiser_Contact_Phone__c)){
                isValid = false;  
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Advertiser Contact Phone :' + phoneError ,''));
                webOnBoardFormModel.Advertiser_Contact_Phone__c.addError(phoneError);
            } 
            if (webOnBoardFormModel.Advertiser_Industry__c == null || String.isEmpty(webOnBoardFormModel.Advertiser_Industry__c)){
                isValid = false;  
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Advertiser Industry:' + primaryIndustryError ,''));
                webOnBoardFormModel.Advertiser_Industry__c.addError(primaryIndustryError);
            }
            if (webOnBoardFormModel.Advertiser_Primary_Focus__c  == null || String.isEmpty(webOnBoardFormModel.Advertiser_Primary_Focus__c)){
                isValid = false;  
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Advertiser Primary Focus:' + primaryFocusError ,''));
                webOnBoardFormModel.Advertiser_Primary_Focus__c.addError(primaryFocusError);
            }
            if (webOnBoardFormModel.Advertiser_Web_Address__c == null || String.isBlank(webOnBoardFormModel.Advertiser_Web_Address__c)){
                isValid = false;  
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Advertiser Web Address: :' + webAddressError1 ,''));
                webOnBoardFormModel.Advertiser_Web_Address__c.addError(webAddressError1);
            }
            if (webOnBoardFormModel.Advertiser_Web_Address__c != null && !String.isBlank(webOnBoardFormModel.Advertiser_Web_Address__c) && 
                !Pattern.matches('http://[0-9a-zA-Z./-]+\\.[+:0-9a-zA-Z/?%&=_#.-]+', webOnBoardFormModel.Advertiser_Web_Address__c) && 
                !Pattern.matches('https://[0-9a-zA-Z./-]+\\.[+:0-9a-zA-Z/?%&=_#.-]+', webOnBoardFormModel.Advertiser_Web_Address__c)){
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Advertiser Web Address: :' + webAddressError2 ,''));
                webOnBoardFormModel.Advertiser_Web_Address__c.addError(webAddressError2);
            }
            
    }
    /*
       Sales Rep: Affiliated Record Type
    */
    private Id affiliatedRecTypeId
    {
        get
        {
            if( affiliatedRecTypeId == NULL )
            {
                RecordType cachedRecType = RecordTypeCache.getRecordType( 'Contact', RECTYPE_AFFILIATED );
                if( cachedRecType != NULL )
                    affiliatedRecTypeId = cachedRecType.Id;
            }
            return affiliatedRecTypeId;
        }
        private set;
    }
    /*
       MediaType : ParterMarket Account Record Type
    */
    private Id partnerMarketRecTypeId
    {
        get
        {
            if( partnerMarketRecTypeId == NULL )
            {
                RecordType cachedRecType = RecordTypeCache.getRecordType( 'Account', RECTYPE_PARTNER_MARKET );
                if( cachedRecType != NULL )
                    partnerMarketRecTypeId = cachedRecType.Id;
            }
            return partnerMarketRecTypeId;
        }
        private set;
    }
  
    
    /*
    Dropdown with YES or NO
    */
    public List<SelectOption> yesNoOptions{
        get{
            if (yesNoOptions == null){
                yesNoOptions = new List<SelectOption>();
                yesNoOptions.add(new SelectOption('false','No'));
                yesNoOptions.add(new SelectOption('true','Yes'));
            }
            return yesNoOptions;
        }
        private set;
    }
    
    /*
    Dropdown with YES or NO
    */
    public List<SelectOption> reportingDashboardOptions{
        get{
            if (reportingDashboardOptions == null){
                reportingDashboardOptions = new List<SelectOption>();
                reportingDashboardOptions.add(new SelectOption('true','Yes'));
                reportingDashboardOptions.add(new SelectOption('false','No'));
            }
            return reportingDashboardOptions;
        }
        private set;
    }
    
    
    /*
       Media Partner List from Account of recordType PartnerMarket
       Changed method name from getMediaPartnerList to loadMediaPartnerList for DEV-6940 fix.
    */
    public void loadMediaPartnerList(){
        restrictedMediaPartner(); //DEV-8915
        if(mediaPartnerList == null){
            System.debug('************* Called One Time');
            mediaPartnerList = new List<SelectOption>();
            //Excluding ClipperPartnerType, CLP, as per requirements of Sprint 2.16.12, Story DEV-5252, "Inactivate Clipper Partner companies"
            List<Account> marketList;
            mediaPartnerList.add(new SelectOption(NONE_CONTACT_ID,NONE));  //We need to set some sfdc id value and hence providing dummy val
            if(emailOnly == null)
                getEmailOnly();     
            system.debug('------emailOnly-' + emailOnly);
            if(emailOnly == true){
                 marketList = [Select Id, Media_Property_List__c
                                        FROM Account
                                        where RecordTypeId = :partnerMarketRecTypeId
										and Partner_Type__c = :RLPartnerType
                                        order by Media_Property_List__c];
            } else {
                marketList = [Select Id, Media_Property_List__c
                                        FROM Account
                                        where RecordTypeId = :partnerMarketRecTypeId
                                        and Id != :GANNETT_LOCAL_ACCOUNT_ID
                                        and Partner_Type__c <> :ClipperPartnerType
										and Partner_Type__c <> :RLPartnerType
                                        order by Media_Property_List__c];
                mediaPartnerList.add(new SelectOption(GANNETT_LOCAL_ACCOUNT_ID,'G/O Digital'));
            }  
            
           
            for (Integer j=0; j<marketList.size(); j++){
                if(!deactivatePartnerMarket.contains(marketList[j].Media_Property_List__c)){
                    mediaPartnerList.add(new SelectOption(marketList[j].Id,marketList[j].Media_Property_List__c));
                }
                //DEV-5253
                if(marketList[j].Media_Property_List__c != null){
                    if(marketList[j].Media_Property_List__c.containsIgnoreCase('G/O Digital')){
                        goDigitalcontractIds.add(marketList[j].Id); 
                    }
                }
            }
            
            goDigitalcontractIds.add(GANNETT_LOCAL_ACCOUNT_ID);    

        }    
    }
    
    /*
      Advertise Industry 
    */
    public List<SelectOption> AdvertiserIndustry{
        get{
            if(AdvertiserIndustry == NULL){
                System.debug('Testing AdvertiserIndustry for duuplicate calls');
                AdvertiserIndustry = new List<SelectOption>();
                AdvertiserIndustry.add(new SelectOption(NONE,NONE));
                Map<String,String> listobjs = AMPRestService.getIndustryList();
                if(listobjs<>null && listobjs.size()>0){
                    List<SelectOption> options = new List<SelectOption>();
                    for (String categoryId: listobjs.keySet()){
                        options.add(new SelectOption(categoryId,listobjs.get(categoryId)));
                    }
                    options = SortSelectOptions.selectOptionSortByLabel(options);
                    AdvertiserIndustry.addall(options);
                }
                AdvertiserIndustry.add(new SelectOption(this.OTHER,this.OTHER));
                this.hasIndustryPicklistChanged = true;
            }
            return AdvertiserIndustry;
        }
        private set;
    }
    
    /*
      Advertise Industry 
    */ 
    public List<SelectOption> AdvertiserIndustryFocus{
        get{
            System.debug('What is Selected Company Name' + selectedIndustryId);
            if(hasIndustryPicklistChanged){
                System.debug('hasIndustryPicklistChanged  >> ' + hasIndustryPicklistChanged);
                AdvertiserIndustryFocus = new List<SelectOption>();
                if(this.selectedIndustryId <> NONE ){
                    if(this.selectedIndustryId <> this.OTHER){
                        AdvertiserIndustryFocus.add(new SelectOption(NONE,NONE));
                        Map<String,String> listobjs = AMPRestService.getFocusByIndustry(selectedIndustryId);
                        if(listobjs<>null && listobjs.size()>0){
                            List<SelectOption> options = new List<SelectOption>();
                            for (String categoryId: listobjs.keySet()){
                                options.add(new SelectOption(categoryId,listobjs.get(categoryId)));
                            }
                            options = SortSelectOptions.selectOptionSortByLabel(options);
                            AdvertiserIndustryFocus.addall(options);
                        }
                    }   
                    AdvertiserIndustryFocus.add(new Selectoption(this.OTHER, this.OTHER));
                }else{
                    AdvertiserIndustryFocus.add(new SelectOption(NONE,NONE));
                }
                this.hasIndustryPicklistChanged = false;
            }
            return AdvertiserIndustryFocus;
        }
        private set;
    }
    
    //DEV-6211
    public void resetOptinFields(){
        if(this.webOnBoardFormModel.Opt_in_Email__c == false){
            this.webOnBoardFormModel.OptIn_Email_Creative_Option__c = null;
        }
    }
    
    //DEV-8585. Reset Contract Length field value whenever Sell Type value is changed.
    public void resetContractLength(){
        this.webOnBoardFormModel.Contract_Length_Months_PPC__c = Null;
        this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c = Null;
        ppcBudgetFieldsMap = Null;
    }
    
    //DEV-8585. Generate dynamic PPC Budget fields in OnboardForm based on the selected Contract Length field value.
    public void generatePPCDynamicFields(){
        ppcBudgetFieldsMap = new Map<Integer, String>();
        System.debug('generatePPCDynamicFields method is invoked: SellType PPC - '+this.webOnBoardFormModel.SellType_PPC__c);
        System.debug('generatePPCDynamicFields method is invoked: Contract Len Months - '+this.webOnBoardFormModel.Contract_Length_Months_PPC__c);
        System.debug('generatePPCDynamicFields method is invoked: Contract Len Months Remaining - '+this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c);

        if(this.webOnBoardFormModel.Is_This_a_Variable_Budget_PPC__c){
            if(this.webOnBoardFormModel.SellType_PPC__c != 'Budget Change' && this.webOnBoardFormModel.Contract_Length_Months_PPC__c != Null && this.webOnBoardFormModel.Contract_Length_Months_PPC__c != '1'){
                if(this.webOnBoardFormModel.Contract_Length_Months_PPC__c.isNumeric()){
                    assignPPCFieldNames(Integer.valueOf(this.webOnBoardFormModel.Contract_Length_Months_PPC__c));
                }
                else if(this.webOnBoardFormModel.Contract_Length_Months_PPC__c == 'Evergreen' || this.webOnBoardFormModel.Contract_Length_Months_PPC__c == 'Spike'){
                    this.webOnBoardFormModel.Is_This_a_Variable_Budget_PPC__c = false;
                }
            }
            else if(this.webOnBoardFormModel.SellType_PPC__c == 'Budget Change' && this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c != Null && this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c != '1'){
                if(this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c.isNumeric()){
                    assignPPCFieldNames(Integer.valueOf(this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c));
                }
                else if(this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c == 'Evergreen' || this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c == 'Spike'){
                    this.webOnBoardFormModel.Is_This_a_Variable_Budget_PPC__c = false;
                }
            }
        }
    }
    
    //DEV-8585
    private void assignPPCFieldNames(Integer contractLen){
        System.debug('assignPPCFieldNames method is invoked: contractLen - '+contractLen);
        String budgetFieldName = 'PPC_Budget_';
        for(integer i=2; i <=contractLen; i++){
            this.webOnBoardFormModel.put(budgetFieldName+i+'__c', null);
            ppcBudgetFieldsMap.put(i, budgetFieldName+i+'__c');
        }
    }
    
    //DEV-8584 Reset Social Ads Contract Length field value whenever Social Ads Sell Type value is changed.
    public void resetSocAdContractLength(){
        this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c = Null;
        this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c = Null;
        socAdBudgetFieldsMap = Null;
    }
    
    //DEV-8584 Reset Spike and Event field value whenever value is changed.
    public void resetSocAdSpike(){
        this.webOnBoardFormModel.Social_Ads_Spike_Budget__c = Null;
        this.webOnBoardFormModel.Requested_Start_Date_SocAd__c = Null; 
        this.webOnBoardFormModel.Requested_End_Date_SocAd__c = Null; 
    }
    
    //DEV-8584 Generate dynamic Social Ads Budget/Month fields based on the selected Contract Length field.
    public void generateSocAdDynamicFields(){
        socAdBudgetFieldsMap = new Map<Integer, String>();
        
        if(this.webOnBoardFormModel.Is_This_a_Variable_Budget_SocAd__c){
            if(this.webOnBoardFormModel.SellType_SocialAds__c != 'Budget Change' && this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c != Null && this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c != '1'){
                if(this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c.isNumeric()){
                    assignSocAdFieldNames(Integer.valueOf(this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c));
                }
                else if(this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c == 'Evergreen' || 
                        this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c == 'Spike' ||
                        this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c == 'Event'){
                    this.webOnBoardFormModel.Is_This_a_Variable_Budget_SocAd__c = false;
                }
                else if(this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c != 'Evergreen' || 
                        this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c != 'Spike' ||
                        this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c != 'Event'){
                    this.webOnBoardFormModel.Social_Ads_Spike_Budget__c = Null;
                    this.webOnBoardFormModel.Social_Ads_Event_Budget__c = Null;
                    this.webOnBoardFormModel.Requested_Start_Date_SocAd__c = Null; 
                    this.webOnBoardFormModel.Requested_End_Date_SocAd__c = Null;
                }
                
            }
            else if(this.webOnBoardFormModel.SellType_SocialAds__c == 'Budget Change' && this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c != Null && this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c != '1'){
                if(this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c.isNumeric()){
                    assignSocAdFieldNames(Integer.valueOf(this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c));
                }
                else if(this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c == 'Evergreen' || 
                        this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c == 'Spike' ||
                        this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c == 'Event'){
                    this.webOnBoardFormModel.Is_This_a_Variable_Budget_SocAd__c = false;
                }
                else if(this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c != 'Evergreen' || 
                        this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c != 'Spike' ||
                        this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c != 'Event'){
                    this.webOnBoardFormModel.Social_Ads_Spike_Budget__c = Null;
                    this.webOnBoardFormModel.Social_Ads_Event_Budget__c = Null;        
                    this.webOnBoardFormModel.Requested_Start_Date_SocAd__c = Null; 
                    this.webOnBoardFormModel.Requested_End_Date_SocAd__c = Null;
                }
            }
        }
    }
    
    //DEV-8584 This method is called by generateSocAdDynamicFields() to populated the socAdBudgetFieldsMap 
    //with coresponding fields.
    private void assignSocAdFieldNames(Integer contractLenSocAd){
        String socAdBudgetFieldName = 'Social_Ads_Budget_Month_';
        for(integer i=2; i <=contractLenSocAd; i++){
            this.webOnBoardFormModel.put(socAdBudgetFieldName + i +'__c', null);
            socAdBudgetFieldsMap.put(i, socAdBudgetFieldName + i + '__c');
        }
    }
    
    /*
       Save Customer Onboarding form with 240+ fields data
    */
    public PageReference saveOnBoardForm(){
        System.debug('------------ Entering saveOnBoardForm()');
        
        try{
            
            if (contactName == strChoseOne || contactName == strSearchRep){
                ApexPages.addMessage (new ApexPages.message(ApexPages.severity.Error, 'Please Choose Sales Rep'));
                return this.currentPage;
            }                 
            if(! this.ValidateFormFields()){
                return this.currentPage;
            }
            
            DigitalFormUtil.upsertContact(newContact, this.webOnBoardFormModel.Media_Partner__c, saveContactId);  
            saveContactId = newContact.Id;
            newContact.Id = null;
            
            //at this point we should have contact
            this.webOnBoardFormModel.Affl_Sales_Rep__c = saveContactId;   
            
            if(hasOppId != true){   
            
            //Advertiser Industry
                System.debug('------------ List<SelectOption> AdvertiserIndustry' + AdvertiserIndustry);
                if(this.selectedIndustryId != NONE && this.selectedIndustryId != OTHER){
                    this.webOnBoardFormModel.Advertiser_Industry_Id__c = Integer.valueOf(this.selectedIndustryId);
                    for(SelectOption oneIndustry: AdvertiserIndustry){
                        if(oneIndustry.getValue().equals(this.selectedIndustryId)){
                            this.webOnBoardFormModel.Advertiser_Industry__c = oneIndustry.getLabel();
                            System.debug('----------- Adviser Industry Label before service call : ' + this.webOnBoardFormModel.Advertiser_Industry__c);
                        }
                    }
                }else if(this.selectedIndustryId == OTHER){
                    this.webOnBoardFormModel.Advertiser_Industry__c = OTHER;
                }
           
                //Advertiser Industry Focus
                System.debug('------------ List<SelectOption> AdvertiserIndustryFocus' + AdvertiserIndustryFocus);
                if(this.selectedIndustryFocusId != NONE && this.selectedIndustryFocusId != OTHER){
                    this.webOnBoardFormModel.Advertiser_Primary_Focus_Id__c = Integer.valueOf(this.selectedIndustryFocusId);
                    for(SelectOption oneIndustryFocus: AdvertiserIndustryFocus){
                        if(oneIndustryFocus.getValue().equals(this.selectedIndustryFocusId)){
                            this.webOnBoardFormModel.Advertiser_Primary_Focus__c = oneIndustryFocus.getLabel();
                            System.debug('---------- Adviser Industry Focus Label before service call : ' + this.webOnBoardFormModel.Advertiser_Primary_Focus__c);
                        }
                    }
                }else if(this.selectedIndustryFocusId == OTHER){
                    this.webOnBoardFormModel.Advertiser_Primary_Focus__c = OTHER;
                }
            }
            if (this.includeClientInfo != 'true'){               
                webOnBoardFormModel.Dashboard_Use_Primary_Contact__c = false;
            }else{
                webOnBoardFormModel.Client_First_Name__c = null;
                webOnBoardFormModel.Client_Last_Name__c = null;
                webOnBoardFormModel.Client_Email__c = null;
                webOnBoardFormModel.Dashboard_Use_Primary_Contact__c = true;
            }
                        
            if (this.includenotify != 'true'){
                webOnBoardFormModel.First_Email_Address__c = null;
                webOnBoardFormModel.Second_Email_Address__c = null;
                webOnBoardFormModel.Third_Email_Address__c = null;
                webOnBoardFormModel.Copy_Others_on_Fulfillment_Notifications__c = false;
            }else{
                webOnBoardFormModel.Copy_Others_on_Fulfillment_Notifications__c = true;
            }
            
            //Re-calculation targetted email budget & targetted Html fee DEV-1112 
            this.targettedEmailFormulaBudget();
            this.targettedEmailHtmlFee();
            
            //Manual resetting values on uncheck event of Retargeting, because it is custom fields, so it cannot clear by default
            if(!this.webOnBoardFormModel.GOO_Retargeting__c) {
                this.webOnBoardFormModel.Ad_Creative_Type__c = null;
                this.webOnBoardFormModel.Site_Budget__c = null;
                this.webOnBoardFormModel.Search_Budget__c = null;
                this.webOnBoardFormModel.Total_Budget__c = null;
                this.webOnBoardFormModel.RTG_Products_Services_to_Advertise_for__c = null;
                this.webOnBoardFormModel.RTG_Special_Offers__c = null;
                this.webOnBoardFormModel.Radius_Miles__c = null;
                this.webOnBoardFormModel.Radius_Centerpoint_Address__c = null;
                this.webOnBoardFormModel.Contract_Length_months_Retargeting__c = null;
                this.webOnBoardFormModel.GOO_Retargeting_Options__c = null;
            }
            
            // todo: add error handling
            insert(webOnBoardFormModel);
        }catch(DmlException ex){
           
            if(ex.getDmlStatusCode(0) !=null && ex.getDmlStatusCode(0) == 'FIELD_CUSTOM_VALIDATION_EXCEPTION'){
                //Warn Application Log  
                ApplicationLogsModel.insertApplicationLog(ex.getMessage(), ex.getStackTraceString(), String.valueOf(ex.getLineNumber()), 
                                                            null, 'OnBoardFormControllerExt', 'saveOnBoardForm', false, ApplicationLogsModel.Loglevel.Warn);
            }else{
                //Error Application Log
                ApplicationLogsModel.insertApplicationLog(ex.getMessage(), ex.getStackTraceString(), String.valueOf(ex.getLineNumber()), 
                                                            null, 'OnBoardFormControllerExt', 'saveOnBoardForm', false, ApplicationLogsModel.Loglevel.Error);
            }
            return this.currentPage;
        }catch(Exception ex){
            ApplicationLogsModel.insertApplicationLog(ex.getMessage(), ex.getStackTraceString(), String.valueOf(ex.getLineNumber()), 
                                                        null, 'OnBoardFormControllerExt', 'saveOnBoardForm', false, ApplicationLogsModel.Loglevel.Warn);
            return this.currentPage;
        }
        
        //Attachments DML
        try{
            //Re-Parenting all siteAttachment Id's to OnboardFormModel and
            //Deleting attachments on SiteAttachments Object
            Set<Id> newAttachmentIds = new Set<Id>();
            /*
                MEDIAKIT_LOGO, MEDIAKIT_IMAGES, CONTRACT_INFO, CLIENT_UPLOAD, DATABASE_LIST, LIABILITY_FORM, ASSET_IMAGE_LOGO_1, ASSET_IMAGE_LOGO_2, ASSET_IMAGE_LOGO_3, ASSET_IMAGE_LOGO_4
            */  
            if(this.logoUploadAttachment <> null && 
                    String.isNotBlank(this.logoUploadAttachment.AttachmentId)){
                 newAttachmentIds.add(this.logoUploadAttachment.AttachmentId);
            }
            if(this.LocationsUploadAttachment <> null && 
                    String.isNotBlank(this.LocationsUploadAttachment.AttachmentId)){
                 newAttachmentIds.add(this.LocationsUploadAttachment.AttachmentId);
            }
            if(this.EventCalendarUploadAttachment <> null && 
                    String.isNotBlank(this.EventCalendarUploadAttachment.AttachmentId)){
                 newAttachmentIds.add(this.EventCalendarUploadAttachment.AttachmentId);
            }
            if(this.ProductsServicesUploadAttachment <> null && 
                    String.isNotBlank(this.ProductsServicesUploadAttachment.AttachmentId)){
                 newAttachmentIds.add(this.ProductsServicesUploadAttachment.AttachmentId);
            }
            
            if(this.imagesCreativeFileAttachment <> null && 
                    String.isNotBlank(this.imagesCreativeFileAttachment.AttachmentId)){
                newAttachmentIds.add(this.imagesCreativeFileAttachment.AttachmentId);
            }
            
            if(this.contractFileAttachment <> null && 
                    String.isNotBlank(this.contractFileAttachment.AttachmentId)){
                newAttachmentIds.add(this.contractFileAttachment.AttachmentId);
            }
            
            //Targetted Email Blast
            /* Commneted out below Section as part of DEV-1073 
            if(this.ClientUploadFileAttachment <> null && 
                    String.isNotBlank(this.ClientUploadFileAttachment.AttachmentId)){
                newAttachmentIds.add(this.ClientUploadFileAttachment.AttachmentId);
            }*/
            
            //Managed Email Section
            if(this.webOnBoardFormModel.Managed_Email__c){
                if(this.DatabaselistFileAttachment <> null && 
                    String.isNotBlank(this.DatabaselistFileAttachment.AttachmentId)){
                    newAttachmentIds.add(this.DatabaselistFileAttachment.AttachmentId);
                }
                
                if(this.LiabilityFormFileAttachment <> null && 
                    String.isNotBlank(this.LiabilityFormFileAttachment.AttachmentId)){
                    newAttachmentIds.add(this.LiabilityFormFileAttachment.AttachmentId);
                }
            }
            
            //All 4 Attachments Social Media Management
            if(this.webOnBoardFormModel.Social_Media_Management__c){
                if(this.AssetImageLogo1FileAttachment <> null && 
                    String.isNotBlank(this.AssetImageLogo1FileAttachment.AttachmentId)){
                    newAttachmentIds.add(this.AssetImageLogo1FileAttachment.AttachmentId);
                }   
                
                if(this.AssetImageLogo2FileAttachment <> null && 
                    String.isNotBlank(this.AssetImageLogo2FileAttachment.AttachmentId)){
                    newAttachmentIds.add(this.AssetImageLogo2FileAttachment.AttachmentId);
                }
                
                if(this.AssetImageLogo3FileAttachment <> null && 
                    String.isNotBlank(this.AssetImageLogo3FileAttachment.AttachmentId)){
                    newAttachmentIds.add(this.AssetImageLogo3FileAttachment.AttachmentId);
                }
                
                if(this.AssetImageLogo4FileAttachment <> null && 
                    String.isNotBlank(this.AssetImageLogo4FileAttachment.AttachmentId)){
                    newAttachmentIds.add(this.AssetImageLogo4FileAttachment.AttachmentId);
                }
            }
            
            // DEV-6211
            if(this.webOnBoardFormModel.Opt_in_Email__c && this.webOnBoardFormModel.OptIn_Email_Creative_Option__c != null && 
               (this.webOnBoardFormModel.OptIn_Email_Creative_Option__c == 'Custom Design' || this.webOnBoardFormModel.OptIn_Email_Creative_Option__c == 'Semi-Custom Design'))
            {
                if(this.highResolutionLogoAttachment <> null && String.isNotBlank(this.highResolutionLogoAttachment.AttachmentId)){
                    newAttachmentIds.add(this.highResolutionLogoAttachment.AttachmentId);
                }  
                
                if(this.imageCopyAttachment <> null && String.isNotBlank(this.imageCopyAttachment.AttachmentId)){
                    newAttachmentIds.add(this.imageCopyAttachment.AttachmentId);
                }  
                
                if(this.webOnBoardFormModel.OptIn_Email_Creative_Option__c == 'Custom Design'){
                    if(this.marketingPiecesAttachment <> null && String.isNotBlank(this.marketingPiecesAttachment.AttachmentId)){
                        newAttachmentIds.add(this.marketingPiecesAttachment.AttachmentId);
                    }   
                }
            }
            
            List<Attachment> attachmentsToInsert = new List<Attachment>();
            List<Attachment> siteAttachments = [Select Name, Description, Body, ContentType from Attachment Where Id In: newAttachmentIds];
            for(Attachment oneAttachment: siteAttachments){
                Attachment newAttachment = new Attachment(); 
                newAttachment.Name=oneAttachment.Name;
                newAttachment.ContentType=oneAttachment.ContentType;
                newAttachment.Body = oneAttachment.Body;
                newAttachment.Description = oneAttachment.Description;
                newAttachment.ParentId = webOnBoardFormModel.Id;
                attachmentsToInsert.add(newAttachment);
            }
            
            insert attachmentsToInsert;
            delete siteAttachments;
            
            PageReference p;
            if(hasOppId == true)
                p = new PageReference('/' + oppId);
            else
                p = new PageReference('/ThankYouFromGLOnBoard');
            p.setRedirect(true);
            return p;
        }catch(Exception ex){
           
            ApplicationLogsModel.insertApplicationLog(ex.getMessage(), ex.getStackTraceString(), String.valueOf(ex.getLineNumber()), 
                                                        null, 'OnBoardFormControllerExt', 'saveOnBoardForm', true, ApplicationLogsModel.Loglevel.Error);
            return this.currentPage;                                                        
        }
    }
    
    /*
       Custom Apex Properties that requires validation on the backend
       Also, Some Object fields that have additional validation
    */
    private boolean ValidateFormFields(){
        isValid = true;
        
          //validate phone number  
         String errMessage = DigitalFormUtil.validatePhone(newcontact.Phone);
         if (errMessage != null){
             isValid = false;
             ApexPages.addMessage (new ApexPages.message(ApexPages.severity.Error, errMessage));
         } 
          //site
        if(hasOppId != true){
            //Advertiser Industry Name
            if(this.selectedIndustryId == NONE && webOnBoardFormModel.Current_Customer__c == false){
                isValid = false;
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Advertiser Industry: You must select a value',''));
            }
            //Advertiser Industry Focus
            if(this.selectedIndustryFocusId == NONE && webOnBoardFormModel.Current_Customer__c == false){
                isValid = false;
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Advertiser Primary Focus: You must select a value',''));
            }
            //Media Partner
            if(webOnBoardFormModel.Media_Partner__c == NONE_CONTACT_ID){
                isValid = false;
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Media Partner: You must select a value'));
            }
        } else if(hasOppId == true) {
           validateOppFields();
        }      
         
        //Site Budget
        if(this.webOnBoardFormModel.GOO_Retargeting__c != null && this.webOnBoardFormModel.GOO_Retargeting__c && String.isEmpty(siteBudget)){
            isValid = false;
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Site Budget: You must enter a value',''));
        }
        
        //Search Budget
        if(this.webOnBoardFormModel.GOO_Retargeting__c != null && this.webOnBoardFormModel.GOO_Retargeting__c && String.isEmpty(searchBudget)){
            isValid = false;
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Search Budget: You must enter a value',''));
        }
        
        //Media Kit>> Creative Upload attachment is manditory
        if (this.webOnBoardFormModel.GOO_Retargeting__c != null && this.webOnBoardFormModel.GOO_Retargeting__c  && this.webOnBoardFormModel.Ad_Creative_Type__c != null && this.webOnBoardFormModel.Ad_Creative_Type__c.equalsIgnoreCase('Creative Upload (Upload zip file)') && !(this.imagesCreativeFileAttachment <> null && String.isNotBlank(this.imagesCreativeFileAttachment.AttachmentId))  ){
            isValid = false;    
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Media Kit, Images/Creative Upload: You must upload a file',''));
        }
        if(this.webOnBoardFormModel.GOO_Retargeting__c != null && this.webOnBoardFormModel.GOO_Retargeting__c  && String.isNotEmpty(siteBudget) && (!siteBudget.isNumeric())){
            isValid = false; 
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Site Budget: Invalid currency',''));
        }
        if(this.webOnBoardFormModel.GOO_Retargeting__c != null && this.webOnBoardFormModel.GOO_Retargeting__c  && String.isNotEmpty(searchBudget) && (!searchBudget.isNumeric())){
            isValid = false; 
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Search Budget: Invalid currency',''));
        }
        //ContractInformation>> Contract File attachment is manditory ( DEV-5253 : If Media partner does not contains G/O Digital)
        if (isContractRequired <> null && isContractRequired && !(this.contractFileAttachment <> null && String.isNotBlank(this.contractFileAttachment.AttachmentId))){
            isValid = false;    
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Contract Information, Contract: You must upload a file',''));
        }
        
         //Business Locations Upload File attachment is manditory if there are more than 4 locations
        if (this.LocationsUploadAttachment == null && this.LocationsUploadAttachment.AttachmentId == null && webOnBoardFormModel.Number_of_Locations__c > 4) {
            isValid = false;    
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'You must upload Business Locations file'));
        }
        
        //Managed Email >> 'Attach signed Opt-in Liability Form' is required only if 'Database list upload (in excel or csv)' is uploaded
        if (this.webOnBoardFormModel.Managed_Email__c && this.DatabaselistFileAttachment <> null && String.isNotBlank(this.DatabaselistFileAttachment.AttachmentId)
             && !(this.LiabilityFormFileAttachment <> null && String.isNotBlank(this.LiabilityFormFileAttachment.AttachmentId))){
            isValid = false;    
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Opt-In Email System, Liability Form: You must upload a file',''));
        }
        if(!this.customWebsiteQuote()){
            isValid = false;
        }
        
        //DEV-8585
        if(!this.validatePPCFields()){
            isValid = false;
        }
        
        //DEV-6211
        if(!this.validateOptInEmail()){
            isValid = false;
        }
        
        if(!this.ValidateSOCustomSelect()){
            isValid=false;
        }
        
        if(!this.validSocialadsbugdet()){
            isValid=false;
        }
        
        if(!this.ValidateSEOPackage()){
            isValid=false;
        }
        
        //Number_of_Locations__c > 0
        if(this.webOnBoardFormModel.Local_Places_Reputation__c){
           if(this.webOnBoardFormModel.Number_of_Locations__c != null 
                && this.webOnBoardFormModel.Number_of_Locations__c <=0){
               isValid = false; 
               ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Maps & Reputation, Number of Locations: You must enter minimum 1 or above',''));
           }
        }
        
        //this code was added to give 30 day grace period for old count id format. it should be deleted after 10/05/17 and code below needs to be uncommented
        //CountId needs to be in the correct format 000000-0000-00000
        if(this.webOnBoardFormModel.Count_ID__c != null &&
           !(Pattern.matches('[0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9]', this.webOnBoardFormModel.Count_ID__c) ||
             Pattern.matches('[a-zA-Z][a-zA-Z]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9]', this.webOnBoardFormModel.Count_ID__c) && Date.Today() < Date.newInstance(2017, 11, 06))){
                isValid = false;
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Count ID: Incorrect format.',''));     
        }
    
        //CountId needs to be in the correct format 000000-0000-00000
        //if(this.webOnBoardFormModel.Count_ID__c != null && !Pattern.matches('[0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9]', this.webOnBoardFormModel.Count_ID__c){
        //    isValid = false;
        //    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Count ID: Incorrect format.',''));
        //}
        
        //Website Structure/Pages is required
        if(this.webOnBoardFormModel.Websites__c
                && String.IsNotBlank(this.webOnBoardFormModel.Website_Option__c) 
                && this.webOnBoardFormModel.Website_Option__c == 'Custom Website'){
            isValid = false;
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Website Structure/Pages: You must select a value',''));
        }
        //Rate Request ID / Notes - PPC is required
        if(this.webOnBoardFormModel.PPC__c && 
            (this.webOnBoardFormModel.Contract_Length_Months_PPC__c=='1' 
            || webOnBoardFormModel.Contract_Length_Months_PPC__c=='2' || this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c == '1' 
            || webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c == '2')){ 
                //DEV-9182
                /*if(this.webOnBoardFormModel.Rate_Request_ID__c == null 
                || this.webOnBoardFormModel.Rate_Request_ID__c == ''){  
                      isValid = false;
                      ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Custom Quote ID : You must enter a value',''));
                 }*/
                 if(webOnBoardFormModel.Notes_PPC__c == null 
                 || webOnBoardFormModel.Notes_PPC__c == ''){
                    isValid = false;
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Notes - PPC : You must enter a value',''));
                  }
         }  
          return isValid;
        
    }
    
    //DEV-8585
    private boolean validatePPCFields(){
        Boolean isValid = true;
        
        if(this.webOnBoardFormModel.PPC__c){
            if(this.webOnBoardFormModel.SellType_PPC__c == Null){
                isValid = false;
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Sell Type - PPC: You must enter a value',''));
            }
            if(this.webOnBoardFormModel.SellType_PPC__c != 'Budget Change' && this.webOnBoardFormModel.Contract_Length_Months_PPC__c == Null){
                isValid = false;
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Contract Length (months) - PPC: You must enter a value',''));
            }
            if(this.webOnBoardFormModel.SellType_PPC__c == 'Budget Change'){
                if(this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c == Null){
                    isValid = false;
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Contract Length (Months Remaining) - PPC: You must enter a value',''));
                }
                if(this.webOnBoardFormModel.PPC_BudgetAdj_Effective_Month__c == Null){
                    isValid = false;
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Effective Month - PPC: You must enter a value',''));
                }
            }
            
            Boolean isContractLengthMonth = this.webOnBoardFormModel.Contract_Length_Months_PPC__c != Null && this.webOnBoardFormModel.Contract_Length_Months_PPC__c.isNumeric();
            Boolean isContractLengthRemainingMonth = this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c != Null && this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c.isNumeric();
            if(this.webOnBoardFormModel.Rate_Request_ID__c == null && (isContractLengthMonth || isContractLengthRemainingMonth)){
                Integer contractLenMonths = isContractLengthMonth ? Integer.valueOf(this.webOnBoardFormModel.Contract_Length_Months_PPC__c) : Integer.valueOf(this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c);
                String errMsg;                
                errMsg = getPriceBookContractLength('PPC', contractLenMonths, isContractLengthMonth, isContractLengthRemainingMonth);
                if(errMsg != Null){ 
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, errMsg,''));
                    isValid = false;
                }
                if(errMsg == Null){
                    errMsg = validateVariableBudgets('PPC', contractLenMonths, this.webOnBoardFormModel.Is_This_a_Variable_Budget_PPC__c);
                    if(errMsg != Null){ 
                        ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, errMsg,''));
                        isValid = false;
                    }
                }
            }
            
            if(this.webOnBoardFormModel.Rate_Request_ID__c == Null && (this.webOnBoardFormModel.Does_this_order_include_a_spike_PPC__c || (this.webOnBoardFormModel.Contract_Length_Months_PPC__c != Null && this.webOnBoardFormModel.Contract_Length_Months_PPC__c == 'Spike') || 
               (this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c != Null && this.webOnBoardFormModel.Contract_Length_Months_Remaining_PPC__c == 'Spike'))){
                   Date reqStartDate = this.webOnBoardFormModel.Requested_Start_Date_PPC__c;
                   Date reqEndDate = this.webOnBoardFormModel.Requested_End_Date_PPC__c;
                   
                   if(reqStartDate != Null && reqEndDate != Null){
                       if(reqStartDate > reqEndDate){
                           isValid = false;    
                           ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Requested Start Date - PPC must be greater than or equal to Requested End Date - PPC',''));
                       }
                       if((reqStartDate.daysBetween(reqEndDate)) > 27){
                           isValid = false;    
                           ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'The total duration between Requested Start Date - PPC and Requested End Date - PPC must be less than or equal to 27 days',''));
                       }
                   }
               }
        }
        return isValid;
    }
    
    // DEV-6211
    public string monthlySends{get; set;}
    
    public boolean validateOptInEmail(){
        Boolean isValid = true;
        this.webOnBoardFormModel.Monthly_Sends__c = monthlySends != null && monthlySends.isNumeric() ? Decimal.valueOf(monthlySends) : null;
        
        if(this.webOnBoardFormModel.Opt_in_Email__c){
            
            if(this.webOnBoardFormModel.OptIn_Email_Creative_Option__c == null){
                isValid = false;    
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Email Creative Option: You must enter a value',''));
            }
            
            // DEV-6950 Starts.
            if(this.webOnBoardFormModel.OptIn_Email_Creative_Option__c.equalsIgnoreCase('Custom Design') && (this.webOnBoardFormModel.Quantity_of_Custom_Design__c == null || this.webOnBoardFormModel.Quantity_of_Custom_Design__c <= 0)){
                isValid = false;
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Quantity of Custom Design must have a value greater than zero',''));
            }
            if(this.webOnBoardFormModel.OptIn_Email_Creative_Option__c.equalsIgnoreCase('Semi-Custom Design') && (this.webOnBoardFormModel.Quantity_of_Semi_Custom_Design__c == null || this.webOnBoardFormModel.Quantity_of_Semi_Custom_Design__c <= 0)){
                isValid = false;
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Quantity of Semi-Custom Design must have a value greater than zero',''));
            }
            // DEV-6950 Ends.

            if(this.webOnBoardFormModel.Monthly_Sends_Unlimited__c == false && this.webOnBoardFormModel.Monthly_Sends__c == null){
                isValid = false;    
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Monthly Sends : You must enter a value',''));
            }
        }
        return isValid;
    }
    
    //ValidateSOCustomSelect
    //Validation that cannot select Custom unless URL included in Row 38 (Audit__c)
    public boolean ValidateSOCustomSelect(){
        Boolean isValid = true;
        if(this.webOnBoardFormModel.Social_Media_Management__c && String.IsNotBlank(this.webOnBoardFormModel.Social_Option__c)){
            if(this.webOnBoardFormModel.Social_Option__c == 'Social Management Custom' 
                    && String.IsBlank(this.webOnBoardFormModel.Audit__c)){
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Social Option: You cannot select (Social Management Custom) without Audit Url in Contract Information',''));
                //this.webOnBoardFormModel.Audit__c.addError('You cannot select (Custom Social Package) without Audit Url in Contract Information');
                isValid = false;
            }
            
            if(this.webOnBoardFormModel.Social_Option__c == 'Social Management Custom' 
                    && String.IsNotBlank(this.webOnBoardFormModel.Audit__c)){
                if(this.webOnBoardFormModel.Social_Budget__c < 3000){
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Social Budget: You must enter minimum $3000',''));
                    this.webOnBoardFormModel.Social_Budget__c.addError('You must enter minimum $3000');
                    isValid = false;
                }
            }
            
            //DEV-8927
            /*if(this.webOnBoardFormModel.Social_Option__c == 'Social Management Reach Ad Spend'){
                if(this.webOnBoardFormModel.Social_Budget__c < 1){
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Social Budget: You must enter minimum $1',''));
                    this.webOnBoardFormModel.Social_Budget__c.addError('You must enter minimum $1');
                    isValid = false;
                }
            }*/
        }
        return isValid;
    }
    
    // SEO Validation rule " Validation that cannot select National/Custom Quote SEO Package unless URL (Audit) is included"
    // if National/Custom Quote SEO Package is selected with a minimum value validation of $7700.
    public boolean ValidateSEOPackage(){
        if(this.webOnBoardFormModel.SEO__c 
            && String.IsNotBlank(this.webOnBoardFormModel.SEO_Package__c)
            && this.webOnBoardFormModel.SEO_Package__c == 'National/Custom Quote SEO Package'){
            if(String.IsBlank(this.webOnBoardFormModel.Audit__c)){
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'SEO Package: You cannot select <National/Custom Quote SEO Package> without Audit Url in Contract Information',''));
                return false;
            }else if(String.IsNotBlank(this.webOnBoardFormModel.Audit__c)){
                if(this.webOnBoardFormModel.SEO_Budget__c < 7700){
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'SEO Budget/Mth: You must enter minimum $7700',''));
                    return false;
                }
            }
        }
        return true;
    }
    
    // Social_Budget__c - UPDATE budget population based on Social_Option__c selection:
    // Social Management Launch = $999 (no change)
    // Social Management Engage = $1699 (no change)
    // Social Management Expand = $2999 (no change)
    // Social Management Reach Ad Spend = Currency entry (7,0); >=1
    // Social Management Weekend Coverage = $1,200 (add)
    // Social Management Custom = Currency entry (7,0); >=3000)
    public void setSocialBudget(){
        //DEV-8927
        Decimal reachMediaSpend = 0;
        if(this.webOnBoardFormModel.SocialMediaMgmt_Spend_Budget__c != null){
            reachMediaSpend = this.webOnBoardFormModel.SocialMediaMgmt_Spend_Budget__c;
        }
        if(this.webOnBoardFormModel.Social_Media_Management__c && String.IsNotBlank(this.webOnBoardFormModel.Social_Option__c)){
            if(SOCIAL_BUDGET_BY_MGMT_OPTIONS.get(this.webOnBoardFormModel.Social_Option__c)<>null){
                  this.webOnBoardFormModel.Social_Budget__c = Integer.valueOf(SOCIAL_BUDGET_BY_MGMT_OPTIONS.get(this.webOnBoardFormModel.Social_Option__c)) + reachMediaSpend;
            }else{
                this.webOnBoardFormModel.Social_Budget__c = this.webOnBoardFormModel.SocialMediaMgmt_Spend_Budget__c;
            }
        }else {
            this.webOnBoardFormModel.Social_Budget__c = this.webOnBoardFormModel.SocialMediaMgmt_Spend_Budget__c != null ? this.webOnBoardFormModel.SocialMediaMgmt_Spend_Budget__c : null;
        }
    }
    
    //setTargetEmailBudget
    //Currency field with calculated value as follows:  
    //if Email Blast Quantity = 1 or 2, then $250 + ((Email Recipients x 1or2_Quantity_Rate  
    //if Email Blast Count = 3+, then $150 + ((Email Recipients x 3+_Quantity_Rate)/1000).  
    //1or2_Quantity_rate for 10,000-49,999 = $80; 
    //50,000-74,999 = $50; 75,000-99,999 = $40; 100,000+ = $35.  
    //3+_Quantity_rate for 10,000-49,999 = $70; 50,000-74,999 = $45; 75,000-99,999 = $35; 100,000+ = $30.
    
    //TODO
    public void setTargetEmailBudget(){
        
    }
    
    //Managed Email Budget
    //Auto filled based on selection above at 0-499 = $25; 500-2,499 = $45; 2,500-4,999 = $65, 5,000-9,999 = $110, 10,000-15,000 = $140.
    public void setManagedEmailBudget(){
        if(this.webOnBoardFormModel.Managed_Email__c && string.isnotblank(this.webOnBoardFormModel.Email_Subscribers__c)){
            if(this.webOnBoardFormModel.Email_Subscribers__c == '0-499'){
                this.webOnBoardFormModel.Managed_Email_Budget__c =25;
            }else if(this.webOnBoardFormModel.Email_Subscribers__c == '500-2,499'){
                this.webOnBoardFormModel.Managed_Email_Budget__c =45;
            }else if(this.webOnBoardFormModel.Email_Subscribers__c == '2,500-4,999'){
                this.webOnBoardFormModel.Managed_Email_Budget__c =65;
            }else if(this.webOnBoardFormModel.Email_Subscribers__c == '5,000-9,999'){
                this.webOnBoardFormModel.Managed_Email_Budget__c =110;
            }else if(this.webOnBoardFormModel.Email_Subscribers__c == '10,000-15,000'){
                this.webOnBoardFormModel.Managed_Email_Budget__c =140;
            }else{
                this.webOnBoardFormModel.Managed_Email_Budget__c =0;
            }
        }else{
            this.webOnBoardFormModel.Managed_Email_Budget__c =0;
        }
    }
    
    //Validate social ads budget
    //Currency field with validation of minimal value of $500, 
    //and start must be = $500, $750, $1000, $1500, $2000; 
    //Build must be between $2001, and $7499; 
    //Grow must be $7500 or above 
    public boolean validSocialadsbugdet(){
        //These validation rules are commentted as part of Story DEV-8584 && DEV-5968
        /*if(this.webOnBoardFormModel.Social_Advertising__c 
            && this.webOnBoardFormModel.Social_Ads_Budget_Month__c <>null
            && String.IsNotBlank(this.webOnBoardFormModel.Social_Ads_Package__c)){
            if(this.webOnBoardFormModel.Social_Ads_Budget_Month__c <500){
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Social Ads Budget/Month: You must enter minimum $500',''));
                return false;
            }
            if(this.webOnBoardFormModel.Social_Ads_Package__c == 'Start'){
                if(this.webOnBoardFormModel.Social_Ads_Budget_Month__c <> 500
                   && this.webOnBoardFormModel.Social_Ads_Budget_Month__c <> 650
                   && this.webOnBoardFormModel.Social_Ads_Budget_Month__c <> 750){
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Social Ads Budget/Month(Start): You must enter $500, $650, $750',''));
                    return false;
                }
            }else if(this.webOnBoardFormModel.Social_Ads_Package__c == 'Climb'){
                if(!(this.webOnBoardFormModel.Social_Ads_Budget_Month__c >= 750
                      && this.webOnBoardFormModel.Social_Ads_Budget_Month__c < 2000)){
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Social Ads Budget/Month(Climb): You must enter between $750, and $1999',''));
                    return false;
                }
            }else if(this.webOnBoardFormModel.Social_Ads_Package__c == 'Build'){
                //DE556
                if(!(this.webOnBoardFormModel.Social_Ads_Budget_Month__c >= 2000
                    && this.webOnBoardFormModel.Social_Ads_Budget_Month__c < 7500)){
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Social Ads Budget/Month(Build): You must enter between $2000, and $7499',''));
                    return false;
                }
            }else if(this.webOnBoardFormModel.Social_Ads_Package__c == 'Grow'){
                if(this.webOnBoardFormModel.Social_Ads_Budget_Month__c < 7500){
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Social Ads Budget/Month(Grow): You must enter $7500 or above',''));
                    return false;
                }
            }
        }*/
        //DEV-8584
        if(this.webOnBoardFormModel.Social_Advertising__c){
            if(this.webOnBoardFormModel.SellType_SocialAds__c == Null){
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Sell Type - Social Ads: You must enter a value',''));
                return false;
            }
            if(this.webOnBoardFormModel.SellType_SocialAds__c != 'Budget Change' && this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c == Null){
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Contract Length (months) - Social Ads: You must enter a value',''));
                return false;
            }
            if(this.webOnBoardFormModel.SellType_SocialAds__c == 'Budget Change'){
                if(this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c == Null){
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Contract Length (Months Remaining) - Social Ads: You must enter a value',''));
                    return false;
                }
                if(this.webOnBoardFormModel.SocialAds_BudgetAdj_Effective_Month__c == Null){
                    isValid = false;
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Effective Month - Social Ads: You must enter a value',''));
                }
            }

            Boolean isContractLengthMonth = this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c != Null && this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c.isNumeric();
            Boolean isContractLengthRemainingMonth = this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c != Null && this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c.isNumeric();
            if(this.webOnBoardFormModel.Rate_Request_ID__c == null && (isContractLengthMonth || isContractLengthRemainingMonth)){
                Integer contractLenMonths = isContractLengthMonth ? Integer.valueOf(this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c) : Integer.valueOf(this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c);
                String errMsg;
                errMsg = getPriceBookContractLength('SocialAdvertising', contractLenMonths, isContractLengthMonth, isContractLengthRemainingMonth);
                if(errMsg != Null){ 
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, errMsg,''));
                    isValid = false;
                }
                if(errMsg == Null){
                    errMsg = validateVariableBudgets('SocialAdvertising', contractLenMonths, this.webOnBoardFormModel.Is_This_a_Variable_Budget_SocAd__c);
                    if(errMsg != Null){ 
                        ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, errMsg,''));
                        isValid = false;
                    }
                }
            }
            
            if(this.webOnBoardFormModel.Rate_Request_ID__c == null && (this.webOnBoardFormModel.Does_this_order_include_a_spike_SocAd__c || (this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c != Null && (this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c == 'Spike' || this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c == 'Event')) || 
               (this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c != Null && (this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c == 'Spike' || this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c == 'Event') ))){
                   Date reqStartDateSocAd = this.webOnBoardFormModel.Requested_Start_Date_SocAd__c;
                   Date reqEndDateSocAd = this.webOnBoardFormModel.Requested_End_Date_SocAd__c;
                   
                   if(reqStartDateSocAd != Null && reqEndDateSocAd != Null){
                       if(reqStartDateSocAd > reqEndDateSocAd){
                           ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Requested Start Date - Social Ads must be greater than or equal to Requested End Date - Social Ads',''));
                           return false;
                       }
                       if((reqStartDateSocAd.daysBetween(reqEndDateSocAd)) > 27){
                           ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'The total duration between Requested Start Date - Social Ads and Requested End Date - Social Ads must be less than or equal to 27 days',''));
                           return false;
                       }
                   }
               }
            if(this.webOnBoardFormModel.Social_Advertising__c == true && this.webOnBoardFormModel.Rate_Request_ID__c == null){
                if(this.webOnBoardFormModel.Contract_Length_Months_SocialAds__c == 'Event' && this.webOnBoardFormModel.Social_Ads_Event_Budget__c < 1400){
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Social Ads Event Budget field must be ≥ $1,400','')); 
                    return false; 
                }
                if(this.webOnBoardFormModel.Contract_Length_Months_Remaining_SocAd__c == 'Event' && this.webOnBoardFormModel.Social_Ads_Event_Budget__c < 1400){
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Social Ads Event Budget field must be ≥ $1,400','')); 
                    return false;   
                }
            }
        }
        return true;
    }
    
	//DEV-5968    
    private String validateVariableBudgets(String productType, Integer contractLength, Boolean budgetVar){
        System.debug('Enter into validateVariableBudgets method');
        
        Variable_Budget_Setting__mdt variableBudSetting;
        for(Variable_Budget_Setting__mdt currVBS : [SELECT Id, Label, DeveloperName, Budget_Amount__c, Allow_Zero_Value__c, Contract_Length_Start_Range__c, Contract_Length_End_Range__c, Number_of_Allowed_Zero__c, Error_Message__c FROM Variable_Budget_Setting__mdt WHERE Product_Type__c =:productType AND Contract_Length_Start_Range__c != Null AND Contract_Length_End_Range__c != Null ORDER BY DeveloperName]){
            if(currVBS.Contract_Length_Start_Range__c <= contractLength && currVBS.Contract_Length_End_Range__c >= contractLength){
                if(currVBS.Allow_Zero_Value__c == false){
                    variableBudSetting = currVBS; 
                    break;
                }
                else{
                    variableBudSetting = currVBS;
                    break;
                }
            }
        }
        
        System.debug('Valid Budget Setting Found:'+variableBudSetting);
        if(variableBudSetting != Null && (productType == 'PPC' || productType == 'SocialAdvertising')){
            String dynamicBudgetFieldName = productType == 'PPC' ? 'PPC_Budget_' : 'Social_Ads_Budget_Month_';
            String staticBudgetFieldName = productType == 'PPC' ? 'PPC_Budget__c' : 'Social_Ads_Budget_Month__c';
            Integer zeroAmountCount = 0, minBudgetAmountCount = 0;
            
            if(budgetVar == TRUE){
                for(integer i = 1; i <= contractLength; i++){
                    Decimal bugAmount;
                    if(i==1)
                        bugAmount = this.webOnBoardFormModel.get(staticBudgetFieldName) != Null ? (Decimal)this.webOnBoardFormModel.get(staticBudgetFieldName) : 0;
                    else
                        bugAmount = this.webOnBoardFormModel.get(dynamicBudgetFieldName+i+'__c') != Null ? (Decimal)this.webOnBoardFormModel.get(dynamicBudgetFieldName+i+'__c') : 0;
                    
                    if(bugAmount <= 0)
                        zeroAmountCount += 1;
                    else if(bugAmount < variableBudSetting.Budget_Amount__c)
                        minBudgetAmountCount += 1;
                }
                
                if((zeroAmountCount > variableBudSetting.Number_of_Allowed_Zero__c) || (minBudgetAmountCount > 0))
                    return variableBudSetting.Error_Message__c;
            }
            else{
                Decimal budgetAmount = this.webOnBoardFormModel.get(staticBudgetFieldName) != Null ? (Decimal)this.webOnBoardFormModel.get(staticBudgetFieldName) : 0;
                if(budgetAmount < 525){
                    String errMsg = productType == 'PPC' ? 'PPC Budget field should be contain a value ≥ 525': 'Social Ads Budget/Month field should be contain a value ≥ 525';
                    return errMsg;
                }
            }
        }
        
        return null;
    }
    
    //DEV-5968    
    private String getPriceBookContractLength(String productType, Integer contractLength, Boolean isContractLengthMonth, Boolean isContractLengthRemainingMonth){
        System.debug('Enter into getPriceBookContractLength method');

        if(this.webOnBoardFormModel.Media_Partner__c != null){
            Account acc = [SELECT Id, Price_Book__c, Price_Book__r.Name FROM Account WHERE Id =:webOnBoardFormModel.Media_Partner__c AND Price_Book__c != Null];
            System.debug('Account Media Partner: '+acc.Price_Book__c);
            
            if(acc != Null){
                List<Variable_Budget_Setting__mdt> variableBudgetSettings;
                
                if(productType == 'PPC'){
                    variableBudgetSettings = [SELECT Id, Label, DeveloperName, Package_Name__c, Product_Type__c, Product_Name__c, Error_Message__c FROM Variable_Budget_Setting__mdt 
                                              WHERE Product_Type__c=:productType AND Package_Name__c =:productType ORDER BY DeveloperName];
                }
                else if(productType == 'SocialAdvertising' && this.webOnBoardFormModel.Social_Ads_Package__c != Null){
                    String socialAdPackValue = (String)this.webOnBoardFormModel.get('Social_Ads_Package__c');
                    
                    if(acc.Price_Book__r.Name == 'USCP Wholesale Price Book'){
                        variableBudgetSettings = [SELECT Id, Label, DeveloperName, Package_Name__c, Product_Type__c, Price_Book_Name__c, Product_Name__c, Error_Message__c FROM Variable_Budget_Setting__mdt 
                                                  WHERE Package_Name__c =:socialAdPackValue AND Product_Type__c=:productType AND Price_Book_Name__c =:acc.Price_Book__r.Name ORDER BY DeveloperName];
                    }
                    else{
                        variableBudgetSettings = [SELECT Id, Label, DeveloperName, Package_Name__c, Product_Type__c, Price_Book_Name__c, Product_Name__c, Error_Message__c FROM Variable_Budget_Setting__mdt 
                                                  WHERE Package_Name__c =:socialAdPackValue AND Product_Type__c=:productType AND Price_Book_Name__c = Null ORDER BY DeveloperName];
                    }                    
                }
                
                System.debug('Enter into getPriceBookContractLength method variableBudgetSettings value'+variableBudgetSettings);
                if(variableBudgetSettings != Null && !variableBudgetSettings.isEmpty() && variableBudgetSettings[0].Product_Name__c != Null){
                    String prodName = variableBudgetSettings[0].Product_Name__c;
                    List<PriceBookEntry> priceBookEntryList = [SELECT Id, Min_Number_of_Contract_Months__c FROM PriceBookEntry WHERE Pricebook2Id =:acc.Price_Book__c AND Product2.Name =:prodName];
                    System.debug('Enter into getPriceBookContractLength method priceBookEntryList value'+priceBookEntryList);
                    
                    if(priceBookEntryList != Null && !priceBookEntryList.isEmpty() && priceBookEntryList[0].Min_Number_of_Contract_Months__c != Null){
                        Integer minContractLen = priceBookEntryList[0].Min_Number_of_Contract_Months__c != Null ? Integer.valueOf(priceBookEntryList[0].Min_Number_of_Contract_Months__c): Null;
                        System.debug('Contract Length: '+contractLength+'## Min Contract Length: '+minContractLen);
                        if(minContractLen != Null && contractLength < minContractLen){
                            if(productType == 'PPC'){
                                if(isContractLengthMonth){
                                    if(!(contractLength == 1 || contractLength == 2 )){
                                        return 'PPC: Contract Length (months) Should be greater than or equal to '+minContractLen;
                                    }else if((contractLength == 1 || contractLength == 2) && (this.webOnBoardFormModel.Rate_Request_ID__c == null || this.webOnBoardFormModel.Notes_PPC__c == null)){
                                        return 'PPC: Contract Length (months) Should be greater than or equal to '+minContractLen+' OR Custom Quote ID must have value';
                                    }
                                }
                                else if(isContractLengthRemainingMonth){
                                    if(!(contractLength == 1 || contractLength == 2 )){
                                        return 'PPC: Contract Length (Months Remaining) Should be greater than or equal to '+minContractLen;
                                    }else if((contractLength == 1 || contractLength == 2) && (this.webOnBoardFormModel.Rate_Request_ID__c == null || this.webOnBoardFormModel.Notes_PPC__c == null)){
                                        return 'PPC: Contract Length (Months Remaining) Should be greater than or equal to '+minContractLen+' OR Custom Quote ID must have value';
                                    }
                                }
                            }
                            else if(productType == 'SocialAdvertising'){
                                if(isContractLengthMonth){
                                    return 'Social Advertising: Contract Length (months) Should be greater than or equal to '+minContractLen;
                                }
                                else if(isContractLengthRemainingMonth){
                                    return 'Social Advertising: Contract Length (Months Remaining) Should be greater than or equal to '+minContractLen;
                                }
                            }
                        }
                    }
                }
            }
        }
        return null;
    }
    //DEV-8915
    public void restrictedMediaPartner(){
        deactivatePartnerMarket = new Set<String>();
        List<Deactivate_Partner_Market__mdt> partnerMarket = new List<Deactivate_Partner_Market__mdt>([SELECT Label FROM Deactivate_Partner_Market__mdt]);
        for(Deactivate_Partner_Market__mdt dpm : partnerMarket){
            deactivatePartnerMarket.add(dpm.Label);  
        }
    }
    
     public static List<Contact> searchContactsRl(String searchString){
        //just scan name/email/phone
        List<Contact> cList = new List<Contact>();
        RecordType rt = RecordTypeCache.getRecordType('Contact', Constants.CONTACT_RECORD_TYPE_AFFILIATED);        
        String searchQuery = 'FIND \'' + searchString + '\' IN ALL Fields RETURNING ' +
                             'Contact (Id, Name, LastName, FirstName, Web_Submitter__c, Phone, Email, Title, AccountId, Account.Name ' +
                                  'Where RecordTypeId = \'' + rt.Id + '\' and LastName != \'In List\' and ' +
                                      'Email != \'\' and Email != null and Web_Submitter__c = True and ' + 
                                      'Account.Partner_Type__c = \'' + RLPartnerType + '\')';
        //System.debug('-----------------------' + searchQuery);                    
        List<List <sObject>> searchList = search.query(searchQuery);
        
        if(searchList != null){
            clist = ((List<contact>)searchList[0]);
        }
        
        return cList;
    }   
}