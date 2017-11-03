/*
Below Defects addresses the clearing product details if they are selected(entered details) and then unselected on the UI.
DE598 : OBF: Wrong Data saved in field Social Ads Option on OBFModel record - Trigger Code Fix
DE548 : OBF - Data Issues - Major - Trigger Code Fix
Modified By : Matthew Shiner modified on 10/11/2016 for DEV-8034
*/
public class OnBoardFormBeforeInsertTriggerHandler extends TriggerHandlerBase {

    public static final String urlError = 'URL provided is not in a valid format.';
    public static List<Contact> newContactList = new List<Contact>(); 
    public static Map<String, Decimal> pbMap;
    //product codes.
    public static final String WEBUPPLUS = 'WEBUPPLUS';
    public static final String WEBPLUS = 'WEBPLUS';
    public static final String WEBGOAL = 'WEBGOAL';
    public static final String WEBHOST  = 'WEBHOST';
    public static final String WEBHOSTM2M  = 'WEBHOSTM2M';
    public static final String WEBHOSTONEYEAR = 'WEBHOSTONEYEAR';
    public static final String WEBPAGEPRE = 'WEBPAGEPRE';
    public static final String WEBBLOG = 'WEBBLOG';
    public static final String WEBBLOGVID = 'WEBBLOGVID';
    public static final String WEBVCBASIC = 'WEBVCBASIC';
    public static final String WEBVCBRAND = 'WEBVCBRAND';
    public static final String WEBVCTEAM = 'WEBVCTEAM';
    public static final String WEBMONTAGE = 'WEBMONTAGE';
    public static final String WEBTARGET = 'WEBTARGET';
    public static final String WEBECOMM10 = 'WEBECOMM10';
    public static final String WEBECOMM100 = 'WEBECOMM100';
    public static final String WEBECOMM2500 = 'WEBECOMM2500';
    public static final String WEBPAGEPOST = 'WEBPAGEPOST';
    public static final String WEBPAGEPOSTSP = 'WEBPAGEPOSTSP';
    public static final String WEBUPESSENTIAL = 'WEBUPESSENTIAL';
    public static final String WEBESSENTIALS = 'WEBESSENTIALS';
    public static final String SOCIALMGMTLAUNCH = 'SOCIALMGMTLAUNCH';
    
    public override void mainEntry(TriggerParameters tp) {
 
        if(pbMap == null)
            this.getPbMap((List<OnBoardFormModel__c>)tp.newList);
            
        for(OnBoardFormModel__c oneRecord : (List<OnBoardFormModel__c>)tp.newList){
            this.clearPPCFields(oneRecord); //Clearing PPC fields data
            this.clearSEOFields(oneRecord); //Clearing SEO fields data
            this.clearMapsAndReputationFields(oneRecord); //Clearing Maps & Reputation fields data
            this.clearLeadCapturePagesFields(oneRecord); //Clearing Lead Capture Pages fields data
            this.clearWebsitesFields(oneRecord); //Clearing Websites fields data
            this.clearSocialAdvertisingFields(oneRecord); //Clearing Social Advertising fields data
            this.clearTargetedEmailFields(oneRecord); //Clearing Targeted Email fields data
            this.clearSocialMediaManagementFields(oneRecord); //Clearing Social Media Management fields data
            
            this.setMediaPartner(oneRecord); //Set Media_Partner__c by Corp_Partner_Code__c if the request is submitted by OrderHub through API Call
            this.createRLContact(oneRecord); //create reach local contact if does not exist
            this.setMediaPartnerTegna(oneRecord); //Set Media_Partner__c by Media_Partner_Ext__c for when the OBF comes from TEGNA Media via Salesforce-to-Salesforce DEV-6969
            this.setAfflSalesRepTegna(oneRecord); //Set Affl_Sales_Rep__c by Affl_Sales_Rep_Ext__c for when the OBF comes from TEGNA Media via Salesforce-to-Salesforce DEV-6970
            this.calculateWebsiteCost(oneRecord);
            //this.populateSMMFields(oneRecord); //populate SMM Fields
                       
        }
        this.addNewContacts((List<OnBoardFormModel__c>)tp.newList);
    }
    
