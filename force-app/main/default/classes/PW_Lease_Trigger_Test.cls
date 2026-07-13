@IsTest
private class PW_Lease_Trigger_Test {
    
    @IsTest
    static void testPWLeaseTriggerActive() {
        // Setup: Insert test Custom Metadata using Metadata API simulation
        // NOTE: You can't insert CMDT directly in Apex tests, so we "mock" the value
        Test.startTest();
        // PropertyWare_Setting__mdt mockSetting = new PropertyWare_Setting__mdt(
        //     DeveloperName = 'PWLeaseTrigger',
        //     MasterLabel = 'PWLeaseTrigger',
        //     PW_Lease_Trigger_Active__c = true
        // );
        // // Use Test.setFixedSearchResults to simulate CMDT getInstance
        // Test.setFixedSearchResults(new List<SObject>{mockSetting});
        
        // Create test PW_Lease__c record to fire the trigger
        PW_Lease__c lease = new PW_Lease__c(
            Name = 'Test Lease',
            PW_Lease_Entity_ID__c = '987654321',
            PW_Date_Renewed__c = '9/1/2025'
            // Add other required fields if necessary
        );
        insert lease;
        
        // Update the same lease to fire after update
        lease.PW_Date_Renewed__c = '9/3/2025';
        lease.Name = 'Updated Test Lease';
        update lease;
        Test.stopTest();
    }
    
    
    @IsTest
    static void testPWLeaseTriggerInactive() {
        Test.startTest();
        // Mock inactive CMDT record
        // PropertyWare_Setting__mdt mockSetting = new PropertyWare_Setting__mdt(
        //     DeveloperName = 'PWLeaseTrigger',
        //     MasterLabel = 'PWLeaseTrigger',
        //     PW_Lease_Trigger_Active__c = false
        // );
        // Test.setFixedSearchResults(new List<SObject>{mockSetting});
        
        // Insert lease; trigger should NOT run handler
        PW_Lease__c lease = new PW_Lease__c(
            Name = 'Inactive Lease',
            PW_Lease_Entity_ID__c = '123456789',
            PW_Date_Renewed__c = '9/1/2025'
        );
        insert lease;
        Test.stopTest();
    }
}