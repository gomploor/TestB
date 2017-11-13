<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>OLI_Expired_30_Days_Ago</fullName>
        <description>OLI Expired 30 Days Ago</description>
        <protected>false</protected>
        <recipients>
            <field>Affl_Sales_Rep__c</field>
            <type>contactLookup</type>
        </recipients>
        <recipients>
            <field>Notify_Email_1__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Notify_Email_2__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Notify_Email_3__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Opportunity_Product_Templates/OLI_Expiration_Reminder_Expired_30_Days_Ago</template>
    </alerts>
    <alerts>
        <fullName>OLI_Expires_Today</fullName>
        <description>OLI Expires Today</description>
        <protected>false</protected>
        <recipients>
            <field>Affl_Sales_Rep__c</field>
            <type>contactLookup</type>
        </recipients>
        <recipients>
            <field>Notify_Email_1__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Notify_Email_2__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Notify_Email_3__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Opportunity_Product_Templates/OLI_Expiration_Reminder_Expiring_Today</template>
    </alerts>
    <alerts>
        <fullName>OLI_Expires_in_30_Days</fullName>
        <description>OLI Expires in 30 Days</description>
        <protected>false</protected>
        <recipients>
            <field>Affl_Sales_Rep__c</field>
            <type>contactLookup</type>
        </recipients>
        <recipients>
            <field>Notify_Email_1__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Notify_Email_2__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Notify_Email_3__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Opportunity_Product_Templates/OLI_Expiration_Reminder_Expiring_Within_30_Days</template>
    </alerts>
    <alerts>
        <fullName>OLI_Expires_in_7_Days</fullName>
        <description>OLI Expires in 7 Days</description>
        <protected>false</protected>
        <recipients>
            <field>Affl_Sales_Rep__c</field>
            <type>contactLookup</type>
        </recipients>
        <recipients>
            <field>Notify_Email_1__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Notify_Email_2__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Notify_Email_3__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Opportunity_Product_Templates/OLI_Expiration_Reminder_Expiring_Within_7_Days</template>
    </alerts>
    <rules>
        <fullName>OLI Expiration Email Notification%3A Website Products</fullName>
        <active>true</active>
        <description>To send automatic notification to the distribution list on Opportunities for expiring Website OLIs.</description>
        <formula>OR(AND(Notify_OLI_Expiration__c = true, ISPICKVAL( Waiting_Status__c, &apos;Live&apos; )),AND(Send_Expiration_Notification__c = true, Expiration_Date__c - TODAY() &gt;= 30))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>OLI_Expires_in_7_Days</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>OpportunityLineItem.Expiration_Date__c</offsetFromField>
            <timeLength>-7</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>OLI_Expires_Today</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>OpportunityLineItem.Expiration_Date__c</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>OLI_Expires_in_30_Days</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>OpportunityLineItem.Expiration_Date__c</offsetFromField>
            <timeLength>-30</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>OLI_Expired_30_Days_Ago</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>OpportunityLineItem.Expiration_Date__c</offsetFromField>
            <timeLength>30</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>OLI Expiration Email Notification%3A Website Products %28Expired 30 Days Ago%29</fullName>
        <active>true</active>
        <description>DEV-13332 - This is a temporary workflow to send automatic notification to the distribution list on Opportunities for Website OLIs 30 days after expiration. This will be deleted once the pending/waiting actions scheduled in the workflow queue is executed.</description>
        <formula>OR(AND(Notify_OLI_Expiration__c = true, ISPICKVAL( Waiting_Status__c, &apos;Live&apos; )), AND(Send_Expiration_Notification__c = true, (TODAY() - Expiration_Date__c &gt; 0),(TODAY() - Expiration_Date__c &lt;= 30)))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>OLI_Expired_30_Days_Ago</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>OpportunityLineItem.Expiration_Date__c</offsetFromField>
            <timeLength>30</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>OLI Expiration Email Notification%3A Website Products %28Expiring Today%29</fullName>
        <active>true</active>
        <description>DEV-13332 - This is a temporary workflow to send automatic notification to the distribution list on Opportunities for Website OLIs expiring today. This will be deleted once the pending/waiting actions scheduled in the workflow queue is executed.</description>
        <formula>OR(AND(Notify_OLI_Expiration__c = true, ISPICKVAL( Waiting_Status__c, &apos;Live&apos; )), AND(Send_Expiration_Notification__c = true, 
(Expiration_Date__c - TODAY() &lt; 7),(Expiration_Date__c - TODAY() &gt;= 0)))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>OLI_Expires_Today</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>OpportunityLineItem.Expiration_Date__c</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>OLI_Expired_30_Days_Ago</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>OpportunityLineItem.Expiration_Date__c</offsetFromField>
            <timeLength>30</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>OLI Expiration Email Notification%3A Website Products %28Expiring in 7 Days%29</fullName>
        <active>true</active>
        <description>DEV-13332 - This is a temporary workflow to send automatic notification to the distribution list on Opportunities for Website OLIs expiring within 7days. This will be deleted once the pending/waiting actions scheduled in the workflow queue is executed.</description>
        <formula>OR(AND(Notify_OLI_Expiration__c = true, 
ISPICKVAL( Waiting_Status__c, &apos;Live&apos; )), AND(Send_Expiration_Notification__c = true, 
(Expiration_Date__c - TODAY() &lt; 30),(Expiration_Date__c - TODAY() &gt;= 7)))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>OLI_Expired_30_Days_Ago</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>OpportunityLineItem.Expiration_Date__c</offsetFromField>
            <timeLength>30</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>OLI_Expires_Today</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>OpportunityLineItem.Expiration_Date__c</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>OLI_Expires_in_7_Days</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>OpportunityLineItem.Expiration_Date__c</offsetFromField>
            <timeLength>-7</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
</Workflow>
