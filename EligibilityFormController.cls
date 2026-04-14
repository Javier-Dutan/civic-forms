/**
 * EligibilityFormController.cls
 * Apex controller for USDS Basic Requirements Form
 * Records eligibility responses and routes to ApplicationForm if eligible
 */
public with sharing class EligibilityFormController {

    // Form field values
    public String citizenship { get; set; }
    public String location { get; set; }
    public String compensation { get; set; }
    public String background { get; set; }
    public String drugtest { get; set; }
    public String commitment { get; set; }
    public String captchaInput { get; set; }

    // Lead record
    public Lead lead { get; set; }

    // Constructor
    public EligibilityFormController() {
        lead = new Lead();
    }

    /**
     * Submit form action
     * Creates Lead record and redirects based on eligibility
     */
    public PageReference submitForm() {
        try {
            // Determine eligibility based on hard requirements
            // Hard requirements: citizenship, location, background, drugtest
            // Soft requirements (warnings only): compensation, commitment
            Boolean isEligible = (
                citizenship == 'yes' &&
                location == 'yes' &&
                background == 'yes' &&
                drugtest == 'yes'
            );

            // Create Lead record to track all submissions
            Lead newLead = new Lead(
                LastName = 'Applicant - ' + DateTime.now().format(),
                Company = 'Digital Service Application',
                LeadSource = 'Eligibility Form',
                Status = isEligible ? 'Eligible' : 'Not Eligible',
                Citizenship__c = citizenship,
                Location__c = location,
                Compensation__c = compensation,
                Background__c = background,
                Drug_Test__c = drugtest,
                Commitment__c = commitment,
                Is_Eligible__c = isEligible
            );

            insert newLead;

            // Always redirect to ApplicationForm - no rejection
            PageReference appForm = new PageReference('/apex/ApplicationForm');
            appForm.getParameters().put('leadId', newLead.Id);
            appForm.setRedirect(true);
            return appForm;

        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'An error occurred: ' + e.getMessage()
            ));
            return null;
        }
    }
}
