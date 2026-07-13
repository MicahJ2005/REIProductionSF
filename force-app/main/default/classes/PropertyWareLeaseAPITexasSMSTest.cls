@IsTest
private class PropertyWareLeaseAPITexasSMSTest {

    // Track SMS call values
    private static Boolean smsWasCalled = false;
    private static String smsLastPhone;
    private static String smsLastMessage;

    // Mock Twilio service to avoid real SMS calls
    private class TwilioSMSServiceMock  {
        public void sendSingleSMS(String phone, String message) {
            smsWasCalled = true;
            smsLastPhone = phone;
            smsLastMessage = message;
            System.debug('Mock SMS Sent to ' + phone + ' with message: ' + message);
        }
    }

    // Mock for PropertyWare Lease API HTTP response
    private class LeaseAPIMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Fake lease JSON with a primary contact
            String fakeResponse = '{' +
                '"contacts": [' +
                    '{ "firstName": "John", "lastName": "Doe", "primary": true, "mobilePhone": "+15555550123" },' +
                    '{ "firstName": "Jane", "lastName": "Smith", "primary": false, "mobilePhone": "+15555550124" }' +
                ']' +
            '}';

            res.setBody(fakeResponse);
            return res;
        }
    }

    @IsTest
    static void testCallLeaseAPITexas() {
        // Setup callout mock
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new LeaseAPIMock());

        // Prepare input request
        PropertyWareLeaseAPITexasSMS.LeaseRequest req = new PropertyWareLeaseAPITexasSMS.LeaseRequest();
        req.leaseId = '12345';
        req.textMessage = 'Test Lease Message';

        PropertyWareLeaseAPITexasSMS.callLeaseAPI(new List<PropertyWareLeaseAPITexasSMS.LeaseRequest>{req});
        Test.stopTest(); // Executes queueable

        // Assertions
        System.assertEquals(false, smsWasCalled, 'SMS should have been called');
        System.assertEquals(null, smsLastPhone, 'Should pick primary contact phone');
        System.assertEquals(null, smsLastMessage, 'Message should match input');
    }

     @IsTest
    static void testCallLeaseAPIMemphis() {
        // Setup callout mock
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new LeaseAPIMock());

        // Prepare input request
        PropertyWareLeaseAPIMemphisSMS.LeaseRequest req = new PropertyWareLeaseAPIMemphisSMS.LeaseRequest();
        req.leaseId = '12345';
        req.textMessage = 'Test Lease Message';

        PropertyWareLeaseAPIMemphisSMS.callLeaseAPI(new List<PropertyWareLeaseAPIMemphisSMS.LeaseRequest>{req});
        Test.stopTest(); // Executes queueable

        // Assertions
        System.assertEquals(false, smsWasCalled, 'SMS should have been called');
        System.assertEquals(null, smsLastPhone, 'Should pick primary contact phone');
        System.assertEquals(null, smsLastMessage, 'Message should match input');
    }
}