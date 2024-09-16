public with sharing class BillAPI {
    public static void getBills() {
        // Step 1: Create HttpRequest and Http objects
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        HttpResponse res;

        // Set the endpoint and HTTP method
        req.setEndpoint('https://my-json-server.typicode.com/walters954/clicked-intro-development-server/bills');
        req.setMethod('GET');

        try {
            // Send the request and get the response
            res = http.send(req);
            String responseBody = res.getBody();

            // Step 2: Deserialize the JSON response
            List<BillWrapper> bwList = (List<BillWrapper>)JSON.deserialize(responseBody, List<BillWrapper>.class);

            // Step 3: Prepare a list to hold new Bill__c records
            List<Bill__c> billsToInsert = new List<Bill__c>();

            // Step 4: Query for active accounts
            Map<String, Id> accountNameToIdMap = new Map<String, Id>();
            for (Account acc : [SELECT Id, Name FROM Account WHERE Active__c = 'Yes']) {
                accountNameToIdMap.put(acc.Name, acc.Id);
            }

            // Step 5: Iterate over the BillWrapper objects
            for (BillWrapper bw : bwList) {
                if (accountNameToIdMap.containsKey(bw.accountName)) {
                    Bill__c newBill = new Bill__c();
                    newBill.BillId__c = bw.billId;
                    newBill.Account__c = accountNameToIdMap.get(bw.accountName);
                    newBill.Balance__c = Decimal.valueOf(bw.balance.replace('$', '')); // Convert balance to decimal

                    // Add to the list of records to insert
                    billsToInsert.add(newBill);
                }
            }

            // Step 6: Insert the Bill__c records
            if (!billsToInsert.isEmpty()) {
                insert billsToInsert;
            }
        } catch (Exception e) {
            // Handle exceptions
            System.debug('Error in BillAPI.getBills: ' + e.getMessage());
        }
    }

    // Wrapper class to match JSON structure
    public class BillWrapper {
        public String billId;
        public String accountName;
        public String balance;
    }
}
