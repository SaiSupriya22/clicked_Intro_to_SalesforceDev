public with sharing class BillScheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        BillBatch bb = new BillBatch();
        Database.executeBatch(bb);

        String cronExpression = '0 0 12 * * ?'; // This cron expression will schedule the batch to run every day at 12 PM.
BillScheduler scheduler = new BillScheduler();
System.schedule('Daily Bill Batch Job', cronExpression, scheduler);

    }
}
