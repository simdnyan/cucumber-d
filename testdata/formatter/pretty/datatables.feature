Feature: DataTables

  Scenario: minimalistic
    Given a simple data table
      | foo | bar |
      | boz | boo |
    And a data table with a single cell
      | foo |
    And a data table with different fromatting
      | foo | bar | boz |
    And a data table with an empty cell
      | foo |  | boz |
    And a data table with comments and newlines inside
      | foo  | bar  |
      | boz  | boo  |
      | boz2 | boo2 |

1 scenario (1 undefined)
5 steps (5 undefined)
