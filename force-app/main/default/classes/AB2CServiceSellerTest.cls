@isTest class AB2CServiceSellerTest {
    @isTest static void testgetFieldsMap() {
        AB2CServiceSeller service = new AB2CServiceSeller();

        Map<String, Object> inputData = new Map<String, Object>{
            ccrz.ccService.OBJECTFIELDS => 'TestField1,TestField2'
        };

        Map<String,Object> response = service.getFieldsMap(inputData);

        String resultFields = (String)response.get(ccrz.ccService.OBJECTFIELDS);

        system.debug(resultFields);
        system.assert(resultFields.contains(service.newFields));
    }
}