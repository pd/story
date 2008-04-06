steps_for('root') do
  When('this story is found') do end
  Then('it should have access to the \'root\' step group') do end
end

steps_for(:root) do
  Then('the symbol form should be available') do end
end
