global with sharing class PWBuildingSchedulableTexas implements Schedulable {
    global void execute(SchedulableContext sc) {
        System.enqueueJob(new PWBuildingBatchJobTexas(0)); // start with offset 0
    }
}