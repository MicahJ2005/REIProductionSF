trigger ContactPhoneTrigger on Contact (before insert, before update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        ContactPhoneFormatterHandler.formatAndConsolidate(Trigger.new, Trigger.oldMap);
    }
}