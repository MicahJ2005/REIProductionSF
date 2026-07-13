global with sharing class PWNightlyPortfolioUpdateScheduleMemphis implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Fire the batch class
        System.enqueueJob(new PWNightlyPortfolioUpdateMemphis(0));
    }
}