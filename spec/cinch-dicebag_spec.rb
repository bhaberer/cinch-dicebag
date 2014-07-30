require 'spec_helper'

describe Cinch::Plugins::Dicebag do
  include Cinch::Test

  before(:all) do
    @bot = make_bot(Cinch::Plugins::Dicebag, { filename: '/dev/null' })
  end

  describe 'rolling specific dice' do
    it 'should return a roll from rolling dice' do
      message = get_replies(make_message(@bot, '!roll 3d3', { nick: 'ted' }))
      expect(message.first)
        .to_not be_nil
    end

    it 'should return a roll from using a blank roll' do
      expect(get_replies(make_message(@bot, '!roll', { nick: 'ted' })).first)
        .to_not be_nil
    end

    it 'should allow "+" modifiers' do
      roll = get_replies(make_message(@bot, '!roll 1d3+5', { nick: 'ted' }))
               .first.text
      roll = roll[/totalling (\d+)/, 1]
      expect(6..8).to include(roll.to_i)
    end

    it 'should allow "-" modifiers' do
      roll = get_replies(make_message(@bot, '!roll 1d1-5', { nick: 'ted' }))
              .first
              .text[/totalling (\-?\d+)/, 1].to_i
      expect(roll).to eq(-4)
    end

    it 'should return a roll in bounds from rolling dice' do
      roll = get_replies(make_message(@bot, '!roll 3d3', { nick: 'ted' })).first.text
      roll = roll[/totalling (\d+)/, 1]
      expect(3..9).to include(roll.to_i)
    end

    it 'should disallow rolling stupid numbers of dice' do
      expect(get_replies(make_message(@bot, '!roll 100001d20', { nick: 'ted' })).first.text)
        .to include('I don\'t have that many dice!')
    end

    it 'should disallow rolling stupid numbers of dice (multiple dice types)' do
      expect(get_replies(make_message(@bot, '!roll 5000d3 5000d20 1d30', { nick: 'ted' })).first.text)
        .to include('I don\'t have that many dice!')
    end

    it 'should return a roll from rolling mixes of dice' do
      expect(get_replies(make_message(@bot, '!roll 3d3 d7 3d21', { nick: 'ted' })).first)
        .to_not be_nil
    end

    it 'should return a roll in bounds from rolling mixes of dice' do
      roll = get_replies(make_message(@bot, '!roll 3d3 d7 3d21', { nick: 'ted' })).first.text
      roll = roll[/totalling (\d+)/, 1]
      expect(7..79).to include(roll.to_i)
    end

    it 'should return a roll from rolling a single die' do
      expect(get_replies(make_message(@bot, '!roll d3', { nick: 'ted' })).first)
        .to_not be_nil
    end

    it 'should return a string describing the dice that were rolled' do
      text = get_replies(make_message(@bot, '!roll 3d3', { nick: 'ted' })).first.text
      expect(text).to match(/rolls\s3d3\stotalling\s\d+/)
    end
  end

  describe 'roll_dicebag' do
    it 'should return a string' do
      expect(get_replies(make_message(@bot, '!dicebag' , { nick: 'ted', channel: '#bar' })).first)
        .to_not be_nil
    end

    it 'should return an error if the user is not in a channel' do
      expect(get_replies(make_message(@bot, '!dicebag' , { nick: 'ted' })).first.text)
        .to eq('You must use that command in the main channel.')
    end

    it 'should return a string describing the user\'s bag roll' do
      expect(get_replies(make_message(@bot, '!dicebag' , { nick: 'ted', channel: '#bar' })).first.text)
        .to match(/ted rolls a [a-z]+ bag of dice totalling \d+/)
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
      expect(text).to match(/A new high score/)
      expect(text).to match(/Their old high roll was \d+/)
    end

    it 'should allow users to get a copy of the high scores' do
      replies = get_replies(make_message(@bot, '!dicebag stats' , { nick: 'brian', channel: '#foo' }))
      expect(replies[1].text).to eq('1 - omega [15]')
      expect(replies[5].text).to eq('5 - grill [11]')
    end

    it 'should only show the first 10 scores' do
      replies = get_replies(make_message(@bot, '!dicebag stats' , { nick: 'brian', channel: '#foo' }))
      expect(replies.length).to eq(11)
    end
  end

  describe 'roll_dice' do
    it 'should return nil if the dice list is empty' do
      expect(Cinch::Plugins::Dicebag::Die.roll([])).to be_nil
    end

    it 'should return a non zero total on a normal dice list' do
      expect(Cinch::Plugins::Dicebag::Die.roll(['3d3', '4d5'])).to_not be_zero
    end

    it 'should clear out any invalid dice rolls' do
      expect(Cinch::Plugins::Dicebag::Die.roll(['33'])).to be_nil
    end

    it 'should allow modifiers' do
      expect(Cinch::Plugins::Dicebag::Die.roll(['1d1+1', '1d1-4'])).to eq(-1)
    end
  end

  describe 'Die.roll' do
    it 'should return an acceptable value for a given roll' do
      expect(Cinch::Plugins::Dicebag::Die.roll('1d1')).to eq(1)
      expect(3..15).to include(Cinch::Plugins::Dicebag::Die.roll('3d5'))
    end

    it 'should return nil for any negetive values' do
      expect(Cinch::Plugins::Dicebag::Die.roll('1d-1')).to eq(nil)
      expect(Cinch::Plugins::Dicebag::Die.roll('-1d-1')).to eq(nil)
    end

    it 'should add modifiers to the total' do
      expect(Cinch::Plugins::Dicebag::Die.roll('1d1+2')).to eq(3)
      expect(Cinch::Plugins::Dicebag::Die.roll('3d1-2')).to eq(1)
    end

    it 'should allow modifiers to take the total below zero' do
      expect(Cinch::Plugins::Dicebag::Die.roll('1d1-1')).to eq(0)
      expect(Cinch::Plugins::Dicebag::Die.roll('1d1-2')).to eq(-1)
    end
  end

  describe 'get_bag_size' do
    before(:each) do
      @bag = Cinch::Plugins::Dicebag::Bag.new({})
    end

    it 'should return \'huge\' for out of bounds queries' do
      @bag.count = 50000
      expect(@bag.size).to eq('huge')
    end

    it 'should return the proper size for tiny range' do
      @bag.count = 0
      expect(@bag.size).to eq('tiny')
    end

    it 'should return the proper size for small range' do
      @bag.count = rand(100)
      expect(@bag.size).to eq('tiny')
    end

    it 'should return the proper size for small range' do
      @bag.count = 100
      expect(@bag.size).to eq('tiny')
    end

    it 'should return the proper size for small range' do
      @bag.count = 101
      expect(@bag.size).to eq('small')
    end

    it 'should return the proper size for small range' do
      @bag.count = rand(399) + 101
      expect(@bag.size).to eq('small')
    end

    it 'should return the proper size for small range' do
      @bag.count = 500
      expect(@bag.size).to eq('small')
    end

    it 'should return the proper size for medium range' do
      @bag.count = 501
      expect(@bag.size).to eq('medium')
    end

    it 'should return the proper size for medium range' do
      @bag.count = rand(499) + 501
      expect(@bag.size).to eq('medium')
    end

    it 'should return the proper size for medium range' do
      @bag.count = 1000
      expect(@bag.size).to eq('medium')
    end

    it 'should return the proper size for large range' do
      @bag.count = 1001
      expect(@bag.size).to eq('large')
    end

    it 'should return the proper size for large range' do
      @bag.count = rand(499) + 1001
      expect(@bag.size).to eq('large')
    end

    it 'should return the proper size for large range' do
      @bag.count = 1500
      expect(@bag.size).to eq('large')
    end

    it 'should return the proper size for hefty range' do
      @bag.count = 1501
      expect(@bag.size).to eq('hefty')
    end

    it 'should return the proper size for hefty range' do
      @bag.count = rand(499) + 1501
      expect(@bag.size).to eq('hefty')
    end

    it 'should return the proper size for hefty range' do
      @bag.count = 2000
      expect(@bag.size).to eq('hefty')
    end

    it 'should return the proper size for huge range' do
      @bag.count = 2001
      expect(@bag.size).to eq('huge')
    end

    it 'should return the proper size for huge range' do
      @bag.count = 20001
      expect(@bag.size).to eq('huge')
    end
  end
end
