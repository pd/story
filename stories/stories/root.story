Story: running stories found in stories/stories/*.story

  Scenario: this file!
    When this story is found
    Then it should have access to the 'root' step group

  Scenario: also works with symbols
    Then the symbol form should be available 
