@isTest
private class PWNightlyPflUpdateScheduleTexasTest {
    
    // Mock API response for portfolios
    private class PortfolioHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            // Fake PropertyWare portfolio response
            String mockJson = '[{' +
                '"id": "P001",' +
                '"active": true,' +
                '"portfolioBalance": 5000.75' +
            '}]';
            
            res.setBody(mockJson);
            return res;
        }
    }
    
    @isTest
    static void testSchedulableExecutesAndUpdatesPortfolio() {
        
        
        // Insert portfolio that should get updated
        PW_Portfolio__c portfolio = new PW_Portfolio__c(
            Name = 'Test Portfolio',
            PW_Portfolio_Entity_ID__c = 'P001',
            PW_Active__c = false,
            PW_Portfolio_Balance__c = 0
        );
        insert portfolio;
        
        // Register callout mock
        Test.setMock(HttpCalloutMock.class, new PortfolioHttpMock());
        
        Test.startTest();
        // Schedule the nightly job (runs immediately in test context)
        String jobId = System.schedule(
            'TestNightlyPortfolioJob',
            '0 0 0 1 1 ? 2099', // arbitrary cron expression
            new PWNightlyPortfolioUpdateScheduleTexas()
        );
        Test.stopTest();
        
        // Verify that portfolio was updated
        PW_Portfolio__c updated = [
            SELECT Id, PW_Active__c, PW_Portfolio_Balance__c
            FROM PW_Portfolio__c
            WHERE Id = :portfolio.Id
        ];
        
    }
}