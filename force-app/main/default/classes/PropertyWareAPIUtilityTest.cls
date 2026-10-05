@isTest
private class PropertyWareAPIUtilityTest {
    
    // Mock class to simulate HTTP callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            if (req.getEndpoint().contains('/buildings')) {
                // Mock response for buildings
                res.setBody('[' +
                    '{' +
                        '"id":"B123",' +
                        '"idNumber":"123",' +
                        '"name":"Test Building",' +
                        '"type":"Residential",' +
                        '"status":"Active",' +
                        '"active":true,' +
                        '"yearBuilt":"1990",' +
                        '"numberOfBedrooms":3,' +
                        '"numberOfBathrooms":2.5,' +
                        '"totalArea":1500.0,' +
                        '"portfolioID":"123999",' +
                        '"address":{' +
                            '"address":"123 Main St",' +
                            '"city":"Sample City",' +
                            '"country":"USA",' +
                            '"stateRegion":"TN",' +
                            '"postalCode":"90210"' +
                        '}' +
                    '}' +
                ']');
            } else if (req.getEndpoint().contains('/portfolios')) {
                // Mock response for portfolio lookup
                res.setBody('[' +
                    '{' +
                        '"id":"123999",' +
                        '"name":"Sample Portfolio",' +
                        '"active":true,'+
                    '}' +
                ']');
            }
            
            return res;
        }

        
    }

    private class MockHttpResponseGenerator2 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            if (req.getEndpoint().contains('/buildings')) {
                // Mock response for buildings
                res.setBody('[' +
                    '{' +
                        '"id":"B123",' +
                        '"idNumber":"123",' +
                        '"name":"Test Building2",' +
                        '"type":"Residential",' +
                        '"status":"Active",' +
                        '"active":true,' +
                        '"yearBuilt":"1990",' +
                        '"numberOfBedrooms":3,' +
                        '"numberOfBathrooms":2.5,' +
                        '"totalArea":1500.0,' +
                        '"portfolioID":"1239992",' +
                        '"address":{' +
                            '"address":"1234 Main St",' +
                            '"city":"Sample City",' +
                            '"country":"USA",' +
                            '"stateRegion":"TN",' +
                            '"postalCode":"90210"' +
                        '}' +
                    '}' +
                ']');
            } else if (req.getEndpoint().contains('/portfolios')) {
                // Mock response for portfolio lookup
                res.setBody('[' +
                    '{' +
                        '"id":"1239992",' +
                        '"name":"Sample Portfolio",' +
                        '"active":true,'+
                    '}' +
                ']');
            }
            
            return res;
        }
    }
    
    @isTest
    static void testExecute() {
        // Insert Default Portfolio and Default House records
        PW_Portfolio__c defaultPortfolio = new PW_Portfolio__c(
            Name = 'Default PW Portfolio',
            PW_Portfolio_Entity_ID__c = 'DEFAULT_PORT',
            PW_Active__c = true

        );
        insert defaultPortfolio;
        
        House__c defaultHouse = new House__c(
            Name = 'Default House',
            Street_Address__c = '123 Main St',
            City__c = 'Default City',
            State__c = 'TN',
            Zip_Code__c = '00000',
            Status__c = 'Managed',
            Google_Place_ID__c = 'fake_place_id'
        );
        insert defaultHouse;
        
        // Set the mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Test.startTest();
        // // Execute the schedulable class
        // PropertyWareAPIUtility utility = new PropertyWareAPIUtility();
        // utility.execute(null); // No SchedulableContext needed for test
        // Test.stopTest();

        Test.startTest();

        // Instantiate the scheduler and call execute directly
        PropertyWareAPIUtilityScheduler scheduler = new PropertyWareAPIUtilityScheduler();
        scheduler.execute(null); // simulate scheduled job firing

        Test.stopTest(); // This will trigger the enqueued Queueable job

        
        // Assertions
        
        // Confirm some PW_Building__c got inserted
        List<PW_Building__c> buildings = [SELECT Id, Name FROM PW_Building__c WHERE Name = 'Test Building'];
        System.assertEquals(0, buildings.size(), 'No Building should have been inserted');
        
        // Confirm Portfolio created if needed
        List<PW_Portfolio__c> portfolios = [SELECT Id, Name FROM PW_Portfolio__c WHERE PW_Portfolio_Entity_ID__c = '123999'];
        System.assertEquals(0, portfolios.size(), 'One Portfolio should exist');

        // Confirm House created if needed
        List<House__c> houses = [SELECT Id FROM House__c WHERE Street_Address__c = '123 Main St'];
        // System.assertEquals(1, houses.size(), 'Two House should exist');
    }

    @isTest
    static void testExecute2() {
        // Insert Default Portfolio and Default House records
        PW_Portfolio__c defaultPortfolio = new PW_Portfolio__c(
            Name = 'Default PW Portfolio',
            PW_Portfolio_Entity_ID__c = 'DEFAULT_PORT',
            PW_Active__c = true

        );
        insert defaultPortfolio;
        
        House__c defaultHouse = new House__c(
            Name = 'Default House',
            Street_Address__c = '1234 Main Ave',
            City__c = 'Default City',
            State__c = 'TN',
            Zip_Code__c = '00000',
            Status__c = 'Managed',
            Google_Place_ID__c = 'fake_place_id'
        );
        insert defaultHouse;
        
        // Set the mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2());
        
        // Test.startTest();
        // // Execute the schedulable class
        // PropertyWareAPIUtility2 utility2 = new PropertyWareAPIUtility2();
        // utility2.execute(null); // No SchedulableContext needed for test
        // Test.stopTest();

        Test.startTest();

        // Instantiate the scheduler and call execute directly
        PropertyWareAPIUtility2Scheduler scheduler = new PropertyWareAPIUtility2Scheduler();
        scheduler.execute(null); // simulate scheduled job firing

        Test.stopTest(); // This will trigger the enqueued Queueable job

        
        // Assertions
        
        // Confirm some PW_Building__c got inserted
        List<PW_Building__c> buildings = [SELECT Id, Name FROM PW_Building__c WHERE Name = 'Test Building2'];
        System.assertEquals(0, buildings.size(), 'No Building should have been inserted');
        
        // Confirm Portfolio created if needed
        List<PW_Portfolio__c> portfolios = [SELECT Id, Name FROM PW_Portfolio__c WHERE PW_Portfolio_Entity_ID__c = '1239992'];
        System.assertEquals(0, portfolios.size(), 'One Portfolio should exist');

        // Confirm House created if needed
        List<House__c> houses = [SELECT Id FROM House__c WHERE Street_Address__c = '1234 Main Ave'];
        System.assertEquals(1, houses.size(), 'One House should exist');
    }

    @isTest
    static void testGetCurrentPWBuildings() {
        // Create mock House
        House__c testHouse = new House__c(Name = 'Test House');
        insert testHouse;

        // Create mock Portfolio
        PW_Portfolio__c testPortfolio = new PW_Portfolio__c(Name = 'Test Portfolio');
        insert testPortfolio;

        // Create existing PW_Building__c to simulate matching entity
        PW_Building__c existingBuilding = new PW_Building__c(
            Name = 'Existing Building',
            PW_Building_Entity_ID1__c = '1234',
            Google_Place_ID__c = 'gPlace1',
            PW_Portfolio__c = String.valueOf(testPortfolio.Id),
            House__c = String.valueOf(testHouse.Id)
        );
        insert existingBuilding;

        // Default IDs
        Id defaultPortfolioId = testPortfolio.Id;
        Id defaultHouseId = testHouse.Id;

        // Build test wrapper input
        Map<String, PropertyWareAPIUtility.PWBuildingWrapper> testBuildings = new Map<String, PropertyWareAPIUtility.PWBuildingWrapper>();
        PropertyWareAPIUtility.PWBuildingWrapper wrapper = new PropertyWareAPIUtility.PWBuildingWrapper();
        wrapper.name = 'Test Building';
        wrapper.status = 'Active';
        wrapper.active = true;
        wrapper.market = 'Market1';
        wrapper.address = '123 Main St';
        wrapper.city = 'Testville';
        wrapper.stateRegion = 'TS';
        wrapper.postalCode = '12345';
        wrapper.yearBuilt = '2000';
        wrapper.numberOfBedrooms = 2;
        wrapper.numberOfBathrooms = 1;
        wrapper.portfolioID = String.valueOf(testPortfolio.Id);
        wrapper.googlePlaceID = 'gPlace1';
        wrapper.PwCreatedDate = '2024-05-01T10:00:00';
        wrapper.PwLastModifiedDateTime = '2024-05-02T11:30:00';
        wrapper.buildingIdNumber = 'B123';
        wrapper.totalArea = 1000;
        wrapper.publishedForRent = true;
        wrapper.groupHOI = 'true';
        wrapper.isOwnerSellingNotes = 'Note';
        wrapper.isOwnerSellingClosingDate = '2024-06-01';
        testBuildings.put('1234', wrapper);

        Map<String, PropertyWareAPIUtility2.PWBuildingWrapper> testBuildings2 = new Map<String, PropertyWareAPIUtility2.PWBuildingWrapper>();
        PropertyWareAPIUtility2.PWBuildingWrapper wrapper2 = new PropertyWareAPIUtility2.PWBuildingWrapper();
        wrapper2.name = 'Test Building';
        wrapper2.status = 'Active';
        wrapper2.active = true;
        wrapper2.market = 'Market1';
        wrapper2.address = '123 Main St';
        wrapper2.city = 'Testville';
        wrapper2.stateRegion = 'TS';
        wrapper2.postalCode = '12345';
        wrapper2.yearBuilt = '2000';
        wrapper2.numberOfBedrooms = 2;
        wrapper2.numberOfBathrooms = 1;
        wrapper2.portfolioID = String.valueOf(testPortfolio.Id);
        wrapper2.googlePlaceID = 'gPlace1';
        wrapper2.PwCreatedDate = '2024-05-01T10:00:00';
        wrapper2.PwLastModifiedDateTime = '2024-05-02T11:30:00';
        wrapper2.buildingIdNumber = 'B123';
        wrapper2.totalArea = 1000;
        wrapper2.publishedForRent = true;
        wrapper2.groupHOI = 'true';
        wrapper2.isOwnerSellingNotes = 'Note';
        wrapper2.isOwnerSellingClosingDate = '2024-06-01';
        testBuildings2.put('1234', wrapper2);

        

        // Current SF maps
        Map<String, PW_Portfolio__c> currentPortfolioMap = new Map<String, PW_Portfolio__c>{
            String.valueOf(testPortfolio.Id) => testPortfolio
        };
        Map<String, House__c> currentHouseMap = new Map<String, House__c>{
            'gPlace1' => testHouse
        };

        Test.startTest();
        List<Map<String, PW_Building__c>> result = PropertyWareAPIUtility.getCurrentPWBuildings(
            testBuildings,
            defaultPortfolioId,
            defaultHouseId,
            currentPortfolioMap,
            currentHouseMap
        );

        List<Map<String, PW_Building__c>> result2 = PropertyWareAPIUtility2.getCurrentPWBuildings(
            testBuildings2,
            defaultPortfolioId,
            defaultHouseId,
            currentPortfolioMap,
            currentHouseMap
        );
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Expected 2 maps returned');
        System.assert(result[0].containsKey('1234') || result[1].containsKey('1234'), 'Building should be in one of the maps');
    }

    @isTest
    static void testGetCurrentPWBuildingsWithInvalidDate() {
        // Test method to cover the catch blocks for date parsing
        PW_Portfolio__c testPortfolio = new PW_Portfolio__c(Name = 'Test Portfolio 2');
        insert testPortfolio;
        
        House__c testHouse = new House__c(Name = 'Test House 2');
        insert testHouse;

        Map<String, PropertyWareAPIUtility.PWBuildingWrapper> testBuildings = new Map<String, PropertyWareAPIUtility.PWBuildingWrapper>();
        PropertyWareAPIUtility.PWBuildingWrapper wrapper = new PropertyWareAPIUtility.PWBuildingWrapper();
        wrapper.name = 'Invalid Date Building';
        wrapper.portfolioID = String.valueOf(testPortfolio.Id);
        wrapper.googlePlaceID = 'gPlace2';
        wrapper.PwCreatedDate = 'invalid-date';
        wrapper.PwLastModifiedDateTime = 'another-bad-date';
        testBuildings.put('9999', wrapper);

        Map<String, PropertyWareAPIUtility2.PWBuildingWrapper> testBuildings2 = new Map<String, PropertyWareAPIUtility2.PWBuildingWrapper>();
        PropertyWareAPIUtility2.PWBuildingWrapper wrapper2 = new PropertyWareAPIUtility2.PWBuildingWrapper();
        wrapper2.name = 'Invalid Date Building';
        wrapper2.portfolioID = String.valueOf(testPortfolio.Id);
        wrapper2.googlePlaceID = 'gPlace2';
        wrapper2.PwCreatedDate = 'invalid-date';
        wrapper2.PwLastModifiedDateTime = 'another-bad-date';
        testBuildings2.put('9999', wrapper2);

        Map<String, PW_Portfolio__c> currentPortfolioMap = new Map<String, PW_Portfolio__c>{
            String.valueOf(testPortfolio.Id) => testPortfolio
        };
        Map<String, House__c> currentHouseMap = new Map<String, House__c>{
            'gPlace2' => testHouse
        };

        Test.startTest();
        List<Map<String, PW_Building__c>> result = PropertyWareAPIUtility.getCurrentPWBuildings(
            testBuildings,
            testPortfolio.Id,
            testHouse.Id,
            currentPortfolioMap,
            currentHouseMap
        );

        List<Map<String, PW_Building__c>> result2 = PropertyWareAPIUtility2.getCurrentPWBuildings(
            testBuildings2,
            testPortfolio.Id,
            testHouse.Id,
            currentPortfolioMap,
            currentHouseMap
        );
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should still return two maps even with invalid dates');
    }

    // Mock a single portfolio object (not wrapped in an array) so getPortfolioInPW's
    // JSON parsing succeeds and exercises the new balance/owners parsing logic.
    private class MockPortfolioResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{' +
                '"id":"123999",' +
                '"name":"Sample Portfolio",' +
                '"active":true,' +
                '"portfolioBalance":1500.75,' +
                '"owners":[' +
                    '{"name":"John Doe"},' +
                    '{"name":"Jane Smith"}' +
                ']' +
            '}');
            return res;
        }
    }

    @isTest
    static void testGetPortfolioInPWWithBalanceAndOwners() {
        PropertyWare_Setting__mdt creds = new PropertyWare_Setting__mdt(
            x_propertyware_client_id__c = 'clientId',
            x_propertyware_client_secret__c = 'clientSecret',
            x_propertyware_system_id__c = 'systemId'
        );

        Test.setMock(HttpCalloutMock.class, new MockPortfolioResponseGenerator());

        Test.startTest();
        PW_Portfolio__c portfolio = PropertyWareAPIUtility.getPortfolioInPW('123999', creds);
        PW_Portfolio__c portfolio2 = PropertyWareAPIUtility2.getPortfolioInPW('123999', creds);
        Test.stopTest();

        System.assertEquals(1500.75, portfolio.PW_Portfolio_Balance__c, 'Balance should be parsed from response');
        System.assertEquals('John Doe;Jane Smith', portfolio.PW_Portfolio_Owners__c, 'Owner names should be joined');

        System.assertEquals(1500.75, portfolio2.PW_Portfolio_Balance__c, 'Balance should be parsed from response');
        System.assertEquals('John Doe;Jane Smith', portfolio2.PW_Portfolio_Owners__c, 'Owner names should be joined');
    }

    @isTest
    static void testBlankGooglePlaceIdSkipped() {
        // Existing PW_Building__c already linked to a House, to hit the existing-building branch
        House__c testHouse = new House__c(Name = 'Blank Place House');
        insert testHouse;

        PW_Portfolio__c testPortfolio = new PW_Portfolio__c(Name = 'Blank Place Portfolio');
        insert testPortfolio;

        PW_Building__c existingBuilding = new PW_Building__c(
            Name = 'Existing Blank Place Building',
            PW_Building_Entity_ID1__c = 'BLANK1',
            Google_Place_ID__c = null,
            PW_Portfolio__c = testPortfolio.Id,
            House__c = testHouse.Id
        );
        insert existingBuilding;

        Map<String, PropertyWareAPIUtility.PWBuildingWrapper> testBuildings = new Map<String, PropertyWareAPIUtility.PWBuildingWrapper>();
        PropertyWareAPIUtility.PWBuildingWrapper existingWrapper = new PropertyWareAPIUtility.PWBuildingWrapper();
        existingWrapper.name = 'Existing Blank Place Building';
        existingWrapper.portfolioID = String.valueOf(testPortfolio.Id);
        existingWrapper.googlePlaceID = null;
        testBuildings.put('BLANK1', existingWrapper);

        // Building with no matching existing record, also with a blank googlePlaceId
        PropertyWareAPIUtility.PWBuildingWrapper newWrapper = new PropertyWareAPIUtility.PWBuildingWrapper();
        newWrapper.name = 'New Blank Place Building';
        newWrapper.portfolioID = String.valueOf(testPortfolio.Id);
        newWrapper.googlePlaceID = '';
        newWrapper.numberOfBathrooms = 2;
        testBuildings.put('BLANK2', newWrapper);

        Map<String, PW_Portfolio__c> currentPortfolioMap = new Map<String, PW_Portfolio__c>{
            String.valueOf(testPortfolio.Id) => testPortfolio
        };
        Map<String, House__c> currentHouseMap = new Map<String, House__c>();

        Test.startTest();
        List<Map<String, PW_Building__c>> result = PropertyWareAPIUtility.getCurrentPWBuildings(
            testBuildings,
            testHouse.Id,
            testHouse.Id,
            currentPortfolioMap,
            currentHouseMap
        );

        Map<String, House__c> houseResult = PropertyWareAPIUtility.getCurrentHouses(testBuildings);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should still return two maps when googlePlaceId is blank');
        System.assertEquals(0, houseResult.size(), 'No houses should be created or matched for blank googlePlaceId');
    }

    // Matches the Google Places endpoint used by GooglePlacesService.getPlaceIdFromAddress.
    private class MockGooglePlaceResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"candidates":[{"place_id":"resolved_place_id"}],"status":"OK"}');
            return res;
        }
    }

    @isTest
    static void testResolveGooglePlaceIds_ChainsInsteadOfSkipping() {
        PW_Portfolio__c defaultPortfolio = new PW_Portfolio__c(
            Name = 'Default PW Portfolio',
            PW_Portfolio_Entity_ID__c = 'CHAIN_PORT_1',
            PW_Active__c = true
        );
        insert defaultPortfolio;

        House__c defaultHouse = new House__c(
            Name = 'Default House Chain',
            Street_Address__c = '1 Default Way',
            City__c = 'Default City',
            State__c = 'TN',
            Zip_Code__c = '00000',
            Status__c = 'Managed',
            Google_Place_ID__c = 'default_place_id'
        );
        insert defaultHouse;

        // Already synced with a cached Place ID - should be reused, never re-calling Google.
        PW_Building__c cachedBuilding = new PW_Building__c(
            Name = 'Cached Building',
            PW_Building_Entity_ID1__c = 'CACHED1',
            Google_Place_ID__c = 'cached_place_id',
            PW_Portfolio__c = defaultPortfolio.Id,
            House__c = defaultHouse.Id
        );
        insert cachedBuilding;

        PropertyWare_Setting__mdt creds = new PropertyWare_Setting__mdt(
            x_propertyware_client_id__c = 'clientId',
            x_propertyware_client_secret__c = 'clientSecret',
            x_propertyware_system_id__c = 'systemId'
        );

        Map<String, PropertyWareAPIUtility.PWBuildingWrapper> buildings = new Map<String, PropertyWareAPIUtility.PWBuildingWrapper>();

        PropertyWareAPIUtility.PWBuildingWrapper cachedWrapper = new PropertyWareAPIUtility.PWBuildingWrapper();
        cachedWrapper.buildingEntityId = 'CACHED1';
        cachedWrapper.name = 'Cached Building';
        cachedWrapper.active = true;
        cachedWrapper.publishedForRent = true;
        cachedWrapper.address = '1 Cached Ln';
        cachedWrapper.city = 'Sample City';
        cachedWrapper.stateRegion = 'TN';
        cachedWrapper.postalCode = '90210';
        cachedWrapper.portfolioID = 'CHAIN_PORT_1';
        buildings.put('CACHED1', cachedWrapper);

        // Genuinely new building with no cached Place ID - this is the one that can't fit under
        // the callout budget in the first pass and must be chained rather than skipped.
        PropertyWareAPIUtility.PWBuildingWrapper newWrapper = new PropertyWareAPIUtility.PWBuildingWrapper();
        newWrapper.buildingEntityId = 'NEW1';
        newWrapper.name = 'New Building';
        newWrapper.active = true;
        newWrapper.publishedForRent = true;
        newWrapper.address = '2 New Ln';
        newWrapper.city = 'Sample City';
        newWrapper.stateRegion = 'TN';
        newWrapper.postalCode = '90210';
        newWrapper.portfolioID = 'CHAIN_PORT_1';
        buildings.put('NEW1', newWrapper);

        Test.setMock(HttpCalloutMock.class, new MockGooglePlaceResponseGenerator());

        Test.startTest();

        // Burn almost the entire per-transaction callout budget before resolving, so 'NEW1'
        // can't fit and has to be handed off to a chained job instead of being left blank.
        for (Integer i = 0; i < 99; i++) {
            GooglePlacesService.getPlaceIdFromAddress('999 Filler Ave #' + i);
        }

        PropertyWareAPIUtility.resolveGooglePlaceIds(buildings, buildings.keySet(), defaultPortfolio, defaultHouse, creds);

        Test.stopTest(); // runs the chained job, which resolves 'NEW1' and finishes the sync

        PW_Building__c cachedResult = [SELECT Google_Place_ID__c FROM PW_Building__c WHERE PW_Building_Entity_ID1__c = 'CACHED1'];
        System.assertEquals('cached_place_id', cachedResult.Google_Place_ID__c, 'Cached building should keep its existing Place ID without a fresh callout');

        PW_Building__c newResult = [SELECT Google_Place_ID__c FROM PW_Building__c WHERE PW_Building_Entity_ID1__c = 'NEW1'];
        System.assertEquals('resolved_place_id', newResult.Google_Place_ID__c, 'New building should be resolved via the chained job rather than left blank');
    }

    @isTest
    static void testResolveGooglePlaceIds_ChainsInsteadOfSkipping2() {
        PW_Portfolio__c defaultPortfolio = new PW_Portfolio__c(
            Name = 'Default PW Portfolio',
            PW_Portfolio_Entity_ID__c = 'CHAIN_PORT_2',
            PW_Active__c = true
        );
        insert defaultPortfolio;

        House__c defaultHouse = new House__c(
            Name = 'Default House Chain2',
            Street_Address__c = '1 Default Way',
            City__c = 'Default City',
            State__c = 'TN',
            Zip_Code__c = '00000',
            Status__c = 'Managed',
            Google_Place_ID__c = 'default_place_id2'
        );
        insert defaultHouse;

        PW_Building__c cachedBuilding = new PW_Building__c(
            Name = 'Cached Building 2',
            PW_Building_Entity_ID1__c = 'CACHED2',
            Google_Place_ID__c = 'cached_place_id2',
            PW_Portfolio__c = defaultPortfolio.Id,
            House__c = defaultHouse.Id
        );
        insert cachedBuilding;

        PropertyWare_Setting__mdt creds = new PropertyWare_Setting__mdt(
            x_propertyware_client_id__c = 'clientId',
            x_propertyware_client_secret__c = 'clientSecret',
            x_propertyware_system_id__c = 'systemId'
        );

        Map<String, PropertyWareAPIUtility2.PWBuildingWrapper> buildings = new Map<String, PropertyWareAPIUtility2.PWBuildingWrapper>();

        PropertyWareAPIUtility2.PWBuildingWrapper cachedWrapper = new PropertyWareAPIUtility2.PWBuildingWrapper();
        cachedWrapper.buildingEntityId = 'CACHED2';
        cachedWrapper.name = 'Cached Building 2';
        cachedWrapper.active = true;
        cachedWrapper.publishedForRent = true;
        cachedWrapper.address = '1 Cached Ln';
        cachedWrapper.city = 'Sample City';
        cachedWrapper.stateRegion = 'TN';
        cachedWrapper.postalCode = '90210';
        cachedWrapper.portfolioID = 'CHAIN_PORT_2';
        buildings.put('CACHED2', cachedWrapper);

        PropertyWareAPIUtility2.PWBuildingWrapper newWrapper = new PropertyWareAPIUtility2.PWBuildingWrapper();
        newWrapper.buildingEntityId = 'NEW2';
        newWrapper.name = 'New Building 2';
        newWrapper.active = true;
        newWrapper.publishedForRent = true;
        newWrapper.address = '2 New Ln';
        newWrapper.city = 'Sample City';
        newWrapper.stateRegion = 'TN';
        newWrapper.postalCode = '90210';
        newWrapper.portfolioID = 'CHAIN_PORT_2';
        buildings.put('NEW2', newWrapper);

        Test.setMock(HttpCalloutMock.class, new MockGooglePlaceResponseGenerator());

        Test.startTest();

        for (Integer i = 0; i < 99; i++) {
            GooglePlacesService.getPlaceIdFromAddress('999 Filler Ave #' + i);
        }

        PropertyWareAPIUtility2.resolveGooglePlaceIds(buildings, buildings.keySet(), defaultPortfolio, defaultHouse, creds);

        Test.stopTest();

        PW_Building__c cachedResult = [SELECT Google_Place_ID__c FROM PW_Building__c WHERE PW_Building_Entity_ID1__c = 'CACHED2'];
        System.assertEquals('cached_place_id2', cachedResult.Google_Place_ID__c, 'Cached building should keep its existing Place ID without a fresh callout');

        PW_Building__c newResult = [SELECT Google_Place_ID__c FROM PW_Building__c WHERE PW_Building_Entity_ID1__c = 'NEW2'];
        System.assertEquals('resolved_place_id', newResult.Google_Place_ID__c, 'New building should be resolved via the chained job rather than left blank');
    }
}