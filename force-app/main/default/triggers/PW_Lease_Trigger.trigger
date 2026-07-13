trigger PW_Lease_Trigger on PW_Lease__c (after insert, after update) {
    Boolean isActive = PropertyWare_Setting__mdt.getInstance('PWLeaseTrigger').PW_Lease_Trigger_Active__c;
    System.debug('PW_Lease_Trigger is active: ' + isActive);
    if(isActive == true){
        if(Trigger.isAfter && Trigger.isInsert){
            PW_Lease_TriggerHandler.afterInsertOrUpdate(Trigger.new, Trigger.oldMap, Trigger.newMap);
        }
        if(Trigger.isAfter && Trigger.isUpdate){
            PW_Lease_TriggerHandler.afterInsertOrUpdate(Trigger.new, Trigger.oldMap, Trigger.newMap);
        }
    }
}