@isTest
private class NormalizeAndConsolidatePhonesBatchTest {
    @testSetup
    static void setup() {
        List<Contact> testContacts = new List<Contact>();
        
        // Case A: Duplicate numbers scattered
        testContacts.add(new Contact(FirstName='TestA', LastName='Dupes', Phone='(901) 505-0730', MobilePhone='9015050730', HomePhone='901-505-0730', OtherPhone='901.505.0730'));
        
        // Case B: Scattered unique numbers
        testContacts.add(new Contact(FirstName='TestB', LastName='Scattered', Phone=null, MobilePhone=null, HomePhone='901-111-2222', OtherPhone='901-333-4444'));
        
        // Case C: Mix of dupes and scattered
        testContacts.add(new Contact(FirstName='TestC', LastName='Mix', Phone='901-999-9999', MobilePhone=null, HomePhone='901-999-9999', OtherPhone='901-888-8888'));
        
        // Case D: Unique
        testContacts.add(new Contact(FirstName='TestD', LastName='Unique', Phone='(901) 222-2222', MobilePhone='9011111111', HomePhone='901-333-3333'));
        
        insert testContacts;
    }

    @isTest
    static void testBatch() {
        Test.startTest();
        NormalizeAndConsolidatePhonesBatch batch = new NormalizeAndConsolidatePhonesBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify Case A
        Contact cA = [SELECT MobilePhone, Phone, HomePhone, OtherPhone FROM Contact WHERE LastName = 'Dupes' LIMIT 1];
        System.assertEquals('+19015050730', cA.MobilePhone, 'MobilePhone should be formatted');
        System.assertEquals(null, cA.Phone, 'Phone should be cleared');
        System.assertEquals(null, cA.HomePhone, 'HomePhone should be cleared');
        
        // Verify Case B
        Contact cB = [SELECT MobilePhone, Phone, HomePhone, OtherPhone FROM Contact WHERE LastName = 'Scattered' LIMIT 1];
        System.assertEquals('+19011112222', cB.MobilePhone, 'HomePhone bubbled to MobilePhone');
        System.assertEquals('+19013334444', cB.Phone, 'OtherPhone bubbled to Phone');
        System.assertEquals(null, cB.HomePhone, 'HomePhone should be cleared');
    }
}