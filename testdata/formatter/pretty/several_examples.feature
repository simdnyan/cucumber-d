Feature: Tagged Examples

  Scenario Outline: minimalistic
    Given the <what>

    @foo
    Examples: 
      | what |
      | foo  |
    @bar

    Examples: 
      | what |
      | bar  |

2 scenarios (2 undefined)
2 steps (2 undefined)
