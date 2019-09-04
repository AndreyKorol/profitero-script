#!/usr/bin/env ruby

require_relative 'parser'

parser = Parser.new(ARGV)
parser.perform
