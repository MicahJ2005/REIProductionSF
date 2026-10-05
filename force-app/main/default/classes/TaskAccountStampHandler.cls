/**
    Name        : TaskAccountStampHandler
    Description : Stamps the department "last activity" dates on Account from Task activity.

                  Replaces the record-triggered flows Sales_Task_Result_Stamp_Account_Dates
                  and CS_Task_Result_Stamp_Account_Dates. Those flows issued one Account
                  update per Task interview, so any batch touching more than 12 Tasks that
                  share an Account blew the platform's duplicate-update limit and rolled the
                  whole transaction back. That is what blocked Lead conversion for leads
                  carrying more than a dozen activities.

                  This aggregates by Account and issues exactly one update per Account.
                  Dates only ever move forward, which matches the flows' behaviour.

                  Only fields the running user can actually read and update are queried. The
                  stamp fields do not share a single FLS story -- for example
                  Customer_Service_Last_Connected__c is visible to far fewer profiles than its
                  siblings -- and naming an invisible field in SOQL throws "No such column",
                  which would fail the user's entire Task save. Skipping a field the user
                  cannot see is always better than blocking their save.

                  Runs without sharing so a rep logging activity against an Account they
                  cannot edit still stamps it -- record-triggered flows ran in system mode,
                  and this preserves that.
**/
public without sharing class TaskAccountStampHandler {

    private static final String SALES_SPOKE = 'Connected - Spoke with';
    private static final String CS_SPOKE    = 'Spoke With Client';
    private static final Set<String> CS_CONNECTED = new Set<String>{
        'Spoke With Client',
        'Client Reply Via Email',
        'Client Reply Via Voicemail',
        'Connected via Text'
    };

    private static final String F_SALES_ACTIVITY = 'Sales_Last_Activity__c';
    private static final String F_SALES_SPOKE    = 'Sales_Last_Spoke_With_Calls__c';
    private static final String F_CS_ACTIVITY    = 'Customer_Service_Last_Activity__c';
    private static final String F_CS_SPOKE       = 'Customer_Service_Last_Spoke_With_Calls__c';
    private static final String F_CS_CONNECTED   = 'Customer_Service_Last_Connected__c';

    private static final Id RT_SALES = recordTypeId('Sales');
    private static final Id RT_CS    = recordTypeId('Customer_Service');

    private static final Map<String, Schema.SObjectField> ACCOUNT_FIELDS =
        Account.SObjectType.getDescribe().fields.getMap();

    // Guards against re-entry if the Account update cascades back into Task DML.
    private static Boolean isRunning = false;

    public static void stampAccounts(List<Task> tasks) {
        if (isRunning) {
            return;
        }

        // Target field -> latest qualifying date per Account, across the whole batch.
        Map<String, Map<Id, Date>> candidates = new Map<String, Map<Id, Date>>{
            F_SALES_ACTIVITY => new Map<Id, Date>(),
            F_SALES_SPOKE    => new Map<Id, Date>(),
            F_CS_ACTIVITY    => new Map<Id, Date>(),
            F_CS_SPOKE       => new Map<Id, Date>(),
            F_CS_CONNECTED   => new Map<Id, Date>()
        };

        for (Task t : tasks) {
            Id acctId = accountIdFor(t);
            if (acctId == null) {
                continue;
            }

            Date taskDate = taskDateFor(t);

            if (t.RecordTypeId == RT_SALES) {
                keepLatest(candidates.get(F_SALES_ACTIVITY), acctId, taskDate);
                if (t.Call_Result_New__c == SALES_SPOKE) {
                    keepLatest(candidates.get(F_SALES_SPOKE), acctId, taskDate);
                }
            } else if (t.RecordTypeId == RT_CS) {
                keepLatest(candidates.get(F_CS_ACTIVITY), acctId, taskDate);
                if (t.CS_Results__c == CS_SPOKE) {
                    keepLatest(candidates.get(F_CS_SPOKE), acctId, taskDate);
                }
                if (CS_CONNECTED.contains(t.CS_Results__c)) {
                    keepLatest(candidates.get(F_CS_CONNECTED), acctId, taskDate);
                }
            }
        }

        // Only fields that have something to say AND that this user can read and write.
        List<String> usable = new List<String>();
        Set<Id> acctIds = new Set<Id>();
        for (String field : candidates.keySet()) {
            Map<Id, Date> byAccount = candidates.get(field);
            if (byAccount.isEmpty() || !isReadWritable(field)) {
                continue;
            }
            usable.add(field);
            acctIds.addAll(byAccount.keySet());
        }
        if (usable.isEmpty()) {
            return;
        }

        String soql = 'SELECT Id, ' + String.join(usable, ', ')
                    + ' FROM Account WHERE Id IN :acctIds';

        isRunning = true;
        try {
            List<Account> toUpdate = new List<Account>();

            for (Account a : (List<Account>) Database.query(soql)) {
                Boolean changed = false;

                for (String field : usable) {
                    Date candidate = candidates.get(field).get(a.Id);
                    Date current   = (Date) a.get(field);
                    if (candidate != null && (current == null || candidate > current)) {
                        a.put(field, candidate);
                        changed = true;
                    }
                }

                if (changed) {
                    toUpdate.add(a);
                }
            }

            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        } catch (Exception e) {
            // These stamps are derived, best-effort data. Losing one is a reporting
            // annoyance; blocking the save loses the rep's actual activity. This class
            // already took Task saves down once by letting an FLS error escape, so it
            // never gets to do that again.
            System.debug(
                LoggingLevel.ERROR,
                'TaskAccountStampHandler could not stamp accounts: ' + e.getMessage()
            );
        } finally {
            isRunning = false;
        }
    }

    private static Boolean isReadWritable(String fieldName) {
        Schema.SObjectField field = ACCOUNT_FIELDS.get(fieldName);
        if (field == null) {
            return false;
        }
        Schema.DescribeFieldResult d = field.getDescribe();
        return d.isAccessible() && d.isUpdateable();
    }

    /**
        AccountId is derived by the platform and is the value the flows read. WhatId is a
        fallback for the window during Lead conversion where the Task points at the Account
        directly before AccountId settles.
    **/
    private static Id accountIdFor(Task t) {
        if (t.AccountId != null) {
            return t.AccountId;
        }
        if (t.WhatId != null && t.WhatId.getSObjectType() == Account.SObjectType) {
            return t.WhatId;
        }
        return null;
    }

    private static Date taskDateFor(Task t) {
        if (t.ActivityDate != null) {
            return t.ActivityDate;
        }
        return t.CreatedDate != null ? t.CreatedDate.date() : Date.today();
    }

    private static void keepLatest(Map<Id, Date> byAccount, Id acctId, Date candidate) {
        Date current = byAccount.get(acctId);
        if (current == null || candidate > current) {
            byAccount.put(acctId, candidate);
        }
    }

    private static Id recordTypeId(String developerName) {
        Schema.RecordTypeInfo info = Task.SObjectType.getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get(developerName);
        return info == null ? null : info.getRecordTypeId();
    }
}