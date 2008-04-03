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
    if @args.empty?
      run_story_files(stories_beneath(story_store))
    else
      stories = @args.map { |arg| stories_beneath(arg) }.flatten
      run_story_files(stories)
    end
  end

  def stories_beneath(path)
    if File.directory?(path)
      Dir.glob(File.join(path, '**', '*.story')).uniq
    else
      [path]
    end
  end

  def using_rails?
    options[:rails]
  end

  def map_story_paths_to_names(paths)
    names = paths.map { |p| File.expand_path(p) }
    names.map! { |name| name.gsub(/\.story$/, '').gsub(%r[#{story_store}/], '') }
    paths.zip(names)
  end

  def run_story_files(files)
    map_story_paths_to_names(files).each do |file, story_name|
      setup_and_run_story(file, story_name)
    end
  end

  def setup_and_run_story(story_file, story_name)
    require(story_helper)

    steps = steps_for_story(story_file, story_name)

    step_files_to_load = steps.map do |step|
      options[:steps_path].map { |path| "#{path}/#{step}.rb" }
    end.flatten.compact
    step_files_to_load.select { |file| File.exist?(file) }.each { |file| require file }

    run_story(story_file, steps)
  end

  def steps_for_story(file, story_name)
    steps  = [story_name, story_name.to_s.split('/')]
    steps += options[:global_steps]

    first_line = File.open(file) { |f| f.readline }
    if first_line =~ /^# \+?steps: /
      steps << first_line.gsub(/^# \+?steps: /, '').split(',').map { |x| x.strip }
    end

    steps = steps.uniq.flatten
    steps += steps.map { |step| step.to_sym }
  end

  def run_story(file, steps)
    story_type = using_rails? ? RailsStory : nil
    with_steps_for(*steps) do
      run file, :type => story_type
    end
  end

  private
    def parse_arguments(args)
      parser = OptionParser.new
      parser.order!(args)
      [parser.options, args]
    end

end
