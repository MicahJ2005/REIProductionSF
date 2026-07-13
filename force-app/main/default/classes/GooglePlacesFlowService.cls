public class GooglePlacesFlowService {

    public class InputWrapper {
        @InvocableVariable(required=true)
        public Id recordId;
    }

    public class OutputWrapper {
        @InvocableVariable
        public String placeId;
    }

    @InvocableMethod(label='Get Google Place ID' description='Returns Google Place ID from Account address')
    public static void getPlaceIdFromAccount(List<InputWrapper> inputs) {
        system.debug('getPlaceIdFromAccount inputs: '+ inputs);
        
        Set<Id> houseIds = new Set<Id>();
        for (InputWrapper input : inputs) {
            if(input.recordId != null) {
                houseIds.add(input.recordId);
            }
        }
        
        if(!houseIds.isEmpty()) {
            Map<Id, House__c> houseMap = new Map<Id, House__c>([SELECT Id, House_Complete_Address__c, Google_Place_ID__c FROM House__c WHERE Id IN :houseIds]);
            GooglePlacesService.getPlaceIdFromHouseRecordId(houseMap, null);
        }
    }
}