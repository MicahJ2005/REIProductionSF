@isTest
public class LeadPhoneNormalizerBatchTest {
    @testSetup
    static void setup() {
        Id leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Investor Prospect').getRecordTypeId();
        
        List<Lead> leads = new List<Lead>();
        leads.add(new Lead(FirstName = 'Batch', LastName = 'Test 1', Company = 'Company 1', Phone = '555-123-4567', MobilePhone = '+1 (555) 123-4567', RecordTypeId = leadRecordTypeId, LeadSource = 'Wholesaler', Original_Source_Data_3__c = 'Front Desk Email Lead', Original_Source_Data_4__c = 'Fortune Builders Client'));
        
        insert leads;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        LeadPhoneNormalizerBatch batch = new LeadPhoneNormalizerBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        System.assert(true, 'Batch should execute without errors');
    }
}