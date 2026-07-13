public with sharing class LeaseRenewalTextBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    // Texas market codes
    public static final Set<String> TEXAS_MARKETS = new Set<String>{
        'DFW', 'HOU', 'SAN', 'TUL', 'OKC', 'LIT', 'AUS'
    };

    // Memphis market codes
    public static final Set<String> MEMPHIS_MARKETS = new Set<String>{
        'MEM', 'STL', 'HSV', 'BHM', 'TUS', 'JKT', 'BNA', 'WME'
    };

    public static String MemphisLeaseTextMessage = [
        SELECT TextValue__c
        FROM PropertyWare_Setting__mdt
        WHERE DeveloperName = 'MemphisLeaseTextMessage'
        LIMIT 1
    ].TextValue__c;

    public static String TexasLeaseTextMessage = [
        SELECT TextValue__c
        FROM PropertyWare_Setting__mdt
        WHERE DeveloperName = 'TexasLeaseTextMessage'
        LIMIT 1
    ].TextValue__c;

    public static final String FROM_PHONE = '+19016757764'; // Your Twilio phone number
    public static final String ACCOUNT_SID = 'AC16db9f7fbd1d72e89545f9f32b28e2c0';

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Name, PW_Building__r.PW_Portfolio__r.PW_Org__c, PW_Building__c,' +
            'PW_Date_Renewed__c, Send_Lease_Renewal_Text__c, Primary_Contact_Mobile__c ' +
            'FROM PW_Lease__c ' +
            'WHERE Send_Lease_Renewal_Text__c = true AND Primary_Contact_Mobile__c != null'
        );
    }

    public void execute(Database.BatchableContext bc, List<PW_Lease__c> scope) {
        Set<Id> buildingIds = new Set<Id>();
        for (PW_Lease__c lease : scope) {
            if (lease.PW_Building__c != null) {
                buildingIds.add(lease.PW_Building__c);
            }
        }

        // Map Building → Market
        Map<Id, String> buildingIdToMarket = new Map<Id, String>();
        if (!buildingIds.isEmpty()) {
            for (PW_Building__c building : [
                SELECT Id, House__r.Market__c
                FROM PW_Building__c
                WHERE Id IN :buildingIds
            ]) {
                buildingIdToMarket.put(building.Id, building.House__r.Market__c);
            }
        }

        
        List<PW_Lease__c> leasesToUpdate = new List<PW_Lease__c>();

        for (PW_Lease__c lease : scope) {
            system.debug('Processing lease: ' + lease);
            try {
                String market = buildingIdToMarket.get(lease.PW_Building__c);
                system.debug('market: ' + market);
                String phoneNumber = lease.Primary_Contact_Mobile__c;
                String messageBody;

                if (TEXAS_MARKETS.contains(market)) {
                    // phoneNumber = lease.Primary_Contact_Mobile__c;
                    messageBody = TexasLeaseTextMessage;
                }
                if (MEMPHIS_MARKETS.contains(market)) {
                    // phoneNumber = lease.Primary_Contact_Mobile__c;
                    messageBody = MemphisLeaseTextMessage;
                }

                if (String.isNotBlank(phoneNumber) && String.isNotBlank(messageBody)) {
                    String endpoint = '/2010-04-01/Accounts/' + ACCOUNT_SID + '/Messages.json';
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint('callout:Twilio_API' + endpoint);
                    req.setMethod('POST');
                    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

                    String body = 'To=' + EncodingUtil.urlEncode(phoneNumber, 'UTF-8') +
                                  '&From=' + EncodingUtil.urlEncode(FROM_PHONE, 'UTF-8') +
                                  '&Body=' + EncodingUtil.urlEncode(messageBody, 'UTF-8');
                    req.setBody(body);

                    Http http = new Http();
                    HttpResponse res = http.send(req);
                    System.debug('Twilio SMS Response for ' + phoneNumber + ': ' + res.getBody());
                }

                // Mark flag as false
                lease.Send_Lease_Renewal_Text__c = false;
                leasesToUpdate.add(lease);

            } catch (Exception e) {
                System.debug('Error processing lease ' + lease.Id + ': ' + e.getMessage());
            }
        }

        if (!leasesToUpdate.isEmpty()) {
            update leasesToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Lease Renewal Text Batch finished.');
    }
}