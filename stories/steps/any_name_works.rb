# As long as a step group is loaded from your helper.rb,
# the filename for it is irrelevant. Just make sure the group
# names specified via steps_for() match up.

steps_for('some other name') do
  Given('that the step file name does not match the step group') do end
  Given('that the helper file loaded the file the step group is in') do end
  Then('the step group should still be included') do end
end
