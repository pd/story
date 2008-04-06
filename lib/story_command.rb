require 'English'
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
        :step_groups => [],
        :story_dir => 'stories/stories',
        :helper_file => 'stories/helper.rb'
      }
    end

    def initialize
      super
      @options = default_options
      on('-R', '--[no-]rails', 'Run stories as type RailsStory') do |bool|
        @options[:rails] = bool
      end
      on('-s', '--step-group NAME', 'Defines a step group to be provided to all stories') do |name|
        @options[:step_groups] << name
      end
      on('-S', '--story-dir DIR', 'Sets the directory from which .story files are loaded (default: stories/stories)') do |dir|
        @options[:story_dir] = dir
      end
      on('-H', '--helper-file FILE', 'Specifies the helper file to load (default: stories/helper.rb)') do |file|
        @options[:helper_file] = file
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
      require(@options[:helper_file])

      stories.each do |story|
        steps  = global_step_groups.dup
        steps += steps_from_story_name(story_name_from_path(story))
        steps += steps_from_story_contents(story)
        run_story(story, steps, using_rails? ? RailsStory : nil)
      end
    end

    def story_name_from_path(path)
      path.sub('.story', '').sub(/^.*?#{Regexp.escape(@options[:story_dir])}\//, '')
    end

    def steps_from_story_name(name)
      tokens = name.sub('.story', '').split('/')
      [ tokens,
        (1..tokens.length-1).map { |i| tokens[0..i].join('/') }
      ].flatten.uniq
    end

    def steps_from_story_contents(path)
      header = read_story_header(path)
      if header =~ /^#\s*\+steps: /
        $POSTMATCH.chomp.split(',').map { |s| s.strip }
      else
        []
      end
    end

    def global_step_groups
      @options[:step_groups]
    end

    def using_rails?
      @options[:rails]
    end

    # Assume it works.
    def run_story(file, steps, type)
      with_steps_for(*steps) do
        run file, :type => type
      end
    end

    # Assume it works.
    def read_story_header(path)
      File.open(path) { |f| f.readline }
    rescue
      ''
    end
  end
end
