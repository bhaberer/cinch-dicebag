module Cinch
  module Plugins
    class Dicebag
      # Module to manage the actuall roling of specific dice.
      module Die
        MOD_REGEX = /[\-\+]\d+/
        ROLLS_REGEX = /(\d+)d\d+/
        SIDES_REGEX = /\d?d(\d+)/

        # Takes a dice roll string or Array of dice rolls, sanitizes them,
        #   parses them, and dispatches their calculation to `Die.cast`.
        # @param [Array] dice Array of strings that correspond to valid die
        #   rolls. (i.e. ['4d6', '6d10']
        # @return [Fixnum] The total from rolling all of the dice.
        def self.roll(dice)
          # Convert to an array if it's a single die roll
          dice = [dice] if dice.is_a?(String)

          # Clean out anything invalid
          dice = clean_roll(dice)

          # Initialize a total
          total = nil

          # Return if the sanity fails
          return 'I don\'t have that many dice!' unless die_check?(dice)

          # Roll each group and total up the returned value
          dice.each do |die|
            total ||= 0
            total += cast(die)
          end

          total
        end

        # Rolls an n-sided die a given amount of times and returns the total
        # @param [String] count Number of times to roll the die.
        # @return [Fixnum] The total from rolling the die.
        def self.cast(die)
          # Pull out the data from the roll. 
          modifier = die[MOD_REGEX]
          count = (die[ROLLS_REGEX, 1] || 1).to_i
          sides = die[SIDES_REGEX, 1].to_i

          # init the total
          total = 0

          # Bail if the roll isn't sane looking.
          return total unless check_die_sanity(count, sides)

          # Roll dem dice!
          count.times { total += rand(sides) + 1 }

          # Parse the modifier and apply it, if there is one
          return total += parse_modifier(modifier) unless modifier.nil?

          total
        end

        # Makes sure people aren't doing silly things.
        def self.check_die_sanity(count, sides)
          return false if count.nil? || sides.nil? || sides < 1 || count < 1
          true
        end

        # Remove any stupid crap people try to sneak into the rolls.
        def self.clean_roll(dice)
          dice.delete_if { |d| d.match(/\d*d\d+([\-\+]\d+)?/).nil? }
          dice
        end

        # Takes an array of rolls and does sanity on it.
        # @param [Array] dice Array of strings that correspond to valid
        #   die rolls. (i.e. ['4d6', '6d10']
        # @return [Boolean] Result of sanity check.
        def self.die_check?(dice)
          # Check to make sure it's not a stupid large roll, they clog threads.
          count = dice.map { |d| d[/(\d+)d\d+/, 1].to_i || 1 }.inject(0, :+)
          return false if count >= 10_000
          true
        end

        # Parse out the modified and return it as an int.
        def self.parse_modifier(modifier)
          operator = modifier[/\A[\+\-]/]
          int = modifier[/\d+\z/].to_i
          0.send(operator, int)
        end
      end
    end
  end
end
