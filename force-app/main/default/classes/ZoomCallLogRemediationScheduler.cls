public class ZoomCallLogRemediationScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        ZoomCallLogRemediationBatch batch = new ZoomCallLogRemediationBatch();
        Database.executeBatch(batch, 200);
    }
}