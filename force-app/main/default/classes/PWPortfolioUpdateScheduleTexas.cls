global with sharing class PWPortfolioUpdateScheduleTexas implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Fire the batch class
        System.enqueueJob(new PWPortfolioUpdateClassTexas());
    }
}