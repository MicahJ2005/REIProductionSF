trigger LeadPhoneTrigger on Lead (before insert, before update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        LeadPhoneFormatterHandler.formatAndConsolidate(Trigger.new, Trigger.oldMap);
    }
}