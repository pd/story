class StoryCommand
  ROOT_PATH = Dir.pwd

  STORIES_PATH        = "#{ROOT_PATH}/stories/stories"
  STEP_MATCHERS_PATHS = ["#{ROOT_PATH}/stories/steps"]
  HELPER_PATH         = "#{ROOT_PATH}/stories/helper"

  def self.run
    self.new.run
  end

  def run
    if ARGV.empty? && first_char = using_stdin?
      setup_and_run_story((first_char + STDIN.read).split("\n"))
    elsif ARGV.empty?
      run_story_files(all_story_files)
    else
      run_story_files(ARGV)
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

  def clean_story_paths(paths)
    paths.map! { |path| File.expand_path(path) }
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
      STEP_MATCHERS_PATHS.map { |path| "#{path}/#{step}.rb" }
    end.flatten.compact
    files.select { |file| File.exist?(file) }.each { |file| require file }

    run_story(lines, steps)
  end

  def steps_for_story(lines, story_name)
    steps  = [story_name, story_name.to_s.split('/')]
    steps += %w(generic common)
    if lines.first =~ /^# \+?steps: /
      steps << lines.first.gsub(/^# \+?steps: /, '').split(',').map { |x| x.strip }
    end
    steps.flatten
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
    with_steps_for(*steps) do
      run tempfile.path #, :type => RailsStory
    end
  end

end
