class OptionParser
  LINK = 0
  FILE = 1

  attr_reader :link, :file

  def initialize(args)
    @link = args[LINK]
    @file = args[FILE]
  end
end
