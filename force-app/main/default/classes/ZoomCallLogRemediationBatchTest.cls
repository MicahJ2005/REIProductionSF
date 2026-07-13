@isTest
public class ZoomCallLogRemediationBatchTest {
    @testSetup
    static void setup() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Investor Owner').getRecordTypeId();
        
        Account a = new Account(Name = 'Batch Test', Phone = '+15551234567', RecordTypeId = accRecordTypeId);
        insert a;
        
        Contact c = new Contact(FirstName = 'Test', LastName = 'Contact', MobilePhone = '+14441234567');
        insert c;
        
        Lead l = new Lead(FirstName = 'Test', LastName = 'Lead', Company = 'Company', MobilePhone = '+13331234567');
        insert l;
        
        List<Task> tasks = new List<Task>();
        // Match Account
        tasks.add(new Task(
            Subject = 'Messages between Ryan Harrell and 5551234567',
            Status = 'Completed',
            Priority = 'Normal'
        ));
        // Match Contact
        tasks.add(new Task(
            Subject = 'Call from 4441234567',
            Status = 'Completed',
            Priority = 'Normal'
        ));
        // Match Lead
        tasks.add(new Task(
            Subject = 'SMS to 3331234567',
            Status = 'Completed',
            Priority = 'Normal'
        ));
        
        // Multi-Contact match Account
        Account a2 = new Account(Name = 'Multi Test', Phone = '5552223333', RecordTypeId = accRecordTypeId);
        insert a2;
        Contact c1 = new Contact(FirstName = 'Test1', LastName = 'Contact', AccountId = a2.Id, MobilePhone = '5552223333');
        Contact c2 = new Contact(FirstName = 'Test2', LastName = 'Contact', AccountId = a2.Id, MobilePhone = '5552223333');
        insert new List<Contact>{c1, c2};
        tasks.add(new Task(
            Subject = 'Call from 5552223333',
            Status = 'Completed',
            Priority = 'Normal'
        ));
        
        insert tasks;
    }

    @isTest
    static void testBatchExecution() {
        List<Task> tasks = [SELECT Id, Subject, WhoId, WhatId, TaskSubtype FROM Task];
        
        Test.startTest();
        ZoomCallLogRemediationBatch batch = new ZoomCallLogRemediationBatch();
        batch.execute(null, tasks);
        Test.stopTest();
        
        List<Task> updatedTasks = [SELECT Subject, WhatId, WhoId FROM Task];
        
        Boolean foundAcc = false;
        Boolean foundCon = false;
        Boolean foundLead = false;
        Boolean foundMultiAcc = false;
        
        for (Task t : updatedTasks) {
            if (t.Subject.contains('5551234567')) {
                System.assertNotEquals(null, t.WhatId, 'Task should be matched to Account');
                foundAcc = true;
            }
            if (t.Subject.contains('4441234567')) {
                System.assertNotEquals(null, t.WhoId, 'Task should be matched to Contact');
                foundCon = true;
            }
            if (t.Subject.contains('3331234567')) {
                System.assertNotEquals(null, t.WhoId, 'Task should be matched to Lead');
                foundLead = true;
            }
            if (t.Subject.contains('5552223333')) {
                System.assertNotEquals(null, t.WhatId, 'Task should be matched to Multi Account');
                foundMultiAcc = true;
            }
        }
        
        System.assert(foundAcc, 'Account task was found');
        System.assert(foundCon, 'Contact task was found');
        System.assert(foundLead, 'Lead task was found');
        System.assert(foundMultiAcc, 'Multi Account task was found');
    }
}