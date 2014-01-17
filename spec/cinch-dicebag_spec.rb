require 'spec_helper'

describe Cinch::Plugins::Dicebag do
  include Cinch::Test

  before(:all) do
    @bot = make_bot(Cinch::Plugins::Dicebag, { filename: '/dev/null' })
  end

  describe 'rolling specific dice' do
    it 'should return a roll from rolling dice' do
      get_replies(make_message(@bot, '!roll 3d3', { nick: 'ted' })).first.
        should_not be_nil
    end

    it 'should return a roll in bounds from rolling dice' do
      roll = get_replies(make_message(@bot, '!roll 3d3', { nick: 'ted' })).first.text
      roll = roll[/totalling (\d+)/, 1]
      (3..9).should include roll.to_i
    end

    it 'should disallow rolling stupid numbers of dice' do
      get_replies(make_message(@bot, '!roll 100001d20', { nick: 'ted' })).first.
        should include 'I don\'t have that many dice in my bag!'
    end

    it 'should disallow rolling stupid numbers of dice (multiple dice types)' do
      get_replies(make_message(@bot, '!roll 5000d3 5000d20 1d30', { nick: 'ted' })).first.
        should include 'I don\'t have that many dice in my bag!'
    end

    it 'should return a roll from rolling mixes of dice' do
      get_replies(make_message(@bot, '!roll 3d3 d7 3d21', { nick: 'ted' })).first.
        should_not be_nil
    end

    it 'should return a roll in bounds from rolling mixes of dice' do
      roll = get_replies(make_message(@bot, '!roll 3d3 d7 3d21', { nick: 'ted' })).first.text
      roll = roll[/totalling (\d+)/, 1]
      (7..79).should include roll.to_i
    end

    it 'should return a roll from rolling a single die' do
      get_replies(make_message(@bot, '!roll d3', { nick: 'ted' })).first.
        should_not be_nil
    end

    it 'should not return a string from rolling dice without a name' do
      get_replies(make_message(@bot, '!roll .' , { nick: 'ted' })).first.
        should be_nil
    end

    it 'should return a string describing the dice that were rolled' do
      text = get_replies(make_message(@bot, '!roll 3d3', { nick: 'ted' })).first.text
      text.should match(/rolls\s3d3\stotalling\s\d+/)
    end
  end

  describe 'roll_dicebag' do
    it 'should return a string' do
      get_replies(make_message(@bot, '!dicebag' , { nick: 'ted', channel: '#bar' })).first.
        should_not be_nil
    end

    it 'should return an error if the user is not in a channel' do
      get_replies(make_message(@bot, '!dicebag' , { nick: 'ted' })).first.text.
        should be_eql("You must use that command in the main channel")
    end

    it 'should return a string describing the user\'s bag roll' do
      get_replies(make_message(@bot, '!dicebag' , { nick: 'ted', channel: '#bar' })).first.text.
        should match(/ted rolls a [a-z]+ bag of dice totalling \d+/)
    end

    it 'should announce a high score if the old score is higher' do
      get_replies(make_message(@bot, '!dicebag' , { nick: 'brian', channel: '#foo' }))
      @bot.plugins.first.storage.data['#foo']['brian'] = { score: 1, time: Time.now }
      text = get_replies(make_message(@bot, '!dicebag' , { nick: 'brian', channel: '#foo' })).first.text
      text.should match(/A new high score/)
      text.should match(/Their old high roll was \d+/)

    end
  end

  describe 'roll_dice' do
    it 'should return nil if the dice list is empty' do
      @bot.plugins.first.roll_dice([]).should be_nil
    end

    it 'should return a non zero total on a normal dice list' do
      @bot.plugins.first.roll_dice(['3d3', '4d5']).should_not be_zero
    end

    it 'should clear out any invalid dice rolls' do
      @bot.plugins.first.roll_dice(['33']).should be_nil
    end
  end

  describe 'roll_die' do
    it 'should return an acceptable value for a given roll' do
      @bot.plugins.first.roll_die('1d1').should == 1
      (5..15).should include(@bot.plugins.first.roll_die('3d5'))
    end

    it 'should return 0 for any negetive values' do
      @bot.plugins.first.roll_die('1d-1').should == 0
      @bot.plugins.first.roll_die('-1d-1').should == 0
    end
  end

  describe 'get_bag_size' do
    it 'should return \'huge\' for out of bounds queries' do
      @bot.plugins.first.get_bag_size(50000).should == 'huge'
    end

    it 'should return the proper size for tiny range' do
      @bot.plugins.first.get_bag_size(0).should            == 'tiny'
      @bot.plugins.first.get_bag_size(rand(100)).should    == 'tiny'
      @bot.plugins.first.get_bag_size(100).should          == 'tiny'
    end

    it 'should return the proper size for small range' do
      @bot.plugins.first.get_bag_size(101).should              == 'small'
      @bot.plugins.first.get_bag_size(rand(399) + 101).should  == 'small'
      @bot.plugins.first.get_bag_size(500).should              == 'small'
    end

    it 'should return the proper size for medium range' do
      @bot.plugins.first.get_bag_size(501).should              == 'medium'
      @bot.plugins.first.get_bag_size(rand(499) + 501).should  == 'medium'
      @bot.plugins.first.get_bag_size(1000).should             == 'medium'
    end

    it 'should return the proper size for large range' do
      @bot.plugins.first.get_bag_size(1001).should              == 'large'
      @bot.plugins.first.get_bag_size(rand(499) + 1001).should  == 'large'
      @bot.plugins.first.get_bag_size(1500).should              == 'large'
    end

    it 'should return the proper size for hefty range' do
      @bot.plugins.first.get_bag_size(1501).should              == 'hefty'
      @bot.plugins.first.get_bag_size(rand(499) + 1501).should  == 'hefty'
      @bot.plugins.first.get_bag_size(2000).should              == 'hefty'
    end

    it 'should return the proper size for huge range' do
      @bot.plugins.first.get_bag_size(2001).should              == 'huge'
      @bot.plugins.first.get_bag_size(20001).should             == 'huge'
    end
  end
end

