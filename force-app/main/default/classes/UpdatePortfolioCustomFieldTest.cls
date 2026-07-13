@isTest
public class UpdatePortfolioCustomFieldTest {
    
    public class HttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testUpdatePortfolioCustomField() {
        PW_Portfolio__c portfolio = new PW_Portfolio__c(
            PW_Portfolio_Entity_ID__c = '12345',
            PW_Org__c = 'PPMG of Texas, LLC'
        );
        insert portfolio;

        UpdatePortfolioCustomField.PortfolioInput input = new UpdatePortfolioCustomField.PortfolioInput();
        input.entityIdList = new List<String>{portfolio.Id};

        List<UpdatePortfolioCustomField.PortfolioInput> inputList = new List<UpdatePortfolioCustomField.PortfolioInput>{ input };

        Test.setMock(HttpCalloutMock.class, new HttpMock());

        Test.startTest();
        UpdatePortfolioCustomField.updateCustomField(inputList);
        Test.stopTest();
    }
}