require 'English'
require 'optparse'

# ganked from facets
module Enumerable
  def split(pattern)
    memo = [[]]
    each do |obj|
      if pattern === obj
        memo.push []
      else
        memo.last << obj
      end
    end
    memo
  end
end

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
        :helper_file => 'stories/helper.rb',
        :rspec_options => []
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
      on('-H', '--helper-file PATH', 'The path to the helper file to load (default: stories/helper.rb)') do |path|
        @options[:helper_file] = path
      end
      on('-O', '--options PATH', 'The path to a story.opts to load (default: stories/story.opts)') do |path|
        begin
          lines = IO.readlines(path).map { |l| l.chomp }
          opts, rspec_opts = lines.split('--')
          @options[:rspec_options].push *rspec_opts
          order(*opts)
        rescue
        end
      end
    end
  end

  # named solely due to the abundance of *Runners out there
  class Engine
    attr_reader :stories
    attr_reader :rspec_options

    def initialize(argv, options_file = nil)
      @argv = argv.dup
      @argv.unshift(*['-O', options_file]) if options_file && File.exist?(options_file)

      parser = OptionParser.new
      @argv = parser.order(@argv)
      @options = parser.options

      if @argv.empty?
        @stories = Dir.glob('stories/stories/**/*.story')
      else
        @stories = @argv.map do |arg|
          File.directory?(arg) ? Dir.glob("#{arg}/**/*.story") : arg
        end.flatten
      end

      # coerces rspec into parsing options like --colour
      ARGV.clear
      ARGV.push *rspec_options
    end

    def run
      require(@options[:helper_file])

      stories.each do |story|
        steps  = global_step_groups.dup
        steps += steps_from_story_name(story_name_from_path(story))
        steps += steps_from_story_contents(story)
        steps += steps.map { |s| s.to_sym }
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

    def rspec_options
      @options[:rspec_options]
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
