# These are all collapsed into a single file, but in a real environment
# could be split into feature.rb, topic.rb, feature/topic.rb, etc.

steps_for('feature') do
  Then("the 'feature' step group should be available") do end
end

steps_for('topic') do
  Then("the 'topic' step group should be available") do end
end

steps_for('branch') do
  Then("the 'branch' step group should be available") do end
end

steps_for('feature/topic') do
  Then("the 'feature/topic' step group should be available") do end
end

steps_for('feature/topic/branch') do
  Then("the 'feature/topic/branch' step group should be available") do end
end
