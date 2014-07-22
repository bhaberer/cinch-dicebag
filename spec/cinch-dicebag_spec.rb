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

    it 'should return a roll from using a blank roll' do
      get_replies(make_message(@bot, '!roll', { nick: 'ted' })).first.
        should_not be_nil
    end

    it 'should allow "+" modifiers' do
      roll = get_replies(make_message(@bot, '!roll 1d3+5', { nick: 'ted' })).first.text
      roll = roll[/totalling (\d+)/, 1]
      (6..8).should include roll.to_i
    end

    it 'should allow "-" modifiers' do
      roll = get_replies(make_message(@bot, '!roll 1d1-5', { nick: 'ted' }))
              .first
              .text[/totalling (\-?\d+)/, 1].to_i
              .should == -4
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
        should == 'You must use that command in the main channel.'
    end

    it 'should return a string describing the user\'s bag roll' do
      get_replies(make_message(@bot, '!dicebag' , { nick: 'ted', channel: '#bar' })).first.text.
        should match(/ted rolls a [a-z]+ bag of dice totalling \d+/)
    end
  end

  describe 'scores' do
    before(:each) do
      @bot.plugins.first.storage.data['#foo'] = { 'brian' => { score: 1, time: Time.now },
                                                  'braad' => { score: 2, time: Time.now },
                                                  'billy' => { score: 3, time: Time.now },
                                                  'britt' => { score: 4, time: Time.now },
                                                  'brett' => { score: 5, time: Time.now },
                                                  'paulv' => { score: 6, time: Time.now },
                                                  'stacy' => { score: 7, time: Time.now },
                                                  'calrs' => { score: 8, time: Time.now },
                                                  'susie' => { score: 9, time: Time.now },
                                                  'enton' => { score: 10, time: Time.now },
                                                  'grill' => { score: 11, time: Time.now },
                                                  'evilg' => { score: 12, time: Time.now },
                                                  'mobiu' => { score: 13, time: Time.now },
                                                  'gamma' => { score: 14, time: Time.now },
                                                  'omega' => { score: 15, time: Time.now } }
    end

    it 'should announce a high score if the old score is higher' do
      text = get_replies(make_message(@bot, '!dicebag' , { nick: 'brian', channel: '#foo' })).first.text
      text.should match(/A new high score/)
      text.should match(/Their old high roll was \d+/)
    end

    it 'should allow users to get a copy of the high scores' do
      replies = get_replies(make_message(@bot, '!dicebag stats' , { nick: 'brian', channel: '#foo' }))
      replies[1].text.should == '1 - omega [15]'
      replies[5].text.should == '5 - grill [11]'
    end

    it 'should only show the first 10 scores' do
      replies = get_replies(make_message(@bot, '!dicebag stats' , { nick: 'brian', channel: '#foo' }))
      replies.length.should == 11
    end
  end

  describe 'roll_dice' do
    it 'should return nil if the dice list is empty' do
      Cinch::Plugins::Dicebag::Die.roll([]).should be_nil
    end

    it 'should return a non zero total on a normal dice list' do
      Cinch::Plugins::Dicebag::Die.roll(['3d3', '4d5']).should_not be_zero
    end

    it 'should clear out any invalid dice rolls' do
      Cinch::Plugins::Dicebag::Die.roll(['33']).should be_nil
    end

    it 'should allow modifiers' do
      Cinch::Plugins::Dicebag::Die.roll(['1d1+1', '1d1-4']).should == -1
    end
  end

  describe 'Die.roll' do
    it 'should return an acceptable value for a given roll' do
      Cinch::Plugins::Dicebag::Die.roll('1d1').should == 1
      (3..15).should include(Cinch::Plugins::Dicebag::Die.roll('3d5'))
    end

    it 'should return nil for any negetive values' do
      Cinch::Plugins::Dicebag::Die.roll('1d-1').should == nil
      Cinch::Plugins::Dicebag::Die.roll('-1d-1').should == nil
    end

    it 'should add modifiers to the total' do
      Cinch::Plugins::Dicebag::Die.roll('1d1+2').should == 3
      Cinch::Plugins::Dicebag::Die.roll('3d1-2').should == 1
    end

    it 'should allow modifiers to take the total below zero' do
      Cinch::Plugins::Dicebag::Die.roll('1d1-1').should == 0
      Cinch::Plugins::Dicebag::Die.roll('1d1-2').should == -1
    end
  end

  describe 'get_bag_size' do
    before(:each) do
      @bag = Cinch::Plugins::Dicebag::Bag.new({})
    end

    it 'should return \'huge\' for out of bounds queries' do
      @bag.count = 50000
      @bag.size.should == 'huge'
    end

    it 'should return the proper size for tiny range' do
      @bag.count = 0
      @bag.size.should == 'tiny'
    end

    it 'should return the proper size for small range' do
      @bag.count = rand(100)
      @bag.size.should == 'tiny'
    end

    it 'should return the proper size for small range' do
      @bag.count = 100
      @bag.size.should == 'tiny'
    end

    it 'should return the proper size for small range' do
      @bag.count = 101
      @bag.size.should == 'small'
    end

    it 'should return the proper size for small range' do
      @bag.count = rand(399) + 101
      @bag.size.should == 'small'
    end

    it 'should return the proper size for small range' do
      @bag.count = 500
      @bag.size.should == 'small'
    end

    it 'should return the proper size for medium range' do
      @bag.count = 501
      @bag.size.should == 'medium'
    end

    it 'should return the proper size for medium range' do
      @bag.count = rand(499) + 501
      @bag.size.should == 'medium'
    end

    it 'should return the proper size for medium range' do
      @bag.count = 1000
      @bag.size.should == 'medium'
    end

    it 'should return the proper size for large range' do
      @bag.count = 1001
      @bag.size.should == 'large'
    end

    it 'should return the proper size for large range' do
      @bag.count = rand(499) + 1001
      @bag.size.should == 'large'
    end

    it 'should return the proper size for large range' do
      @bag.count = 1500
      @bag.size.should == 'large'
    end

    it 'should return the proper size for hefty range' do
      @bag.count = 1501
      @bag.size.should == 'hefty'
    end

    it 'should return the proper size for hefty range' do
      @bag.count = rand(499) + 1501
      @bag.size.should == 'hefty'
    end

    it 'should return the proper size for hefty range' do
      @bag.count = 2000
      @bag.size.should == 'hefty'
    end

    it 'should return the proper size for huge range' do
      @bag.count = 2001
      @bag.size.should == 'huge'
    end

    it 'should return the proper size for huge range' do
      @bag.count = 20001
      @bag.size.should == 'huge'
    end
  end
end
