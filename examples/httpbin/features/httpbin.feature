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

