@isTest public class AB2CMailchimpHttpMock implements HttpCalloutMock {
    public String rawResponse;
    public Integer statusCode = 200;
    public Integer nextCode = null; // if filled, statusCode changes to this after the first request
    public String status = 'mock';
    
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(statusCode);
        if (nextCode != null){
            statusCode = nextCode;
            nextCode = null;
        }
        if (rawResponse != null){
            res.setBody(rawResponse);
        } else {
            Map<String, Object> bodyMap = new Map<String, Object>{
                'status' => status
            };
            res.setBody(JSON.serialize(bodyMap));
        }
        return res;
    }
}