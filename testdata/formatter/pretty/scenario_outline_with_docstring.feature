Feature: Scenario Outline with a docstring

  Scenario Outline: Greetings come in many forms
    Given this file:
      """
      Greeting:<content>
      """

    Examples: 
      | type | content |
      | en   | Hello   |
      | fr   | Bonjour |

2 scenarios (2 undefined)
2 steps (2 undefined)
