#Cinch::Plugins::Dicebag

[![Code Climate](https://codeclimate.com/github/bhaberer/cinch-dicebag.png)](https://codeclimate.com/github/bhaberer/cinch-dicebag)

Cinch Plugin to allow users to roll dice in channels.

Supports rolling specific dice as well as a random assortment of dice. (Leaderboards coming soon)

## Installation

Add this line to your application's Gemfile:

    gem 'cinch-dicebag'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cinch-dicebag

## Usage

Just add the plugin to your list:

    @bot = Cinch::Bot.new do
      configure do |c|
        c.plugins.plugins = [Cinch::Plugins::Dicebag]
      end
    end

Then in channel use .roll:

    .roll 5d20

You can also use .dicebag to roll a random assortment of dice.

    < Brian > .dicebag
    < bot > Brian rolls a large bag of dice totalling 11052.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
