#!/usr/bin/env ruby
require_relative 'caffeinate.rb'

drink_coffee = Caffeinate.new('secrets.yml')

drink_coffee.and_go!
