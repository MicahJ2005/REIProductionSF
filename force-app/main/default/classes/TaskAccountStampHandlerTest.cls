/**
    Name        : TaskAccountStampHandlerTest
    Description : Covers TaskAccountStampHandler, including the regression that motivated it:
                  more than 12 Tasks sharing one Account in a single batch used to blow the
                  platform's duplicate-update limit and roll the transaction back.

                  Note: something in the Task save path in this org forces ActivityDate to
                  today on insert, so these tests separate cases by Account rather than by
                  back-dated activity, and drive the forward-only check off the Account.

                  Every test invokes stampAccounts() directly. As of 2026-08-10 this class is
                  no longer called from TaskTrigger -- it must never run inside a Task save
                  again -- so testing it through Task DML would assert behaviour that is
                  deliberately gone.
**/
@IsTest
private class TaskAccountStampHandlerTest {

    private static final Id RT_SALES = Task.SObjectType.getDescribe()
        .getRecordTypeInfosByDeveloperName().get('Sales').getRecordTypeId();
    private static final Id RT_CS = Task.SObjectType.getDescribe()
        .getRecordTypeInfosByDeveloperName().get('Customer_Service').getRecordTypeId();

    /**
        The org's default Account record type is a vendor one, which carries picklist
        defaults that trip VendorTypeAndCategoriesVerification. Investor Prospect is both
        clean for testing and what a converted lead actually becomes.
    **/
    private static final Id RT_ACCOUNT = Account.SObjectType.getDescribe()
        .getRecordTypeInfosByDeveloperName().get('Investor_Prospect').getRecordTypeId();

    private static Account makeAccount(String name) {
        Account a = new Account(Name = name, RecordTypeId = RT_ACCOUNT);
        insert a;
        return a;
    }

    private static Task salesTask(Id acctId, String callResult) {
        return new Task(
            RecordTypeId       = RT_SALES,
            WhatId             = acctId,
            Subject            = 'Sales activity',
            Status             = 'Completed',
            ActivityDate       = Date.today(),
            Call_Result_New__c = callResult
        );
    }

    private static Task csTask(Id acctId, String csResult) {
        return new Task(
            RecordTypeId  = RT_CS,
            WhatId        = acctId,
            Subject       = 'CS activity',
            Status        = 'Completed',
            ActivityDate  = Date.today(),
            CS_Results__c = csResult
        );
    }

    /**
        The regression. Forty Tasks on one Account in one DML used to produce forty separate
        Account updates and fail on the twelfth. It must now produce exactly one.
    **/
    @IsTest
    static void stampsOnceForFortyTasksSharingAnAccount() {
        Account a = makeAccount('Stamp Bulk Test');

        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < 40; i++) {
            tasks.add(salesTask(a.Id, null));
        }

        Test.startTest();
        insert tasks;
        TaskAccountStampHandler.stampAccounts(tasks);
        Test.stopTest();

