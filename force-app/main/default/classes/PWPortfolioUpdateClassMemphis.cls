public with sharing class PWPortfolioUpdateClassMemphis implements Queueable, Database.AllowsCallouts{

    public void execute(QueueableContext ctx) {
        getPortfolios();
    }
    public static void getPortfolios() {
         PropertyWare_Setting__mdt PWPPMGCREDS = [
                                                SELECT 
                                                    MasterLabel,
                                                    DeveloperName,
                                                    x_propertyware_client_id__c,
                                                    x_propertyware_client_secret__c,
                                                    x_propertyware_system_id__c
                                                FROM PropertyWare_Setting__mdt
                                                WHERE DeveloperName = 'PW_PPMG_Creds'
                                                LIMIT 1
                                            ];

        PropertyWare_Setting__mdt PWgetBuildingHoursSpanMTD = [
                                                        SELECT 
                                                            MasterLabel,
                                                            DeveloperName,
                                                            IntegerValue__c
                                                        FROM PropertyWare_Setting__mdt
                                                        WHERE DeveloperName = 'EndFromHoursAgo'
                                                        LIMIT 1
                                                            ];

        PropertyWare_Setting__mdt PWStartFromHoursAgoMTD = [
                                                            SELECT 
                                                                MasterLabel,
                                                                DeveloperName,
                                                                IntegerValue__c
                                                            FROM PropertyWare_Setting__mdt
                                                            WHERE DeveloperName = 'StartFromHoursAgo'
                                                            LIMIT 1
                                                                ];                   
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        Datetime now = Datetime.now(); // Current datetime
        String toDateTime = now.addHours(Integer.valueOf(PWgetBuildingHoursSpanMTD.IntegerValue__c)).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''); // set by EndFromHoursAgo Custom Metadata
       
        String fromDateTime = now.addHours(Integer.valueOf(PWStartFromHoursAgoMTD.IntegerValue__c)).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''); // set by StartFromHoursAgo Custom Metadata

        string dateTimeParameters = '?lastModifiedDateTimeStart='+ EncodingUtil.urlEncode(fromDateTime, 'UTF-8')+'&lastModifiedDateTimeEnd='+ EncodingUtil.urlEncode(toDateTime, 'UTF-8');
        System.debug(dateTimeParameters);

        request.setEndpoint('https://api.propertyware.com/pw/api/rest/v1/portfolios'+ dateTimeParameters +'&includeDeactivated=true&includeCustomFields=true&includeBalances=true');
        request.setMethod('GET');

        // Set required headers
        request.setHeader('x-propertyware-client-id', PWPPMGCREDS.x_propertyware_client_id__c);
        request.setHeader('x-propertyware-client-secret', PWPPMGCREDS.x_propertyware_client_secret__c);
        request.setHeader('x-propertyware-system-id', PWPPMGCREDS.x_propertyware_system_id__c);

        // Optional common headers
        request.setHeader('Accept', '*/*');
        request.setHeader('Accept-Encoding', 'gzip, deflate, br');
        request.setHeader('Connection', 'keep-alive');


        
        map<String, Object> portfolioIdsFromPWMap = new map<String, Object>();
        map<String, PW_Portfolio__c> portfoliosToUpdateMap = new map<String, PW_Portfolio__c>();
        List<Object> Portfolios = new List<Object>();
        Map<Id, PW_Portfolio__c> PortfoliosToUpdate = new Map<Id, PW_Portfolio__c>();

        try {
            HttpResponse response = http.send(request);
            if(response.getStatusCode() == 200) {
                Object raw = (Object) JSON.deserializeUntyped(response.getBody());
                System.debug('Portfolio: '+raw);
                Portfolios = (List<Object>) raw;
                for(Object o: Portfolios){
                    system.debug('IN LOOP: '+ o);
                    Map<String, Object> Portfolio = (Map<String, Object>) o;
                    system.debug('IN String.valueOf(Portfolio.get()): '+ String.valueOf(Portfolio.get('id')));
                    if(!portfolioIdsFromPWMap.containsKey(String.valueOf(Portfolio.get('id')))){
                        portfolioIdsFromPWMap.put(String.valueOf(Portfolio.get('id')), Portfolio);
                    }
                }
            }

            if(portfolioIdsFromPWMap.isEmpty() == false){
                for(PW_Portfolio__c p: [SELECT Id, Name, PW_Portfolio_Entity_ID__c, PW_Active__c, PW_Org__c, PW_Portfolio_Balance__c FROM PW_Portfolio__c WHERE PW_Portfolio_Entity_ID__c IN :portfolioIdsFromPWMap.keySet()]){
                    if(p.PW_Portfolio_Entity_ID__c != null){
                        portfoliosToUpdateMap.put(p.PW_Portfolio_Entity_ID__c, p);
                    }
                }
            } 

            for(Object o: Portfolios){
                system.debug('IN LOOP: '+ o);
                Map<String, Object> Portfolio = (Map<String, Object>) o;
                if(portfoliosToUpdateMap.containsKey(String.valueOf(Portfolio.get('id')))){
                    
                    PW_Portfolio__c newPortfolio = new PW_Portfolio__c();
                    newPortfolio.Id = portfoliosToUpdateMap.get(String.valueOf(Portfolio.get('id'))).Id;
                    newPortfolio.PW_Active__c = Boolean.valueOf(Portfolio.get('active'));
                    newPortfolio.PW_Portfolio_Balance__c = Decimal.valueOf(String.valueOf(Portfolio.get('portfolioBalance')));

                    List<String> ownerNames = new List<String>();
                    List<Object> owners = (List<Object>) Portfolio.get('owners');
                    if(owners != null) {
                        for(Object ownerObj : owners) {
                            Map<String, Object> owner = (Map<String, Object>) ownerObj;
                            if(owner.get('name') != null) {
                                ownerNames.add(String.valueOf(owner.get('name')));
                            }
                        }
                        newPortfolio.PW_Portfolio_Owners__c = String.join(ownerNames, ';');
                    }
                    String ownerNamesList = String.join(ownerNames, ';');
                    system.debug('ownerNamesList: ' + ownerNamesList);
                    if(!PortfoliosToUpdate.containsKey(newPortfolio.Id)){
                        system.debug('newPortfolio.Id: ' + newPortfolio.Id);
                        PortfoliosToUpdate.put(newPortfolio.Id, newPortfolio);
                    }
                }
            }

        } catch (Exception e) {
            System.debug('Callout error: ' + e.getMessage());
        }
        
        if(PortfoliosToUpdate.isEmpty() == false){
            update PortfoliosToUpdate.values();
        }
    }
}