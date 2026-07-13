trigger AccountPhoneTrigger on Account (before insert, before update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        AccountPhoneFormatterHandler.formatAndConsolidate(Trigger.new, Trigger.oldMap);
    }
}