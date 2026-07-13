global with sharing class PWPortfolioUpdateScheduleMemphis implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Fire the batch class
        System.enqueueJob(new PWPortfolioUpdateClassMemphis());
    }
}