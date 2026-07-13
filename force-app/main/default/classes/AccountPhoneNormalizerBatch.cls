public class AccountPhoneNormalizerBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Phone, Additional_Phone_Numbers__c, Customer_Service_Notes__c 
            FROM Account 
            WHERE (Phone != null AND Phone != '') OR (Additional_Phone_Numbers__c != null AND Additional_Phone_Numbers__c != '')
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Account> scope) {
        List<Account> accountsToUpdate = new List<Account>();
        
        for (Account a : scope) {
            String originalPhone = a.Phone;
            String originalAdditional = a.Additional_Phone_Numbers__c;
            String originalNotes = a.Customer_Service_Notes__c;
            
            // Re-use logic from handler
            if (String.isNotBlank(a.Phone) && containsAlpha(a.Phone)) {
                String noteAppend = '\n[System - Preserved Phone Value: ' + a.Phone + ']';
                if (String.isBlank(a.Customer_Service_Notes__c)) {
                    a.Customer_Service_Notes__c = noteAppend.trim();
                } else if (!a.Customer_Service_Notes__c.contains(noteAppend.trim())) {
                    a.Customer_Service_Notes__c += noteAppend;
                }
            }
            
            a.Phone = cleanPhoneNumber(a.Phone);
            a.Additional_Phone_Numbers__c = cleanPhoneNumber(a.Additional_Phone_Numbers__c);
            
            if (String.isNotBlank(a.Phone) && a.Phone == a.Additional_Phone_Numbers__c) {
                a.Additional_Phone_Numbers__c = null;
            }
            
            // Check if anything actually changed before adding to update list
            if (a.Phone != originalPhone || a.Additional_Phone_Numbers__c != originalAdditional || a.Customer_Service_Notes__c != originalNotes) {
                accountsToUpdate.add(a);
            }
        }
        
        if (!accountsToUpdate.isEmpty()) {
            Database.update(accountsToUpdate, false); // All or nothing = false, to allow partial success
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('AccountPhoneNormalizerBatch finished.');
    }
    
    private Boolean containsAlpha(String s) {
        return Pattern.compile('[a-zA-Z]').matcher(s).find();
    }

    private String cleanPhoneNumber(String rawPhone) {
        if (String.isBlank(rawPhone)) return null;
        
        String digitsOnly = rawPhone.replaceAll('[^0-9+]', '');
        Boolean hasLeadingPlus = digitsOnly.startsWith('+');
        if (hasLeadingPlus) digitsOnly = digitsOnly.substring(1);
        
        digitsOnly = digitsOnly.replaceAll('[^0-9]', '');

        if (digitsOnly.length() == 11 && digitsOnly.startsWith('1')) {
            digitsOnly = digitsOnly.substring(1);
        }
        
        if (digitsOnly.length() == 10) {
            return '+1' + digitsOnly;
        }
        
        return rawPhone; 
    }
}