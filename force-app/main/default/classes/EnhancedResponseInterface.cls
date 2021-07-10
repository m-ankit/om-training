global virtual class EnhancedResponseInterface extends vlocity_cmt.DefaultSystemInterface {

    global override void processResponse(vlocity_cmt__OrchestrationItem__c item, String url, String path,
    vlocity_cmt.XOMOrderDomainObject orderObj, HttpResponse res){

        String responseBody = res.getBody();
        if(responseBody != null && responseBody.length() > 0){
            Map<String, Object> responseObj = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            responseObj.put('frlId', item.vlocity_cmt__FulfilmentRequestLineId__c);
            res.setBody(JSON.serializePretty(responseObj));
        }
        super.processResponse(item, url, path, orderObj, res);
    }
}