@isTest  class AB2CLogicProductFindFiltersServiceTest {

    @isTest static void testfetchFilters(){
        AB2C_PLP_Filter__c pf = new AB2C_PLP_Filter__c();
        pf.AB2C_Active_Flooring__c = true;
        insert pf;

        AB2CLogicProductFindFiltersService pffs = new AB2CLogicProductFindFiltersService();
        Map<String,Object> inputData = new Map<String,Object>();
        Map<String,Object> retData = pffs.fetchFilters(inputData);
        AB2C_PLP_Filter__c lstAA = (AB2C_PLP_Filter__c)retData.get('filtersExpanded');
        System.assert(lstAA.AB2C_Active_Flooring__c == true, 'Must return PLP Filter');
    

    }
}