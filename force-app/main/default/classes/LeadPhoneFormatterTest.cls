@isTest
public class LeadPhoneFormatterTest {
    @isTest
    static void testLeadPhoneFormatting() {
        Id leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Investor Prospect').getRecordTypeId();
        
        Lead l = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Phone = '555-123-4567',
            MobilePhone = '+1 (555) 123-4567',
            RecordTypeId = leadRecordTypeId,
            LeadSource = 'Wholesaler', 
            Original_Source_Data_3__c = 'Front Desk Email Lead', 
            Original_Source_Data_4__c = 'Fortune Builders Client'
        );
        
        Test.startTest();
        insert l;
        Test.stopTest();
        
        l = [SELECT Phone, MobilePhone FROM Lead WHERE Id = :l.Id];
        
        // Since Phone and MobilePhone resolve to same number, Phone should be nulled out and bubbled
        System.assertEquals('+15551234567', l.MobilePhone, 'MobilePhone should be normalized');
        System.assertEquals(null, l.Phone, 'Duplicate phone should be cleared');
    }
}