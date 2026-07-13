trigger TaskTrigger on Task (before insert, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            TaskTriggerHandler.routeOrphanedZoomCalls(Trigger.new);
        }
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
           TaskTriggerHandler.assignTaskToLeadOwner(Trigger.new);
        } 
    }
}