    /* 
    ----------- BEGIN CODE TRANSPLANT -----------------
    */
    //Set Media_Partner__c by Corp_Partner_Code__c if the request is submitted by OrderHub through API Call - should work for RL
    private void setMediaPartner(OnBoardFormModel__c oneRecord){
    	if(String.IsNotBlank(oneRecord.Corp_Partner_Code__c) 
    		&& String.IsBlank(oneRecord.Media_Partner__c)){
    		if(OnBoardFormModelTriggerDispatcher.partnerMarketMap != null){
                for(Account acct :OnBoardFormModelTriggerDispatcher.partnerMarketMap.values()){
                    if(acct.Corp_Partner_Code__c == oneRecord.Corp_Partner_Code__c)
                        oneRecord.Media_Partner__c = acct.Id;
                }
            }    								 
    	}
    }
    
     //Create Reach Local contact if not found. - match on media partner and email
    private void createRLContact(OnBoardFormModel__c oneRecord){
        String defaultLastName = 'Reach Local Contact';
        Boolean foundContact = false;
    	if(oneRecord.Media_Partner__c != null && String.isNotBlank(oneRecord.Affl_Sales_Rep_Email__c) &&
    	    OnBoardFormModelTriggerDispatcher.partnerMarketMap != null &&
    	    OnBoardFormModelTriggerDispatcher.partnerMarketMap.containsKey(oneRecord.Media_Partner__c) &&
    	    OnBoardFormModelTriggerDispatcher.partnerMarketMap.get(oneRecord.Media_Partner__c).Partner_Type__c == OnBoardFormModelTriggerDispatcher.RL_PARTNER_TYPE){
        	    //look for contact
        	    if(OnBoardFormModelTriggerDispatcher.affContactMap != null && !OnBoardFormModelTriggerDispatcher.affContactMap.isEmpty()){     
        	        for(Contact cnt :OnBoardFormModelTriggerDispatcher.affContactMap.values()){
                        if(cnt.AccountId == oneRecord.Media_Partner__c && cnt.Email == oneRecord.Affl_Sales_Rep_Email__c){
                            foundContact = true;
                            oneRecord.Affl_Sales_Rep__c = cnt.Id;
                        }
                            
                    }
        	    }
        	    if(foundContact == false)
        	        newContactList.add(new Contact(AccountId = oneRecord.Media_Partner__c, 
    	                                   Email = oneRecord.Affl_Sales_Rep_Email__c,
    	                                   LastName = defaultLastName,
    	                                   Web_Submitter__c = true,
    	                                   RecordTypeId = 
    	                                   RecordTypeCache.getRecordType('Contact', Constants.CONTACT_RECORD_TYPE_AFFILIATED).Id));
    	}
    	
    }
    //Set Media_Partner__c by Media_Partner_Ext__c for when the OBF comes from TEGNA Media via Salesforce-to-Salesforce DEV-6969
    private void setMediaPartnerTegna(OnBoardFormModel__c oneRecord){
        if(oneRecord.Media_Partner_Ext__c != null && Pattern.matches('[0][0][1][a-zA-Z_0-9]{12,15}', oneRecord.Media_Partner_Ext__c)){
            Id mediaPartnerId = Id.valueOf(oneRecord.Media_Partner_Ext__c);
        
        	if(String.IsNotBlank(oneRecord.Media_Partner_Ext__c) && String.IsBlank(oneRecord.Media_Partner__c) && 
             OnBoardFormModelTriggerDispatcher.partnerMarketMap != null &&
             OnBoardFormModelTriggerDispatcher.partnerMarketMap.containsKey(mediaPartnerId)){
                oneRecord.Media_Partner__c = OnBoardFormModelTriggerDispatcher.partnerMarketMap.get(mediaPartnerId).Id;
            }
        }
    }
    //Set Affl_Sales_Rep__c by Affl_Sales_Rep_Ext__c for when the OBF comes from TEGNA Media via Salesforce-to-Salesforce DEV-6970
    private void setAfflSalesRepTegna(OnBoardFormModel__c oneRecord){
        if(oneRecord.Affl_Sales_Rep_Ext__c != null && Pattern.matches('[0][0][3][a-zA-Z_0-9]{12,15}', oneRecord.Affl_Sales_Rep_Ext__c)){
            Id afflSalesRepId = Id.valueOf(oneRecord.Affl_Sales_Rep_Ext__c);
            
        	if(String.IsNotBlank(oneRecord.Affl_Sales_Rep_Ext__c) && String.IsBlank(oneRecord.Affl_Sales_Rep__c) &&
              OnBoardFormModelTriggerDispatcher.affContactMap != null && OnBoardFormModelTriggerDispatcher.affContactMap.containsKey(afflSalesRepId)){
               oneRecord.Affl_Sales_Rep__c = OnBoardFormModelTriggerDispatcher.affContactMap.get(afflSalesRepId).Id;
           }
        }
    }
    //PPC Fields
    private void clearPPCFields(OnBoardFormModel__c oneRecord){
        System.debug('Clearing PPC fields data');
        if(!oneRecord.PPC__c){
            oneRecord.PPC_Budget__c = null;
            oneRecord.PPC_Spend_Budget__c = null;
            oneRecord.Contract_Length_Months_PPC__c = null;
            
            oneRecord.Campaign_Goals__c = null;
            oneRecord.Products_Services_to_Advertise_For__c = null;
            oneRecord.Special_Offers__c = null;
            oneRecord.Ad_Copy__c = null;
            oneRecord.Business_Differentiators__c = null;
            oneRecord.Products_Services_Not_to_Advertise_For__c = null;
            oneRecord.Target_Geographical_Location__c = null;
            oneRecord.Target_State__c = null;
            oneRecord.Target_Radius__c = null;
            oneRecord.Notes_PPC__c = null;
            oneRecord.PPC_Product_Order_Id__c = null;
        }
    }
    //SEO fields
    private void clearSEOFields(OnBoardFormModel__c oneRecord){
        System.debug('Clearing SEO fields data');
        if(!(oneRecord.SEO__c  || oneRecord.Brand_Building__c )){
            oneRecord.SEO_Budget__c = null;
            oneRecord.SEO_Package__c = null;
            oneRecord.Contract_Length_Months_SEO__c = null;
        
            //Google Analytics
            oneRecord.SEO_Google_Analytics_Admin_Confirmed__c = false;
            oneRecord.SEO_Google_Analytics_Installed__c = null;
        
            oneRecord.Website_Access__c = null; // CMS, FTP, Web Developer
            oneRecord.Notes_SEO__c = null;
            oneRecord.SEO_Product_Order_Id__c = null;
        }
        
        // CMS Fields
        if (!((oneRecord.SEO__c  || oneRecord.Brand_Building__c) && String.IsNotBlank(oneRecord.Website_Access__c) 
                && oneRecord.Website_Access__c == 'FTP/CMS')){
            oneRecord.CMS_Used__c = null;
            oneRecord.CMS_Login_URL__c = null;
            oneRecord.Username__c = null;
            oneRecord.Password__c = null;
            oneRecord.Host_URL__c = null;  
            oneRecord.Host_Provider_Username__c = null;
            oneRecord.Host_Provider_Password__c = null;
        }
        
        //Web Developer Fields
        if(!( (oneRecord.SEO__c  || oneRecord.Brand_Building__c) && String.IsNotBlank(oneRecord.Website_Access__c) 
                && oneRecord.Website_Access__c == 'Web Developer')){
            oneRecord.First_Name__c = null;
            oneRecord.Last_Name__c = null;
            oneRecord.Web_Developer_Contact_Phone__c = null;
            oneRecord.Web_Developer_Email_Address__c = null;
        }
    }
    //Maps & Reputation fields
    private void clearMapsAndReputationFields(OnBoardFormModel__c oneRecord){
        System.debug('Clearing Maps & Reputation fields data');
        if(!(oneRecord.Local_Places_Reputation__c || oneRecord.Brand_Building__c)){
            oneRecord.Number_of_Locations__c = null;
            oneRecord.Has_Google_Maps_Listing_Been_Claimed__c = null;
            oneRecord.Local_Places_Username__c = null;
            oneRecord.Local_Places_Password__c = null;
            oneRecord.Recovery_Email_or_Phone_Number__c = null;
            oneRecord.Legal_Business_Name_DBA__c = null;
            oneRecord.If_Medical_Dental_Legal_License_Name__c = null;
            oneRecord.Publishable_Email_Address__c = null;
            oneRecord.Is_Business_Brick_Mortar_or_Mobile__c = null;
            oneRecord.Top_Products_Services_You_Offer_1__c = null;
            oneRecord.Top_Products_Services_You_Offer_2__c = null;
            oneRecord.Top_Products_Services_You_Offer_3__c = null;
            oneRecord.Notes_MapsRep__c = null;
            oneRecord.MNR_Product_Order_Id__c = null;
        }
    }
    //Lead Capture Pages fields
    private void clearLeadCapturePagesFields(OnBoardFormModel__c oneRecord){
        System.debug('Clearing Lead Capture Pages fields data');
        
        if(!oneRecord.Lead_Capture_Pages__c){
            oneRecord.Lead_Capture_Page_Option__c = null;
            oneRecord.Contract_Length_Months_LCP__c = null;
            oneRecord.Lead_Capture_Page_Budget__c = null;
            oneRecord.Notes_LeadCapture__c = null;
            oneRecord.LCP_Product_Order_Id__c = null;
        }
        
        if (!(oneRecord.Lead_Capture_Pages__c 
            && String.IsNotBlank(oneRecord.Lead_Capture_Page_Option__c) 
            && oneRecord.Lead_Capture_Page_Option__c == 'Signature')){
            oneRecord.Desired_URL_Domain_Name__c = null;
        }
    }
    //Websites fields
    private void clearWebsitesFields(OnBoardFormModel__c oneRecord){
        System.debug('Clearing Websites fields data');
        if(!oneRecord.Websites__c){
            oneRecord.Website_Option__c = null;
            oneRecord.Link_to_Proposal__c = null;
            oneRecord.Website_Quote_Cost_Custom__c = null;
            oneRecord.Contract_Length_Months_Websites__c = null;
            oneRecord.Client_Email_Provider_Name__c = null;
            oneRecord.Use_Existing_URL__c = null;
            oneRecord.Domain_Name__c = null;
            oneRecord.Domain_Registrar__c = null;
            oneRecord.Domain_Registrar_Other__c = null;
            oneRecord.Domain_Registrar_Username__c = null;
            oneRecord.Domain_Registrar_Password__c = null;
            oneRecord.TWDesired_URL_Domain_Name__c = null;
            oneRecord.Notes_Websites__c = null;
            oneRecord.WEB_Product_Order_Id__c = null;
        }
    }
    //Social Advertising fields
    private void clearSocialAdvertisingFields(OnBoardFormModel__c oneRecord){
        System.debug('Clearing Social Advertising fields data');
        
        if(!oneRecord.Social_Advertising__c){
            oneRecord.Social_Ads_Option__c = null;
            oneRecord.Social_Ads_Package__c = null;
            oneRecord.Social_Ads_Budget_Month__c = null;
            oneRecord.SocialAds_Spend_Budget__c = null;
            oneRecord.Contract_Length_Months_SocialAds__c = null;
            
            oneRecord.SA_Current_Facebook_Page_URL__c = null;
            oneRecord.Facebook_Ads_Landing_Page_URL__c = null;
            oneRecord.SA_Manager_Level_Admin_Access__c = false;
            oneRecord.SA_Campaign_Goal__c = null;
            oneRecord.SA_Campaign_Goal2__c = null;
            oneRecord.Offer_Description__c = null;
            //oneRecord.SA_Copy_Theme_Ideas__c = null;
            oneRecord.SA_Target_Geographical_Location__c = null;
            oneRecord.SA_Target_State__c = null;
            //oneRecord.SA_Target_Radius__c = null;
            oneRecord.SA_Target_Demographics_Age__c = null;
            oneRecord.SA_Target_Demographics_Gender__c = null;
            oneRecord.Notes_SocialAds__c = null;
            oneRecord.SocAd_Product_Order_Id__c = null;
        }else{
            //Clearing Subsections data due to Ajax & Submit behavior
            // Clearing Campaign Targeting Section based on Social Ads Package dependant picklist
            if (oneRecord.Social_Ads_Package__c == 'Start'){
                oneRecord.SA_Campaign_Goal2__c = null;
                oneRecord.SA_Target_Geographical_Location__c = null; 
                oneRecord.SA_Target_State__c = null;
                //oneRecord.SA_Target_Radius__c = null;
                oneRecord.SA_Target_Demographics_Age__c = null;
                oneRecord.SA_Target_Demographics_Gender__c = null;
                oneRecord.Facebook_Ads_Landing_Page_URL__c = null;
            }else if (oneRecord.Social_Ads_Package__c == 'Build'){
            	oneRecord.SA_Campaign_Goal2__c = null;
            }
            //This part only afects 
            if (!(oneRecord.SA_Target_Geographical_Location__c == 'State')){
        		oneRecord.SA_Target_State__c = null;
        	} else if (!(oneRecord.SA_Target_Geographical_Location__c == 'Radius')){
        		//oneRecord.SA_Target_Radius__c = null;
        	}
        }
    }
    //Targeted Email fields
    private void clearTargetedEmailFields(OnBoardFormModel__c oneRecord){
        System.debug('Clearing Targeted Email fields data');
        if(!oneRecord.Targeted_Email__c){
            oneRecord.Quantity_of_Email_Blasts_per_60_Days__c = null;
            oneRecord.Email_Recipients_per_Blast__c = null;
            oneRecord.Targeted_Email_Budget__c = null;
            oneRecord.TargetedEmail_BlastReminder__c = null;
            oneRecord.TargetedEMail_BlastReminderBudget__c = null;
            oneRecord.TargetedEmail_CreativeOption__c = null;
            oneRecord.TargetedEmail_HTMLFee__c = null;
            
            oneRecord.Email_Count_Pulled_in_Last_60_Days__c = null;
            oneRecord.Count_ID__c = null;
            oneRecord.TargetedEmail_AutoTemplate_Brand__c = null;
            oneRecord.TargetedEmail_AutoTemplate_Persona__c = null;
            oneRecord.TargetedEmail_AutoTemplate_Specific__c = null;
            oneRecord.TargetedEmail_CreativeAnalysis__c = null;
            oneRecord.TargetedEmail_AssetsURL__c = null;
            oneRecord.TargetedEmail_Notes__c = null;
            oneRecord.TEmail_Product_Order_Id__c = null;
            
        }
    }
    //Social Media Management fields
    private void clearSocialMediaManagementFields(OnBoardFormModel__c oneRecord){
        System.debug('Clearing Social Media Management fields data');
        if(!oneRecord.Social_Media_Management__c){
            oneRecord.Social_Option__c = null;
            oneRecord.Social_Budget__c = null;
            oneRecord.SocialMediaMgmt_Spend_Budget__c  = null;
            oneRecord.Contract_Length_Months_SocialMedia__c = null;
            
            oneRecord.Has_Facebook_Page__c = null;
            oneRecord.Current_Facebook_URL__c = null;
            oneRecord.Confirm_Manager_Level_Admin_Access__c = false;
            oneRecord.Has_Twitter_Profile__c = false;
            oneRecord.Twitter_Username__c = null;
            oneRecord.Twitter_Password__c = null;
            oneRecord.Campaign_Contact_Email__c = null;
            oneRecord.Campaign_Goal__c = null;
            oneRecord.Notes_SMM__c = null;
            oneRecord.SocMgmt_Product_Order_Id__c = null;
        }else{
            //Clearing Subsections data due to Ajax & Submit behavior
            if(String.IsNotBlank(oneRecord.Social_Option__c)){
                //Clearing Twitter Sub Section
                if (!(oneRecord.Social_Option__c == 'Social Management Engage' 
                        || oneRecord.Social_Option__c == 'Social Management Expand')){
                    oneRecord.Has_Twitter_Profile__c = false;
                    oneRecord.Twitter_Username__c = null;
                    oneRecord.Twitter_Password__c = null;
                }   
                
            }
            
            //Clearing Twitter Subsection
            if(!oneRecord.Has_Twitter_Profile__c){
                oneRecord.Twitter_Username__c = null;
                oneRecord.Twitter_Password__c = null;
            }
        
        }
    }
        
