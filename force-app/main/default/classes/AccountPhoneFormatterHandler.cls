public class AccountPhoneFormatterHandler {
    
    public static void formatAndConsolidate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        for (Account a : newAccounts) {
            Boolean changed = false;
            if (oldMap == null) {
                changed = true; 
            } else {
                Account oldA = oldMap.get(a.Id);
                if (a.Phone != oldA.Phone || a.Additional_Phone_Numbers__c != oldA.Additional_Phone_Numbers__c) {
                    changed = true; 
                }
            }
            
            if (changed) {
                // If there are letters in the Phone field, save the original value to Customer Service Notes
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
            }
        }
    }

    private static Boolean containsAlpha(String s) {
        return Pattern.compile('[a-zA-Z]').matcher(s).find();
    }

    private static String cleanPhoneNumber(String rawPhone) {
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