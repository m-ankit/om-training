global with sharing class PropagateAttributeAcrossSwimlane implements vlocity_cmt.XOMOrchestrationInterfaces.IAutoTask {
    global static void executeBatch(List<vlocity_cmt__OrchestrationItem__c> items) {
        Set<Id> planIds = new Set<Id>();
        Set<Id> orchItemDefIds = new Set<Id>();
        Map<String, Object> productCodeToFRLMap = new Map<String, Object>();
        for(vlocity_cmt__OrchestrationItem__c item : items){
            planIds.add(item.vlocity_cmt__OrchestrationPlanId__c);
            orchItemDefIds.add(item.vlocity_cmt__OrchestrationItemDefinitionId__c);
        }
        List<vlocity_cmt__FulfilmentRequestLine__c> allFRL = [select Id, vlocity_cmt__Product2Id__r.ProductCode, 
                                                                vlocity_cmt__FulfilmentRequestID__r.vlocity_cmt__orchestrationPlanId__c
                                                                from vlocity_cmt__FulfilmentRequestLine__c
                                                                where vlocity_cmt__FulfilmentRequestID__r.vlocity_cmt__orchestrationPlanId__c IN : planIds];
        for(vlocity_cmt__FulfilmentRequestLine__c frl : allFRL){
            List<Object> frls = new List<Object>();
            if(productCodeToFRLMap.containsKey(frl.vlocity_cmt__Product2Id__r.ProductCode)){
                frls.add(productCodeToFRLMap.get(frl.vlocity_cmt__Product2Id__r.ProductCode));
            }
            frls.add(frl);
            productCodeToFRLMap.put(frl.vlocity_cmt__Product2Id__r.ProductCode, frls);
        }
        List<vlocity_cmt__OrchestrationItemDefinition__c> allDefs = [select Id, vlocity_cmt__AutoTaskParameters__c from 
                                                                    vlocity_cmt__OrchestrationItemDefinition__c  where 
                                                                    Id IN : orchItemDefIds];
        Map<Id, String> orchDefIdToParameterMap = new Map<Id, String>();
        for(vlocity_cmt__OrchestrationItemDefinition__c def : allDefs){
            orchDefIdToParameterMap.put(def.Id, def.vlocity_cmt__AutoTaskParameters__c);
        }
        //Logic Here
        for(vlocity_cmt__OrchestrationItem__c item : items){
            Id targetId;
            List<Object> autoTaskParameters = (List<Object>) JSON.deserializeUntyped(orchDefIdToParameterMap.get(item.vlocity_cmt__OrchestrationItemDefinitionId__c));
            Map<String, Object> autoTaskParamMap = (Map<String, Object>)autoTaskParameters[0];
            vlocity_cmt.XOMOrderItemService xois = (vlocity_cmt.XOMOrderItemService) vlocity_cmt.XOMObjectFactory.getService(vlocity_cmt__FulfilmentRequestLine__c.SObjectType);
            vlocity_cmt.XOMOrderItemDomainObject sourcefrl = (vlocity_cmt.XOMOrderItemDomainObject) xois.getObject(Id.valueOf(item.vlocity_cmt__FulfilmentRequestLineId__c));
            vlocity_cmt.XOMAttributeValueRT sourceAttribute = sourcefrl.getAttributeValue((String) autoTaskParamMap.get('source_attr_code'));
            String sourceAttributeVal = sourceAttribute.getValue();
            if(productCodeToFRLMap.containsKey((String) autoTaskParamMap.get('destination_prod_code'))){
                List<Object> frlObjs = (List<Object>)productCodeToFRLMap.get((String) autoTaskParamMap.get('destination_prod_code'));
                for(Object obj : frlObjs){
                    vlocity_cmt__FulfilmentRequestLine__c frl = (vlocity_cmt__FulfilmentRequestLine__c) obj;
                    if(frl.vlocity_cmt__FulfilmentRequestID__r.vlocity_cmt__orchestrationPlanId__c == item.vlocity_cmt__orchestrationPlanId__c){
                        targetId = frl.Id;
                        break;
                    }
                }
            }
            if(targetId != null){
                vlocity_cmt.XOMOrderItemDomainObject targetfrl = (vlocity_cmt.XOMOrderItemDomainObject) xois.getObject(targetId);
                vlocity_cmt.XOMAttributeValueRT targetAttribute = targetfrl.getAttributeValue((String) autoTaskParamMap.get('destination_attr_code'));
                targetAttribute.setValue(sourceAttributeVal);
                targetfrl.updateObject();
                vlocity_cmt.XOMObjectFactory.commitObjs();
            }
        }
    }
}