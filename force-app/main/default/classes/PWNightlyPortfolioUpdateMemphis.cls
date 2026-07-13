public with sharing class PWNightlyPortfolioUpdateMemphis implements Queueable, Database.AllowsCallouts{
 private Integer offsetVal;
    private static final Integer LIMIT_SIZE = 20;
    

    public PWNightlyPortfolioUpdateMemphis(Integer offsetVal) {
        this.offsetVal = offsetVal;
    }

    public void execute(QueueableContext context) {
        PropertyWare_Setting__mdt PWPPMGCREDS = [
                    SELECT 
                        x_propertyware_client_id__c,
                        x_propertyware_client_secret__c,
                        x_propertyware_system_id__c
                    FROM PropertyWare_Setting__mdt
                    WHERE DeveloperName = 'PW_PPMG_Creds'
                    LIMIT 1
                ];

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.propertyware.com/pw/api/rest/v1/portfolios?limit=' + LIMIT_SIZE + '&offset=' + offsetVal+'&includeDeactivated=true&includeCustomFields=true&includeBalances=true');
        req.setMethod('GET');
        req.setTimeout(120000); // 2 Minutes timeout for callout

       // Set required headers
        req.setHeader('x-propertyware-client-id', PWPPMGCREDS.x_propertyware_client_id__c);
        req.setHeader('x-propertyware-client-secret', PWPPMGCREDS.x_propertyware_client_secret__c);
        req.setHeader('x-propertyware-system-id', PWPPMGCREDS.x_propertyware_system_id__c);

        // Optional common headers
        req.setHeader('Accept', '*/*');
        req.setHeader('Accept-Encoding', 'gzip, deflate, br');
        req.setHeader('Connection', 'keep-alive');

        map<String, Object> portfolioIdsFromPWMap = new map<String, Object>();
        map<String, PW_Portfolio__c> portfoliosToUpdateMap = new map<String, PW_Portfolio__c>();
        List<Object> Portfolios = new List<Object>();
        List<PW_Portfolio__c> PortfoliosToUpdate = new List<PW_Portfolio__c>();

         try {
            HttpResponse response = http.send(req);
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
            

                if(portfolioIdsFromPWMap.isEmpty() == false){
                    for(PW_Portfolio__c p: [SELECT Id, Name, PW_Portfolio_Entity_ID__c, PW_Active__c, PW_Org__c, PW_Portfolio_Balance__c, PW_Portfolio_Owners__c FROM PW_Portfolio__c WHERE PW_Portfolio_Entity_ID__c IN :portfolioIdsFromPWMap.keySet()]){
                        if(p.PW_Portfolio_Entity_ID__c != null && portfolioIdsFromPWMap.containsKey(p.PW_Portfolio_Entity_ID__c)){
                            Map<String, Object> Portfolio = (Map<String, Object>) portfolioIdsFromPWMap.get(p.PW_Portfolio_Entity_ID__c);
                            // system.debug('SF ID on Portfolio: '+ p.Id);
                            p.PW_Active__c = Boolean.valueOf(Portfolio.get('active'));
                            // system.debug('portfolio balance: '+ Portfolio.get('portfolioBalance'));
                            p.PW_Portfolio_Balance__c = Decimal.valueOf(String.valueOf(Portfolio.get('portfolioBalance')));
                            List<String> ownerNames = new List<String>();
                            List<Object> owners = (List<Object>) Portfolio.get('owners');
                            if(owners != null) {
                                for(Object ownerObj : owners) {
                                    Map<String, Object> owner = (Map<String, Object>) ownerObj;
                                    if(owner.get('name') != null) {
                                        ownerNames.add(String.valueOf(owner.get('name')));
                                    }
                                }
                                p.PW_Portfolio_Owners__c = String.join(ownerNames, ';');
                            }
                            system.debug('ownerNamesList: ' + String.join(ownerNames, ';'));
                            PortfoliosToUpdate.add(p);
                            // portfoliosToUpdateMap.put(p.PW_Portfolio_Entity_ID__c, p);
                        }
                    }
                } 

                if (!PortfoliosToUpdate.isEmpty()) {
                    Database.update(PortfoliosToUpdate, false);
                }

                system.debug('Portfolios.size(): '+ Portfolios.size());
                // If we got a full batch, queue the next offset
                if (Portfolios.size() == LIMIT_SIZE) {
                    System.enqueueJob(new PWNightlyPortfolioUpdateMemphis(offsetVal + LIMIT_SIZE));
                }
            }

        } catch (Exception e) {
            System.debug('Callout error: ' + e.getMessage());
        }
        
        // if(PortfoliosToUpdate.isEmpty() == false){
        //     update PortfoliosToUpdate.values();
        // }
    }
}