        Account result = [SELECT Sales_Last_Activity__c FROM Account WHERE Id = :a.Id];
        System.assertEquals(
            Date.today(),
            result.Sales_Last_Activity__c,
            'Forty tasks on one account should stamp it once, not fail on the twelfth'
        );
    }

    @IsTest
    static void stampsSalesSpokeOnlyForSpokeResult() {
        Account spoke = makeAccount('Stamp Sales Spoke');
        Account vm    = makeAccount('Stamp Sales Voicemail');

        List<Task> tasks = new List<Task>{
            salesTask(spoke.Id, 'Connected - Spoke with'),
            salesTask(vm.Id, 'Attempted - Left voicemail')
        };

        Test.startTest();
        insert tasks;
        TaskAccountStampHandler.stampAccounts(tasks);
        Test.stopTest();

        Map<Id, Account> byId = new Map<Id, Account>([
            SELECT Id, Sales_Last_Activity__c, Sales_Last_Spoke_With_Calls__c
            FROM Account WHERE Id IN (:spoke.Id, :vm.Id)
        ]);

        System.assertEquals(
            Date.today(),
            byId.get(spoke.Id).Sales_Last_Activity__c,
            'A spoke-with task should move the activity date'
        );
        System.assertEquals(
            Date.today(),
            byId.get(spoke.Id).Sales_Last_Spoke_With_Calls__c,
            'A spoke-with task should move the spoke date'
        );
        System.assertEquals(
            Date.today(),
            byId.get(vm.Id).Sales_Last_Activity__c,
            'A voicemail task should still move the activity date'
        );
        System.assertEquals(
            null,
            byId.get(vm.Id).Sales_Last_Spoke_With_Calls__c,
            'A voicemail task must not move the spoke date'
        );
    }

    @IsTest
    static void stampsCustomerServiceFieldsByResult() {
        Account spoke  = makeAccount('Stamp CS Spoke');
        Account texted = makeAccount('Stamp CS Texted');
        Account vm     = makeAccount('Stamp CS Voicemail');

        List<Task> tasks = new List<Task>{
            csTask(spoke.Id, 'Spoke With Client'),
            csTask(texted.Id, 'Connected via Text'),
            csTask(vm.Id, 'Left Voicemail')
        };

        Test.startTest();
        insert tasks;
        TaskAccountStampHandler.stampAccounts(tasks);
        Test.stopTest();

        Map<Id, Account> byId = new Map<Id, Account>([
            SELECT Id,
                   Customer_Service_Last_Activity__c,
                   Customer_Service_Last_Spoke_With_Calls__c,
                   Customer_Service_Last_Connected__c
            FROM Account WHERE Id IN (:spoke.Id, :texted.Id, :vm.Id)
        ]);

        Account s = byId.get(spoke.Id);
        System.assertEquals(Date.today(), s.Customer_Service_Last_Activity__c,
            'Spoke With Client should move the CS activity date');
        System.assertEquals(Date.today(), s.Customer_Service_Last_Spoke_With_Calls__c,
            'Spoke With Client should move the CS spoke date');
        System.assertEquals(Date.today(), s.Customer_Service_Last_Connected__c,
            'Spoke With Client also counts as connected');

        Account t = byId.get(texted.Id);
        System.assertEquals(Date.today(), t.Customer_Service_Last_Activity__c,
            'Connected via Text should move the CS activity date');
        System.assertEquals(null, t.Customer_Service_Last_Spoke_With_Calls__c,
            'Connected via Text is not a spoke-with');
        System.assertEquals(Date.today(), t.Customer_Service_Last_Connected__c,
            'Connected via Text should move the connected date');

        Account v = byId.get(vm.Id);
        System.assertEquals(Date.today(), v.Customer_Service_Last_Activity__c,
            'Left Voicemail should still move the CS activity date');
        System.assertEquals(null, v.Customer_Service_Last_Spoke_With_Calls__c,
            'Left Voicemail is not a spoke-with');
        System.assertEquals(null, v.Customer_Service_Last_Connected__c,
            'Left Voicemail is not a connect');
    }

    /**
        Driven through the handler directly rather than through Task DML. Other automation
        in this org also writes these fields on Task save, so going through the trigger
        would be testing that automation rather than this class. Passing an in-memory Task
        with only WhatId set also covers the AccountId fallback.
    **/
    @IsTest
    static void neverMovesDatesBackward() {
        Account a = makeAccount('Stamp Forward Only');
        Date future = Date.today().addDays(30);
        a.Sales_Last_Activity__c = future;
        a.Sales_Last_Spoke_With_Calls__c = future;
        update a;

        Task t = new Task(
            RecordTypeId       = RT_SALES,
            WhatId             = a.Id,
            Subject            = 'Sales activity',
            Status             = 'Completed',
            ActivityDate       = Date.today(),
            Call_Result_New__c = 'Connected - Spoke with'
        );

        Test.startTest();
        TaskAccountStampHandler.stampAccounts(new List<Task>{ t });
        Test.stopTest();

        Account result = [
            SELECT Sales_Last_Activity__c, Sales_Last_Spoke_With_Calls__c
            FROM Account WHERE Id = :a.Id
        ];
        System.assertEquals(future, result.Sales_Last_Activity__c,
            'An earlier task must not drag the activity date backward');
        System.assertEquals(future, result.Sales_Last_Spoke_With_Calls__c,
            'An earlier task must not drag the spoke date backward');
    }

    /**
        Lead conversion reparents Tasks onto the new Account. That is an update, not an
        insert, and it is the path that used to fail.
    **/
    @IsTest
    static void stampsWhenTasksAreReparentedOntoAnAccount() {
        Account a = makeAccount('Stamp Reparent Test');

        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < 20; i++) {
            tasks.add(new Task(
                RecordTypeId = RT_SALES,
                Subject      = 'Unparented activity',
                Status       = 'Completed',
                ActivityDate = Date.today()
            ));
        }
        insert tasks;

        for (Task t : tasks) {
            t.WhatId = a.Id;
        }

        Test.startTest();
        update tasks;
        TaskAccountStampHandler.stampAccounts(tasks);
        Test.stopTest();

        Account result = [SELECT Sales_Last_Activity__c FROM Account WHERE Id = :a.Id];
        System.assertEquals(
            Date.today(),
            result.Sales_Last_Activity__c,
            'Reparenting a batch of tasks should stamp the receiving Account once'
        );
    }

    /**
        The bug this class shipped with. Customer_Service_Last_Connected__c is readable by
        only two profiles, so naming it in SOQL threw "No such column" for everyone else and
        took down their whole Task save -- including Lead conversion. Admin-only tests never
        saw it. Run as a Sales Rep, who cannot see that field.
    **/
    @IsTest
    static void stampsForAUserWhoCannotSeeEveryStampField() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Custom: Sales Rep' LIMIT 1];
        User rep = new User(
            ProfileId         = p.Id,
            LastName          = 'StampFls',
            Email             = 'stampfls@example.com',
            Username          = 'stampfls' + DateTime.now().getTime() + '@example.com.invalid',
            Alias             = 'sfls',
            TimeZoneSidKey    = 'America/Chicago',
            LocaleSidKey      = 'en_US',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert rep;

        Account a = new Account(
            Name         = 'Stamp FLS Test',
            RecordTypeId = RT_ACCOUNT,
            OwnerId      = rep.Id
        );
        insert a;

        Test.startTest();
        System.runAs(rep) {
            Task t = salesTask(a.Id, 'Connected - Spoke with');
            insert t;
            TaskAccountStampHandler.stampAccounts(new List<Task>{ t });
        }
        Test.stopTest();

        Account result = [SELECT Sales_Last_Activity__c FROM Account WHERE Id = :a.Id];
        System.assertEquals(
            Date.today(),
            result.Sales_Last_Activity__c,
            'A user without FLS on every stamp field must still save the task and stamp '
            + 'the fields they can see'
        );
    }

    @IsTest
    static void ignoresTasksWithNoAccount() {
        Task t = new Task(
            RecordTypeId = RT_SALES,
            Subject      = 'No account',
            Status       = 'Completed',
            ActivityDate = Date.today()
        );

        Test.startTest();
        insert t;
        TaskAccountStampHandler.stampAccounts(new List<Task>{ t });
        Test.stopTest();
        // Reaching here without an exception is the assertion.
        System.assert(true, 'Tasks without an Account must be skipped cleanly');
    }

    /**
        The trigger must stay out of this class. A Task save on its own must not stamp
        anything -- that is the whole point of taking it off TaskTrigger on 2026-08-10.
    **/
    @IsTest
    static void taskSaveAloneDoesNotStampTheAccount() {
        Account a = makeAccount('Stamp Not In Save Path');

        Test.startTest();
        insert csTask(a.Id, 'Spoke With Client');
        Test.stopTest();

        Account result = [
            SELECT Customer_Service_Last_Connected__c FROM Account WHERE Id = :a.Id
        ];
        System.assertEquals(
            null,
            result.Customer_Service_Last_Connected__c,
            'Saving a Task must not reach TaskAccountStampHandler -- derived data belongs '
            + 'outside the save path of the record it is derived from'
        );
    }
}