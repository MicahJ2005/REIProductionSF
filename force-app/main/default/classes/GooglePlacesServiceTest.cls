@isTest
private class GooglePlacesServiceTest {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"candidates":[{"place_id":"ChIJN1t_tDeuEmsRUsoyG83frY4"}],"status":"OK"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testGetPlaceIdFromHouseRecordId() {
        House__c testHouse = new House__c(
            Name = 'Test House',
            Street_Address__c = '1600 Amphitheatre Parkway',
            City__c = 'Mountain View',
            State__c = 'TN',
            Zip_Code__c = '94043'
        );
        insert testHouse;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        Map<Id, House__c> oldMap = new Map<Id, House__c>();
        Map<Id, House__c> newMap = new Map<Id, House__c>([SELECT Id, Name, House_Complete_Address__c, Google_Place_ID__c FROM House__c WHERE Id = :testHouse.Id]);
        // Notice: newMap goes first as defined in GooglePlacesService
        GooglePlacesService.getPlaceIdFromHouseRecordId(newMap, oldMap);
        Test.stopTest();

        testHouse = [SELECT Google_Place_ID__c FROM House__c WHERE Id = :testHouse.Id];
        System.assertEquals('ChIJN1t_tDeuEmsRUsoyG83frY4', testHouse.Google_Place_ID__c);
    }
}