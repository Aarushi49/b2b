global with sharing class AB2CServiceDebug extends ccrz.ccServiceTransactionPayment {
    /**
    * Used to debug CloudCraze Service classes under CC Admin > Service Management 
    * 1) Update the "extends" to the service class being debugged
    * 2) Update the LOGIC_CLASSNAME to something meaningful, like AB2C<service_class_name>
    * 3) In Service Management, override the service class with c.AB2CServiceDebug
    **/
    private final String LOGIC_CLASSNAME = 'AB2CServiceTransactionPayment';

    global override virtual Map<String,Object> fetch(Map<String,Object> inputData) {
        debug('fetch', 'input', inputData);
        Map<String,Object> retData = super.fetch(inputData);
        debug('fetch', 'output', retData);
        return retData;
    }
    
    global override virtual Map<String,Object> getFieldsMap(Map<String,Object> inputData) {
        debug('getFieldsMap', 'input', inputData);
        Map<String,Object> retData = super.getFieldsMap(inputData);
        debug('getFieldsMap', 'output', retData);
        return retData;
    }
    global override virtual Map<String,Object> getFilterMap(Map<String,Object> inputData) {
        debug('getFilterMap', 'input', inputData);
        Map<String,Object> retData = super.getFilterMap(inputData);
        debug('getFilterMap', 'output', retData);
        return retData;
    }

    global override virtual Map<String,Object> getFindFieldsClauseMap(Map<String,Object> inputData) {
        debug('getFindFieldsClauseMap', 'input', inputData);
        Map<String,Object> retData = super.getFindFieldsClauseMap(inputData);
        debug('getFindFieldsClauseMap', 'output', retData);
        return retData;
    }

    global override virtual Map<String,Object> getOrderByMap(Map<String,Object> inputData) {
        debug('getOrderByMap', 'input', inputData);
        Map<String,Object> retData = super.getOrderByMap(inputData);
        debug('getOrderByMap', 'output', retData);
        return retData;
    }

    global override virtual Map<String,Object> getReturnClauseMap(Map<String,Object> inputData) {
        debug('getReturnClauseMap', 'input', inputData);
        Map<String,Object> retData = super.getReturnClauseMap(inputData);
        debug('getReturnClauseMap', 'output', retData);
        return retData;
    }

    global override virtual Map<String,Object> getSubQueryMap(Map<String,Object> inputData) {
        debug('getSubQueryMap', 'input', inputData);
        Map<String,Object> retData = super.getSubQueryMap(inputData);
        debug('getSubQueryMap', 'output', retData);
        return retData;
    }

    global override virtual Map<String,Object> prepReturn(Map<String,Object> inputData) {
        debug('prepReturn', 'input', inputData);
        Map<String,Object> retData = super.prepReturn(inputData);
        debug('prepReturn', 'output', retData);
        return retData;
    }

    global override virtual Map<String,Object> processSearchResult(Map<String,Object> inputData) {
        debug('processSearchResult', 'input', inputData);
        Map<String,Object> retData = super.processSearchResult(inputData);
        debug('processSearchResult', 'output', retData);
        return retData;
    }

    global override virtual Map<String,Object> search(Map<String,Object> inputData) {
        debug('search', 'input', inputData);
        Map<String,Object> retData = super.search(inputData);
        debug('search', 'output', retData);
        return retData;
    }

    global override virtual Map<String,Object> transformOut(Map<String,Object> inputData) {
        debug('transformOut', 'input', inputData);
        Map<String,Object> retData = super.transformOut(inputData);
        debug('transformOut', 'output', retData);
        return retData;
    }
    
    private void debug(String functionName, String tag, Map<String,Object> input) {
        try {
        	ccrz.ccLog.log(System.LoggingLevel.DEBUG, LOGIC_CLASSNAME + ':' + functionName + ':' + tag, JSON.serialize(input));
        } catch (Exception e) {
			ccrz.ccLog.log(System.LoggingLevel.ERROR, LOGIC_CLASSNAME + ':' + functionName + ':' + tag, e.getMessage());
        }
    }
}