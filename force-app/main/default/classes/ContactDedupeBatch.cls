public class ContactDedupeBatch implements Database.Batchable<AggregateResult> {

    public Iterable<AggregateResult> start(Database.BatchableContext BC) {
        if (Test.isRunningTest()) {
            return [
                SELECT FirstName, LastName, Email, MobilePhone, AccountId 
                FROM Contact 
                WHERE Email != null AND MobilePhone != null 
                GROUP BY FirstName, LastName, Email, MobilePhone, AccountId 
                HAVING COUNT(Id) > 1
                LIMIT 1
            ];
        }
        return [
            SELECT FirstName, LastName, Email, MobilePhone, AccountId 
            FROM Contact 
            WHERE Email != null AND MobilePhone != null 
            GROUP BY FirstName, LastName, Email, MobilePhone, AccountId 
            HAVING COUNT(Id) > 1
        ];
    }

    public void execute(Database.BatchableContext BC, List<AggregateResult> scope) {
        
        // Dynamically get all updateable fields for Contact
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Contact.fields.getMap();
        List<String> updateableFields = new List<String>();
        for(String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
            if(dfr.isUpdateable() && !dfr.isUnique() && !dfr.isCalculated()) {
                updateableFields.add(fieldName);
            }
        }
        
        String fieldsStr = String.join(updateableFields, ',');
        
        for (AggregateResult ar : scope) {
            String fName = (String)ar.get('FirstName');
            String lName = (String)ar.get('LastName');
            String email = (String)ar.get('Email');
            String phone = (String)ar.get('MobilePhone');
            Id accId = (Id)ar.get('AccountId');
            
            // Query dynamically to get all fields
            String queryStr = 'SELECT ' + fieldsStr + ' FROM Contact WHERE FirstName = :fName AND LastName = :lName AND Email = :email AND MobilePhone = :phone AND AccountId = :accId ORDER BY CreatedDate ASC';
            List<Contact> records = Database.query(queryStr);
            
            if (records.size() > 1) {
                Contact master = records[0];
                List<Contact> duplicates = new List<Contact>();
                for (Integer i = 1; i < records.size(); i++) {
                    duplicates.add(records[i]);
                }
                
                // Dynamically copy missing fields from duplicates to the master
                Boolean masterNeedsUpdate = false;
                for(String fNameField : updateableFields) {
                    Object masterVal = master.get(fNameField);
                    if(masterVal == null || (masterVal instanceof String && String.isBlank((String)masterVal))) {
                        for(Contact dup : duplicates) {
                            Object dupVal = dup.get(fNameField);
                            if(dupVal != null && (!(dupVal instanceof String) || !String.isBlank((String)dupVal))) {
                                // Prevent setting invalid dates (before 1700) which crash Salesforce DML
                                if (dupVal instanceof Date && ((Date)dupVal).year() < 1700) continue;
                                if (dupVal instanceof Datetime && ((Datetime)dupVal).year() < 1700) continue;
                                
                                master.put(fNameField, dupVal);
                                masterNeedsUpdate = true;
                                break;
                            }
                        }
                    }
                }
                
                if (masterNeedsUpdate) {
                    Database.SaveResult sr = Database.update(master, false);
                    if (!sr.isSuccess()) {
                        System.debug('Failed to update master ' + master.Id + ': ' + sr.getErrors()[0].getMessage());
                        // If we can't update the master with missing fields, it's safer to skip merging this group
                        continue;
                    }
                }
                
                // Salesforce allows max 2 duplicates per merge call
                while (duplicates.size() > 0) {
                    List<Contact> chunk = new List<Contact>();
                    chunk.add(duplicates.remove(0));
                    if (duplicates.size() > 0) {
                        chunk.add(duplicates.remove(0));
                    }
                    
                    Database.merge(master, chunk, false);
                }
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Contact Deduplication Batch Complete.');
    }
}