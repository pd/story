require 'optparse'

class StoryCommand
  class OptionParser < ::OptionParser
    attr_reader :options

    OPTIONS = {
      :rails => ['-R', '--rails', 'Run stories as type RailsStory'],
      :global_steps => ['-g', '--global-steps STEPS', 'Comma separated list of step groups to always include'],
      :steps => ['-s', '--steps-path PATH', 'Add a path to the list of directories to load step groups from'],
      :options_file => ['-O', '--options PATH', 'Read options from a file']
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
      on(*OPTIONS[:options_file]) do |path|
        parse_options_file(path)
      end
    end

    def order!(argv, &blk)
      @argv = argv
      super(@argv)
      @options
    end

    def parse_options_file(options_file)
      args = IO.readlines(options_file).map { |l| l.chomp }
      @argv.unshift(*args)
    end
  end
end

class StoryCommand
  attr_reader :project_root
  attr_reader :options

  def initialize(args, project_root = nil)
    @project_root = File.expand_path(project_root || Dir.pwd)

    args = args.dup
    args.unshift('-O', default_opts_path) if File.exist?(default_opts_path)

    @options, @args = parse_arguments(args)
    options[:steps_path] << step_store
  end

  def story_root
    File.join(project_root, 'stories')
  end

  def step_store
    File.join(story_root, 'steps')
  end

  def story_store
    File.join(story_root, 'stories')
  end

  def story_helper
    File.join(story_root, 'helper')
  end

  def default_opts_path
    File.join(story_root, 'story.opts')
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
    Dir["#{story_store}/**/*.story"].uniq
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

  # what's the point of this?
  # we then go *back* through and reconstruct the paths later, possibly incorrectly.
  def clean_story_paths(paths)
    paths = paths.map { |path| File.expand_path(path) }
    paths.map! { |path| File.directory?(path) ? Dir.glob("#{path}/**/*.story") : path }
    paths.flatten!
    paths.map! { |path| path.gsub(/\.story$/, "") }
    paths.map! { |path| path.gsub(/#{story_store}\//, "") }
  end

  def run_story_files(stories)
    clean_story_paths(stories).each do |story|
      setup_and_run_story(File.readlines("#{story_store}/#{story}.story"), story)
    end
  end

  def setup_and_run_story(lines, story_name = nil)
    require(story_helper)

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

  def run_story(lines, steps)
    tempfile = Tempfile.new("story")
    lines.each do |line|
      tempfile.puts line
    end
    tempfile.close

    steps += steps.map { |step| step.to_sym }
    story_type = using_rails? ? RailsStory : nil
    with_steps_for(*steps) do
      run tempfile.path, :type => story_type
    end
  end

  private
    def parse_arguments(args)
      parser = OptionParser.new
      parser.order!(args)
      [parser.options, args]
    end

end
