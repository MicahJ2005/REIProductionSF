@isTest
public class ZoomCallLogRemediationSchedulerTest {
    @isTest
    static void testScheduler() {
        Test.startTest();
        String jobId = System.schedule('Test Zoom Call Log Remediation', '0 0 0 15 3 ? 2042', new ZoomCallLogRemediationScheduler());
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Job ID should not be null');
    }
}