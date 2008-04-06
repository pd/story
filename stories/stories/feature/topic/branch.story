Story: deep nesting

  Scenario: loads the feature, topic, and 'feature/topic' step groups
    Then the 'feature' step group should be available
    Then the 'topic' step group should be available
    Then the 'feature/topic' step group should be available

  Scenario: loads the 'feature/topic/branch' step group
    GivenScenario loads the feature, topic, and 'feature/topic' step groups
    Then the 'feature/topic/branch' step group should be available
