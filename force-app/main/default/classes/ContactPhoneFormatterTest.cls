@isTest
private class ContactPhoneFormatterTest {
    @isTest
    static void testInsertFormatter() {
        Test.startTest();
        Contact c = new Contact(FirstName='Trigger', LastName='Test', Phone='(901) 505-0730', MobilePhone='9015050730', HomePhone='901-505-0730');
        insert c;
        Test.stopTest();
        
        Contact inserted = [SELECT MobilePhone, Phone, HomePhone FROM Contact WHERE Id = :c.Id];
        System.assertEquals('+19015050730', inserted.MobilePhone, 'Should format and set as primary');
        System.assertEquals(null, inserted.Phone, 'Should be cleared');
        System.assertEquals(null, inserted.HomePhone, 'Should be cleared');
    }

    @isTest
    static void testUpdateFormatter() {
        Contact c = new Contact(FirstName='Update', LastName='Test', MobilePhone='+19011112222');
        insert c;
        
        Test.startTest();
        c.Phone = '(901) 333-4444';
        update c;
        Test.stopTest();
        
        Contact updated = [SELECT MobilePhone, Phone FROM Contact WHERE Id = :c.Id];
        System.assertEquals('+19011112222', updated.MobilePhone);
        System.assertEquals('+19013334444', updated.Phone);
    }
}