     private void calculateWebsiteCost(OnBoardFormModel__c oneRecord){
         
        String Yes = 'Yes';
         //website cost constants
        String WebsiteOptionSiteEssentials = 'Site Essentials';
        String WebsiteOptionSitePlus = 'Site Plus';
        String WebsiteOptionSitePremier = 'Site Premier';
        String WebsiteOptionAdditionalServiceOnly = 'Additional Service Only';
        String WebsiteOptionWebsiteHostingOnly = 'Website Hosting Only';
        
        //scheduling options
        String SchedulingBasic = 'Basic';
        String SchedulingBranded = 'Branded';
        String SchedulingTeam = 'Team';
        
        //number of commerce products
        String commProducts1_10 = '1-10';
        String commProducts11_100 = '11-100';
        String commProducts101_2500 = '101-2,500';
        Decimal domainTransferFee = 99;
        
         //only calculate when website option selected.
         if(oneRecord.Website_Option__c != null && pbMap != null && !pbMap.isEmpty()){
             oneRecord.Website_Cost__c = 0;
             //add $99 for Domain Transfer Fee
             if(oneRecord.Domain_Transfer_Fee__c == Yes)
                oneRecord.Website_Cost__c = oneRecord.Website_Cost__c + domainTransferFee;
             //essentials
             if(oneRecord.Website_Option__c == WebsiteOptionSiteEssentials){
                 if(pbMap.containsKey(WEBESSENTIALS))
                    oneRecord.Website_Cost__c += pbMap.get(WEBESSENTIALS);
                 if(oneRecord.Google_Analytics_Events_Goal_Setup__c != null && 
                    oneRecord.Google_Analytics_Events_Goal_Setup__c == Yes && pbMap.containsKey(WEBGOAL))
                     oneRecord.Website_Cost__c += pbMap.get(WEBGOAL) * nullToZero(oneRecord.How_Many_Google_Analytics_Events_Goals__c);
             }
             //plus
             if(oneRecord.Website_Option__c == WebsiteOptionSitePlus){
                 if(pbMap.containsKey(WEBPLUS))
                    oneRecord.Website_Cost__c += pbMap.get(WEBPLUS);
             }
             //essentials or plus
             if(oneRecord.Website_Option__c == WebsiteOptionSiteEssentials || oneRecord.Website_Option__c == WebsiteOptionSitePlus){
                if(pbMap.containsKey(WEBHOSTONEYEAR))
                    oneRecord.Website_Cost__c += pbMap.get(WEBHOSTONEYEAR);
                 if(pbMap.containsKey(WEBPAGEPRE))
                    oneRecord.Website_Cost__c += pbMap.get(WEBPAGEPRE) * nullToZero(oneRecord.Number_of_Add_l_Pages_Req_d__c); 
             }
              //additional only
             if(oneRecord.Website_Option__c == WebsiteOptionAdditionalServiceOnly){
                 if(pbMap.containsKey(WEBPAGEPOST))
                     oneRecord.Website_Cost__c += pbMap.get(WEBPAGEPOST) * nullToZero(oneRecord.Number_of_Add_l_Pages_Req_d__c);
                 if(pbMap.containsKey(WEBPAGEPOSTSP))
                     oneRecord.Website_Cost__c += pbMap.get(WEBPAGEPOSTSP) * nullToZero(oneRecord.Number_of_Add_l_Pages_Req_d__c);
                 if(oneRecord.Upgrade_Site_Essentials_to_Site_Plus__c != null && 
                    oneRecord.Upgrade_Site_Essentials_to_Site_Plus__c == Yes && pbMap.containsKey(WEBUPESSENTIAL))
                     oneRecord.Website_Cost__c += pbMap.get(WEBUPESSENTIAL);
             }
             //plus or additional only
             if(oneRecord.Website_Option__c == WebsiteOptionSitePlus || oneRecord.Website_Option__c == WebsiteOptionAdditionalServiceOnly){
                if(oneRecord.Is_this_site_E_Commerce__c != null && oneRecord.Is_this_site_E_Commerce__c == Yes &&
                    oneRecord.How_Many_E_Commerce_Products__c != null){
                     if(oneRecord.How_Many_E_Commerce_Products__c == commProducts1_10 && pbMap.containsKey(WEBECOMM10))
                        oneRecord.Website_Cost__c += pbMap.get(WEBECOMM10);
                     else if(oneRecord.How_Many_E_Commerce_Products__c == commProducts11_100 && pbMap.containsKey(WEBECOMM100))
                        oneRecord.Website_Cost__c += pbMap.get(WEBECOMM100);
                     else if(oneRecord.How_Many_E_Commerce_Products__c == commProducts101_2500 && pbMap.containsKey(WEBECOMM2500))
                        oneRecord.Website_Cost__c += pbMap.get(WEBECOMM2500);
                    
                }
             }
             //website hosting only
             if(oneRecord.Website_Option__c == WebsiteOptionWebsiteHostingOnly){
                 if(oneRecord.Website_Hosting_Only_Option__c != null){
                     if(oneRecord.Website_Hosting_Only_Option__c == WebsiteOptionSitePremier){
                        if(pbMap.containsKey(WEBHOST))
                            oneRecord.Website_Cost__c += pbMap.get(WEBHOST) * stringToNumber(oneRecord.Contract_Length_Months_Websites__c);    
                     } else {
                        if(pbMap.containsKey(WEBHOSTM2M)) 
                            oneRecord.Website_Cost__c += pbMap.get(WEBHOSTM2M) * stringToNumber(oneRecord.Contract_Length_Months_Websites__c);  
                     }
                 }
             } else {
             //for all websites except for website hosting only
                 if(pbMap.containsKey(WEBBLOG)) 
                    oneRecord.Website_Cost__c += pbMap.get(WEBBLOG) * nullToZero(oneRecord.Migrate_How_Many_Blog_Posts_w_o_Video__c);
                 if(pbMap.containsKey(WEBBLOGVID))
                    oneRecord.Website_Cost__c += pbMap.get(WEBBLOGVID) * nullToZero(oneRecord.Migrate_How_Many_Blog_Posts_with_Video__c);
                 if(oneRecord.Scheduling_Tool_Required__c != null && oneRecord.Scheduling_Tool_Required__c == Yes && 
                    oneRecord.Which_Scheduling_Tool__c != null){
                        if(oneRecord.Which_Scheduling_Tool__c == SchedulingBasic && pbMap.containsKey(WEBVCBASIC))
                            oneRecord.Website_Cost__c += pbMap.get(WEBVCBASIC);
                        else if(oneRecord.Which_Scheduling_Tool__c == SchedulingBranded && pbMap.containsKey(WEBVCBRAND))
                            oneRecord.Website_Cost__c += pbMap.get(WEBVCBRAND);
                        else if(oneRecord.Which_Scheduling_Tool__c == SchedulingTeam && pbMap.containsKey(WEBVCTEAM)) 
                            oneRecord.Website_Cost__c += pbMap.get(WEBVCTEAM);
                 }
                 if(oneRecord.Montage_Business_Video__c != null && oneRecord.Montage_Business_Video__c == Yes && pbMap.containsKey(WEBMONTAGE)){
                     oneRecord.Website_Cost__c += pbMap.get(WEBMONTAGE);
                 }
                 if(oneRecord.Lead_Accelerators__c != null && oneRecord.Lead_Accelerators__c == Yes && pbMap.containsKey(WEBTARGET)){
                     oneRecord.Website_Cost__c += pbMap.get(WEBTARGET) * nullToZero(oneRecord.How_Many_Lead_Accelerators__c);
                 } 
             }
         }
        
    }
    
