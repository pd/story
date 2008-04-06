require 'optparse'

module StoryCommand
  class << self
    # see Engine.
    def new(*args)
      Engine.new(*args)
    end
  end

  class OptionParser < ::OptionParser
    attr_accessor :options

    def default_options
      { :rails => false,
        :step_groups => []
      }
    end

    def initialize
      super
      @options = default_options
      on('-R', '--[no-]rails', 'Run stories as type RailsStory') do |bool|
        @options[:rails] = bool
      end
      on('-s', '--step-group NAME', 'Define a step group to be provided to all stories') do |name|
        @options[:step_groups] << name
      end
    end
  end

  # named solely due to the abundance of *Runners out there
  class Engine
    attr_reader :stories

    def initialize(argv)
      parser = OptionParser.new
      @argv = parser.order(argv.dup)
      @options = parser.options

      if @argv.empty?
        @stories = Dir.glob('stories/stories/**/*.story')
      else
        @stories = @argv.map do |arg|
          File.directory?(arg) ? Dir.glob("#{arg}/**/*.story") : arg
        end.flatten
      end
    end

    def run
      stories.each do |story|
        steps  = global_step_groups.dup
        # steps += steps_from_story_name(story)
        # steps += steps_from_contents(story)
        run_story(story, steps, using_rails? ? RailsStory : nil)
      end
    end

    def steps_from_story_name(name)
      [name.sub('.story', '')]
    end

    def global_step_groups
      @options[:step_groups]
    end

    def using_rails?
      @options[:rails]
    end

    # Assume it works.
    def run_story(file, steps, type)
      with_steps_for(steps) do
        run file, :type => type
      end
    end
  end
end
