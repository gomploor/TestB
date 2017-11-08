/**
 *  Class Name          : BillingScheduleCompCntrl
 *  Created By          : Paul Juneau
 *  Last Modified By    : Paul Juneau
 *  Description         : This controller governs what is populated in Billing Schedule VF Component. Part of E2E Variable Billing. DEV-6774
 *  Modifed History     : 08/02/2016 Created this class. 
 */
public without sharing class BillingScheduleCompCntrl {
		public String VIDEOADS = 'VIDEOADS';
		public id oliId {set;get;}
        public Boolean renderUnits {get;set;}
        public Boolean renderPackage {get;set;}
    	Public List<Billing_Schedule__c> billingScheduleList; 
	
	public BillingScheduleCompCntrl() {
		
		billingScheduleList = new List<Billing_Schedule__c>();

    }
    /* DEV-11150 - Commented due to the Variable Billing record deletion done in DEV-10686
    //DEV-10451 
    public BillingScheduleCompCntrl(ApexPages.StandardController stdController) 
    {
    }*/

	public List<Billing_Schedule__c>  getBillingScheduleList() {
      opportunityLineItem oli = [select id,name,opportunity.name,OpportunityId,Product2.Name, Product2.ProductCode,LastModifiedBy.Name,Project__c, Product2.Has_Package__c
                                from opportunityLineItem where id =:oliId];

      if(oli.Product2.ProductCode == VIDEOADS){
        renderUnits = true;
      }
      renderPackage = false;
      if(oli.Product2.Has_Package__c == true)
            renderPackage = true;    
      billingScheduleList = [select Id, Name, Period_Start__c, Period_End__c, Media_Budget__c, Management_Fee_percent__c, Management_Fee__c, Total_Amount__c, Type__c, Units__c, Package__c 
                      		 from Billing_Schedule__c where Opportunity__c =:oli.OpportunityId  and Opportunity_Product__c =:oliId];
      
      return billingScheduleList;
  	}  
}