    //private void populateSMMFields(OnBoardFormModel__c oneRecord){
    //    Double amount299 = 299; //hardcoded for now - where does it come from?
    //    Double percentage35 = .35; //hardcoded for now - 35%
    //    Double percentage65 = .65; //hardcoded for now - 65%
    //    //populate fields for social media managment
    //    if(oneRecord.Social_Media_Management__c != null && oneRecord.Social_Media_Management__c){
    //        if(pbMap != null && !pbMap.isEmpty() && pbMap.containsKey(SOCIALMGMTLAUNCH))
    //            oneRecord.Baked_In_Spend__c = (pbMap.get(SOCIALMGMTLAUNCH) * percentage35).setScale(2);
    //        if(oneRecord.Baked_In_Spend__c != null)
    //            oneRecord.SocialMediaMgmt_Spend_Budget__c = (oneRecord.Baked_In_Spend__c * percentage65).setScale(2);
    //        if(oneRecord.Additional_Facebook_Content_Quantity__c != null)
    //            oneRecord.Facebook_Additional_Content_Budget__c = (oneRecord.Additional_Facebook_Content_Quantity__c * amount299).setScale(2);
    //        if(oneRecord.Additional_Instagram_Content_Quantity__c != null)
    //            oneRecord.Instagram_Additional_Content_Budget__c = (oneRecord.Additional_Instagram_Content_Quantity__c * amount299).setScale(2);
    //        if(oneRecord.Additional_Twitter_Content_Quantity__c != null)
    //            oneRecord.Twitter_Additional_Content_Budget__c = (oneRecord.Additional_Twitter_Content_Quantity__c * amount299).setScale(2);
    //        
    //    }
    //}    
    private void addNewContacts(List<OnBoardFormModel__c> obfList){
        //insert new contact here - need Id  
        if(newContactList != null && !newContactList.isEmpty()){
            Database.insert(newContactList, false);
            for(OnBoardFormModel__c obf :obfList){  //match inserted contacts
                if(obf.Affl_Sales_Rep__c == null){
                    for(Integer i=0; i<newContactList.size(); i++){
                        if(newContactList[i].Id != null && newContactList[i].AccountId == obf.Media_Partner__c &&
                           newContactList[i].Email == obf.Affl_Sales_Rep_Email__c)
                            obf.Affl_Sales_Rep__c = newContactList[i].Id;
                    }
                }
            }
        }
    }
    
