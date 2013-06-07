require 'spec_helper'

describe Cinch::Plugins::Dicebag do

  before(:all) do
    @plugin = Cinch::Plugins::Dicebag.new
  end

  describe 'rolling specific dice' do
    it "should return a string from rolling multiple dice" do
      @plugin.roll('thom', '3d3').should_not be_nil
    end

    it "should return a string from rolling mixes of dice" do
      @plugin.roll('thom', '3d3 d7 3d25').should_not be_nil
    end

    it "should return a string from rolling a single die" do
      @plugin.roll('thom', 'd3').should_not be_nil
    end

    it "should not return a string from rolling dice without a name" do
      @plugin.roll(nil, '3d3').should be_nil
    end

    it "should not return a string from rolling dice without a name" do
      @plugin.roll('joe', nil).should be_nil
    end

    it "should return a string describing the dice that were rolled" do
      text = @plugin.roll('thom', '3d3')
      text.match(/rolls\s3d3\stotalling\s\d+/).should_not be_nil
    end
  end

  describe 'rolling a dicebag' do
    it "should return a string" do
      @plugin.roll_dicebag('user', Cinch::Channel.new('foo', fake_bot)).should_not be_nil
    end

    it "should return an error if the user is not in a channel" do
      @plugin.roll_dicebag('user', nil).
        should be_eql("You must use that command in the main channel.")
    end

    it "should return a string describing the user's bag roll" do
      text = @plugin.roll_dicebag('user', Cinch::Channel.new('foo', fake_bot))
      text.match(/user rolls a [a-z]+ bag of dice totalling \d+/).should_not be_nil
    end

    it "should announce a high score if the old score is higher" do
      @plugin.storage.data['thom'] = { :score => 1, :time => Time.now }
      text = @plugin.roll_dicebag('user', Cinch::Channel.new('foo', fake_bot))
      text.match(/A new high score! Their old high roll was \d+/).should_not be_nil
    end
  end

end
