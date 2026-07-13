public class LeadPhoneNormalizerBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Phone, MobilePhone 
            FROM Lead 
            WHERE (Phone != null AND Phone != '') OR (MobilePhone != null AND MobilePhone != '')
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Lead> scope) {
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (Lead l : scope) {
            String originalPhone = l.Phone;
            String originalMobile = l.MobilePhone;
            
            l.Phone = cleanPhoneNumber(l.Phone);
            l.MobilePhone = cleanPhoneNumber(l.MobilePhone);
            
            if (String.isNotBlank(l.Phone) && l.Phone == l.MobilePhone) {
                l.Phone = null;
            }
            
            if (String.isBlank(l.MobilePhone) && String.isNotBlank(l.Phone)) {
                l.MobilePhone = l.Phone;
                l.Phone = null;
            }
            
            if (l.Phone != originalPhone || l.MobilePhone != originalMobile) {
                leadsToUpdate.add(l);
            }
        }
        
        if (!leadsToUpdate.isEmpty()) {
            Database.update(leadsToUpdate, false); 
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('LeadPhoneNormalizerBatch finished.');
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