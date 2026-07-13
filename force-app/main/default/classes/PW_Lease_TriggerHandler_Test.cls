@IsTest
private class PW_Lease_TriggerHandler_Test {

    //Mock SMS API classes so test doesn't actually call external APIs
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
    static void testHandlerInsertAndUpdate() {
        // Create required CMDT values
        // insert new PropertyWare_Setting__mdt(
        //     DeveloperName = 'MemphisLeaseTextMessage',
        //     MasterLabel = 'MemphisLeaseTextMessage',
        //     TextValue__c = 'Memphis Test Message'
        // );
        // insert new PropertyWare_Setting__mdt(
        //     DeveloperName = 'TexasLeaseTextMessage',
        //     MasterLabel = 'TexasLeaseTextMessage',
        //     TextValue__c = 'Texas Test Message'
        // );
        

        // Create a portfolio (required by PW_Building__c)
        PW_Portfolio__c portfolio = new PW_Portfolio__c(Name='Test Portfolio');
        insert portfolio;

        // Create Houses for each market
        House__c memphisHouse = new House__c(Name='Memphis House', Market__c='MEM');
        insert memphisHouse;
        House__c texasHouse = new House__c(Name='Texas House', Market__c='DFW');
        insert texasHouse;

        // Create Buildings with required fields
        PW_Building__c memphisBuilding = new PW_Building__c(
            Name='Memphis Building',
            House__c=memphisHouse.Id,
            PW_Portfolio__c=portfolio.Id,
            PW_Building_Entity_ID1__c='MEM-BLD-001'
        );
        PW_Building__c texasBuilding = new PW_Building__c(
            Name='Texas Building',
            House__c=texasHouse.Id,
            PW_Portfolio__c=portfolio.Id,
            PW_Building_Entity_ID1__c='TX-BLD-001'
        );
        insert new List<PW_Building__c>{memphisBuilding, texasBuilding};

        // Create Leases for insert testing
        PW_Lease__c memphisLease = new PW_Lease__c(
            Name='Memphis Lease',
            PW_Building__c=memphisBuilding.Id,
            PW_Lease_Entity_ID__c='MEM-LEASE-001',
            PW_Date_Renewed__c= '9/1/2025'
        );
        PW_Lease__c texasLease = new PW_Lease__c(
            Name='Texas Lease',
            PW_Building__c=texasBuilding.Id,
            PW_Lease_Entity_ID__c='TX-LEASE-001',
            PW_Date_Renewed__c='9/1/2025'
        );

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new LeaseAPIMock());
        insert new List<PW_Lease__c>{memphisLease, texasLease};
       

        // Update leases to trigger update path
        memphisLease.PW_Date_Renewed__c = '9/3/2025';
        texasLease.PW_Date_Renewed__c = '9/3/2025';

        update new List<PW_Lease__c>{memphisLease, texasLease};
        Test.stopTest();
    }

    @IsTest
    static void testHandlerEmptyLeasesList() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new LeaseAPIMock());
        // Calling handler with null/empty lists should just return
        PW_Lease_TriggerHandler.afterInsertOrUpdate(
            new List<PW_Lease__c>(),
            new Map<Id, PW_Lease__c>(),
            new Map<Id, PW_Lease__c>()
        );
        Test.stopTest();
    }
}