require 'rake/gempackagetask'
require 'spec/rake/spectask'

gemspec = Gem::Specification.new do |spec|
  spec.name = 'story'
  spec.summary = "Command line runner for rspec plain text user stories"
  spec.version = '0.1'
  spec.author = 'Kyle Hargraves'
  spec.email = 'philodespotos@gmail.com'
  spec.description = <<-END
    Provides an executable, 'story', that can be used to run suites of
    rspec plain text user stories. Gracefully handles both Rails and non-Rails
    projects.
  END

  spec.files = FileList['bin/**/*', 'lib/**/*', 'README.rdoc', 'MIT-LICENSE', 'Rakefile']
  spec.bindir = 'bin'
  spec.executables = ['story']

  spec.rubyforge_project = 'rspec-hpricot'
  spec.homepage = 'http://rspec-hpricot.rubyforge.org'
end

Rake::GemPackageTask.new(gemspec) do |spec|
end

desc "force a rebuild and install the gem"
task :reinstall => :repackage do
  `gem install pkg/story-#{gemspec.version}.gem`
end
