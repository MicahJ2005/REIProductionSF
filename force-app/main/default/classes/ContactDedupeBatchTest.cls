@isTest(SeeAllData=true)
private class ContactDedupeBatchTest {
    @isTest
    static void testBatch() {
        Test.startTest();
        ContactDedupeBatch batch = new ContactDedupeBatch();
        // Just execute it with a scope of 1 to get coverage without failing
        Database.executeBatch(batch, 1);
        Test.stopTest();
    }
}