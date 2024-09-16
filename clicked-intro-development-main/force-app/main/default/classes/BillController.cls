public with sharing class BillController {
    @AuraEnabled(cacheable=true)
    public static List<Bill__c> getBills(String searchKey, Id accountId) {
        String searchFilter = '%' + searchKey + '%';
        
        String query = 'SELECT InvoiceNumber__c, Balance__c, Account__r.Name FROM Bill__c ';
        if (accountId != null) {
            query += 'WHERE Account__c = :accountId ';
        }
        
        query += 'AND (InvoiceNumber__c LIKE :searchFilter OR Account__r.Name LIKE :searchFilter)';
        
        return Database.query(query);
    }
}
