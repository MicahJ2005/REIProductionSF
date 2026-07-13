@isTest
public class TaskTriggerHandlerTest {
    
    @testSetup
    public static void TestData(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System administrator']; 
		User u = new User( FirstName='Hubspot',LastName='Admin', Alias = 'standt', Email='test2@testorg.com', 
                          EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='HubspotAdmin' + DateTime.now().getTime() + '@testorg.com');
        insert u;
        
        insert new One_to_One_Lead_Ref__c(Not_One_to_One__c = 0, One_to_One__c = 0); 
    }
    
    @isTest
    public static void Test_1(){
        
        Test.startTest();
        
        List<User> u = [SELECT Id FROM User WHERE FirstName = 'Hubspot' LIMIT 1];
        
        System.runAs(u[0]){
            Lead ld2 = new Lead();
            ld2.recordTypeId = Schema.sObjectType.Lead.getRecordTypeInfosByName().get('Investor Prospect').getRecordTypeId();
            ld2.FirstName = 'First';
            ld2.LastName = 'Last';
            ld2.Email = 'test@email.com';
            ld2.Phone = '999888777';
            ld2.MobilePhone = '987987987';
            ld2.Status = 'Qualified';
            ld2.Street = 'Test Street';
            ld2.City = 'Test City';
            ld2.State = 'MS';
            ld2.postalCode = '12345';
            ld2.Country = 'Test Country';
            ld2.Company = 'Test Company';
            ld2.Market__c = 'MEM';
            ld2.Status = 'Open';
            ld2.Timeline_of_Investment_life__c = '7-10 yrs';
            ld2.Timeframe_to_transact_on_a_property__c = '30-90 days';
            ld2.Who_are_you_investing_with_if_anyone__c = 'Self';
            ld2.The_Why__c = 'Quit full-time job';
            ld2.Experience_as_an_investor__c = 'No current Passive or Active Properties';
            ld2.How_much_are_you_looking_to_invest__c = 1233;
            ld2.Purchase_Method__c = 'Cash';
            ld2.Time_Zone__c = 'Central';
            ld2.lead_details__c = 'Test Company';
            ld2.Listing_Date__c = date.today();
            ld2.LeadSource = 'Wholesaler';
            ld2.Original_Source_Data_3__c = 'Front Desk Email Lead';
            ld2.Original_Source_Data_4__c = 'Fortune Builders Client';
            Insert ld2;
        	System.debug('User'+u[0]);
            Task t = new Task();
            t.OwnerId = u[0].id;
            t.Subject='Submitted Form \'One To One Session Registrations\'';
            t.Status='Completed';
            t.Priority='Normal';
            t.Description = 'Hello this is for testing purpose \n a new line \n address: test@email.com \n address: test2@email.com\n address: test3@email.com';
            t.whoid = ld2.id;
            insert t;
        }
        Test.stopTest();
    }
    @isTest
    public static void Test_2(){
        
        Test.startTest();
        
        List<User> u = [SELECT Id FROM User WHERE FirstName = 'Hubspot' LIMIT 1];
        
        System.runAs(u[0]){
            Lead ld2 = new Lead();
            ld2.recordTypeId = Schema.sObjectType.Lead.getRecordTypeInfosByName().get('Investor Prospect').getRecordTypeId();
            ld2.FirstName = 'First';
            ld2.LastName = 'Last';
            ld2.Email = 'test@email.com';
            ld2.Phone = '999888777';
            ld2.MobilePhone = '987987987';
            ld2.Status = 'Qualified';
            ld2.Street = 'Test Street';
            ld2.City = 'Test City';
            ld2.State = 'MS';
            ld2.postalCode = '12345';
            ld2.Country = 'Test Country';
            ld2.Company = 'Test Company';
            ld2.Market__c = 'MEM';
            ld2.Status = 'Open';
            ld2.Timeline_of_Investment_life__c = '7-10 yrs';
            ld2.Timeframe_to_transact_on_a_property__c = '30-90 days';
            ld2.Who_are_you_investing_with_if_anyone__c = 'Self';
            ld2.The_Why__c = 'Quit full-time job';
            ld2.Experience_as_an_investor__c = 'No current Passive or Active Properties';
            ld2.How_much_are_you_looking_to_invest__c = 1233;
            ld2.Purchase_Method__c = 'Cash';
            ld2.Time_Zone__c = 'Central';
            ld2.lead_details__c = 'Test Company';
            ld2.Listing_Date__c = date.today();
            ld2.LeadSource = 'Wholesaler';
            ld2.Original_Source_Data_3__c = 'Front Desk Email Lead';
            ld2.Original_Source_Data_4__c = 'Fortune Builders Client';
            Insert ld2;
        	System.debug('User'+u[0]);
            Task t = new Task();
            t.OwnerId = u[0].id;
            t.Subject='Submitted Form \'One To One Session Registrations\'';
            t.Status='Completed';
            t.Priority='Normal';
            t.Description = 'First name: Kelcie \n Last name: Raskowsky \n Phone Number: 8087489934 \n Email Address: sumesh@cmentor.com \n Best day for session? (We will follow up to confirm): Monday \n Schedule 1 to 1: Yes \n City: Kailua \n State: Hi \n Zip: 96734';
            t.whoid = ld2.id;
            insert t;
        }
        Test.stopTest();
    }
    
