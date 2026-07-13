@isTest
public class AccountPhoneFormatterTest {
    @isTest
    static void testAccountPhoneFormatting() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Investor Owner').getRecordTypeId();
        
        Account a = new Account(
            Name = 'Test Account',
            Phone = '555-123-4567 cell',
            Additional_Phone_Numbers__c = '+1 (555) 999-8888',
            RecordTypeId = accRecordTypeId
        );
        
        Test.startTest();
        insert a;
        Test.stopTest();
        
        a = [SELECT Phone, Additional_Phone_Numbers__c, Customer_Service_Notes__c FROM Account WHERE Id = :a.Id];
        
        System.assertEquals('+15551234567', a.Phone, 'Phone should be normalized');
        System.assertEquals('+15559998888', a.Additional_Phone_Numbers__c, 'Additional phone should be normalized');
        System.assert(a.Customer_Service_Notes__c.contains('555-123-4567 cell'), 'Original phone value should be preserved in notes');
    }
}