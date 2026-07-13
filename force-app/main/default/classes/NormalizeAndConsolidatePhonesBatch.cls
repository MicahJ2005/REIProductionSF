global class NormalizeAndConsolidatePhonesBatch implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Phone, MobilePhone, HomePhone, OtherPhone FROM Contact WHERE Phone != null OR MobilePhone != null OR HomePhone != null OR OtherPhone != null';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Contact> scope) {
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for (Contact c : scope) {
            String origPhone = c.Phone;
            String origMobile = c.MobilePhone;
            String origHome = c.HomePhone;
            String origOther = c.OtherPhone;
            
            c.Phone = cleanPhoneNumber(c.Phone);
            c.MobilePhone = cleanPhoneNumber(c.MobilePhone);
            c.HomePhone = cleanPhoneNumber(c.HomePhone);
            c.OtherPhone = cleanPhoneNumber(c.OtherPhone);
            
            if (String.isNotBlank(c.Phone) && c.Phone == c.MobilePhone) c.Phone = null;
            if (String.isNotBlank(c.HomePhone) && (c.HomePhone == c.MobilePhone || c.HomePhone == c.Phone)) c.HomePhone = null;
            if (String.isNotBlank(c.OtherPhone) && (c.OtherPhone == c.MobilePhone || c.OtherPhone == c.Phone || c.OtherPhone == c.HomePhone)) c.OtherPhone = null;
            
            for (Integer i = 0; i < 3; i++) {
                if (String.isBlank(c.MobilePhone) && String.isNotBlank(c.Phone)) {
                    c.MobilePhone = c.Phone;
                    c.Phone = null;
                }
                if (String.isBlank(c.Phone) && String.isNotBlank(c.HomePhone)) {
                    c.Phone = c.HomePhone;
                    c.HomePhone = null;
                }
                if (String.isBlank(c.HomePhone) && String.isNotBlank(c.OtherPhone)) {
                    c.HomePhone = c.OtherPhone;
                    c.OtherPhone = null;
                }
            }
            
            if (c.Phone != origPhone || c.MobilePhone != origMobile || c.HomePhone != origHome || c.OtherPhone != origOther) {
                contactsToUpdate.add(c);
            }
        }
        
        if (!contactsToUpdate.isEmpty()) {
            Database.update(contactsToUpdate, false);
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Contact Phone Normalization and Consolidation Batch Complete.');
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