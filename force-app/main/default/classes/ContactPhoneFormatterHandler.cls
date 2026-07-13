public class ContactPhoneFormatterHandler {
    
    public static void formatAndConsolidate(List<Contact> newContacts, Map<Id, Contact> oldMap) {
        for (Contact c : newContacts) {
            
            // Only process if it's an insert or one of the phone fields changed
            Boolean changed = false;
            if (oldMap == null) {
                changed = true; // Insert
            } else {
                Contact oldC = oldMap.get(c.Id);
                if (c.Phone != oldC.Phone || c.MobilePhone != oldC.MobilePhone || c.HomePhone != oldC.HomePhone || c.OtherPhone != oldC.OtherPhone) {
                    changed = true; // Update
                }
            }
            
            if (changed) {
                c.Phone = cleanPhoneNumber(c.Phone);
                c.MobilePhone = cleanPhoneNumber(c.MobilePhone);
                c.HomePhone = cleanPhoneNumber(c.HomePhone);
                c.OtherPhone = cleanPhoneNumber(c.OtherPhone);
                
                // Deduplicate
                if (String.isNotBlank(c.Phone) && c.Phone == c.MobilePhone) c.Phone = null;
                if (String.isNotBlank(c.HomePhone) && (c.HomePhone == c.MobilePhone || c.HomePhone == c.Phone)) c.HomePhone = null;
                if (String.isNotBlank(c.OtherPhone) && (c.OtherPhone == c.MobilePhone || c.OtherPhone == c.Phone || c.OtherPhone == c.HomePhone)) c.OtherPhone = null;
                
                // Bubble Up
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