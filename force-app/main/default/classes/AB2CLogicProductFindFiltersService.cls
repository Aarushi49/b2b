global with sharing class AB2CLogicProductFindFiltersService extends ccrz.ccLogicProductFindFilters{
    
    global virtual override Map<String,Object> fetchFilters(Map<String,Object> inputData) {
        Map<String,Object> retData = super.fetchFilters(inputData);

        retData.put('filtersExpanded',getPLPFilterExpanded());
        return retData;
    }


    private sObject getPLPFilterExpanded(){
        Set<String> flds = AB2C_PLP_Filter__c.sObjectType.getDescribe().fields.getMap().keySet();
        list<string> lstFields = new list<string>();
        for(string field : flds){
            if(field.contains('__c')){
                lstFields.add(field.toLowerCase());
            }
        }
        String fieldsStr = String.join(lstFields,',');
        String qry = 'select ' + fieldsStr + ' FROM AB2C_PLP_Filter__c ';
        return Database.query(qry);
    }

}