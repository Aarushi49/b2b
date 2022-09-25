@isTest class AB2CServiceDebugTest {
    @isTest static void testAB2CServiceDebugTest() {
        // class in test is only used for logging out
        AB2CServiceDebug service = new AB2CServiceDebug();
        Map<String, Object> input = new Map<String, Object>();
        service.fetch(input);
        service.getFieldsMap(input);
        service.getFilterMap(input);
        service.getFindFieldsClauseMap(input);
        service.getOrderByMap(input);
        service.getReturnClauseMap(input);
        service.getSubQueryMap(input);
        service.prepReturn(input);
        service.processSearchResult(input);
        service.search(input);
        service.transformOut(input);
    }
}