    private void getPbMap(List<OnBoardFormModel__c> obfList){
        
        String BroadcastWholesalePriceBook  = 'Broadcast Wholesale Price Book'; 
        pbMap = new Map<String, Decimal>();
        Boolean getProducts = false;
        for(OnBoardFormModel__c obf :obfList){
            if(obf.Website_Option__c != null || obf.Social_Media_Management__c)
                getProducts = true;
        }
        if(getProducts == true){ //only get it if one of records is for website
            Set<String> productCodes = new Set<String>{WEBUPPLUS, WEBPLUS, WEBGOAL, WEBHOSTONEYEAR, WEBPAGEPRE, WEBBLOG, WEBBLOGVID, 
                                        WEBVCBASIC,WEBVCBRAND, WEBVCTEAM, WEBMONTAGE, WEBTARGET, WEBECOMM10, WEBECOMM100, WEBESSENTIALS,
                                        WEBECOMM2500, WEBPAGEPOST, WEBPAGEPOSTSP, WEBUPESSENTIAL, WEBHOST, WEBHOSTM2M, SOCIALMGMTLAUNCH};
            List<PriceBookEntry> pbList = [Select Id, UnitPrice, ProductCode
                                           from PricebookEntry 
                                           where Product2.IsActive = true and Pricebook2.Name = :BroadcastWholesalePriceBook and 
                                            ProductCode IN :productCodes];
            if(pbList != null && !pbList.isEmpty()){
                for(PricebookEntry pb :pbList)
                    pbMap.put(pb.ProductCode, nullToZero(pb.UnitPrice));
            }
        }
    }
    
    private static Decimal nullToZero(Decimal input){
        return (input == null ? 0 : input);
    }
    
     private static Decimal stringToNumber(String input){
        return (input.isNumeric() ? Decimal.valueOf(input) : 0);
    }
}