@IsTest
public class LeaseRenewalTextBatchSchedulerTest {

    // Mock Twilio HTTP callout
    private class TwilioHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"queued","sid":"SM12345"}');
            return res;
        }
    }

    @IsTest
    static void testSchedulerRunsBatch() {
        // Setup test data
        House__c house = new House__c(Name = 'Scheduled Test House', Market__c = 'DFW');
        insert house;

        PW_Portfolio__c portfolio = new PW_Portfolio__c(Name = 'Test Portfolio');
        insert portfolio;

        PW_Building__c building = new PW_Building__c(
            Name = 'Scheduled Test Building',
            House__c = house.Id,
            PW_Portfolio__c = portfolio.Id,
            PW_Building_Entity_ID1__c = 'B-001'
        );
        insert building;

        PW_Lease__c lease = new PW_Lease__c(
            Name = 'Scheduled Test Lease',
            PW_Building__c = building.Id,
            Primary_Contact_Mobile__c = '+15555550199',
            Send_Lease_Renewal_Text__c = true,
            PW_Lease_Entity_ID__c = 'L-001',
            PW_Date_Renewed__c = String.valueOf(Date.today().addDays(-30))
        );
        insert lease;

        // Mock callout
        Test.setMock(HttpCalloutMock.class, new TwilioHttpMock());

        Test.startTest();
        // Schedule the job to run once immediately
        String cron = '0 0 0 15 3 ? 2042'; // runs at a specific date/time
        System.schedule('LeaseRenewalTextBatchSchedulerJob', cron, new LeaseRenewalTextBatchScheduler());
        Test.stopTest();

        // Verify lease flag updated by batch
        lease = [SELECT Id, Send_Lease_Renewal_Text__c FROM PW_Lease__c WHERE Id = :lease.Id];
        System.assertEquals(True, lease.Send_Lease_Renewal_Text__c, 'Lease flag should be false after scheduler runs batch');
    }
}