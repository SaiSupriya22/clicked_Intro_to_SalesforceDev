public with sharing class BillBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    // List to store Account IDs that need to receive bills via email
    public List<Id> receivesBillByEmail = new List<Id>();

    // Start method: Defines the query to fetch the accounts that have opted to receive bills by email
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all accounts that have Bill_By_Email__c set to true
        String query = 'SELECT Id, Bill_By_Email__c FROM Account WHERE Bill_By_Email__c = true';
        return Database.getQueryLocator(query);
    }

    // Execute method: Processes each batch of accounts
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // Iterate over the accounts in the scope to prepare a list of Account IDs for further processing
        for (Account acc : scope) {
            if (acc.Bill_By_Email__c == true) {
                receivesBillByEmail.add(acc.Id);
            }
        }
    }

    // Finish method: Executes after all batches are processed and sends emails with the latest bill PDF to each account
    public void finish(Database.BatchableContext bc) {
        // Step 1: Query for the most recent bill for each account in receivesBillByEmail
        List<Account> accountList = [
            SELECT Id, (SELECT Id FROM Bills__r ORDER BY CreatedDate DESC LIMIT 1) 
            FROM Account 
            WHERE Id IN :receivesBillByEmail
        ];

        // Step 2: Prepare Maps to hold account emails and bill PDF blobs
        Map<Id, Id> billMap = new Map<Id, Id>(); // Holds AccountId -> BillId
        Map<Id, String> emailMap = new Map<Id, String>(); // Holds AccountId -> Email

        for (Account acc : accountList) {
            if (acc.Bills__r.size() > 0) {
                // Get the most recent bill's ID and associate it with the account
                Id billId = acc.Bills__r[0].Id;
                billMap.put(acc.Id, billId);

                // Assuming Account has an Email field to send the email
                emailMap.put(acc.Id, acc.Email);
            }
        }

        // Step 3: Prepare the map to hold emails with the PDF bills
        Map<String, Blob> sendMap = new Map<String, Blob>();

        for (Id accountId : billMap.keySet()) {
            Id billId = billMap.get(accountId);
            String email = emailMap.get(accountId);

            // Step 4: Generate a PDF for the bill using Visualforce
            PageReference pageRef = new PageReference('/apex/BillVFP?id=' + billId);
            Blob pdfBlob = pageRef.getContentAsPDF();

            // Step 5: Associate the account email with the PDF Blob
            if (email != null && pdfBlob != null) {
                sendMap.put(email, pdfBlob);
            }
        }

        // Step 6: Call the BillEmailer class to send emails with the attached bills
        BillEmailer.sendEmails(sendMap);
    }
}
