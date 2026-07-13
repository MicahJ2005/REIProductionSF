public with sharing class BatchSObjectDeleter implements Database.Batchable<sObject>, Database.Stateful {
    private String query;
    private Integer totalDeleted = 0;
    
    public BatchSObjectDeleter(String query) {
        this.query = query;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        if (scope != null && !scope.isEmpty()) {
            try {
                totalDeleted += scope.size();
                // Safe delete ignoring error records to avoid batch lockups
                Database.delete(scope, false);
            } catch (Exception e) {
                System.debug('Error executing batch delete: ' + e.getMessage());
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch delete completed. Total records deleted: ' + totalDeleted);
    }
}