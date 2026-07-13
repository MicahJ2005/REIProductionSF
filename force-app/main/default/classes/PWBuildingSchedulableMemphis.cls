global with sharing class PWBuildingSchedulableMemphis implements Schedulable {
    global void execute(SchedulableContext sc) {
        System.enqueueJob(new PWBuildingBatchJobMemphis(0)); // start with offset 0
    }
}