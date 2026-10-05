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
        // Account activity-date stamping deliberately does NOT run here.
        //
        // On 2026-08-10 a QueryException in TaskAccountStampHandler rolled back the
        // transaction it was running in, which destroyed twelve Zoom call logs that the
        // ZVC package was inserting -- twelve real customer calls with no record left.
        // A try/catch was added, but that is not enough on its own: governor
        // LimitExceptions (CPU time, DML rows) cannot be caught, so any code in this
        // trigger can still take down someone else's save.
        //
        // These dates are derived data. They are recomputable from Task at any time and
        // nothing is lost if they are stale, so they must not sit in the save path of the
        // record they are derived from. They are maintained outside this transaction.
    }
}