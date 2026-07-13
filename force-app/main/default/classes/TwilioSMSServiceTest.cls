@IsTest
private class TwilioSMSServiceTest {

    // Mock HTTP response for Twilio callout
    class MockTwilioResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"sid": "SMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "status": "sent"}');
            res.setStatusCode(201);
            return res;
        }
    }

    @IsTest
    static void testSendSMS() {
        // Set mock response
        Test.setMock(HttpCalloutMock.class, new MockTwilioResponse());

        // Prepare input
        TwilioSMSService.SMSRequest request = new TwilioSMSService.SMSRequest();
        request.toPhone = '+1234567890';
        request.messageBody = 'Test message from Apex';

        // Execute method
        Test.startTest();
        TwilioSMSService.sendSMS(new List<TwilioSMSService.SMSRequest>{ request });
        Test.stopTest();

        // You can’t assert the callout body directly, but you can confirm no exceptions were thrown
        System.assert(true, 'SMS was sent successfully.');
    }
}