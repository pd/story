require 'rubygems'
require 'spec/story'

# Any step groups that may be loaded need to be required here,
# so that they are available once `story` tries to run the story.
Dir["#{File.dirname(__FILE__)}/steps/**/*.rb"].each { |f| require f }
