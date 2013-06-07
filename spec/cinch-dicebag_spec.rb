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

  describe 'roll_dicebag' do
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
      @plugin.storage.data['foo']['brian'] = { :score => 1, :time => Time.now }
      text = @plugin.roll_dicebag('brian', Cinch::Channel.new('foo', fake_bot))
      text.match(/A new high score/).should_not be_nil
      text.match(/Their old high roll was \d+/).should_not be_nil
    end
  end

  describe 'roll_dice' do
    it "should return zero if the dice list is empty" do
      @plugin.roll_dice([]).should be_zero
    end

    it "should return a non zero total on a normal dice list" do
      @plugin.roll_dice(['3d3', '4d5']).should_not be_zero
    end

    it "should clear out any invalid dice rolls" do
      @plugin.roll_dice(['33']).should be_zero
    end
  end

  describe "roll_die" do
    it "should return an acceptable value for a given roll" do
      @plugin.roll_die(1, 1).should == 1
      (5..15).should include(@plugin.roll_die(3, 5))
    end

    it "should return 0 for any negetive values" do
      @plugin.roll_die(-1,  1).should == 0
      @plugin.roll_die( 1, -1).should == 0
      @plugin.roll_die(-1, -1).should == 0
    end
  end

  describe "get_bag_size" do
    it "should return 'huge' for out of bounds queries" do
      @plugin.get_bag_size(50000).should == 'huge'
    end

    it "should return the proper size for tiny range" do
      @plugin.get_bag_size(0).should            == 'tiny'
      @plugin.get_bag_size(rand(100)).should    == 'tiny'
      @plugin.get_bag_size(100).should          == 'tiny'
    end

    it "should return the proper size for small range" do
      @plugin.get_bag_size(101).should              == 'small'
      @plugin.get_bag_size(rand(399) + 101).should  == 'small'
      @plugin.get_bag_size(500).should              == 'small'
    end

    it "should return the proper size for medium range" do
      @plugin.get_bag_size(501).should              == 'medium'
      @plugin.get_bag_size(rand(499) + 501).should  == 'medium'
      @plugin.get_bag_size(1000).should             == 'medium'
    end

    it "should return the proper size for large range" do
      @plugin.get_bag_size(1001).should              == 'large'
      @plugin.get_bag_size(rand(499) + 1001).should  == 'large'
      @plugin.get_bag_size(1500).should              == 'large'
    end

    it "should return the proper size for hefty range" do
      @plugin.get_bag_size(1501).should              == 'hefty'
      @plugin.get_bag_size(rand(499) + 1501).should  == 'hefty'
      @plugin.get_bag_size(2000).should              == 'hefty'
    end

    it "should return the proper size for huge range" do
      @plugin.get_bag_size(2001).should              == 'huge'
      @plugin.get_bag_size(20001).should             == 'huge'
    end
  end
end
