public class ZoomCallLogRemediationBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    public Integer successCount = 0;

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Subject, WhoId, WhatId, TaskSubtype 
            FROM Task 
            WHERE CreatedDate >= LAST_N_DAYS:90 
              AND WhoId = null 
              AND WhatId = null 
              AND (TaskSubtype = 'Call' OR Subject LIKE '%Call%' OR Subject LIKE '%Zoom%' OR Subject LIKE '%SMS%' OR Subject LIKE '%Message%')
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Task> scope) {
        List<Task> tasksToUpdate = new List<Task>();
        Set<String> phonePatterns = new Set<String>();

        for (Task t : scope) {
            if (t.Subject == null) continue;
            Matcher m = Pattern.compile('(?i)(from|to|and|,)\\s*\\+?1?(\\d{10})').matcher(t.Subject);
            if (m.find()) {
                String p = m.group(2);
                String searchStr = '%' + p.substring(0,3) + '%' + p.substring(3,6) + '%' + p.substring(6) + '%';
                phonePatterns.add(searchStr);
            }
        }

        if (phonePatterns.isEmpty()) return;

        List<Contact> allMatchedContacts = [SELECT Id, AccountId, Is_Primary__c, MobilePhone, Phone FROM Contact WHERE MobilePhone LIKE :phonePatterns OR Phone LIKE :phonePatterns];
        List<Lead> allMatchedLeads = [SELECT Id, MobilePhone, Phone FROM Lead WHERE MobilePhone LIKE :phonePatterns OR Phone LIKE :phonePatterns];
        List<Account> allMatchedAccounts = [SELECT Id, Phone FROM Account WHERE Phone LIKE :phonePatterns];

        for (Task t : scope) {
            if (t.Subject == null) continue;
            Matcher m = Pattern.compile('(?i)(from|to|and|,)\\s*\\+?1?(\\d{10})').matcher(t.Subject);
            if (!m.find()) continue;
            
            String p = m.group(2);
            
            List<Contact> foundC = new List<Contact>();
            for (Contact c : allMatchedContacts) {
                if ((c.MobilePhone != null && c.MobilePhone.replaceAll('\\D','') != null && c.MobilePhone.replaceAll('\\D','').contains(p)) || 
                    (c.Phone != null && c.Phone.replaceAll('\\D','') != null && c.Phone.replaceAll('\\D','').contains(p))) {
                    foundC.add(c);
                }
            }
            
            List<Lead> foundL = new List<Lead>();
            for (Lead l : allMatchedLeads) {
                if ((l.MobilePhone != null && l.MobilePhone.replaceAll('\\D','') != null && l.MobilePhone.replaceAll('\\D','').contains(p)) || 
                    (l.Phone != null && l.Phone.replaceAll('\\D','') != null && l.Phone.replaceAll('\\D','').contains(p))) {
                    foundL.add(l);
                }
            }

            List<Account> foundA = new List<Account>();
            for (Account a : allMatchedAccounts) {
                if (a.Phone != null && a.Phone.replaceAll('\\D','') != null && a.Phone.replaceAll('\\D','').contains(p)) {
                    foundA.add(a);
                }
            }

            Boolean updated = false;

            if (foundC.size() == 1) {
                t.WhoId = foundC[0].Id;
                t.WhatId = foundC[0].AccountId;
                updated = true;
            } else if (foundC.size() > 1) {
                Set<Id> accIds = new Set<Id>();
                Integer primaryCount = 0;
                Contact primaryContact = null;
                
                for (Contact c : foundC) {
                    if (c.AccountId != null) {
                        accIds.add(c.AccountId);
                    }
                    if (c.Is_Primary__c) {
                        primaryCount++;
                        primaryContact = c;
                    }
                }
                
                if (accIds.size() <= 1) {
                    Id accId = accIds.isEmpty() ? null : new List<Id>(accIds)[0];
                    if (accId != null) {
                        t.WhatId = accId;
                    }
                    if (primaryCount == 1) {
                        t.WhoId = primaryContact.Id;
                    } else {
                        t.WhoId = foundC[0].Id;
                    }
                    updated = true;
                }
            } else if (!foundL.isEmpty()) {
                t.WhoId = foundL[0].Id;
                updated = true;
            } else if (!foundA.isEmpty()) {
                t.WhatId = foundA[0].Id;
                updated = true;
            }
            
            if (updated) {
                tasksToUpdate.add(t);
                successCount++;
            }
        }

        if (!tasksToUpdate.isEmpty()) {
            Database.update(tasksToUpdate, false);
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('ZoomCallLogRemediationBatch finished. Successfully backfilled ' + successCount + ' tasks!');
    }
}