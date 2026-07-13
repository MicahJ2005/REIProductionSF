public class TaskTriggerHandler { 
    public static void assignTaskToLeadOwner(List<Task> taskList){
        EmailTemplate et = [SELECT Id,Subject,HtmlValue,Body FROM EmailTemplate WHERE DeveloperName = 'Lead_Intro_1_to_1'];
        Set<id> leadIdSet = new Set<id>();
        Set<id> UserIdSet = new Set<id>();
        List<Task> taskListqueried = new List<Task>();
        Set<String> fromAddSet = new Set<String>();
        Map<Id,User> userIdVsUserMap = new Map<Id,User>();
        Map<String,Id> fromAddVsIdMap = new Map<String,Id>();
        List<Task> taskListToUpdate = new List<Task>();
        Set<Id> leadIds = new Set<Id>();
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        for(Task tsk : [SELECT id,WhoId,Subject,Owner.Name,OwnerId,Owner.Id,Owner.Email,Description, CreatedById,CreatedBy.Name,LastModifiedById, CreatedDate , LastModifiedDate  FROM Task WHERE ID IN : taskList]){
            // Added 10/11/22 - All new tasks related to Leads
           	if(tsk.WhoId != null && String.valueOf(tsk.WhoId).startsWith('00Q') && tsk.CreatedBy.Name == 'Hubspot Admin'){
                leadIds.add(tsk.WhoId);
            }
            //
            if(tsk.WhoId != null 
               && (String.valueOf(tsk.whoId).startsWith('00Q') || String.valueOf(tsk.whoId).startsWith('003')) 
               && String.isNotBlank(tsk.Subject) 
               && tsk.Subject.indexOf('One To One') != -1
               //  && tsk.Owner.Name =='Hubspot Admin'
               && tsk.CreatedById== tsk.LastModifiedById
               && tsk.CreatedDate == tsk.LastModifiedDate
              ){
                  if(tsk.WhoId != null){
                      leadIdSet.add(tsk.WhoId);
                  }
              }   
        }
        
        List<Lead> leadsToUpdate = new List<Lead>(); // 10/11/22 - Update Lead status to Open
        for(Lead lead : [SELECT Id, CreatedBy.Name, Status FROM Lead WHERE Id IN :leadIds 
                         	AND Status = 'Nurturing']){
            lead.Status = 'Open';
            leadsToUpdate.add(lead);
        }
        update leadsToUpdate;
        
        if(leadIdSet.size() > 0){
            Map<id,id> leadOwnerMap = new Map<id,id>();
            for(Lead ld : [SELECT Id,OwnerId FROM Lead WHERE Id IN : leadIdSet]){
                if(!leadOwnerMap.containsKey(ld.id)){
                    leadOwnerMap.put(ld.id,ld.OwnerId);
                }
            }
            
            List<Task> updateTaskList = new List<Task>();
            for(Task tsk : taskList){
                if(tsk.WhoId != null 
                   && (String.valueOf(tsk.whoId).startsWith('00Q') || String.valueOf(tsk.whoId).startsWith('003')) 
                   && String.isNotBlank(tsk.Subject) 
                   && tsk.Subject.indexOf('One To One') != -1
                   && tsk.CreatedById== tsk.LastModifiedById
                   && tsk.CreatedDate == tsk.LastModifiedDate
                  ){
                      Task newTask = new Task();
                      newTask.id =  tsk.id;
                      newTask.Status = 'Not Started';
                      newTask.Priority = 'High';
                      if(leadOwnerMap.containsKey(tsk.WhoId))
                      {
                          newTask.OwnerId = leadOwnerMap.get(tsk.WhoId);
                      }
                      updateTaskList.add(newTask);
                  }       
            }
            if(updateTaskList.size() > 0)
            {
                update updateTaskList;
            }
            
        }
        for(Task tsk : [SELECT id,WhoId,Subject,Owner.Name,OwnerId,owner.Email,Description,CreatedById,CreatedBy.Name,LastModifiedById, CreatedDate , LastModifiedDate  FROM Task WHERE ID IN : taskList]){
            UserIdSet.add(tsk.OwnerId);
            taskListqueried.add(tsk);
            if(tsk.WhoId != null 
               && String.valueOf(tsk.whoId).startsWith('00Q') && tsk.Subject.contains('One To One')  
               && tsk.Description != null && tsk.CreatedBy.Name == 'Hubspot Admin' )  //&& tsk.Subject == 'Submitted Form \'One To One Session Registrations\''
            {
                fromAddSet.add(tsk.Owner.Email);
                Task taskNew = new Task();
                taskNew.Id = tsk.Id;
                taskNew.Priority = 'High';
                taskListToUpdate.add(taskNew);
            }
        }
        for(User u : [select id,Time_Trade_Link__c,Full_Name__c,Sig2__c from user where Id IN:UserIdSet]){
            userIdVsUserMap.put(u.id,u);
        }
        OrgWideEmailAddress orgEmail = [select Id, DisplayName, Address from OrgWideEmailAddress where DisplayName = 'Portfolio Advisor'];
        List<EmailMessageRelation> emrList = new List<EmailMessageRelation>();
        List<EmailMessage> emailHistories = new List<EmailMessage>();
        
        //List<Task> tskList = new List<Task>();
        Map<Id, String> leadIdToToAddressMap = new Map<Id, String>();
        Map<Id, List<EmailMessage>> leadIdToEmailMessageMap = new Map<Id, List<EmailMessage>>();
        for(Task tsk : [SELECT id,WhoId,Subject,Owner.Name,OwnerId,owner.Email,Description, CreatedById,CreatedBy.Name,LastModifiedById, CreatedDate , LastModifiedDate  FROM Task WHERE ID IN : taskListqueried]){
            System.debug('Task Description ==> '+tsk.Description);
            if(tsk.WhoId != null 
               && String.valueOf(tsk.whoId).startsWith('00Q') &&  tsk.Subject.contains('One To One')
               && tsk.Description != null && tsk.CreatedBy.Name == 'Hubspot Admin') {  // 
                   system.debug('OwnerId   '+tsk.OwnerId);
                   System.debug('Task Description inside condition ==> '+tsk.Description);
                   if((tsk.Description.split('\n'))[3].contains('address: ')){
                       if((tsk.Description.split('\n'))[3].split('address: ').size() > 1 ){
                           Id leadId = tsk.WhoId;
                           String toEmail = (tsk.Description.split('\n'))[3].split('address: ')[1];
                           string htmlbody = et.HtmlValue;
                           String[] ccAddresses = new String[]{tsk.Owner.Email};
                               String[] toAddresses = new String[]{toEmail};
                                   if(userIdVsUserMap.containsKey(tsk.ownerId)){
                                       if(userIdVsUserMap.get(tsk.ownerId).Time_Trade_Link__c != null){
                                           htmlbody = htmlbody.replace('{!User.Time_Trade_Link__c}', userIdVsUserMap.get(tsk.ownerId).Time_Trade_Link__c);
                                       }else{
                                           htmlbody = htmlbody.replace('{!User.Time_Trade_Link__c}', 'inform us');
                                       }
                                       if(userIdVsUserMap.get(tsk.ownerId).Full_Name__c != null){
                                           htmlbody = htmlbody.replace('{!User.Full_Name__c}', userIdVsUserMap.get(tsk.ownerId).Full_Name__c);
                                       }
                                       if(userIdVsUserMap.get(tsk.ownerId).Sig2__c != null){
                                           htmlbody = htmlbody.replace('{!User.Sig2__c}', userIdVsUserMap.get(tsk.ownerId).Sig2__c);
                                       }else{
                                           htmlbody = htmlbody.replace('{!User.Sig2__c}', '');
                                       }
                                       //
                                       if(leadId != null){
                                           htmlbody = htmlbody.replace('{!Lead.Id}', leadId);
                                       }else{
                                           htmlbody = htmlbody.replace('{!Lead.Id}', '');
                                       }
                                       //
                                   }
                           
                           Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
                           //mail.setTemplateID(et.Id);  
                           mail.setSubject(et.Subject + ' EST');
                           System.debug('htmlbody' +htmlbody);
                           System.debug('To Address '+toAddresses);
                           System.debug('CC Address '+ccAddresses);
                           mail.setReplyTo('hubspottaskemailservice@5-59mrjbl6dghzlve6ts2lk8afedsxiz6asuc3i2fwbfm02z7tu.3-pfxleai.na138.apex.salesforce.com');
                           //  mail.setReplyTo('hubspottaskemailservice@o-2xv6vzsufhqhsv7zi6qsze8fl8eewesjsv50g26s55fj63x3b3.01-8l3reaq.cs194.apex.sandbox.salesforce.com');
                           mail.setOrgWideEmailAddressId(orgEmail.Id);
                           mail.setToAddresses(toAddresses);
                           mail.setCcAddresses(ccAddresses);
                           mail.setHtmlBody(htmlbody);  
                           mail.setSaveAsActivity(false);
                           allmsg.add(mail);
                           EmailMessage emailMsg = new EmailMessage(
                               MessageDate = Datetime.now(),
                               Status = '3',
                               FromAddress = orgEmail.Address,
                               FromName = orgEmail.DisplayName,
                               ToAddress = toAddresses[0],
                               CcAddress = ccAddresses[0],
                               Subject = et.Subject,
                               HtmlBody = htmlbody
                           );
                           
                           emailHistories.add(emailMsg);
                           List<EmailMessage> emailMsgList = (leadIdToEmailMessageMap.containsKey(leadId)) ? leadIdToEmailMessageMap.get(leadId) : new List<EmailMessage>();
                           emailMsgList.add(emailMsg);
                           leadIdToEmailMessageMap.put(leadId, emailMsgList);
                           leadIdToToAddressMap.put(leadId, toAddresses[0]);
                       }                   
                   }else{
                       if((tsk.Description.split('\n'))[3].split('Address: ').size() > 1 ){
                           Id leadId = tsk.WhoId;
                           String toEmail = (tsk.Description.split('\n'))[3].split('Address: ')[1];
                           string htmlbody = et.HtmlValue;
                           String[] ccAddresses = new String[]{tsk.Owner.Email};
                               String[] toAddresses = new String[]{toEmail};
                                   if(userIdVsUserMap.containsKey(tsk.ownerId)){
                                       if(userIdVsUserMap.get(tsk.ownerId).Time_Trade_Link__c != null){
                                           htmlbody = htmlbody.replace('{!User.Time_Trade_Link__c}', userIdVsUserMap.get(tsk.ownerId).Time_Trade_Link__c);
                                       }else{
                                           htmlbody = htmlbody.replace('{!User.Time_Trade_Link__c}', 'inform us');
                                       }
                                       if(userIdVsUserMap.get(tsk.ownerId).Full_Name__c != null){
                                           htmlbody = htmlbody.replace('{!User.Full_Name__c}', userIdVsUserMap.get(tsk.ownerId).Full_Name__c);
                                       }
                                       if(userIdVsUserMap.get(tsk.ownerId).Sig2__c != null){
                                           htmlbody = htmlbody.replace('{!User.Sig2__c}', userIdVsUserMap.get(tsk.ownerId).Sig2__c);
                                       }else{
                                           htmlbody = htmlbody.replace('{!User.Sig2__c}', '');
                                       }
                                       //
                                       if(leadId != null){
                                           htmlbody = htmlbody.replace('{!Lead.Id}', leadId);
                                       }else{
                                           htmlbody = htmlbody.replace('{!Lead.Id}', '');
                                       }
                                       //
                                   }
                           
                           Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
                           //mail.setTemplateID(et.Id);  
                           mail.setSubject(et.Subject + ' EST');
                           System.debug('htmlbody' +htmlbody);
                           System.debug('To Address '+toAddresses);
                           System.debug('CC Address '+ccAddresses);
                           mail.setReplyTo('hubspottaskemailservice@5-59mrjbl6dghzlve6ts2lk8afedsxiz6asuc3i2fwbfm02z7tu.3-pfxleai.na138.apex.salesforce.com');
                           //  mail.setReplyTo('hubspottaskemailservice@o-2xv6vzsufhqhsv7zi6qsze8fl8eewesjsv50g26s55fj63x3b3.01-8l3reaq.cs194.apex.sandbox.salesforce.com');
                           mail.setOrgWideEmailAddressId(orgEmail.Id);
                           mail.setToAddresses(toAddresses);
                           mail.setCcAddresses(ccAddresses);
                           mail.setHtmlBody(htmlbody);  
                           mail.setSaveAsActivity(false);
                           allmsg.add(mail);
                           EmailMessage emailMsg = new EmailMessage(
                               MessageDate = Datetime.now(),
                               Status = '3',
                               FromAddress = orgEmail.Address,
                               FromName = orgEmail.DisplayName,
                               ToAddress = toAddresses[0],
                               CcAddress = ccAddresses[0],
                               Subject = et.Subject,
                               HtmlBody = htmlbody
                           );
                           
                           emailHistories.add(emailMsg);
                           List<EmailMessage> emailMsgList = (leadIdToEmailMessageMap.containsKey(leadId)) ? leadIdToEmailMessageMap.get(leadId) : new List<EmailMessage>();
                           emailMsgList.add(emailMsg);
                           leadIdToEmailMessageMap.put(leadId, emailMsgList);
                           leadIdToToAddressMap.put(leadId, toAddresses[0]);
                       } 
                   }
               }
            
        }
        if(!Test.isRunningTest()){
            Messaging.SendEmailResult[] r = Messaging.sendEmail(allmsg);
            system.debug('mail send results'+ r);
        }        
        //insert email history entries
        if(!emailHistories.isEmpty()){
            insert emailHistories;
        }
        if(!taskListToUpdate.isEmpty()){
            update taskListToUpdate;
        }
        System.debug('emailHistories:\n' + emailHistories);
        
        List<EmailMessageRelation> emailMsgRelation = new List<EmailMessageRelation>();
        for(Id leadId : leadIdToEmailMessageMap.keySet()) {
            for(EmailMessage msg : leadIdToEmailMessageMap.get(leadId)) {
                emailMsgRelation.add(new EmailMessageRelation(
                    emailMessageId = msg.Id,
                    relationId = leadId,
                    relationType = 'ToAddress',
                    RelationAddress = leadIdToToAddressMap.get(leadId)
                ));
            }
        }
        System.debug('emailMsgRelation:\n' + emailMsgRelation);
        if(!emailMsgRelation.isEmpty()) {
            insert emailMsgRelation;
        }
    }
    public static void routeOrphanedZoomCalls(List<Task> newTasks) {
        Set<String> phonePatterns = new Set<String>();
        
        for (Task t : newTasks) {
            if (t.WhoId == null && t.WhatId == null && t.Subject != null && 
                (t.TaskSubtype == 'Call' || t.Subject.containsIgnoreCase('Call') || t.Subject.containsIgnoreCase('SMS') || t.Subject.containsIgnoreCase('Text') || t.Subject.containsIgnoreCase('Zoom') || t.Subject.containsIgnoreCase('Message'))) {
                
                Matcher m = Pattern.compile('(?i)(from|to|and|,)\\s*\\+?1?(\\d{10})').matcher(t.Subject);
                if (m.find()) {
                    String p = m.group(2);
                    String searchStr = '%' + p.substring(0,3) + '%' + p.substring(3,6) + '%' + p.substring(6) + '%';
                    phonePatterns.add(searchStr);
                }
            }
        }
        
        if (phonePatterns.isEmpty()) return;

        List<Contact> allMatchedContacts = [SELECT Id, AccountId, Is_Primary__c, MobilePhone, Phone FROM Contact WHERE MobilePhone LIKE :phonePatterns OR Phone LIKE :phonePatterns];
        List<Lead> allMatchedLeads = [SELECT Id, MobilePhone, Phone FROM Lead WHERE MobilePhone LIKE :phonePatterns OR Phone LIKE :phonePatterns];
        List<Account> allMatchedAccounts = [SELECT Id, Phone FROM Account WHERE Phone LIKE :phonePatterns];
        
        for (Task t : newTasks) {
            if (t.WhoId == null && t.WhatId == null && t.Subject != null && 
                (t.TaskSubtype == 'Call' || t.Subject.containsIgnoreCase('Call') || t.Subject.containsIgnoreCase('SMS') || t.Subject.containsIgnoreCase('Text') || t.Subject.containsIgnoreCase('Zoom') || t.Subject.containsIgnoreCase('Message'))) {
                
                Matcher m = Pattern.compile('(?i)(from|to|and|,)\\s*\\+?1?(\\d{10})').matcher(t.Subject);
                if (!m.find()) continue;
                String p = m.group(2);

                List<Contact> foundC = new List<Contact>();
                for (Contact c : allMatchedContacts) {
                    if ((c.MobilePhone != null && c.MobilePhone.replaceAll('\\D','') != null && c.MobilePhone.replaceAll('\\D','').contains(p)) || 
                        (c.Phone != null && c.Phone.replaceAll('\\D','') != null && c.Phone.replaceAll('\\D','').contains(p))) {
                        foundC.add(c);
                    }
                }
                
                List<Lead> foundL = new List<Lead>();
                for (Lead l : allMatchedLeads) {
                    if ((l.MobilePhone != null && l.MobilePhone.replaceAll('\\D','') != null && l.MobilePhone.replaceAll('\\D','').contains(p)) || 
                        (l.Phone != null && l.Phone.replaceAll('\\D','') != null && l.Phone.replaceAll('\\D','').contains(p))) {
                        foundL.add(l);
                    }
                }

                List<Account> foundA = new List<Account>();
                for (Account a : allMatchedAccounts) {
                    if (a.Phone != null && a.Phone.replaceAll('\\D','') != null && a.Phone.replaceAll('\\D','').contains(p)) {
                        foundA.add(a);
                    }
                }

                // 1. Single Contact Rule
                if (foundC.size() == 1) {
                    t.WhoId = foundC[0].Id;
                    t.WhatId = foundC[0].AccountId;
                    continue;
                }

                // 2. Check Primary Contact Rule
                if (foundC.size() > 1) {
                    Set<Id> accIds = new Set<Id>();
                    Integer primaryCount = 0;
                    Contact primaryContact = null;
                    
                    for (Contact c : foundC) {
                        if (c.AccountId != null) {
                            accIds.add(c.AccountId);
                        }
                        if (c.Is_Primary__c) {
                            primaryCount++;
                            primaryContact = c;
                        }
                    }
                    
                    if (accIds.size() <= 1) {
                        Id accId = accIds.isEmpty() ? null : new List<Id>(accIds)[0];
                        if (accId != null) {
                            t.WhatId = accId;
                        }
                        if (primaryCount == 1) {
                            t.WhoId = primaryContact.Id;
                        } else {
                            t.WhoId = foundC[0].Id;
                        }
                        continue;
                    }
                }
                
                // 3. Lead Fallback
                if (!foundL.isEmpty()) {
                    t.WhoId = foundL[0].Id;
                    continue;
                }
                
                // 4. Account Fallback
                if (!foundA.isEmpty()) {
                    t.WhatId = foundA[0].Id;
                    continue;
                }
            }
        }
    }
}