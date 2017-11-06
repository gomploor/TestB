/**
       
    Last Modified by : Paul Juneau
    Date             : 6/7/2016
                 : 07/18/2016 : Vijaya Varada : DEV-4735 PropGen: Automation Related Changes
    Last Modified by: Matthew Shiner
    Date: 10/14/2016
    Description: DEV-8300 - Removed validation check for Website, since there is a validation check in before insert trigger handler that allows
                            no http/https.
    Last Modified by: Matthew Shiner
    Date: 4/21/2017
    Description: DEV-11456 - Removing all code that relates to Call Request case.

*/

public without sharing class DigitalAuditExtension {
    //Constants
    public Static Final String HELPTEXT_TYPEOFAUDIT = 'Digital Snapshot: Conversation starting tool to support a client needs assessment.  Budgets and Expectations: One sheet PDF with suggested budgets and performance expectations.  Full Digital Proposal: Budgets and Expectations with additional details of the "why" behind the recommendation.';
    public Static Final String TRUE_VAL = 'true';
    public Static Final String DIGAUDIT_DESCR = 'Digital Audit Request';
    public Static Final String EMAIL_DESCR =    'Email Count Request';
    public Static Final String WEBSITE_DESCR =  'Website Quote Request';
    public Static Final String CALL_DESCR =     'Sales Call Request';
    public Static Final String DIGITAL_SNAPSHOT = 'Digital Snapshot';
    public Static Final String FULL_DIGITAL_PROPOSAL =  'Full Digital Proposal (Industry Info, Digital Footprint, Budgets and Expectations)';
    public Static Final String NO = 'No';
    public Case oneCase {get; set;}
    //DEV-9783
    //public Boolean isPPC {get;set;}
    public Contact newContact {get; set;}
    public List<Contact> contactList2 {get; set;}
    public List<Contact> contactList {get; set;}
    public RecordType rt {get; set;}
    public String sessionId {get; set;}
    public String url {get; set;}
    public String includeDigitalAudit {get;set;}
    public String includeLetter {get;set;}
    public String includeSalesReps {get;set;}
    public String includeWebsiteQuote {get;set;}
    public String includeWebsiteType {get;set;}//full or lead capture
    public String isClientUsingGOServices {get;set;}
    public String includeEmailCount {get;set;}
    //public String landingTypeOptions {get;set;}
    public String leadCaptureTypeOptions {get;set;}
    public String fullPageTypeOptions {get;set;}
    public String onlinePresence {get;set;}
    public String includeNotify {get;set;}
    public String includeAttach {get;set;}
    public String Notify1 {get;set;}
    public String Notify2 {get;set;}
    public String Notify3 {get;set;}
    public String saveContactId {get; set;}
    public String Message {get; set;}
    
    public Id RelatedCompany {get; set;}
    
    //attachements
    public String contentType {get; set;}
    public String fileName {get;set;}
    public Blob file {get; set;}
    public Boolean submitted {get;set;}
    public String fileName2 {get;set;}
    public Blob file2 {get; set;}
    public String fileName3 {get;set;}
    public Blob file3 {get; set;}

    public String searchString {get; set;}
    public String errorMessage {get; set;}
    public String contactName {get; set;}
    public Boolean emailOnly {get; set;}
    public Boolean hasOppId {get; set;}
    public Boolean editContactInfo {get; set;}
    public Boolean editClientInfo {get; set;}
    public Boolean editDsClientInfo {get; set;}
    public Id oppId {get;set;}
    //public String inputParent {get; set;}
    //public String newCaseId;
    
    //contants so it's not hardcoded 10 times everywhere
    public final String strNotInList = 'Not In List';
    public final String strChoseOne = '--Choose One--';
    public final String strSearchRep = 'Search for Sales Rep';
    
    //Excluding ClipperPartnerType, CLP, as per requirements of Sprint 2.16.12, Story DEV-5252, "Inactivate Clipper Partner companies"
    public static final String ClipperPartnerType = 'CLP';
    public static final String RLPartnerType = 'RL';
    
    
    //error messages - will put here for now
    public final String errNoSearchValue = 'Please enter value to search';
    public final String errSearchValue2char = 'Search value must be at least 2 char';
    public final String errNoContactsFound = 'No contacts found. Select \'Not In List\' to create a new contact';
    
    public List<SelectOption> ContactNames{get;set;}
    public Boolean boolShowContacts {get;set;}
    
    public Case digaudRequest{get;set;}
    public Case EcountRequest{get;set;}
    public Case WebsiteRequest{get;set;}
    public Id firstMediaPartner;
    public Boolean isValid = true;
    public Boolean isValidDigAudit;
    public Map<String, Contact> contactMap = new Map<String, Contact>();
    public static Map<String, String> eCommereceAddress = new Map<String,String>
    {
        'Address'     => '123 ecommerce street',
        'City'        => 'Phoenix',
        'State'       => 'AZ',
        'PostalCode'  => '85083'
    };
    public static Map<String, Map<String, String>> mapAddressFieldApis = new Map<String,Map<String, String>>
    {
        'Client'        => new Map<String, String>
                            {
                                'DA_Client_Address__c'     => 'Address', 
                                'DA_Client_City__c'        => 'City', 
                                'DA_Client_State__c'       => 'State',
                                'DA_Client_Postal_Code__c' => 'PostalCode'
                            },
        'Competitor1'   => new Map<String, String>
                            {
                                'DA_Competitor1_Address__c'     => 'Address', 
                                'DA_Competitor1_City__c'        => 'City', 
                                'DA_Competitor1_State__c'       => 'State',
                                'DA_Competitor1_Zip_Code__c' => 'PostalCode'
                            },
        'Competitor2'   => new Map<String, String>
                            {
                                'DA_Competitor2_Address__c'     => 'Address', 
                                'DA_Competitor2_City__c'        => 'City', 
                                'DA_Competitor2_State__c'       => 'State',
                                'DA_Competitor2_Zip_Code__c' => 'PostalCode'
                            }
    };
    
    public List<String> selectedMediaPartners {
        get {
            if (selectedMediaPartners == null) {
                selectedMediaPartners = new List<String>();
            }
            return selectedMediaPartners;
        }
        
        set;
    }

    private BusinessHours defaultBusinessHour;
    
    /**
    * @description
    */

    public DigitalAuditExtension(ApexPages.StandardController ctl) {
        this.oneCase = (Case)ctl.getRecord();
        this.oneCase.RecordTypeId =  RecordTypeCache.getRecordType('Case', Constants.CASE_RECORD_TYPE_GL_DIGITAL_AUDIT).Id;
        //cases
        digaudRequest = new Case();
        digaudRequest.RecordTypeId =  RecordTypeCache.getRecordType('Case', Constants.CASE_RECORD_TYPE_GL_DIGITAL_AUDIT).Id;
        EcountRequest = new Case();
        ECountRequest.RecordTypeId = RecordTypeCache.getRecordType('Case', Constants.CASE_RECORD_TYPE_GL_EMAIL_COUNT).Id;
        WebsiteRequest = new Case();
        WebsiteRequest.RecordTypeId =  RecordTypeCache.getRecordType('Case', Constants.CASE_RECORD_TYPE_GL_WEBSITE_AUDIT).Id;
        newContact = new Contact();
        boolShowContacts = false;
        ContactName = strSearchRep;
        ContactNames = new List<SelectOption>();  
        ContactNames.add(new SelectOption(strSearchRep,strSearchRep));
        
        String email = ApexPages.currentPage().getParameters().get('email');
      
        if(email != null && email == 'RL'){
            includeEmailCount = 'true';
            emailOnly = true;
        } else {
            emailOnly = false;
        }
        
        hasOppId = false;
        editContactInfo = true;
        editClientInfo = true;
        editDsClientInfo = true;
        oppId = ApexPages.currentPage().getParameters().get('oppId');
        if(oppId!=null){
           hasOppId = true;
           Opportunity opp = [select Id, Media_Partner__c, AccountId, Account.Name, Account.Phone, Account.Website, Account.BillingStreet, Account.BillingCity, Account.BillingState,
                              Account.BillingPostalCode,  Account.Account_Primary_Industry__c,  Account.Account_Primary_Focus__c, Dig_Account_Manager__c,
                              Account.Alt_Direct_Phone__c, Sales_Rep__c
                              from Opportunity where Id = :oppId ];
           //get related contact will return null contact if not found.
           if(opp.Sales_Rep__c != null){
               List<Contact> contList = new List<Contact>([select Id, LastName, FirstName, Phone 
                                                            from Contact where Id  = :opp.Sales_Rep__c]);
               if(contList != null && !contList.isEmpty()){
                  newContact = contList[0];
               }
           }
           oneCase.Media_Partner__c = opp.Media_Partner__c;
           oneCase.Company_Name__c = opp.Account.Name; 
           oneCase.AccountId = opp.AccountId;
           oneCase.Opportunity__c = opp.Id;
           oneCase.Dig_Account_Manager__c = opp.Dig_Account_Manager__c;
           if(newContact != null){
              oneCase.Affl_Sales_Rep__c = newContact.Id;
              digaudRequest.Contact_Name__c  = newContact.LastName;
           }
           digaudRequest.DA_Client_Address__c = opp.Account.BillingStreet;
           digaudRequest.DA_Client_City__c = opp.Account.BillingCity;
           digaudRequest.DA_Client_State__c = opp.Account.BillingState;
           digaudRequest.DA_Client_Postal_Code__c = opp.Account.BillingPostalCode;
           digaudRequest.Contact_Phone__c = opp.Account.Phone;
           digaudRequest.DA_Client_Phone_Number__c = opp.Account.Alt_Direct_Phone__c;
           if (opp.Account.Website != null){
                if (opp.Account.Website.startsWith('http://') || opp.Account.Website.startsWith('https://')  )
                    digaudRequest.DA_Website__c = opp.Account.Website;
                else
                    digaudRequest.DA_Website__c = 'http://' + opp.Account.Website;
            }    
           oneCase.Case_Primary_Industry__c = opp.Account.Account_Primary_Industry__c;
           oneCase.Case_Primary_Focus__c = opp.Account.Account_Primary_Focus__c;
           validateOppFields();
        }
    }
    
    /**
    * @description
    */
    
    public void resetWebsiteOptions(){
        if(includeWebsiteQuote == 'false'){
            includeWebsiteType = 'Choose One';
            fullPageTypeOptions = 'Choose One';
            leadCaptureTypeOptions = 'Choose One';
        }
        if(includeWebsiteType == 'Choose One'){
            fullPageTypeOptions = 'Choose One';
        }
        if(fullPageTypeOptions == 'Choose One'){
            leadCaptureTypeOptions = 'Choose One';
        }
        
    }
    
    //DEV-9549
    public void resetWebsite(){
        resetWebsiteOptions();
        
        if(this.websiteQuoteReportingUploadAttachment <> null && String.isNotBlank(this.websiteQuoteReportingUploadAttachment.AttachmentId)){
            DELETE [SELECT Name, Description, Body, ContentType FROM Attachment WHERE Id =: this.websiteQuoteReportingUploadAttachment.AttachmentId];
            
            websiteQuoteReportingUploadAttachment =new AttachmentsExt();
            websiteQuoteReportingUploadAttachment.AttachmentDescription = 'Attachment';
            websiteQuoteReportingUploadAttachment.siteAttachmentsParentRecordName = 'DigitalAuditFormAttachments-' + String.ValueOf(system.today());
        }
    }
    
   public PageReference searchContacts(){
          boolShowContacts = false;
          errorMessage = validateString(searchString);
          List<Contact> contList;
         
          if(contactList2 == null){
              contactList2 = new List<Contact>();
          } else {
              contactList2.clear();
          }
          //String strX = ApexPages.currentPage().getParameters().get('sessionId');
          //System.debug('------------------------ session id--' + sessionId);
          if (errorMessage == null){
              ContactNames.clear();
              
          ContactNames.add(new SelectOption(strChoseOne, strChoseOne));
          ContactNames.add(new SelectOption(strNotInList, strNotInList)); 
              contactName = strChoseOne;
              if(emailOnly == true)
                contactList2 = searchContactsRl(searchString);
              else
                contactList2 = DigitalFormUtil.searchContacts(searchString);
              if (!contactList2.isEmpty()){
                    for (Contact cnt : contactList2){  
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
                  errorMessage= null;  
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
      
     
    
   
    
    // <refactor> These 26 blocks of code are identical other than the StartsWith letter ... 1 for each letter A-Z
    // I didn't even bother cleaning it up for Ph1 because this should be replaced with a function 
    // be gone ugly code! - AC
    // </refactor>

//********************************************************************************Testing New List Area
    //need to refactor to remove hardcoded Ids
    public List<SelectOption> getItemsm(){
        List<SelectOption> moptions = new List<SelectOption>();
        //Excluding ClipperPartnerType, CLP, as per requirements of Sprint 2.16.12, Story DEV-5252, "Inactivate Clipper Partner companies"
        List<Account> marketList;
        Id partnerMarketRec = RecordTypeCache.getRecordType('Account', Constants.ACCOUNT_RECORD_TYPE_PARTNER_MARKET).Id;
        if(emailOnly == true)
            marketList = [Select Id, Media_Property_List__c
                                    FROM Account
                                    where RecordTypeId = :partnerMarketRec
                                    and Partner_Type__c = :RLPartnerType
                                    order by Media_Property_List__c];
        else
            marketList = [Select Id, Media_Property_List__c
                                    FROM Account
                                    where RecordTypeId = :partnerMarketRec
                                    and Id != '001F000000n1sGU'
                                    and Id != '001A000000QTk0g' 
                                    and Partner_Type__c <> :ClipperPartnerType 
                                    and Partner_Type__c <> :RLPartnerType
                          	    and Show_In_Media_Partner_List__c = true
                                    order by Media_Property_List__c];
        moptions.add(new SelectOption('001i000001AWbWuGTA','--Choose One--'));
        for (Integer j=0; j<marketList.size(); j++){
            moptions.add(new SelectOption(marketList[j].Id, marketList[j].Media_Property_List__c));
        }
        if(emailOnly != true)
            moptions.add(new SelectOption('001A000000QTk0g','G/O Digital'));
        return moptions;
    }

//*********************************************************************************    
        
    
    public List<SelectOption> mediaPartnerOptions {
        get {
            if (mediaPartnerOptions == null) {
                mediaPartnerOptions = new List<SelectOption>();
                  
                List<Account> marketList = [SELECT Id, Name, Media_Property_List__c 
                                            FROM Account 
                                            WHERE RecordTypeId = '012F0000000y9Wc' 
                                            //AND Id != '001F000000n1sGU' 
                                            AND Id != '001A000000QTk0g' 
                                            ORDER BY Media_Property_List__c];
                  
                for (Account a : marketList) {
                    mediaPartnerOptions.add(new SelectOption(a.id, a.Media_Property_List__c));
                }
            } 
            return mediaPartnerOptions;
        }
        private set;
    }

    public List<SelectOption> yesNoOptions {
        get {
            if (yesNoOptions == null) {
                yesNoOptions = new List<SelectOption>();
                //yesNoOptions.add(new SelectOption('Choose One','--Choose One--'));
                yesNoOptions.add(new SelectOption('false','No'));
                yesNoOptions.add(new SelectOption('true','Yes'));
            
            }
            
            return yesNoOptions;
        }
        private set;
    
    }
    
    public List<SelectOption> yesNoOptionsEmail {
        get {
            if (yesNoOptionsEmail == null) {
                yesNoOptionsEmail = new List<SelectOption>();
                //yesNoOptions.add(new SelectOption('Choose One','--Choose One--'));
                if(emailOnly == true){
                    yesNoOptionsEmail.add(new SelectOption('true','Yes'));
                    includeEmailCount = 'true';
                } else {
                    yesNoOptionsEmail.add(new SelectOption('false','No'));
                    yesNoOptionsEmail.add(new SelectOption('true','Yes'));
                }
               
            
            }
            
            return yesNoOptions;
        }
        private set;
    }
    
    public List<SelectOption> pageTypeOptions {
        get {
            if (pageTypeOptions == null) {
                pageTypeOptions = new List<SelectOption>();
                pageTypeOptions.add(new SelectOption('Choose One','--Choose One--'));
                pageTypeOptions.add(new SelectOption('full','Website'));
                pageTypeOptions.add(new SelectOption('lead capture','Lead Capture Page'));
            }
            
            return pageTypeOptions;
        }
        private set;
    
    }
    public List<SelectOption> leadCapturePageType {
        get {
            if (leadCapturePageType == null) {
                leadCapturePageType = new List<SelectOption>();
                leadCapturePageType.add(new SelectOption('Choose One','--Choose One--'));
                leadCapturePageType.add(new SelectOption('single','Single'));
                leadCapturePageType.add(new SelectOption('premium','Premium'));
                leadCapturePageType.add(new SelectOption('signature','Signature'));
            }
            
            return leadCapturePageType;
        }
    private set;
    
    }
    public List<SelectOption> yesNoTempOptions {
        get {
            if (yesNoTempOptions == null) {
                yesNoTempOptions = new List<SelectOption>();
                yesNoTempOptions.add(new SelectOption('Choose One','--Choose One--'));
                yesNoTempOptions.add(new SelectOption('true','Yes'));
                yesNoTempOptions.add(new SelectOption('false','No'));
                yesNoTempOptions.add(new SelectOption('false','Template'));
            }
            
            return yesNoTempOptions;
        }
        private set;
    
    }
    
    
     public AttachmentsExt CampaignReportingUploadAttachment {
        get {
            if(CampaignReportingUploadAttachment == NULL){
                CampaignReportingUploadAttachment=new AttachmentsExt();
                CampaignReportingUploadAttachment.AttachmentDescription = 'Attachment';
                CampaignReportingUploadAttachment.siteAttachmentsParentRecordName = 'DigitalAuditFormAttachments-' + String.ValueOf(system.today());
            }
            return CampaignReportingUploadAttachment;
        }
        set;
    }
    
    //DEV-9549
    public AttachmentsExt websiteQuoteReportingUploadAttachment {
        get {
            if(websiteQuoteReportingUploadAttachment == NULL){
                websiteQuoteReportingUploadAttachment =new AttachmentsExt();
                websiteQuoteReportingUploadAttachment.AttachmentDescription = 'Attachment';
                websiteQuoteReportingUploadAttachment.siteAttachmentsParentRecordName = 'DigitalAuditFormAttachments-' + String.ValueOf(system.today());
            }
            return websiteQuoteReportingUploadAttachment;
        }
        set;
    }
    
    public List<SelectOption> fullPageOptions {
        get {
            if (fullPageOptions == null) {
                fullPageOptions = new List<SelectOption>();
                fullPageOptions.add(new SelectOption('Choose One','--Choose One--'));
                fullPageOptions.add(new SelectOption('SiteEss','Site Essentials'));
                fullPageOptions.add(new SelectOption('SitePlus','Site Plus'));
                fullPageOptions.add(new SelectOption('custom','Site Premier'));
                fullPageOptions.add(new SelectOption('migServ','Migration Services'));
            }
        
            return fullPageOptions;
        }
        private set;
    
    }
    
    //****************************************************************************************
    //Get Things Into Place
    //****************************************************************************************
    public PageReference saveRequest() {
        
        if(!(includeWebsiteQuote == TRUE_VAL || includeEmailCount == TRUE_VAL || includeDigitalAudit == TRUE_VAL)){
            ApexPages.addMessage (new ApexPages.message(ApexPages.severity.Error, 'Please Select at Least One (1) Audit type'));
                Return null;
        }
        
        if(editContactInfo == true) {    
            if (contactName == strChoseOne || contactName == strSearchRep){
                ApexPages.addMessage (new ApexPages.message(ApexPages.severity.Error, 'Please Choose Sales Rep'));
                 return null;
            }   
            String errMessage = DigitalFormUtil.validatePhone(newcontact.Phone);
            if(errMessage != null){
                ApexPages.addMessage (new ApexPages.message(ApexPages.severity.Error, errMessage));
                return null;
            }
            
            DigitalFormUtil.upsertContact(newContact, RelatedCompany, saveContactId);
            saveContactId = newContact.Id;
            newContact.Id = null;
            oneCase.Affl_Sales_Rep__c = saveContactId;
        }
        if(editClientInfo == true){
            firstMediaPartner = relatedCompany;//selectedMediaPartners[0];
            if(relatedCompany == '001i000001AWbWuGTA'){
                ApexPages.addMessage (new ApexPages.message(ApexPages.severity.Error,'Please Select Media Partner'));
                return null;
            }
        }
            //Create Digital Audit Case
            //if Digital Audit Request Selected Store Values for Case
            if (includeDigitalAudit == TRUE_VAL) {
                 getCommonFields(digaudRequest);
                
                // DEV-12870: Clear hidden field values if Type_of_Audit__c = 'Digital Snapshot'
                clearFieldValues(digaudRequest);


                /* Start DEV-7813 
                Set Client , Competitor1 and competitor2 address fields default to eCommereceAddress (Static Map defined above)
                if all the respective address fields are blank */
                if(String.IsNotBlank(digaudRequest.DA_IsThisBusiness_EcommerceOnly__c)
                    && digaudRequest.DA_IsThisBusiness_EcommerceOnly__c == 'Yes'){
                    for(String key : mapAddressFieldApis.KeySet()){
                        Boolean addressBlank = true;
                        Map<String, String> mapSingleAddress = mapAddressFieldApis.get(key);
                        for(String fieldAPIName : mapSingleAddress.KeySet()){
                            if(String.IsNotBlank(String.ValueOf(digaudRequest.get(fieldAPIName)))){
                                addressBlank = false;
                            }
                        }
                        
                        //set default eCommereceAddress 
                        if(addressBlank){
                            for(String fieldAPIName : mapSingleAddress.KeySet()){
                                digaudRequest.put(fieldAPIName, eCommereceAddress.get(mapSingleAddress.get(fieldAPIName)));
                            } 
                        }
                    }
                }
                // Stop Start DEV-7813 
                digaudRequest.Description = DIGAUDIT_DESCR; 
               
                
            }
            
            //Create Email Count Case
            //if Call Request Selected Store Values for Case
            if (includeEmailCount == TRUE_VAL) { 
                getCommonFields(ECountRequest);
                ECountRequest.Description = EMAIL_DESCR;
            }                                               
            
            //Create Website Audit Case
            if (includeWebsiteQuote == TRUE_VAL) {
                if(includeDigitalAudit == TRUE_VAL)
                    getCompetitorFields();
                String fullPageCheck = Null;
                String siteCheck = Null;
                String landingCheck = Null;
                if(includeWebsiteType == 'Choose One'){
                    ApexPages.addMessage (new ApexPages.message(ApexPages.severity.Error, 'Select Do You Need A Lead Capture Page Or A Full Website?'));
                    return null;
                }
                
                if(includeWebsiteType == 'full'){
                    fullPageCheck = 'Website';
                    if(fullPageTypeOptions == 'Choose One'){
                        ApexPages.addMessage (new ApexPages.message(ApexPages.severity.Error, 'Select Choose Template Type Or Custom'));
                       return null;
                    }
                    
                    //This section needs to be updated, since some of these options do not exist anymore.
                    if(fullPageTypeOptions == 'custom'){
                        siteCheck = 'Site Premier';
                    }
                    if(fullPageTypeOptions == 'SiteEss'){
                        siteCheck = 'Site Essentials';
                    }
                     if(fullPageTypeOptions == 'SitePlus'){
                        siteCheck = 'Site Plus';
                    }
                    if(fullPageTypeOptions == 'migServ'){
                        siteCheck = 'Migration Services';
                    }
                        
                }
                 if(includeWebsiteType == 'lead capture'){
                    fullPageCheck = 'Lead Capture Page';
                    if(leadCaptureTypeOptions == 'Choose One'){
                        ApexPages.addMessage (new ApexPages.message(ApexPages.severity.Error, 'Select Lead Capture Type'));
                        return null;
                    }
                    if(leadCaptureTypeOptions == 'single'){
                           landingCheck = 'Lead Capture Page Single';
                        }
                        if(leadCaptureTypeOptions == 'premium'){
                           landingCheck = 'Lead Capture Page Premium';
                        }
                        if(leadCaptureTypeOptions == 'signature'){
                           landingCheck = 'Lead Capture Page Signature';
                        }
                       
                }
                getCommonFields(WebsiteRequest);
                WebsiteRequest.Description = WEBSITE_DESCR;
                WebsiteRequest.GLW_Web_Page_Type__c = fullPageCheck; //Overall Page Type - Full Site Or Lead Capture
                WebsiteRequest.GLW_Landing_Page_Type__c = landingCheck; //Landing Page Type - Single, Premium or Signature
                WebsiteRequest.GLW_Full_Page_Type__c = siteCheck; //Full Page Type - Templates Or Custom
               
           
            }
          Case clonedDigAudRequestCase = New Case();
          Case clonedECountRequestCase = New Case();
          Case clonedWebsiteRequestCase = New Case();
          case selectedCase;

          Savepoint SP = Database.setSavepoint();
            try{
              if(digaudRequest != null){
                selectedCase = digaudRequest;
              }else if(WebsiteRequest != null){
                selectedCase = WebsiteRequest;
              }else if(ECountRequest != null){
                selectedCase = ECountRequest;
              }
            if(includeDigitalAudit == TRUE_VAL && digaudRequest != null){
                clonedDigAudRequestCase = digaudRequest.clone();
                insert clonedDigAudRequestCase ;
                //Right now we have only one attachment. But still code is written to handle the multiple attachments for future requirements.
                Set<Id> newAttachmentIds = new Set<Id>();
                if(this.CampaignReportingUploadAttachment <> null && digaudRequest.Type_of_Audit__c != DIGITAL_SNAPSHOT && 
                    String.isNotBlank(this.CampaignReportingUploadAttachment.AttachmentId)){
                    newAttachmentIds.add(this.CampaignReportingUploadAttachment.AttachmentId);
                }
                if(!newAttachmentIds.isEmpty()){
                     List<Attachment> attachmentsToInsert = new List<Attachment>();
                    
                     List<Attachment> siteAttachments = [Select Name, Description, Body, ContentType from Attachment Where Id In: newAttachmentIds];
                     for(Attachment oneAttachment: siteAttachments){
                        Attachment newAttachment = new Attachment(); 
                        newAttachment.Name=oneAttachment.Name;
                        newAttachment.ContentType=oneAttachment.ContentType;
                        newAttachment.Body = oneAttachment.Body;
                        newAttachment.Description = oneAttachment.Name;
                        newAttachment.ParentId = clonedDigAudRequestCase.Id;
                        attachmentsToInsert.add(newAttachment);
                    }
            
                    insert attachmentsToInsert;
                    delete siteAttachments;
                }
            }
             if(includeEmailCount == TRUE_VAL && ECountRequest != null){
                clonedECountRequestCase = ECountRequest.clone();
                insert clonedECountRequestCase;
            }
            if(includeWebsiteQuote == TRUE_VAL && WebsiteRequest != null){
                clonedWebsiteRequestCase = WebsiteRequest.clone();
                insert clonedWebsiteRequestCase; 
                
                //DEV-9549
                Set<Id> newAttachmentIds = new Set<Id>();
                if(this.websiteQuoteReportingUploadAttachment <> null && String.isNotBlank(this.websiteQuoteReportingUploadAttachment.AttachmentId)){
                    newAttachmentIds.add(this.websiteQuoteReportingUploadAttachment.AttachmentId);
                }
                if(!newAttachmentIds.isEmpty()){
                    List<Attachment> attachmentsToInsert = new List<Attachment>();
                    List<Attachment> siteAttachments = [Select Name, Description, Body, ContentType from Attachment Where Id In: newAttachmentIds];
                    for(Attachment oneAttachment: siteAttachments){
                        Attachment newAttachment = new Attachment(); 
                        newAttachment.Name=oneAttachment.Name;
                        newAttachment.ContentType=oneAttachment.ContentType;
                        newAttachment.Body = oneAttachment.Body;
                        newAttachment.Description = oneAttachment.Name;
                        newAttachment.ParentId = clonedWebsiteRequestCase.Id;
                        attachmentsToInsert.add(newAttachment);
                    }
                    
                    insert attachmentsToInsert;
                    delete siteAttachments;
                }
            }
        }
    
        catch(System.DMLException e) {
            
            string msg = e.getMessage();
            if(msg != null && !msg.containsIgnoreCase('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, msg,''));
            }
            Database.rollback(SP);
            return null;
        }
        catch(Exception e){
            string msg = e.getMessage();
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, msg,''));
            Database.rollback(SP);
            return null;
        }
    
        PageReference p;
        if(hasOppId == true)
            p = new PageReference('/apex/DigitalAuditThankYou');
        else 
            p = new PageReference('/DigitalAuditThankYou');
        p.setRedirect(true);
        return p;

    } //saveRequest()
    
    /* DEV-9783
    //Dev-9333
    public PageReference checkPPCEstimator(){
        isPPC = false;
        if(newLead.Select_New_Products__c != null && newLead.Select_New_Products__c.contains('PPC')) {
            isPPC = true;
        }
        return null;
    } */
    public void getCompetitorFields(){
       
        WebsiteRequest.DA_Competitor1_Business_Name__c = digaudRequest.DA_Competitor1_Business_Name__c;
        WebsiteRequest.DA_Competitor1_Address__c = digaudRequest.DA_Competitor1_Address__c;
        WebsiteRequest.DA_Competitor1_City__c = digaudRequest.DA_Competitor1_City__c;
        WebsiteRequest.DA_Competitor1_State__c = digaudRequest.DA_Competitor1_State__c;
        WebsiteRequest.DA_Competitor1_Zip_Code__c = digaudRequest.DA_Competitor1_Zip_Code__c;
        WebsiteRequest.DA_Competitor1_Phone_Number__c = digaudRequest.DA_Competitor1_Phone_Number__c;
        WebsiteRequest.DA_Competitor1_URL__c = digaudRequest.DA_Competitor1_URL__c;
        WebsiteRequest.DA_Competitor1_Facebook_URL__c = digaudRequest.DA_Competitor1_Facebook_URL__c;
        WebsiteRequest.DA_Competitor1_Twitter_URL__c = digaudRequest.DA_Competitor1_Twitter_URL__c;
        WebsiteRequest.DA_Competitor2_Business_Name__c = digaudRequest.DA_Competitor2_Business_Name__c;
        WebsiteRequest.DA_Competitor2_Address__c = digaudRequest.DA_Competitor2_Address__c;
        WebsiteRequest.DA_Competitor2_City__c = digaudRequest.DA_Competitor2_City__c;
        WebsiteRequest.DA_Competitor2_State__c = digaudRequest.DA_Competitor2_State__c;
        WebsiteRequest.DA_Competitor2_Zip_Code__c = digaudRequest.DA_Competitor2_Zip_Code__c;
        WebsiteRequest.DA_Competitor2_Phone_Number__c = digaudRequest.DA_Competitor2_Phone_Number__c;
        WebsiteRequest.DA_Competitor2_URL__c = digaudRequest.DA_Competitor2_URL__c;
        WebsiteRequest.DA_Competitor2_Facebook_URL__c = digaudRequest.DA_Competitor2_Facebook_URL__c;
        WebsiteRequest.DA_Competitor2_Twitter_URL__c = digaudRequest.DA_Competitor2_Twitter_URL__c;
       
    }
    
    public String getTypeOfAuditHelpText() {
      String typeOfAuditHelpText;
      typeOfAuditHelpText = HELPTEXT_TYPEOFAUDIT;
      return typeOfAuditHelpText;
    }

    //
    public Boolean getIsRequired() {
      Boolean isRequired = true;
      if(digaudRequest.Type_of_Audit__c == DIGITAL_SNAPSHOT || digaudRequest.Type_of_Audit__c == FULL_DIGITAL_PROPOSAL || digaudRequest.DA_IsThisBusiness_EcommerceOnly__c == NO)
        isRequired = false;
      return isRequired;  
    }

    public void getCommonFields(Case cs){
        
        cs.Media_Partner__c = firstMediaPartner;
        cs.Company_Name__c = oneCase.Company_Name__c;
        cs.Affl_Sales_Rep__c = oneCase.Affl_Sales_Rep__c;
        cs.Affl_Sales_Rep_Text__c = newContact.FirstName + ' ' + newContact.LastName;
        cs.Case_Primary_Industry__c = oneCase.Case_Primary_Industry__c;
        cs.Case_Primary_Focus__c = oneCase.Case_Primary_Focus__c;
        cs.Notify_Email_1__c = null;
        cs.Notify_Email_2__c = null;
        cs.Notify_Email_3__c = null;
        if (includeNotify == TRUE_VAL){
            if(Notify1 != Null)
                cs.Notify_Email_1__c = Notify1;
            if(Notify2 != Null)
                cs.Notify_Email_2__c = Notify2;
            if(Notify3 != Null)
                cs.Notify_Email_3__c = Notify3;
        }
        cs.DA_WhichProducts_ClientCurrentlyUsing__c = oneCase.DA_WhichProducts_ClientCurrentlyUsing__c;
        if(hasOppId == true){
            cs.AccountId = oneCase.AccountId;
            cs.Opportunity__c = oneCase.Opportunity__c;
            cs.Dig_Account_Manager__c = oneCase.Dig_Account_Manager__c;
        }
        if(editClientInfo != true){
             cs.Media_Partner__c = oneCase.Media_Partner__c;
        }
    }

    public void clearFieldValues(Case cs){

      if(cs.Type_of_Audit__c == DIGITAL_SNAPSHOT){
        cs.DA_IsThisBusiness_EcommerceOnly__c = null;
        cs.DA_Target_Geo_Type__c = null;
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
    
    public void validateOppFields(){
    
        editClientInfo = false;
        editContactInfo = false;
        if (oneCase.Media_Partner__c == null ||
            oneCase.Company_Name__c == null || String.isBlank(oneCase.Company_Name__c) || 
            oneCase.Case_Primary_Industry__c == null || String.isEmpty(oneCase.Case_Primary_Industry__c) ||
            oneCase.Case_Primary_Focus__c  == null || String.isEmpty(oneCase.Case_Primary_Focus__c))
          editClientInfo = true;
        if (newContact == null || digaudRequest.Contact_Name__c == null)
            editContactInfo = true;
       
    }
    
    public PageReference validateFields(){
        if(hasOppId == true && includeDigitalAudit == TRUE_VAL)
            validateDigAuditOppFields();
        return null;
    }
     public void validateDigAuditOppFields(){
         
         editDsClientInfo = false;
         if(String.isBlank(digaudRequest.DA_Client_Address__c) ||  String.isBlank(digaudRequest.DA_Client_City__c) ||
            String.isBlank(digaudRequest.DA_Client_State__c) || String.isBlank(digaudRequest.DA_Client_Postal_Code__c) ||
            (digaudRequest.DA_Client_Postal_Code__c != null && !Pattern.matches('\\d{5}(-\\d{4})?', digaudRequest.DA_Client_Postal_Code__c)) ||
            String.isBlank(digaudRequest.Contact_Phone__c) || 
            (digaudRequest.Contact_Phone__c != null &&  !Pattern.matches('(^\\(?(\\d{3})\\)?[- ]?(\\d{3})[- ]?(\\d{4})$)', digaudRequest.Contact_Phone__c)) ||
            String.isBlank(digaudRequest.DA_Website__c))
                editDsClientInfo = true;

     }     
    

}