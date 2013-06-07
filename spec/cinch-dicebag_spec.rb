require 'spec_helper'

describe Cinch::Plugins::Dicebag do

  before(:all) do
    @plugin = Cinch::Plugins::Dicebag.new
  end

  describe 'roll' do
    it "should return a string from rolling dice" do
      @plugin.roll('thom', '3d3').should_not be_nil
    end

    it "should return a string from rolling a die" do
      @plugin.roll('thom', 'd3').should_not be_nil
    end

    it "should not return a string from rolling dice without a name" do
      @plugin.roll(nil, '3d3').should be_nil
    end
  end

  it "should return a string from rolling a dicebag" do
    @plugin.roll_dicebag('user', Cinch::Channel.new('foo', fake_bot)).should_not be_nil
  end

end
