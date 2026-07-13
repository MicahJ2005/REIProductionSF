global with sharing class PWNightlyPortfolioUpdateScheduleTexas implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Fire the batch class
        System.enqueueJob(new PWNightlyPortfolioUpdateTexas(0));
    }
}