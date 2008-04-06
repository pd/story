Story: the options in story.opts are honoured

  Scenario: step groups named with -s are globally available
    Then the 'global' step group should be available
    Then the 'global but less used' step group should be available
