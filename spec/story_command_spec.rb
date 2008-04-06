require File.dirname(__FILE__) + '/spec_helper'

class RailsStory; end

describe StoryCommand, 'story discovery:' do
  it "should default to running all .story files beneath stories/stories" do
    Dir.should_receive(:glob).with('stories/stories/**/*.story').and_return(['a', 'b'])
    sc = StoryCommand.new []
    sc.stories.should == %w(a b)
  end

  it "should run the story files passed in as arguments" do
    sc = StoryCommand.new %w(stories/a.story b.story)
    sc.stories.should == %w(stories/a.story b.story)
  end

  it "should recurse through directories looking for .story files" do
    File.should_receive(:directory?).with('a').and_return(true)
    File.should_receive(:directory?).with('b').and_return(false)
    Dir.should_receive(:glob).with('a/**/*.story').and_return(['a/deep.story'])

    sc = StoryCommand.new %w(a b)
    sc.stories.should == %w(a/deep.story b)
  end
end

describe StoryCommand, 'step group name inference:' do
  it "should return 'foo' for a story named 'foo.story'" do
    sc = StoryCommand.new []
    sc.steps_from_story_name('foo.story').should == %w(foo)
  end

  it "should return 'foo', 'bar', and 'foo/bar' for a story named 'foo/bar.story'" do
    sc = StoryCommand.new []
    sc.steps_from_story_name('foo/bar.story').should == %w(foo bar foo/bar)
  end

  it "should return 'foo', 'bar', 'baz', 'foo/bar', and 'foo/bar/baz' for a story named 'foo/bar/baz.story'" do
    sc = StoryCommand.new []
    sc.steps_from_story_name('foo/bar/baz.story').should == %w(foo bar baz foo/bar foo/bar/baz)
  end

  it "should run the story with the inferred step groups" do
    sc = StoryCommand.new %w(foo/bar.story)
    sc.should_receive(:run_story).with('foo/bar.story', ['foo', 'bar', 'foo/bar'], nil)
    sc.run
  end
end

describe StoryCommand, 'global step groups:' do
  it "should result in stories being run with their steps" do
    sc = StoryCommand.new %w(-s foo --step-group bar a.story)
    sc.should_receive(:run_story).with('a.story', include('foo', 'bar'), nil)
    sc.run
  end

  it "should be empty by default" do
    sc = StoryCommand.new %w(a.story)
    sc.should_receive(:run_story).with('a.story', ['a'], nil)
    sc.run
  end
end

describe StoryCommand, 'rails interop:' do
  it "should be off by default" do
    sc = StoryCommand.new %w(a.story)
    sc.should_receive(:run_story).with('a.story', an_instance_of(Array), nil)
    sc.run
  end

  it "should result in stories being run as a RailsStory" do
    sc = StoryCommand.new %w(--rails a.story)
    sc.should_receive(:run_story).with('a.story', an_instance_of(Array), RailsStory)
    sc.run
  end
end
