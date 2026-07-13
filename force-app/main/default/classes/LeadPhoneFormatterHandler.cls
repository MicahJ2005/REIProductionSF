public class LeadPhoneFormatterHandler {
    
    public static void formatAndConsolidate(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        for (Lead l : newLeads) {
            Boolean changed = false;
            if (oldMap == null) {
                changed = true; 
            } else {
                Lead oldL = oldMap.get(l.Id);
                if (l.Phone != oldL.Phone || l.MobilePhone != oldL.MobilePhone) {
                    changed = true; 
                }
            }
            
            if (changed) {
                l.Phone = cleanPhoneNumber(l.Phone);
                l.MobilePhone = cleanPhoneNumber(l.MobilePhone);
                
                if (String.isNotBlank(l.Phone) && l.Phone == l.MobilePhone) {
                    l.Phone = null;
                }
                
                if (String.isBlank(l.MobilePhone) && String.isNotBlank(l.Phone)) {
                    l.MobilePhone = l.Phone;
                    l.Phone = null;
                }
            }
        }
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