#!/usr/bin/env ruby

require_relative 'parser'
require 'benchmark'

parser = Parser.new(ARGV)
parser.perform
