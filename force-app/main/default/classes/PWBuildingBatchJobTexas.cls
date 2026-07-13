public with sharing class PWBuildingBatchJobTexas implements Queueable, Database.AllowsCallouts {
    private Integer offsetVal;
    private static final Integer LIMIT_SIZE = 100;
    

    public PWBuildingBatchJobTexas(Integer offsetVal) {
        this.offsetVal = offsetVal;
    }

    public void execute(QueueableContext context) {
            PropertyWare_Setting__mdt PWPPMGCREDS = [
                    SELECT 
                        x_propertyware_client_id__c,
                        x_propertyware_client_secret__c,
                        x_propertyware_system_id__c
                    FROM PropertyWare_Setting__mdt
                    WHERE DeveloperName = 'PW_PPMG_of_Texas_Creds'
                    LIMIT 1
                ];

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.propertyware.com/pw/api/rest/v1/buildings?limit=' + LIMIT_SIZE + '&offset=' + offsetVal+'&includeDeactivated=true&includeCustomFields=true');
        req.setMethod('GET');
        req.setTimeout(30000); // 30 seconds

       // Set required headers
        req.setHeader('x-propertyware-client-id', PWPPMGCREDS.x_propertyware_client_id__c);
        req.setHeader('x-propertyware-client-secret', PWPPMGCREDS.x_propertyware_client_secret__c);
        req.setHeader('x-propertyware-system-id', PWPPMGCREDS.x_propertyware_system_id__c);

        // Optional common headers
        req.setHeader('Accept', '*/*');
        req.setHeader('Accept-Encoding', 'gzip, deflate, br');
        req.setHeader('Connection', 'keep-alive');

        Map<String, PropertyWareAPIUtility.PWBuildingWrapper> PWIdAndAddress = new Map<String, PropertyWareAPIUtility.PWBuildingWrapper>();

        Set<String> buildingIds = new Set<String>();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            List<Object> responseList = (List<Object>) JSON.deserializeUntyped(res.getBody());

            List<PW_Building__c> updates = new List<PW_Building__c>();

            for (Object obj : responseList) {
                Map<String, Object> building = (Map<String, Object>) obj;
                    System.debug(building);
                    PropertyWareAPIUtility.PWBuildingWrapper bw = new PropertyWareAPIUtility.PWBuildingWrapper();
                    for(String key: building.keySet()){
                        PropertyWareAPIUtility.Address addressWrapper = new PropertyWareAPIUtility.Address();
                        if(key == 'address'){
                            System.debug('Address at 46: ' + building.get(key));
                            Map<String, Object> address = (Map<String, Object>) building.get(key);
                            System.debug(address);
                            
                            bw.address = String.valueOf(address.get('address'));
                            bw.city = String.valueOf(address.get('city'));  
                            bw.country = String.valueOf(address.get('country'));    
                            bw.stateRegion = String.valueOf(address.get('stateRegion'));
                            bw.postalCode = String.valueOf(address.get('postalCode'));
                            
                        }
                        if(key == 'marketing'){
                            System.debug('marketing: ' + building.get(key));
                            Map<String, Object> marketing = (Map<String, Object>) building.get(key);
                            System.debug(marketing);
                            bw.publishedForRent = Boolean.valueOf(marketing.get('publishedForRent'));
                        }
                        if(key == 'customFields'){
                            System.debug('customFields: ' + building.get(key));
                            for(object o2: (List<Object>) building.get(key)){
                                Map<String, Object> temp = (Map<String, Object>) o2;
                                // System.debug('temp: ' + temp);
                                if(temp.get('fieldName') == 'Building Market'){
                                    if(temp.get('value') != '' && temp.get('value') != null){
                                        bw.market = String.valueOf(temp.get('value'));
                                    }
                                }
                                if(temp.get('fieldName') == 'Group HOI DO NOT EDIT'){
                                    if(temp.get('value') != '' && temp.get('value') != null){
                                        bw.groupHOI = String.valueOf(temp.get('value'));
                                    }
                                }
                                if(temp.get('fieldName') == 'Is Owner Selling? notes'){
                                    if(temp.get('value') != '' && temp.get('value') != null){
                                        System.debug('Is Owner Selling? notes: '+String.valueOf(temp.get('value')));
                                        bw.isOwnerSellingNotes = String.valueOf(temp.get('value'));
                                    }
                                }
                                if(temp.get('fieldName') == 'Is Owner Selling? Closing Date'){
                                    if(temp.get('value') != '' && temp.get('value') != null){
                                        System.debug('Is Owner Selling? Closing Date: '+String.valueOf(temp.get('value')));
                                        bw.isOwnerSellingClosingDate = String.valueOf(temp.get('value'));
                                    }
                                }
                                if(temp.get('fieldName') == 'Is Owner Selling?'){
                                    if(temp.get('value') != '' && temp.get('value') != null){
                                        System.debug('Is Owner Selling?: '+String.valueOf(temp.get('value')));
                                        bw.isOwnerSelling = String.valueOf(temp.get('value'));
                                    }
                                }
                            }
                        }
                    }
                    
                    bw.PwCreatedDate = String.valueOf(building.get('createdDateTime'));
                    bw.PwLastModifiedDateTime = String.valueOf(building.get('lastModifiedDateTime'));
                    bw.propertyType = String.valueOf(building.get('type'));
                    bw.buildingEntityId = String.valueOf(building.get('id'));
                    bw.buildingIdNumber  = String.valueOf(building.get('idNumber'));
                    bw.portfolioID  = String.valueOf(building.get('portfolioID'));
                    bw.name = String.valueOf(building.get('name'));
                    bw.status = String.valueOf(building.get('status'));
                    bw.active = Boolean.valueOf(building.get('active'));
                    bw.yearBuilt  = String.valueOf(building.get('yearBuilt'));
                    bw.numberOfBedrooms  = Integer.valueOf(building.get('numberOfBedrooms'));
                    bw.numberOfBathrooms  = Double.valueOf(building.get('numberOfBathrooms'));
                    bw.totalArea = Double.valueOf(building.get('totalArea'));
                    
                    System.debug('id: '+ building.get('id'));
                    System.debug('idNumber: '+ building.get('idNumber'));
                    PWIdAndAddress.put(bw.buildingEntityId , bw);
            }

            List<PW_Building__c> buildingsToMatch = [SELECT Id, Name, PW_State__c, 
                                                        PW_Building_Market__c, PW_Total_Area__c, 
                                                        PW_Zip__c, PW_Address__c, PW_City__c, 
                                                        PW_Target_Rent__c, House__c, PW_Status__c, Owner_Account__c, 
                                                        Investor_Owner_Account__c, SF_Market__c, PW_Portfolio__c, PW_Active__c, 
                                                        Investor_From_House_del__c, SF_Street_Address__c, SF_City__c, SF_Sq_Feet__c, SF_State__c, SF_Zip__c, 
                                                        SF_Year_Built__c, PW_Bedrooms__c, PW_Bathroos__c, SF_Bedrooms__c, SF_Bathrooms__c, 
                                                        PW_Building_Entity_ID1__c, Customer_Service_Assignment__c, Sales_Assignment__c, 
                                                        PW_Year_Built1__c, PW_Portfolio_Entity_ID1__c, PW_Building_ID__c, PW_Created_Date_in_Propetyware__c, 
                                                        PW_Last_Modified_in_Propertyware__c, Google_Place_ID__c, Published_For_Rent__c, Group_HOI__c, 
                                                        Is_Owner_Selling_Notes__c, Is_Owner_Selling_Closing_Date__c, Is_Owner_Selling__c 
                                                        FROM PW_Building__c 
                                                        WHERE PW_Building_Entity_ID1__c 
                                                        IN: PWIdAndAddress.keySet()];

            Map<String, PW_Building__c> existingBuildings = new Map<String, PW_Building__c>();

            for (PW_Building__c building : buildingsToMatch) {
                system.debug('BuildingId: '+ building.Id);
                string formattedPWCreatedDate = '';
                if(PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).PwCreatedDate != null){
                    try{
                        string zuluCreateDate = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).PwCreatedDate;
                        if(zuluCreateDate.contains('T')) {
                            zuluCreateDate = zuluCreateDate.replace('T',' ');
                        }
                        DateTime transformedPWCreatedDate = DateTime.valueOfGmt(zuluCreateDate);
                        formattedPWCreatedDate = transformedPWCreatedDate.format('M/d/yyyy h:mm a');
                    } catch (Exception e) {
                        System.debug('Invalid datetime string: ' + PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).PwCreatedDate);
                        // Optionally set a fallback
                        formattedPWCreatedDate = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).PwCreatedDate;
                    }
                }
                string formattedPWLastModifiedDate = '';
                if(PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).PwLastModifiedDateTime != null){
                    try{
                        string zuluLastModified = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).PwLastModifiedDateTime;
                        if(zuluLastModified.contains('T')) {
                            zuluLastModified = zuluLastModified.replace('T',' ');
                        }
                        DateTime transformedPWLastModifiedDate = DateTime.valueOfGmt(zuluLastModified);
                        formattedPWLastModifiedDate = transformedPWLastModifiedDate.format('M/d/yyyy h:mm a');
                    }  catch (Exception e) {
                        System.debug('Invalid datetime string: ' + PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).PwLastModifiedDateTime);
                        // Optionally set a fallback
                        formattedPWLastModifiedDate = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).PwLastModifiedDateTime;
                    }
                }
                 building.PW_State__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).stateRegion;
                 building.PW_Building_Market__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).market;
                 building.PW_Total_Area__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).totalArea;
                 building.PW_Zip__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).postalCode;
                 building.PW_Address__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).address;
                 building.PW_Year_Built1__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).yearBuilt;
                 building.PW_City__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).city;
                 building.PW_Status__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).status;
                 building.PW_Active__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).active;
                 building.PW_Bedrooms__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).numberOfBedrooms;
                 building.PW_Bathroos__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).numberOfBathrooms;
                 building.PW_Created_Date_in_Propetyware__c = formattedPWCreatedDate;
                 building.PW_Last_Modified_in_Propertyware__c = formattedPWLastModifiedDate;
                 building.PW_Total_Area__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).totalArea;
                 building.Published_For_Rent__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).publishedForRent;
                 building.Group_HOI__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).groupHOI;
                 building.Is_Owner_Selling_Notes__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).isOwnerSellingNotes;
                 building.Is_Owner_Selling__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).isOwnerSelling;
                 building.Is_Owner_Selling_Closing_Date__c = PWIdAndAddress.get(building.PW_Building_Entity_ID1__c).isOwnerSellingClosingDate;
                updates.add(building);
            }


            // if (!updates.isEmpty()) {
            //     // Database.update(updates, false);
            //     Database.SaveResult[] results = Database.update(updates, false);

            //     List<Error_Log__c> errorLogs = new List<Error_Log__c>();

            //     for (Integer i = 0; i < results.size(); i++) {
            //         Database.SaveResult sr = results[i];
            //         if (!sr.isSuccess()) {
            //             for (Database.Error err : sr.getErrors()) {
            //                 errorLogs.add(new Error_Log__c(
            //                     Message__c     = err.getMessage(),
            //                     Stack_Trace__c = err.getStackTraceString(),
            //                     Record_Id__c   = String.valueOf(updates[i].Id),
            //                     Context__c     = context
            //                 ));
            //             }
            //         }
            //     }
            // }

            if (updates == null || updates.isEmpty()) return;

            Database.SaveResult[] results = Database.update(updates, false);
            List<Error_Log__c> errorLogs = new List<Error_Log__c>();

            String contextInfo = (context == null) ? 'Unknown Context' : String.valueOf(context);

            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult sr = results[i];
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        errorLogs.add(new Error_Log__c(
                            Message__c   = err.getMessage(),
                            // No getStackTraceString() for Database.Error — use statusCode + fields instead
                            Stack_Trace__c = 
                                'StatusCode: ' + String.valueOf(err.getStatusCode()) + 
                                ' | Fields: ' + String.join(err.getFields(), ','),
                            Record_Id__c = String.valueOf(updates[i].Id),
                            Context__c   = contextInfo
                        ));
                    }
                }
            }

            if (!errorLogs.isEmpty()) {
                try {
                    insert errorLogs;
                } catch (Exception logEx) {
                    System.debug('Error writing to Error_Log__c: ' + logEx.getMessage());
                }
            }

            // If we got a full batch, queue the next offset
            if (responseList.size() == LIMIT_SIZE) {
                System.enqueueJob(new PWBuildingBatchJobTexas(offsetVal + LIMIT_SIZE));
            }
        } else {
            System.debug('Error from PropertyWare API: ' + res.getBody());
        }
    }
}