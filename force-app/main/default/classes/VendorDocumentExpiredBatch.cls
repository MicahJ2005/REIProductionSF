/*
    Name             : VendorDocumentExpiredBatch
    Author           : Shweta F.
    Date             : 08/06/2019
    Description      : This class is used for vendor document expired batch .
*/
global class VendorDocumentExpiredBatch implements Database.Batchable<sObject> {

    //Start Method
    global Database.QueryLocator start(Database.BatchableContext bc) {
    
        //Return vendor list where record type equal to vendor. 
        String vendorLabel = label.AccVendorRecType;
        String vendorFieldServiceLabel = label.AccountVendorFieldServiceRecordType;
        String Squery = 'SELECT id,Name,Vendor_Email__c,Status__c FROM Account WHERE RecordType.Name =: vendorFieldServiceLabel AND (Status__c = \'Active\' OR Status__c = \'On Hold\')';                           
        return Database.getQueryLocator(Squery); 
    }
    
    //Execute Method
    global void execute(Database.BatchableContext BC, List<Account> accountList) {

        Set<Id> accountIdsSet = new Set<Id>();
        for(Account acc: accountList) {
            accountIdsSet.add(acc.id);
        }

        if(!accountIdsSet.isEmpty()) {
            // Get all content document links for these accounts
            Set<Id> contentDocumentIds = new Set<Id>();
            Map<Id, Id> contentDocToAccountMap = new Map<Id, Id>();
            for(ContentDocumentLink cdl : [SELECT id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN: accountIdsSet]) {
                contentDocumentIds.add(cdl.ContentDocumentId);
                contentDocToAccountMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
            }

            // Mark newly-expired documents as Expired and track which accounts are affected
            Set<Id> accountsWithExpiredDocs = new Set<Id>();
            List<ContentVersion> contentVersionList = [SELECT Expiration_Date__c, Status__c, ContentDocumentId FROM ContentVersion WHERE Status__c != 'Expired' AND Expiration_Date__c <=: System.today() AND Expiration_Date__c != Null AND isLatest = true AND ContentDocumentId IN: contentDocumentIds];
            for(ContentVersion cv : contentVersionList) {
                cv.Status__c = 'Expired';
                Id accId = contentDocToAccountMap.get(cv.ContentDocumentId);
                if (accId != null) {
                    accountsWithExpiredDocs.add(accId);
                }
            }

            try {
                update contentVersionList;
            } catch(Exception ex) {
                system.debug('======error====='+ex.getMessage()+'======Line No====='+ ex.getLineNumber());
            }

            // Also flag Active accounts that already have a previously-expired document
            Set<Id> activeAccountIds = new Set<Id>();
            for(Account acc : accountList) {
                if (acc.Status__c == 'Active') {
                    activeAccountIds.add(acc.Id);
                }
            }
            if (!activeAccountIds.isEmpty()) {
                for(ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion WHERE Status__c = 'Expired' AND isLatest = true AND ContentDocumentId IN: contentDocumentIds]) {
                    Id accId = contentDocToAccountMap.get(cv.ContentDocumentId);
                    if (accId != null && activeAccountIds.contains(accId)) {
                        accountsWithExpiredDocs.add(accId);
                    }
                }
            }

            // Identify accounts that have a Payment Agreement document
            Set<Id> accountsWithPaymentAgreement = new Set<Id>();
            for(ContentVersion cv : [SELECT ContentDocumentId, Attachment_Type__c FROM ContentVersion WHERE isLatest = true AND Attachment_Type__c = 'Payment Agreement' AND ContentDocumentId IN: contentDocumentIds]) {
                Id accId = contentDocToAccountMap.get(cv.ContentDocumentId);
                if (accId != null) {
                    accountsWithPaymentAgreement.add(accId);
                }
            }

            // Put account On Hold if it has any expired documents OR is missing a Payment Agreement
            List<Account> accountsToUpdate = new List<Account>();
            for(Account acc : accountList) {
                Boolean hasExpiredDocs = accountsWithExpiredDocs.contains(acc.Id);
                Boolean missingPaymentAgreement = !accountsWithPaymentAgreement.contains(acc.Id);
                if (hasExpiredDocs || missingPaymentAgreement) {
                    accountsToUpdate.add(new Account(Id = acc.Id, Status__c = 'On Hold'));
                }
            }

            if (!accountsToUpdate.isEmpty()) {
                try {
                    update accountsToUpdate;
                } catch(Exception ex) {
                    system.debug('======error====='+ex.getMessage()+'======Line No====='+ ex.getLineNumber());
                }
            }
        }
    }
      
    //Finish Method 
    global void finish(Database.BatchableContext BC) {
    }
}