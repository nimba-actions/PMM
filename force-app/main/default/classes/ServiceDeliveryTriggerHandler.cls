/*
 *
 *  * Copyright (c) 2021, salesforce.com, inc.
 *  * All rights reserved.
 *  * SPDX-License-Identifier: BSD-3-Clause
 *  * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 *
 */

public with sharing class ServiceDeliveryTriggerHandler {
    @TestVisible
    private AttendanceService service = new AttendanceService();

    private final SObjectField ATTENDANCE_STATUS = ServiceDelivery__c.AttendanceStatus__c;
    private final SObjectField DELIVERY_DATE = ServiceDelivery__c.DeliveryDate__c;
    private Map<SObjectField, Set<Id>> recordIdsByLookupFieldForAttendance = new Map<SObjectField, Set<Id>>{
        ServiceDelivery__c.Contact__c => new Set<Id>(),
        ServiceDelivery__c.Service__c => new Set<Id>(),
        ServiceDelivery__c.ServiceSession__c => new Set<Id>(),
        ServiceDelivery__c.ProgramEngagement__c => new Set<Id>()
    };
    private Map<SObjectField, Set<Id>> recordIdsByLookupFieldForLastServiceDate = new Map<SObjectField, Set<Id>>{
        ServiceDelivery__c.Contact__c => new Set<Id>(),
        ServiceDelivery__c.ProgramEngagement__c => new Set<Id>()
    };
    private Map<SObjectType, List<SObject>> sObjectsByType = new Map<SObjectType, List<SObject>>();
    private static Map<String, SObjectField> LOOKUP_FIELD_BY_FEATURE = new Map<String, SObjectField>{
        'ServiceDeliveriesToContact' => ServiceDelivery__c.Contact__c,
        'ServiceDeliveriesToService' => ServiceDelivery__c.Service__c,
        'ServiceDeliveriesToServiceSession' => ServiceDelivery__c.ServiceSession__c,
        'ServiceDeliveriesToProgramEngagement' => ServiceDelivery__c.ProgramEngagement__c
    };
    private Set<SObjectField> lookupFields {
        get {
            if (lookupFields == null) {
                lookupFields = getLookupFields();
            }

            return lookupFields;
        }
        set;
    }

    public void execute() {
        if (!Trigger.isExecuting) {
            return;
        }

        delegate(Trigger.operationType);
        service.doRollups(
            recordIdsByLookupFieldForAttendance,
            recordIdsByLookupFieldForLastServiceDate
        );
    }

    @TestVisible
    private void delegate(TriggerOperation operationType) {
        switch on operationType {
            when AFTER_DELETE {
                handleAfterDelete();
            }
            when AFTER_INSERT {
                handleAfterInsert();
            }
            when AFTER_UNDELETE {
                handleAfterUndelete();
            }
            when AFTER_UPDATE {
                handleAfterUpdate();
            }
            when else {
                return;
            }
        }
    }

    private void handleAfterDelete() {
        for (SObject record : Trigger.old) {
            extractRecordIdsToRecalculate(record, null);
        }
    }

    private void handleAfterInsert() {
        for (SObject record : Trigger.new) {
            extractRecordIdsToRecalculate(null, record);
        }
    }

    private void handleAfterUndelete() {
        for (SObject record : Trigger.new) {
            extractRecordIdsToRecalculate(null, record);
        }
    }

    private void handleAfterUpdate() {
        for (SObject record : Trigger.new) {
            extractRecordIdsToRecalculate(Trigger.oldMap.get(record.Id), record);
        }
    }

    private void extractRecordIdsToRecalculate(SObject oldRecord, SObject newRecord) {
        extractRecordIdsToRecalculate(
            oldRecord,
            newRecord,
            DELIVERY_DATE,
            recordIdsByLookupFieldForLastServiceDate
        );
        extractRecordIdsToRecalculate(
            oldRecord,
            newRecord,
            ATTENDANCE_STATUS,
            recordIdsByLookupFieldForAttendance
        );
    }

    @TestVisible
    private void extractRecordIdsToRecalculate(
        SObject oldRecord,
        SObject newRecord,
        SObjectField fieldToInspect,
        Map<SObjectField, Set<Id>> recordIdsByLookupField
    ) {
        Object oldValue = oldRecord == null ? null : oldRecord.get(fieldToInspect);
        Object newValue = newRecord == null ? null : newRecord.get(fieldToInspect);

        if (oldValue == null && newValue == null) {
            return;
        }

        for (SObjectField lookupField : lookupFields) {
            if (!recordIdsByLookupField.containsKey(lookupField)) {
                continue;
            }

            Id oldParentId = (Id) (oldRecord == null ? null : oldRecord.get(lookupField));
            Id newParentId = (Id) (newRecord == null ? null : newRecord.get(lookupField));

            if (oldValue == newValue && oldParentId == newParentId) {
                continue;
            }

            Set<Id> recordIds = recordIdsByLookupField.get(lookupField);

            if (oldParentId != null) {
                recordIds.add(oldParentId);
            }

            if (newParentId != null) {
                recordIds.add(newParentId);
            }
        }
    }

    private Set<SObjectField> getLookupFields() {
        Set<SObjectField> fields = new Set<SObjectField>();
        List<FeatureGate__mdt> features = FeatureGate__mdt.getAll().values();

        for (FeatureGate__mdt feature : features) {
            if (
                feature.IsActive__c &&
                LOOKUP_FIELD_BY_FEATURE.containsKey(feature.DeveloperName)
            ) {
                fields.add(LOOKUP_FIELD_BY_FEATURE.get(feature.DeveloperName));
            }
        }

        return fields;
    }
}