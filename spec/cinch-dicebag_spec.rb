require 'spec_helper'

describe Cinch::Plugins::Dicebag do

  before(:each) do
    @plugin = Cinch::Plugins::Dicebag.new
  end

  it "should return a string from rolling dice" do
    @plugin.roll('thom', '3d3').should_not be_nil
  end

  it "should return a string from rolling a dicebag" do
    @plugin.roll_dicebag('user', Cinch::Channel.new('foo', fake_bot)).should_not be_nil
  end

end
