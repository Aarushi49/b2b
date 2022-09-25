@IsTest class AB2CUrlRewriterTest {
    @isTest static void testMapRequestUrl() {
        AB2CUrlRewriter service = new AB2CUrlRewriter();

        String keyToTest = getKeyToTest();

        System.PageReference inputData = new System.PageReference('/' + keyToTest);

        System.PageReference outputData = service.mapRequestUrl(inputData);
        system.assert(outputData.getUrl() == AB2CUrlRewriter.URL_MAP.get(keyToTest), 'service should find matching url');
    }

    private static String getKeyToTest() {
        String keyToTest;
        for (String key : AB2CUrlRewriter.URL_MAP.keySet()) {
            if (keyToTest == null) keyToTest = key;
        }
        return keyToTest;
    }

    @isTest static void testGenerateUrlFor() {
        AB2CUrlRewriter service = new AB2CUrlRewriter();

        String keyToTest = getKeyToTest();
        System.PageReference testPageRef = new System.Pagereference(AB2CUrlRewriter.URL_MAP.get(keyToTest));
        List<System.PageReference> inputData = new List<System.PageReference>{testPageRef};

        List<System.PageReference> outputData = service.generateUrlFor(inputData);

        system.assert(outputData[0].getUrl() == inputData[0].getUrl());
    }
}