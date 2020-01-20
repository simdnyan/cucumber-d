Feature: Assert httpbin response

  Scenario: httpbin returns 200 OK
    When the user sends a GET request to http://httpbin.org/
    Then the response status should be 200

  Scenario Outline: httpbin returns 4xx
    When the user sends a GET request to http://httpbin.org/status/<codes>
    Then the response status should be <status>

    Examples:
     | codes | status |
     | 400   | 400    |
     | 404   | 404    |

  Scenario Outline: httpbin returns requested headers
    Given the following request headers
      | Content-Type | <Content-Type>   |
      | User-Agent   | cucumber-example |
    When the user sends a GET request to http://httpbin.org/headers
    Then the response status should be 200
    And the response body should be:
      """json
      {
        "headers": {
          "Accept-Encoding":"gzip,deflate",
          "Content-Type": "application/json",
          "Host": "httpbin.org",
          "User-Agent": "<User-Agent>"
        }
      }
      """

    Examples:
      | Content-Type     | User-Agent       |
      | application/json | cucumber-example |