    @isTest
    public static void testZoomCallRouting() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Investor Owner').getRecordTypeId();
        Account a = new Account(Name = 'Zoom Test Account', Phone = '5551234567', RecordTypeId = accRecordTypeId);
        insert a;
        
        Contact c = new Contact(FirstName = 'Zoom', LastName = 'Test', AccountId = a.Id, MobilePhone = '5551234567');
        insert c;
        
        Id leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Investor Prospect').getRecordTypeId();
        Lead l = new Lead(FirstName = 'Zoom', LastName = 'Lead', Company = 'Zoom Test', MobilePhone = '5559998888', RecordTypeId = leadRecordTypeId,
                          LeadSource = 'Wholesaler', Original_Source_Data_3__c = 'Front Desk Email Lead', Original_Source_Data_4__c = 'Fortune Builders Client');
        insert l;
        
        Test.startTest();
        
        Task t1 = new Task(Subject = 'Call from +15551234567', Status = 'Completed');
        insert t1;
        
        Task t2 = new Task(Subject = 'Call from 5559998888', Status = 'Completed');
        insert t2;
        
        Task t3 = new Task(Subject = '(5/12/2026) Messages between Ryan and 5551234567', Status = 'Completed');
        insert t3;
        
        Test.stopTest();
        
        t1 = [SELECT WhoId, WhatId FROM Task WHERE Id = :t1.Id];
        t2 = [SELECT WhoId, WhatId FROM Task WHERE Id = :t2.Id];
        t3 = [SELECT WhoId, WhatId FROM Task WHERE Id = :t3.Id];
        
        System.assertEquals(c.Id, t1.WhoId, 'Task 1 should link to Contact');
        System.assertEquals(a.Id, t1.WhatId, 'Task 1 should link to Account');
        System.assertEquals(l.Id, t2.WhoId, 'Task 2 should link to Lead');
        System.assertEquals(c.Id, t3.WhoId, 'Task 3 (SMS) should link to Contact');
    }
    
    @isTest
    public static void testZoomCallRouting_MultiContact() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Investor Owner').getRecordTypeId();
        Account a = new Account(Name = 'Zoom Test Account Multi', Phone = '5552223333', RecordTypeId = accRecordTypeId);
        insert a;
        
        Contact c1 = new Contact(FirstName = 'Zoom', LastName = 'Test1', AccountId = a.Id, MobilePhone = '5552223333');
        Contact c2 = new Contact(FirstName = 'Zoom', LastName = 'Test2', AccountId = a.Id, MobilePhone = '5552223333');
        insert new List<Contact>{c1, c2};
        
        Test.startTest();
        Task t1 = new Task(Subject = 'Call from +15552223333', Status = 'Completed');
        insert t1;
        Test.stopTest();
        
        t1 = [SELECT WhoId, WhatId FROM Task WHERE Id = :t1.Id];
        System.assertEquals(a.Id, t1.WhatId, 'Task should link to Account even if multiple contacts match');
    }
}