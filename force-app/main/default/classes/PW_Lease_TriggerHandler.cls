public with sharing class PW_Lease_TriggerHandler {
   // Texas market codes
    public static final Set<String> TEXAS_MARKETS = new Set<String>{
        'DFW', 'HOU', 'SAN', 'TUL', 'OKC', 'LIT', 'AUS'
    };

    // Memphis market codes
    public static final Set<String> MEMPHIS_MARKETS = new Set<String>{
        'MEM', 'STL', 'HSV', 'BHM', 'TUS', 'JKT', 'BNA', 'WME'
    };

    public static string MemphisLeaseTextMessage = [
            SELECT TextValue__c
            FROM PropertyWare_Setting__mdt
            WHERE DeveloperName = 'MemphisLeaseTextMessage'
            LIMIT 1
        ].TextValue__c;

     public static string TexasLeaseTextMessage = [
            SELECT TextValue__c
            FROM PropertyWare_Setting__mdt
            WHERE DeveloperName = 'TexasLeaseTextMessage'
            LIMIT 1
        ].TextValue__c;
    /**
     * Runs after insert or update of PW_Lease__c records.
     */
    public static void afterInsertOrUpdate(
        List<PW_Lease__c> newLeases,
        Map<Id, PW_Lease__c> oldLeaseMap,
        Map<Id, PW_Lease__c> newLeaseMap
    ) {
        if (newLeases == null || newLeases.isEmpty()) {
            return;
        }

        // Separate insert vs update
        List<PW_Lease__c> insertedLeases = new List<PW_Lease__c>();
        List<PW_Lease__c> updatedLeases = new List<PW_Lease__c>();

        for (PW_Lease__c lease : newLeases) {
            if (oldLeaseMap == null || !oldLeaseMap.containsKey(lease.Id)) {
                insertedLeases.add(lease);
            } else {
                updatedLeases.add(lease);
            }
        }

        // Process inserts
        if (!insertedLeases.isEmpty()) {
            handleInsertedLeases(insertedLeases);
        }

        // Process updates
        if (!updatedLeases.isEmpty()) {
            handleUpdatedLeases(updatedLeases, oldLeaseMap);
        }
    }

    /**
     * Handles after insert logic for PW_Lease__c records.
     */
    private static void handleInsertedLeases(List<PW_Lease__c> leases) {
        // Collect Building Ids to query Market
        Set<Id> buildingIds = new Set<Id>();
        for (PW_Lease__c lease : leases) {
            if (lease.PW_Building__c != null) {
                buildingIds.add(lease.PW_Building__c);
            }
        }

        // Query Buildings with related House and Market
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
        // TODO: Add logic for inserts
        System.debug('Processing inserted leases: ' + leases);
        for (PW_Lease__c lease : leases) {
            String market = buildingIdToMarket.get(lease.PW_Building__c);

            if (lease.PW_Date_Renewed__c != null) {
                // System.debug('Market for Lease ' + lease.Id + ': ' + market);
                // System.debug('PW_Date_Renewed__c changed -->>> FIRE THE LAZER');
                if(TEXAS_MARKETS.contains(market)){
                    System.debug('TEXAS MARKET -->>> for Lease ' + lease.Id + ': ' + market);
                    PropertyWareLeaseAPITexasSMS.callLeaseAPI(lease.PW_Lease_Entity_ID__c, TexasLeaseTextMessage);

                    // TwilioSMSService.sendSingleSMS('763-333-5159', 'We’re so grateful you renewed your lease! It is a pleasure having you as part of the PPMG of Texas family, and we look forward to serving you for many years to come!');
                }
                if(MEMPHIS_MARKETS.contains(market)){
                    System.debug('MEMPHIS MARKET -->>> for Lease ' + lease.Id + ': ' + market);
                    PropertyWareLeaseAPIMemphisSMS.callLeaseAPI(lease.PW_Lease_Entity_ID__c, MemphisLeaseTextMessage);
                    // TwilioSMSService.sendSingleSMS('763-333-5159', 'We’re so grateful you renewed your lease! It is a pleasure having you as part of the Premier Property Management family, and we look forward to serving you for many years to come!');
                }
            }
        }
    }

    /**
     * Handles after update logic for PW_Lease__c records.
     */
    private static void handleUpdatedLeases(
        List<PW_Lease__c> leases, 
        Map<Id, PW_Lease__c> oldLeaseMap
    ) {
        System.debug('Processing updated leases: ' + leases);

        // Collect Building Ids to query Market
        Set<Id> buildingIds = new Set<Id>();
        for (PW_Lease__c lease : leases) {
            if (lease.PW_Building__c != null) {
                buildingIds.add(lease.PW_Building__c);
            }
        }

        // Query Buildings with related House and Market
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

        // Now you can safely access Market for each Lease
        for (PW_Lease__c lease : leases) {
            String market = buildingIdToMarket.get(lease.PW_Building__c);

            if (lease.PW_Date_Renewed__c != oldLeaseMap.get(lease.Id).PW_Date_Renewed__c) {
                // System.debug('Market for Lease ' + lease.Id + ': ' + market);
                // System.debug('PW_Date_Renewed__c changed -->>> FIRE THE LAZER');
                if(TEXAS_MARKETS.contains(market)){
                    System.debug('TEXAS MARKET -->>> for Lease ' + lease.Id + ': ' + market);
                    PropertyWareLeaseAPITexasSMS.callLeaseAPI(lease.PW_Lease_Entity_ID__c, TexasLeaseTextMessage);

                    // TwilioSMSService.sendSingleSMS('763-333-5159', 'We’re so grateful you renewed your lease! It is a pleasure having you as part of the PPMG of Texas family, and we look forward to serving you for many years to come!');
                }
                if(MEMPHIS_MARKETS.contains(market)){
                    System.debug('MEMPHIS MARKET -->>> for Lease ' + lease.Id + ': ' + market);
                    PropertyWareLeaseAPIMemphisSMS.callLeaseAPI(lease.PW_Lease_Entity_ID__c, MemphisLeaseTextMessage);
                    // TwilioSMSService.sendSingleSMS('763-333-5159', 'We’re so grateful you renewed your lease! It is a pleasure having you as part of the Premier Property Management family, and we look forward to serving you for many years to come!');
                }
            }
        }
    }
}