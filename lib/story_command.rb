require 'optparse'

class StoryCommand
  class OptionParser < ::OptionParser
    attr_reader :options

    OPTIONS = {
      :rails => ['-R', '--rails', 'Run stories as type RailsStory'],
      :global_steps => ['-g', '--global-steps STEPS', 'Comma separated list of step groups to always include'],
      :steps => ['-s', '--steps-path PATH', 'Add a path to the list of directories to load step groups from']
    }

    def default_options
      { :rails => false,
        :steps_path => ["#{Dir.pwd}/stories/steps"],
        :global_steps => []
      }
    end

    def initialize
      super()

      @options = default_options

      self.banner = 'Usage: story [options] (DIR|FILE|GLOB)'
      self.separator ''

      on(*OPTIONS[:rails]) { @options[:rails] = true }
      on(*OPTIONS[:global_steps]) do |names|
        @options[:global_steps] ||= []
        @options[:global_steps] += names.split(',').map { |x| x.strip }
      end
      on(*OPTIONS[:steps]) do |path|
        @options[:steps_path] ||= []
        @options[:steps_path] << path
      end
    end
  end
end

class StoryCommand
  attr_reader :options

  ROOT_PATH = Dir.pwd

  STORIES_PATH = "#{ROOT_PATH}/stories/stories"
  STEPS_PATHS  = ["#{ROOT_PATH}/stories/steps"]
  HELPER_PATH  = "#{ROOT_PATH}/stories/helper"

  def initialize(args)
    @options, @args = parse_arguments(args)
    options[:steps_path] += STEPS_PATHS
  end

  def run
    if @args.empty? && first_char = using_stdin?
      setup_and_run_story((first_char + STDIN.read).split("\n"))
    elsif @args.empty?
      run_story_files(all_story_files)
    else
      run_story_files(@args)
    end
  end

  def all_story_files
    Dir["#{STORIES_PATH}/**/*.story"].uniq
  end

  def using_stdin?
    char = nil
    begin
      char = STDIN.read_nonblock(1)
    rescue Errno::EAGAIN
      return false
    end
    return char
  end

  def using_rails?
    options[:rails]
  end

  def clean_story_paths(paths)
    paths = paths.map { |path| File.expand_path(path) }
    paths.map! { |path| path.gsub(/\.story$/, "") }
    paths.map! { |path| path.gsub(/#{STORIES_PATH}\//, "") }
  end

  def run_story_files(stories)
    clean_story_paths(stories).each do |story|
      setup_and_run_story(File.readlines("#{STORIES_PATH}/#{story}.story"), story)
    end
  end

  def setup_and_run_story(lines, story_name = nil)
    require HELPER_PATH

    steps = steps_for_story(lines, story_name)
    files = steps.map do |step|
      options[:steps_path].map { |path| "#{path}/#{step}.rb" }
    end.flatten.compact
    files.select { |file| File.exist?(file) }.each { |file| require file }

    run_story(lines, steps)
  end

  def steps_for_story(lines, story_name)
    steps  = [story_name, story_name.to_s.split('/')]
    steps += options[:global_steps]
    if lines.first =~ /^# \+?steps: /
      steps << lines.first.gsub(/^# \+?steps: /, '').split(',').map { |x| x.strip }
    end
    steps = steps.uniq.flatten
    steps += steps.map { |step| step.to_sym }
  end

  def steps_for_story_name(story_name)
    [story_name, story_name.to_s.split('/')].flatten
  end

  def run_story(lines, steps)
    tempfile = Tempfile.new("story")
    lines.each do |line|
      tempfile.puts line
    end
    tempfile.close

    steps += steps.map { |step| step.to_sym }
    if using_rails?
      with_steps_for(*steps) do
        run tempfile.path, :type => RailsStory
      end
    else
      with_steps_for(*steps) do
        run tempfile.path
      end
    end
  end

  private
    def parse_arguments(args)
      parser = OptionParser.new
      parser.order!(args)
      [parser.options, args]
    end

end
