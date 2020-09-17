public with sharing class SelectParticipantService {
    @TestVisible
    private ProgramEngagementSelector programEngagementSelector = new ProgramEngagementSelector();

    public Map<String, String> getLabels() {
        Map<String, String> labels = new Map<String, String>{
            Schema.SObjectType.Program__c.getName() => Schema.SObjectType.Program__c.getLabel(),
            Schema.SObjectType.ProgramCohort__c.getName() => Schema.SObjectType.ProgramCohort__c.getLabel(),
            Schema.SObjectType.ServiceParticipant__c.getName() => Schema.SObjectType.ServiceParticipant__c.getLabel(),
            Schema.SObjectType.Contact.Fields.Name.getName() => Schema.SObjectType.Contact.Fields.Name.getLabel(),
            Schema.SObjectType.Contact.Fields.Email.getName() => Schema.SObjectType.Contact.Fields.Email.getLabel(),
            Schema.SObjectType.ProgramEngagement__c.Fields.Stage__c.getName() => Schema.SObjectType.ProgramEngagement__c.Fields.Stage__c.getLabel()
        };

        return labels;
    }

    public SelectParticipantModel getSelectParticipantModel(Id serviceId) {
        SelectParticipantModel participantModel = new SelectParticipantModel();

        participantModel.programEngagements = programEngagementSelector.getProgramEngagementsByServiceId(
            serviceId
        );
        participantModel.programCohorts = programEngagementSelector.getProgramCohortsByServiceId(
            serviceId
        );
        participantModel.labels = getLabels();

        return participantModel;
    }

    public class SelectParticipantModel {
        @AuraEnabled
        public List<ProgramEngagement__c> programEngagements;
        @AuraEnabled
        public List<ProgramCohort__c> programCohorts;
        @AuraEnabled
        public Map<String, String> labels;

        public SelectParticipantModel() {
            this.programEngagements = new List<ProgramEngagement__c>();
            this.programCohorts = new List<ProgramCohort__c>();
            this.labels = new Map<String, String>();
        }
    }
}