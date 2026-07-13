@isTest
public class OpportunityTriggerTest {
    @isTest
    static void testTriggerCoverage() {
        // Create custom setting for trigger
        Trigger_Switch__c triggerSwitch = new Trigger_Switch__c(Name='Opportunity', Is_Enabled__c=true);
        insert triggerSwitch;

        // Create Account
        Account acc = TestDataFactory.createAccount('Test Acc', Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId(), 'Maintenance');
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'New',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            LeadSource = 'Facebook',
            Listing_Date__c = Date.today(),
            Closing_Stage__c = 'Start',
            Follow_Up_Sold_Date__c = Date.today()
        );
        insert opp; // covers isBefore isInsert and isAfter isInsert

        // Update Opportunity
        opp.StageName = 'Closed Won';
        update opp; // covers isBefore isUpdate, isAfter isUpdate, and Trigger.isUpdate block
    }
}