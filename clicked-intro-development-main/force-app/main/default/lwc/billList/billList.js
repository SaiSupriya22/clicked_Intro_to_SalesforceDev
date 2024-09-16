import { LightningElement, wire, track } from 'lwc';
import getBills from '@salesforce/apex/BillController.getBills';
import { NavigationMixin } from 'lightning/navigation';

export default class BillList extends NavigationMixin(LightningElement) {
    @track bills = [];
    @track error;
    @track searchKey = '';
    @track isLoading = false;

    // To capture debouncing state
    searchTimeout;

    // Fetch bills from the server
    @wire(getBills, { searchKey: '$searchKey', accountId: null })
    wiredBills({ error, data }) {
        this.isLoading = true;
        if (data) {
            this.bills = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.bills = undefined;
        }
        this.isLoading = false;
    }

    // Handles input change with debouncing
    handleSearchChange(event) {
        const searchKey = event.target.value;

        // Clear the previous timeout to debounce
        clearTimeout(this.searchTimeout);

        // Set a new timeout
        this.searchTimeout = setTimeout(() => {
            this.searchKey = searchKey;
        }, 300); // 300ms debounce delay
    }

    // Navigation to Bill record page
    handleNavigateToBill(event) {
        const invoiceNumber = event.target.textContent.trim();
        const selectedBill = this.bills.find(bill => bill.InvoiceNumber__c === invoiceNumber);

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: selectedBill.Id,
                actionName: 'view'
            }
        });
    }
}
