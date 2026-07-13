@isTest
private class BatchSObjectDeleterTest {
    @isTest
    static void testBatchDelete() {
        // Create test Contacts
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            testContacts.add(new Contact(
                FirstName = 'John',
                LastName = 'Smith'
            ));
        }
        insert testContacts;
        
        System.assertEquals(10, [SELECT COUNT() FROM Contact WHERE LastName = 'Smith' AND FirstName = 'John']);
        
        Test.startTest();
        String query = 'SELECT Id FROM Contact WHERE LastName = \'Smith\' AND FirstName = \'John\'';
        BatchSObjectDeleter batchJob = new BatchSObjectDeleter(query);
        Database.executeBatch(batchJob);
        Test.stopTest();
        
        System.assertEquals(0, [SELECT COUNT() FROM Contact WHERE LastName = 'Smith' AND FirstName = 'John']);
    }
}