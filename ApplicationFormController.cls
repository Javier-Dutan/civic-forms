/**
 * Controller for USDS Application Form
 * Record Type: USDS Lead
 * Handles cascading Role -> Category -> Skills selection using SelectableItem wrappers
 */
public with sharing class ApplicationFormController {

    /**
     * Wrapper class for selectable chip items (categories and skills)
     */
    public class SelectableItem {
        public String name { get; set; }
        public Boolean selected { get; set; }

        public SelectableItem(String name, Boolean selected) {
            this.name = name;
            this.selected = selected;
        }
    }

    // Contact fields
    public String firstName { get; set; }
    public String lastName { get; set; }
    public String email { get; set; }
    public String phone { get; set; }
    public String linkedIn { get; set; }
    public String currentLocation { get; set; }
    public Date earliestStartDate { get; set; }

    // Eligibility fields
    public String isCitizen { get; set; }
    public String canWorkInDC { get; set; }
    public String acceptsCompensation { get; set; }
    public String canPassBackground { get; set; }
    public String canPassDrugTest { get; set; }
    public String commitmentLength { get; set; }

    // Role & Skills fields (maps to USDS Lead record type)
    public String selectedRole { get; set; }           // WF_Role_Type__c
    public List<SelectableItem> categoryItems { get; set; }
    public List<SelectableItem> skillItems { get; set; }

    // Experience fields
    public String yearsOfExperience { get; set; }
    public String targetLevel { get; set; }
    public String securityClearance { get; set; }
    public String hasClearance { get; set; }
    public String previousFedEmployee { get; set; }

    // Resume & Additional fields
    public Blob resume { get; set; }
    public String resumeContentType { get; set; }
    public String resumeFileName { get; set; }
    public String portfolioUrl { get; set; }
    public String whyUsds { get; set; }
    public String howDidYouHear { get; set; }

    // UI State
    public String activeSection { get; set; }

    // Skills data structure
    private Map<String, Map<String, List<String>>> skillsData;

    public ApplicationFormController() {
        initializeSkillsData();
        categoryItems = new List<SelectableItem>();
        skillItems = new List<SelectableItem>();
        activeSection = 'contact';
    }

    /**
     * Returns list of all available roles for the picklist
     */
    public List<SelectOption> getRoleOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', 'Select a role...'));
        options.add(new SelectOption('Engineering', 'Engineering'));
        options.add(new SelectOption('Data Science', 'Data Science'));
        options.add(new SelectOption('AI and Machine Learning', 'AI and Machine Learning'));
        options.add(new SelectOption('Product', 'Product'));
        options.add(new SelectOption('Marketing', 'Marketing'));
        options.add(new SelectOption('Design', 'Design'));
        options.add(new SelectOption('Talent', 'Talent'));
        options.add(new SelectOption('Legal', 'Legal'));
        options.add(new SelectOption('Executive', 'Executive'));
        options.add(new SelectOption('Procurement', 'Procurement'));
        options.add(new SelectOption('Finance', 'Finance'));
        options.add(new SelectOption('Cybersecurity', 'Cybersecurity'));
        options.add(new SelectOption('Operations', 'Operations'));
        options.add(new SelectOption('Communications', 'Communications'));
        options.add(new SelectOption('Policy', 'Policy'));
        return options;
    }

    /**
     * Called when role selection changes - updates available categories
     */
    public void onRoleChange() {
        categoryItems = new List<SelectableItem>();
        skillItems = new List<SelectableItem>();

        if (String.isNotBlank(selectedRole) && skillsData.containsKey(selectedRole)) {
            List<String> categories = new List<String>(skillsData.get(selectedRole).keySet());
            categories.sort();
            for (String cat : categories) {
                categoryItems.add(new SelectableItem(cat, false));
            }
        }
    }

    /**
     * Toggle a category selection via chip click
     */
    public void toggleCategory() {
        String catName = ApexPages.currentPage().getParameters().get('catName');
        if (String.isBlank(catName)) return;

        for (SelectableItem item : categoryItems) {
            if (item.name == catName) {
                item.selected = !item.selected;
                break;
            }
        }

        refreshSkills();
    }

    /**
     * Rebuild skill items based on currently selected categories,
     * preserving previously selected skill state
     */
    private void refreshSkills() {
        Set<String> selectedCats = new Set<String>();
        for (SelectableItem item : categoryItems) {
            if (item.selected) {
                selectedCats.add(item.name);
            }
        }

        // Preserve previously selected skills
        Set<String> previouslySelected = new Set<String>();
        for (SelectableItem item : skillItems) {
            if (item.selected) {
                previouslySelected.add(item.name);
            }
        }

        // Build new skill items from selected categories (deduplicated)
        Set<String> addedSkills = new Set<String>();
        skillItems = new List<SelectableItem>();

        if (String.isNotBlank(selectedRole) && skillsData.containsKey(selectedRole)) {
            Map<String, List<String>> categoryMap = skillsData.get(selectedRole);
            for (String cat : selectedCats) {
                if (categoryMap.containsKey(cat)) {
                    for (String skill : categoryMap.get(cat)) {
                        if (!addedSkills.contains(skill)) {
                            addedSkills.add(skill);
                            skillItems.add(new SelectableItem(skill, previouslySelected.contains(skill)));
                        }
                    }
                }
            }
        }
    }

    /**
     * Toggle a skill selection via chip click
     */
    public void toggleSkill() {
        String skillName = ApexPages.currentPage().getParameters().get('skillName');
        if (String.isBlank(skillName)) return;

        for (SelectableItem item : skillItems) {
            if (item.name == skillName) {
                item.selected = !item.selected;
                break;
            }
        }
    }

    /**
     * Set active accordion section
     */
    public void setSection() {
        String section = ApexPages.currentPage().getParameters().get('section');
        if (String.isNotBlank(section)) {
            activeSection = section;
        }
    }

    /**
     * Years of experience options
     */
    public List<SelectOption> getYearsOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', 'Select range...'));
        options.add(new SelectOption('0-2', '0-2 years'));
        options.add(new SelectOption('3-5', '3-5 years'));
        options.add(new SelectOption('6-10', '6-10 years'));
        options.add(new SelectOption('11-15', '11-15 years'));
        options.add(new SelectOption('15+', '15+ years'));
        return options;
    }

    /**
     * Target level options
     */
    public List<SelectOption> getLevelOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', 'Select level...'));
        options.add(new SelectOption('IC', 'Individual Contributor'));
        options.add(new SelectOption('Senior IC', 'Senior Individual Contributor'));
        options.add(new SelectOption('Lead', 'Lead / Principal'));
        options.add(new SelectOption('Manager', 'Manager'));
        options.add(new SelectOption('Director', 'Director'));
        options.add(new SelectOption('Executive', 'Executive'));
        return options;
    }

    /**
     * Security clearance options
     */
    public List<SelectOption> getClearanceOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('None', 'No clearance'));
        options.add(new SelectOption('Public Trust', 'Public Trust'));
        options.add(new SelectOption('Secret', 'Secret'));
        options.add(new SelectOption('Top Secret', 'Top Secret'));
        options.add(new SelectOption('TS/SCI', 'TS/SCI'));
        return options;
    }

    /**
     * State options for location
     */
    public List<SelectOption> getStateOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', 'Select state...'));
        options.add(new SelectOption('AL', 'Alabama'));
        options.add(new SelectOption('AK', 'Alaska'));
        options.add(new SelectOption('AZ', 'Arizona'));
        options.add(new SelectOption('AR', 'Arkansas'));
        options.add(new SelectOption('CA', 'California'));
        options.add(new SelectOption('CO', 'Colorado'));
        options.add(new SelectOption('CT', 'Connecticut'));
        options.add(new SelectOption('DE', 'Delaware'));
        options.add(new SelectOption('DC', 'District of Columbia'));
        options.add(new SelectOption('FL', 'Florida'));
        options.add(new SelectOption('GA', 'Georgia'));
        options.add(new SelectOption('HI', 'Hawaii'));
        options.add(new SelectOption('ID', 'Idaho'));
        options.add(new SelectOption('IL', 'Illinois'));
        options.add(new SelectOption('IN', 'Indiana'));
        options.add(new SelectOption('IA', 'Iowa'));
        options.add(new SelectOption('KS', 'Kansas'));
        options.add(new SelectOption('KY', 'Kentucky'));
        options.add(new SelectOption('LA', 'Louisiana'));
        options.add(new SelectOption('ME', 'Maine'));
        options.add(new SelectOption('MD', 'Maryland'));
        options.add(new SelectOption('MA', 'Massachusetts'));
        options.add(new SelectOption('MI', 'Michigan'));
        options.add(new SelectOption('MN', 'Minnesota'));
        options.add(new SelectOption('MS', 'Mississippi'));
        options.add(new SelectOption('MO', 'Missouri'));
        options.add(new SelectOption('MT', 'Montana'));
        options.add(new SelectOption('NE', 'Nebraska'));
        options.add(new SelectOption('NV', 'Nevada'));
        options.add(new SelectOption('NH', 'New Hampshire'));
        options.add(new SelectOption('NJ', 'New Jersey'));
        options.add(new SelectOption('NM', 'New Mexico'));
        options.add(new SelectOption('NY', 'New York'));
        options.add(new SelectOption('NC', 'North Carolina'));
        options.add(new SelectOption('ND', 'North Dakota'));
        options.add(new SelectOption('OH', 'Ohio'));
        options.add(new SelectOption('OK', 'Oklahoma'));
        options.add(new SelectOption('OR', 'Oregon'));
        options.add(new SelectOption('PA', 'Pennsylvania'));
        options.add(new SelectOption('RI', 'Rhode Island'));
        options.add(new SelectOption('SC', 'South Carolina'));
        options.add(new SelectOption('SD', 'South Dakota'));
        options.add(new SelectOption('TN', 'Tennessee'));
        options.add(new SelectOption('TX', 'Texas'));
        options.add(new SelectOption('UT', 'Utah'));
        options.add(new SelectOption('VT', 'Vermont'));
        options.add(new SelectOption('VA', 'Virginia'));
        options.add(new SelectOption('WA', 'Washington'));
        options.add(new SelectOption('WV', 'West Virginia'));
        options.add(new SelectOption('WI', 'Wisconsin'));
        options.add(new SelectOption('WY', 'Wyoming'));
        return options;
    }

    /**
     * How did you hear about us options
     */
    public List<SelectOption> getReferralOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', 'Select one...'));
        options.add(new SelectOption('LinkedIn', 'LinkedIn'));
        options.add(new SelectOption('Referral', 'Friend or colleague referral'));
        options.add(new SelectOption('News', 'News article'));
        options.add(new SelectOption('Event', 'Conference or event'));
        options.add(new SelectOption('Social', 'Social media'));
        options.add(new SelectOption('Search', 'Web search'));
        options.add(new SelectOption('Other', 'Other'));
        return options;
    }

    /**
     * Validate and submit the application
     */
    public PageReference submitApplication() {
        if (!validateForm()) {
            return null;
        }

        try {
            // Collect selected categories and skills from wrappers
            List<String> selectedCategories = new List<String>();
            for (SelectableItem item : categoryItems) {
                if (item.selected) selectedCategories.add(item.name);
            }

            List<String> selectedSkills = new List<String>();
            for (SelectableItem item : skillItems) {
                if (item.selected) selectedSkills.add(item.name);
            }

            // Create Contact with USDS Lead record type
            Contact newContact = new Contact();
            newContact.FirstName = firstName;
            newContact.LastName = lastName;
            newContact.Email = email;
            newContact.Phone = phone;

            // Set USDS Lead record type
            RecordType usdsLeadRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'USDS_Lead' LIMIT 1];
            newContact.RecordTypeId = usdsLeadRT.Id;

            // Map to USDS Lead fields
            newContact.WF_Role_Type__c = selectedRole;
            newContact.WF_Category__c = String.join(selectedCategories, '; ');
            newContact.WF_Skill__c = String.join(selectedSkills, '; ');

            // Additional custom fields (uncomment when fields exist in org)
            // newContact.LinkedIn__c = linkedIn;
            // newContact.Current_Location__c = currentLocation;
            // newContact.Earliest_Start_Date__c = earliestStartDate;
            // newContact.Years_of_Experience__c = yearsOfExperience;
            // newContact.Target_Level__c = targetLevel;
            // newContact.Security_Clearance__c = securityClearance;
            // newContact.Previous_Fed_Employee__c = previousFedEmployee;
            // newContact.Portfolio_URL__c = portfolioUrl;
            // newContact.Why_USDS__c = whyUsds;
            // newContact.Referral_Source__c = howDidYouHear;

            insert newContact;

            // Attach resume if uploaded
            if (resume != null) {
                Attachment att = new Attachment();
                att.Body = resume;
                att.Name = String.isNotBlank(resumeFileName) ? resumeFileName : 'Resume.pdf';
                att.ContentType = String.isNotBlank(resumeContentType) ? resumeContentType : 'application/pdf';
                att.ParentId = newContact.Id;
                insert att;
            }

            // Redirect to confirmation page
            PageReference confirmPage = Page.ApplicationConfirmation;
            confirmPage.setRedirect(true);
            return confirmPage;

        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                'An error occurred while submitting your application: ' + e.getMessage()));
            return null;
        }
    }

    /**
     * Form validation
     */
    private Boolean validateForm() {
        Boolean isValid = true;

        if (String.isBlank(firstName)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'First name is required.'));
            isValid = false;
        }
        if (String.isBlank(lastName)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Last name is required.'));
            isValid = false;
        }
        if (String.isBlank(email)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Email is required.'));
            isValid = false;
        }
        if (String.isBlank(selectedRole)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a role.'));
            isValid = false;
        }
        if (String.isBlank(isCitizen) || isCitizen == 'No') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,
                'U.S. citizenship is required for USDS positions.'));
        }

        return isValid;
    }

    /**
     * Initialize the skills data structure
     * Structure: Role -> Category -> List<Skill>
     */
    private void initializeSkillsData() {
        skillsData = new Map<String, Map<String, List<String>>>();

        // Engineering
        Map<String, List<String>> engineering = new Map<String, List<String>>();
        engineering.put('Languages', new List<String>{'Python', 'JavaScript', 'TypeScript', 'Java', 'Go', 'Ruby', 'C++', 'C Sharp'});
        engineering.put('Databases', new List<String>{'SQL', 'PostgreSQL', 'MongoDB', 'Redis'});
        engineering.put('Cloud', new List<String>{'AWS', 'Azure', 'GCP'});
        engineering.put('Infrastructure', new List<String>{'Kubernetes', 'Docker', 'Terraform', 'CI/CD'});
        engineering.put('Frontend', new List<String>{'React', 'Node.js', 'Vue', 'Angular'});
        engineering.put('Backend', new List<String>{'REST APIs', 'GraphQL', 'Microservices'});
        engineering.put('Mobile', new List<String>{'iOS', 'Android', 'React Native'});
        engineering.put('Other', new List<String>{'Git', 'Linux', 'Security', 'Agile'});
        skillsData.put('Engineering', engineering);

        // Data Science
        Map<String, List<String>> dataScience = new Map<String, List<String>>();
        dataScience.put('Languages', new List<String>{'Python', 'SQL', 'R'});
        dataScience.put('Tools', new List<String>{'Tableau', 'Power BI', 'Looker', 'Excel', 'Jupyter'});
        dataScience.put('Platforms', new List<String>{'Snowflake', 'BigQuery', 'Databricks', 'Spark'});
        dataScience.put('Skills', new List<String>{'Statistics', 'Data Modeling', 'ETL', 'Data Visualization', 'A/B Testing', 'Data Governance', 'dbt'});
        skillsData.put('Data Science', dataScience);

        // AI and Machine Learning
        Map<String, List<String>> aiMl = new Map<String, List<String>>();
        aiMl.put('Frameworks', new List<String>{'TensorFlow', 'PyTorch', 'Scikit-learn', 'Keras', 'Hugging Face'});
        aiMl.put('LLMs', new List<String>{'OpenAI API', 'Langchain', 'Prompt Engineering', 'Fine-tuning', 'RAG'});
        aiMl.put('Specialties', new List<String>{'NLP', 'Computer Vision', 'Deep Learning', 'Neural Networks', 'Reinforcement Learning', 'Generative AI'});
        aiMl.put('Operations', new List<String>{'MLOps', 'Model Deployment', 'Feature Engineering', 'Model Evaluation'});
        aiMl.put('Other', new List<String>{'AI Ethics', 'Python'});
        skillsData.put('AI and Machine Learning', aiMl);

        // Product
        Map<String, List<String>> product = new Map<String, List<String>>();
        product.put('Core', new List<String>{'Roadmapping', 'Product Strategy', 'User Stories', 'PRDs', 'Prioritization', 'OKRs'});
        product.put('Research', new List<String>{'User Interviews', 'Customer Discovery', 'Market Research', 'Competitive Analysis', 'A/B Testing'});
        product.put('Tools', new List<String>{'Jira', 'Confluence', 'Amplitude', 'Mixpanel', 'SQL'});
        product.put('Methods', new List<String>{'Agile', 'Scrum', 'Stakeholder Management', 'Go-to-Market', 'Wireframing'});
        skillsData.put('Product', product);

        // Marketing
        Map<String, List<String>> marketing = new Map<String, List<String>>();
        marketing.put('Digital', new List<String>{'SEO', 'SEM', 'PPC', 'Paid Ads', 'Google Analytics', 'Social Media'});
        marketing.put('Content', new List<String>{'Content Strategy', 'Copywriting', 'Email Marketing', 'Brand Strategy'});
        marketing.put('Tools', new List<String>{'HubSpot', 'Salesforce Marketing Cloud', 'Mailchimp', 'CRM', 'Marketing Automation'});
        marketing.put('Skills', new List<String>{'Campaign Management', 'Market Research', 'Growth Marketing', 'Conversion Optimization', 'Attribution'});
        marketing.put('Other', new List<String>{'PR', 'Events', 'Influencer Marketing'});
        skillsData.put('Marketing', marketing);

        // Design
        Map<String, List<String>> design = new Map<String, List<String>>();
        design.put('Tools', new List<String>{'Figma', 'Sketch', 'Adobe Creative Suite', 'InVision', 'Miro'});
        design.put('Research', new List<String>{'User Research', 'Usability Testing', 'Journey Mapping', 'Personas'});
        design.put('Skills', new List<String>{'Prototyping', 'Wireframing', 'Visual Design', 'Interaction Design', 'Information Architecture', 'Design Systems', 'Accessibility', 'Responsive Design'});
        design.put('Specialties', new List<String>{'Service Design', 'Content Design', 'Motion Design', 'Mobile Design'});
        design.put('Technical', new List<String>{'HTML CSS'});
        skillsData.put('Design', design);

        // Talent
        Map<String, List<String>> talent = new Map<String, List<String>>();
        talent.put('Recruiting', new List<String>{'Sourcing', 'Interviewing', 'LinkedIn Recruiter', 'Employer Branding', 'Candidate Experience'});
        talent.put('Tools', new List<String>{'ATS Systems', 'Greenhouse', 'Lever', 'Workday', 'HRIS'});
        talent.put('HR', new List<String>{'Compensation Analysis', 'Benefits Administration', 'Employee Relations', 'HR Compliance', 'Performance Management'});
        talent.put('Strategy', new List<String>{'Workforce Planning', 'Succession Planning', 'Talent Analytics', 'DEI', 'Onboarding'});
        talent.put('Development', new List<String>{'Training', 'Learning and Development', 'Culture Building'});
        skillsData.put('Talent', talent);

        // Legal
        Map<String, List<String>> legal = new Map<String, List<String>>();
        legal.put('Contracts', new List<String>{'Contract Review', 'Contract Negotiation', 'Government Contracts', 'FAR DFAR'});
        legal.put('Compliance', new List<String>{'Regulatory Affairs', 'Compliance', 'Risk Management', 'Ethics'});
        legal.put('Privacy', new List<String>{'Privacy Law', 'GDPR', 'CCPA', 'Data Privacy'});
        legal.put('Specialties', new List<String>{'Employment Law', 'Intellectual Property', 'Cybersecurity Law', 'Tech Law'});
        legal.put('Government', new List<String>{'FOIA', 'Security Clearances', 'Policy Development'});
        legal.put('Other', new List<String>{'Litigation', 'Negotiations'});
        skillsData.put('Legal', legal);

        // Executive
        Map<String, List<String>> executive = new Map<String, List<String>>();
        executive.put('Strategy', new List<String>{'Strategic Planning', 'Digital Transformation', 'Organizational Design', 'Change Management'});
        executive.put('Finance', new List<String>{'P and L Management', 'Budget Management', 'Fundraising', 'M and A'});
        executive.put('Relationships', new List<String>{'Board Relations', 'Investor Relations', 'Government Relations', 'Partnerships', 'Stakeholder Engagement'});
        executive.put('Leadership', new List<String>{'Team Building', 'Executive Communications', 'Public Speaking', 'Thought Leadership', 'Crisis Management'});
        executive.put('Other', new List<String>{'Policy Development'});
        skillsData.put('Executive', executive);

        // Procurement
        Map<String, List<String>> procurement = new Map<String, List<String>>();
        procurement.put('Contracting', new List<String>{'Government Contracting', 'FAR DFAR', 'Contract Administration', 'RFP RFQ', 'Vendor Management'});
        procurement.put('Skills', new List<String>{'Cost Analysis', 'Negotiations', 'Acquisition Strategy', 'Market Research', 'Compliance'});
        procurement.put('Tools', new List<String>{'Contract Management Systems', 'SAP'});
        procurement.put('Government', new List<String>{'GSA Schedules', 'CPARS', 'Source Selection'});
        skillsData.put('Procurement', procurement);

        // Finance
        Map<String, List<String>> finance = new Map<String, List<String>>();
        finance.put('Core', new List<String>{'FP and A', 'Budgeting', 'Forecasting', 'Financial Modeling', 'Financial Analysis'});
        finance.put('Accounting', new List<String>{'GAAP', 'Auditing', 'Tax', 'Revenue Recognition'});
        finance.put('Tools', new List<String>{'Excel', 'SAP', 'Oracle', 'NetSuite'});
        finance.put('Treasury', new List<String>{'Cash Management', 'Treasury', 'Accounts Payable', 'Accounts Receivable'});
        skillsData.put('Finance', finance);

        // Cybersecurity
        Map<String, List<String>> cybersecurity = new Map<String, List<String>>();
        cybersecurity.put('Offensive', new List<String>{'Penetration Testing', 'Vulnerability Assessment', 'Red Team'});
        cybersecurity.put('Defensive', new List<String>{'SOC', 'Incident Response', 'Threat Intelligence', 'Blue Team'});
        cybersecurity.put('Infrastructure', new List<String>{'Network Security', 'Cloud Security', 'Identity Management', 'Zero Trust'});
        cybersecurity.put('Compliance', new List<String>{'FedRAMP', 'FISMA', 'NIST', 'SOC 2'});
        cybersecurity.put('Tools', new List<String>{'SIEM', 'Splunk', 'CrowdStrike'});
        skillsData.put('Cybersecurity', cybersecurity);

        // Operations
        Map<String, List<String>> operations = new Map<String, List<String>>();
        operations.put('Process', new List<String>{'Process Improvement', 'Lean', 'Six Sigma', 'Business Process Reengineering'});
        operations.put('Management', new List<String>{'Project Management', 'Program Management', 'PMP', 'Scrum Master'});
        operations.put('Tools', new List<String>{'MS Project', 'Smartsheet', 'Asana', 'Monday'});
        operations.put('Skills', new List<String>{'Vendor Management', 'Supply Chain', 'Resource Planning', 'Risk Management'});
        skillsData.put('Operations', operations);

        // Communications
        Map<String, List<String>> communications = new Map<String, List<String>>();
        communications.put('External', new List<String>{'Public Affairs', 'Media Relations', 'Press Releases', 'Crisis Communications'});
        communications.put('Internal', new List<String>{'Internal Communications', 'Employee Engagement'});
        communications.put('Content', new List<String>{'Speech Writing', 'Executive Communications', 'Storytelling'});
        communications.put('Digital', new List<String>{'Social Media', 'Digital Communications', 'Content Management'});
        skillsData.put('Communications', communications);

        // Policy
        Map<String, List<String>> policy = new Map<String, List<String>>();
        policy.put('Analysis', new List<String>{'Policy Analysis', 'Regulatory Analysis', 'Research', 'Data Analysis'});
        policy.put('Government', new List<String>{'Legislative Affairs', 'Government Affairs', 'Public Policy', 'Interagency Coordination'});
        policy.put('Skills', new List<String>{'Policy Writing', 'Briefings', 'Stakeholder Engagement', 'Coalition Building'});
        skillsData.put('Policy', policy);
    }
}
