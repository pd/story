require File.dirname(__FILE__) + '/spec_helper'

class RailsStory; end

def neutered_story_command(*args)
  sc = StoryCommand.new(*args)
  sc.stub!(:require)
  sc.stub!(:run_story)
  sc
end

describe StoryCommand, 'story discovery:' do
  it "should default to running all .story files beneath stories/stories" do
    Dir.should_receive(:glob).with('stories/stories/**/*.story').and_return(['a', 'b'])
    sc = neutered_story_command []
    sc.stories.should == %w(a b)
  end

  it "should run the story files passed in as arguments" do
    sc = neutered_story_command %w(stories/a.story b.story)
    sc.stories.should == %w(stories/a.story b.story)
  end

  it "should recurse through directories looking for .story files" do
    File.should_receive(:directory?).with('a').and_return(true)
    File.should_receive(:directory?).with('b').and_return(false)
    Dir.should_receive(:glob).with('a/**/*.story').and_return(['a/deep.story'])

    sc = neutered_story_command %w(a b)
    sc.stories.should == %w(a/deep.story b)
  end
end

describe StoryCommand, 'helper file:' do
  it "should be required before running stories" do
    sc = neutered_story_command []
    sc.should_receive(:require).with('stories/helper.rb')
    sc.run
  end

  it "should be default to 'stories/helper.rb'" do
    # meh see above
  end

  it "should be defined with the -H / --helper-file option" do
    %w(-H --helper-file).each do |opt|
      sc = neutered_story_command [opt, 'different/helper.rb']
      sc.should_not_receive(:require).with('stories/helper.rb')
      sc.should_receive(:require).with('different/helper.rb')
      sc.run
    end
  end
end

describe StoryCommand, 'step group name inference:' do
  it "should return 'foo' for a story named 'foo.story'" do
    sc = neutered_story_command []
    sc.steps_from_story_name('foo.story').should == %w(foo)
  end

  it "should return 'foo', 'bar', and 'foo/bar' for a story named 'foo/bar.story'" do
    sc = neutered_story_command []
    sc.steps_from_story_name('foo/bar.story').should == %w(foo bar foo/bar)
  end

  it "should return 'foo', 'bar', 'baz', 'foo/bar', and 'foo/bar/baz' for a story named 'foo/bar/baz.story'" do
    sc = neutered_story_command []
    sc.steps_from_story_name('foo/bar/baz.story').should == %w(foo bar baz foo/bar foo/bar/baz)
  end

  it "should run the story with the inferred step groups" do
    sc = neutered_story_command %w(foo/bar.story)
    sc.should_receive(:run_story).with('foo/bar.story', ['foo', 'bar', 'foo/bar'], nil)
    sc.run
  end
end

describe StoryCommand, 'global step groups:' do
  it "should result in stories being run with their steps" do
    sc = neutered_story_command %w(-s foo --step-group bar a.story)
    sc.should_receive(:run_story).with('a.story', include('foo', 'bar'), nil)
    sc.run
  end

  it "should be empty by default" do
    sc = neutered_story_command %w(a.story)
    sc.should_receive(:run_story).with('a.story', ['a'], nil)
    sc.run
  end
end

describe StoryCommand, 'per-story step group inclusion:' do
  it "should include steps named using '# +steps: a, b' at the top of the .story file" do
    sc = neutered_story_command []
    sc.stub!(:read_story_header).and_return("# +steps: foo, bar\n")
    sc.steps_from_story_contents('path/to/the.story').should == %w(foo bar)
  end

  it "should support spaces in the step group names" do
    sc = neutered_story_command []
    sc.stub!(:read_story_header).and_return("# +steps: foo bar, baz/quux")
    sc.steps_from_story_contents('path/to/the.story').should == ['foo bar', 'baz/quux']
  end

  it "should be empty if the story does not contain such a line" do
    sc = neutered_story_command []
    sc.stub!(:read_story_header).and_return('Story: hey a story')
    sc.steps_from_story_contents('path/to/the.story').should == []
  end

  it "should run the story with its specified steps" do
    sc = neutered_story_command %w(a.story)
    sc.stub!(:read_story_header).and_return('# +steps: test, steps')
    sc.should_receive(:run_story).with('a.story', include('test', 'steps'), nil)
    sc.run
  end

  it "should not bleed specified steps between stories" do
    sc = neutered_story_command %w(a.story b.story)
    sc.stub!(:read_story_header).twice.and_return('# +steps: test', '# +steps: not a test')
    sc.should_receive(:run_story).with('a.story', include('test'), nil)
    sc.should_receive(:run_story).with('b.story', include('not a test'), nil)
    sc.run
  end
end

describe StoryCommand, 'rails interop:' do
  it "should be off by default" do
    sc = neutered_story_command %w(a.story)
    sc.should_receive(:run_story).with('a.story', an_instance_of(Array), nil)
    sc.run
  end

  it "should result in stories being run as a RailsStory" do
    sc = neutered_story_command %w(--rails a.story)
    sc.should_receive(:run_story).with('a.story', an_instance_of(Array), RailsStory)
    sc.run
  end
end
