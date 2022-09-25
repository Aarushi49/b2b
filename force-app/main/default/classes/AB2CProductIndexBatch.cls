global class AB2CProductIndexBatch  implements Schedulable {
    /**
     * Schedule loading the product indexes 
     * https://developer.salesforce.com/docs/atlas.en-us.noversion.b2b_commerce_dev_guide.meta/b2b_commerce_dev_guide/ccrz_ccProductIndexBuilder.htm
     * https://cloudcraze.atlassian.net/wiki/spaces/B2BDOCS410/pages/890503355/ccrz.ccProductIndexBuilder
     * ccrz.ccProductIndexBuilder.NUMBER_OF_SCOPE_KEY_PAIRS => 5,
     * ccrz.ccProductIndexBuilder.IS_FULL_REFRESH => TRUE,
     */
    global void execute(SchedulableContext ctx) {        
        ccrz.ccProductIndexBuilder.build(new Map<String, Object> {
            ccrz.ccAPIProductIndex.CLEAN_ONLY => false, 
            ccrz.ccAPIProductIndex.LOCALES => new Set<String>{'en_US', 'en','en_CA'}
        });
    }
    
}