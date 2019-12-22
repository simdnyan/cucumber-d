module step_definitions.steps;

import cucumber.keywords : When, Then;
import requests : Request, Response;
import unit_threaded.assertions : should;

///
Response response;

///
@When("^the user sends a GET request to (?P<url>.*)$")
void sendAGetRequestTo(string url)
{
    response = Request().get(url);
}

///
@Then("^the response status should be (?P<code>[0-9]+)$")
void theResponseStatusShouldBe(int code)
{
    response.code.should == code;
}
