#!/usr/bin/env ruby

require_relative 'lib/parser'

parser = Parser.new(ARGV)
parser.perform
