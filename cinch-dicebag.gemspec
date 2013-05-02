# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cinch/plugins/dicebag/version'

Gem::Specification.new do |gem|
  gem.name          = "cinch-dicebag"
  gem.version       = Cinch::Dicebag::VERSION
  gem.authors       = ["Brian Haberer"]
  gem.email         = ["bhaberer@gmail.com"]
  gem.description   = %q{Cinch Plugin that allows uses in the channel to roll specific dice or roll a random assortment of dice to compete for high scores.}
  gem.summary       = %q{Cinch Plugin: Dicebag and Dice rolls}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'cinch', '>= 2.0.0'
  gem.add_dependency 'time-lord', '1.0.1'
  gem.add_dependency 'cinch-cooldown'
  gem.add_dependency 'cinch-storage'
end
