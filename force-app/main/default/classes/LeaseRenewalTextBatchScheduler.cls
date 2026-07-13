// This class lets you schedule your LeaseRenewalTextBatch
global with sharing class LeaseRenewalTextBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Instantiate your batch
        LeaseRenewalTextBatch batch = new LeaseRenewalTextBatch();
        
        // Run the batch with a scope size (e.g., 50)
        Database.executeBatch(batch, 50);
    }
}