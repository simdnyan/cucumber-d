module step_definitions.steps;

import std.conv : to;
import std.json : JSONValue, parseJSON;

import cucumber.keywords : Given, When, Then;
import gherkin.datatable;
import gherkin.docstring;
import requests : Request, Response;
import unit_threaded.assertions : should;

///
Request request = Request();
///
Response response;

///
@When("^the user sends a GET request to (?P<url>.*)$")
void sendAGetRequestTo(string url)
{
    response = request.get(url);
}

///
@Then("^the response status should be (?P<code>[0-9]+)$")
void theResponseStatusShouldBe(int code)
{
    response.code.should == code;
}

///
@Given("the following request headers")
void theFollowingRequestHeader(DataTable dataTable)
{
    foreach (row; dataTable.rows)
    {
        request.addHeaders([row.cells[0].value: row.cells[1].value]);
    }
}
///
@Then("the response body should be")
void theResponseBodyShouldBe(DocString docString)
{
    immutable auto expected = parseJSON(docString.content);
    immutable auto actual = parseJSON(response.responseBody.to!string);

    actual.should == expected;
}
