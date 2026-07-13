public class TwilioSMSService {
    private static final String FROM_PHONE = '+19016757764'; // Your Twilio phone number
    private static final String ACCOUNT_SID = 'AC16db9f7fbd1d72e89545f9f32b28e2c0';

    // ---------- WRAPPER FOR FLOWS ----------
    public class SMSRequest {
        @InvocableVariable(required=true)
        public String toPhone;

        @InvocableVariable(required=true)
        public String messageBody;
    }

    // ---------- FLOW ENTRY POINT ----------
    @InvocableMethod(label='Send SMS via Twilio' description='Send an SMS message using Twilio API')
    public static void sendSMS(List<SMSRequest> requests) {
        for (SMSRequest reqItem : requests) {
            System.enqueueJob(new TwilioSMSSender(reqItem.toPhone, reqItem.messageBody));
        }
    }

    // ---------- APEX ENTRY POINT ----------
    public static void sendSingleSMS(String toPhone, String messageBody) {
        System.enqueueJob(new TwilioSMSSender(toPhone, messageBody));
    }

    // ---------- QUEUEABLE JOB ----------
    public class TwilioSMSSender implements Queueable, Database.AllowsCallouts {
        private String toPhone;
        private String messageBody;

        public TwilioSMSSender(String toPhone, String messageBody) {
            this.toPhone = toPhone;
            this.messageBody = messageBody;
        }

        public void execute(QueueableContext context) {
            String endpoint = '/2010-04-01/Accounts/' + ACCOUNT_SID + '/Messages.json';

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Twilio_API' + endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

            String body = 'To=' + EncodingUtil.urlEncode(toPhone, 'UTF-8') +
                          '&From=' + EncodingUtil.urlEncode(FROM_PHONE, 'UTF-8') +
                          '&Body=' + EncodingUtil.urlEncode(messageBody, 'UTF-8');
            req.setBody(body);

            Http http = new Http();
            try {
                HttpResponse res = http.send(req);
                System.debug('Twilio SMS Response: ' + res.getBody());
            } catch (Exception e) {
                System.debug('Error sending SMS: ' + e.getMessage());
            }
        }
    }
}