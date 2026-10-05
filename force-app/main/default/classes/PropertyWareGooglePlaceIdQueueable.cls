// Chained follow-up to PropertyWareAPIUtility.resolveGooglePlaceIds when a run can't resolve
// every pending Google Place ID under the per-transaction callout limit. Carries the still-open
// work forward instead of letting those buildings get skipped; re-chains itself again if a fresh
// burst still can't all fit under the limit.
public with sharing class PropertyWareGooglePlaceIdQueueable implements Queueable, Database.AllowsCallouts {

    private Map<String, PropertyWareAPIUtility.PWBuildingWrapper> buildings;
    private Set<String> pendingIds;
    private PW_Portfolio__c defaultPortfolio;
    private House__c defaultHouse;
    private PropertyWare_Setting__mdt pwCreds;

    public PropertyWareGooglePlaceIdQueueable(Map<String, PropertyWareAPIUtility.PWBuildingWrapper> buildings,
                                               Set<String> pendingIds,
                                               PW_Portfolio__c defaultPortfolio,
                                               House__c defaultHouse,
                                               PropertyWare_Setting__mdt pwCreds) {
        this.buildings = buildings;
        this.pendingIds = pendingIds;
        this.defaultPortfolio = defaultPortfolio;
        this.defaultHouse = defaultHouse;
        this.pwCreds = pwCreds;
    }

    public void execute(QueueableContext ctx) {
        PropertyWareAPIUtility.resolveGooglePlaceIds(buildings, pendingIds, defaultPortfolio, defaultHouse, pwCreds);
    }
}