# +steps: some other name

Story: step group names which do not match file names

  Scenario: using the step group 'some other name'
    Given that the step file name does not match the step group
    And that the helper file loaded the file the step group is in
    Then the step group should still be included
