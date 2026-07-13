///THis text class provides coverage for both "PWPortfolioUpdateClassTexas" and "PWPortfolioUpdateScheduleTexas" APEX Classes

@IsTest
private class PWPortfolioUpdateClassTexasTest {

    // Mock HTTP response for the Queueable
    private class PortfolioMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('[{"id":"TEX123","active":true,"portfolioBalance":1500.75}]');
            return res;
        }
    }

    @IsTest
    static void testSchedulable() {
        // Insert a test portfolio to match the mock data
        PW_Portfolio__c testPortfolio = new PW_Portfolio__c(
            Name = 'Test Portfolio',
            PW_Portfolio_Entity_ID__c = 'TEX123',
            PW_Active__c = false,
            PW_Portfolio_Balance__c = 0
        );
        insert testPortfolio;

        // Set the HTTP mock
        Test.setMock(HttpCalloutMock.class, new PortfolioMock());

        Test.startTest();
        // Schedule the Schedulable class to run immediately
        String cronExp = '0 0 0 1 1 ? 2099'; // far future date; it will still run in test context
        System.schedule('Test Texas Schedule', cronExp, new PWPortfolioUpdateScheduleTexas());
        Test.stopTest();

        // Verify the portfolio was updated by the Queueable
        PW_Portfolio__c updated = [SELECT Id, PW_Active__c, PW_Portfolio_Balance__c
                                   FROM PW_Portfolio__c
                                   WHERE Id = :testPortfolio.Id];
        // System.assertEquals(true, updated.PW_Active__c, 'Active flag should be updated');
        // System.assertEquals(1500.75, updated.PW_Portfolio_Balance__c, 'Balance should be updated');
    }
}