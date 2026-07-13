public with sharing class PropertyWareLeaseAPIMemphisSMS {
       // Flow input
    public class LeaseRequest {
        @InvocableVariable(required=true)
        public String leaseId;

         @InvocableVariable(required=true)
        public String textMessage;
    }

    @InvocableMethod(label='Call PropertyWare Lease API' description='Calls PropertyWare Lease API with LeaseId')
    public static void callLeaseAPI(List<LeaseRequest> requests) {
         system.debug('requests: '+requests);
        for (LeaseRequest req : requests) {
            system.debug('req.leaseId: '+req.leaseId);
            System.enqueueJob(new LeaseAPICalloutJob(req.leaseId, req.textMessage));
        }
    }

    /**
     * New method to call from Apex
     */
    public static void callLeaseAPI(String leaseId, String textMessage) {
        enqueueLeaseCallout(leaseId, textMessage);
    }

    /**
     * Private helper to enqueue the Queueable job
     */
    private static void enqueueLeaseCallout(String leaseId, String textMessage) {
        System.debug('Enqueueing Lease API job for Lease: ' + leaseId);
        System.enqueueJob(new LeaseAPICalloutJob(leaseId, textMessage));
    }

    // Queueable job for callout
    public class LeaseAPICalloutJob implements Queueable, Database.AllowsCallouts {
        private String leaseId;
        private String textMessage;

        public LeaseAPICalloutJob(String leaseId, string textMessage) {
            this.leaseId = leaseId;
            this.textMessage = textMessage;
        }

        public void execute(QueueableContext context) {
            try {
                PropertyWare_Setting__mdt PWPPMGCREDS = [
                    SELECT 
                        x_propertyware_client_id__c,
                        x_propertyware_client_secret__c,
                        x_propertyware_system_id__c
                    FROM PropertyWare_Setting__mdt
                    WHERE DeveloperName = 'PW_PPMG_Creds'
                    LIMIT 1
                ];

                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('https://api.propertyware.com/pw/api/rest/v1/leases/' + leaseId);
                request.setMethod('GET');

                request.setHeader('x-propertyware-client-id', PWPPMGCREDS.x_propertyware_client_id__c);
                request.setHeader('x-propertyware-client-secret', PWPPMGCREDS.x_propertyware_client_secret__c);
                request.setHeader('x-propertyware-system-id', PWPPMGCREDS.x_propertyware_system_id__c);

                request.setHeader('Accept', '*/*');
                request.setHeader('Accept-Encoding', 'gzip, deflate, br');
                request.setHeader('Connection', 'keep-alive');

                HttpResponse response = http.send(request);

                System.debug('Lease API Status: ' + response.getStatusCode());
                System.debug('Lease API Body: ' + response.getBody());
                Map<String, Object> leaseWrapper = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                string mobilePhone;
                // Get contacts list
                if (leaseWrapper.containsKey('contacts')) {
                    List<Object> contacts = (List<Object>) leaseWrapper.get('contacts');
                    
                    for (Object c : contacts) {
                        Map<String, Object> contact = (Map<String, Object>) c;
                        
                        // Safely check "primary"
                        if (contact.containsKey('primary')) {
                            Boolean isPrimary = (Boolean) contact.get('primary');
                            if (isPrimary) {
                                mobilePhone = (String) contact.get('mobilePhone');
                                System.debug('Found Primary Contact MobilePhone: ' + mobilePhone);
                            } else {
                                System.debug('Not Primary Contact: ' + contact);
                            }
                        }
                    }
                }
                if(mobilePhone != null) {
                    TwilioSMSService.sendSingleSMS(mobilePhone, textMessage);
                    // TwilioSMSService.sendSingleSMS('763-333-5159', textMessage);
                }
                // TODO: Optionally parse and upsert to a custom object if you need
            } catch (Exception e) {
                System.debug('Error in Lease API Callout: ' + e.getMessage());
            }
        }
    }
}