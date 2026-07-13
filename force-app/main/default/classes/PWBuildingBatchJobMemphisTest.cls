@isTest
private class PWBuildingBatchJobMemphisTest {
    
    // Mock response class
    private class PWBuildingHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            // Fake response with one building
            String mockJson = '[{' +
                '"id": "B001",' +
                '"idNumber": "1001",' +
                '"portfolioID": "PF123",' +
                '"name": "Test Building",' +
                '"status": "Active",' +
                '"active": true,' +
                '"yearBuilt": "2000",' +
                '"numberOfBedrooms": 3,' +
                '"numberOfBathrooms": 2.0,' +
                '"totalArea": 1200.5,' +
                '"createdDateTime": "2024-01-01T12:00:00Z",' +
                '"lastModifiedDateTime": "2024-01-10T12:00:00Z",' +
                '"type": "Residential",' +
                '"address": {' +
                    '"address": "123 Main St",' +
                    '"city": "Memphis",' +
                    '"country": "USA",' +
                    '"stateRegion": "TN",' +
                    '"postalCode": "38104"' +
                '},' +
                '"marketing": {"publishedForRent": true},' +
                '"customFields": [' +
                    '{"fieldName":"Building Market","value":"Memphis"},' +
                    '{"fieldName":"Group HOI DO NOT EDIT","value":"HOI123"},' +
                    '{"fieldName":"Is Owner Selling?","value":"No"},' +
                    '{"fieldName":"Is Owner Selling? notes","value":"Not Selling"},' +
                    '{"fieldName":"Is Owner Selling? Closing Date","value":"2025-12-01"}' +
                ']' +
            '}]';
            
            res.setBody(mockJson);
            return res;
        }
    }
    
    @isTest
    static void testQueueableExecution() {
         House__c house = new House__c(Name = 'Test House');
        insert house;

        PW_Portfolio__c portfolio = new PW_Portfolio__c(Name = 'Test Portfolio');
        insert portfolio;

        // Insert building with required lookups
        PW_Building__c building = new PW_Building__c(
            Name = 'Test Building',
            PW_Building_Entity_ID1__c = 'B001',
            PW_Building_ID__c = '001',
            House__c = house.Id,
            PW_Portfolio__c = portfolio.Id
        );
        insert building;
        
        // Register mock
        Test.setMock(HttpCalloutMock.class, new PWBuildingHttpMock());
        
        Test.startTest();
         // Schedule job (runs immediately in test context)
            String jobId = System.schedule(
                'TestSchedulableJob',
                '0 0 0 1 1 ? 2050', // arbitrary cron - fires once in test
                new PWBuildingSchedulableMemphis()
            );
        // System.enqueueJob(new PWBuildingBatchJobMemphis(0));
        Test.stopTest();
        
        // Verify updates
        PW_Building__c updated = [SELECT Id, Name, PW_City__c, PW_Building_Market__c, 
                                         PW_Year_Built1__c, Published_For_Rent__c, Group_HOI__c,
                                         Is_Owner_Selling__c, Is_Owner_Selling_Notes__c, 
                                         Is_Owner_Selling_Closing_Date__c
                                  FROM PW_Building__c
                                  WHERE Id = :building.Id];
    }
}