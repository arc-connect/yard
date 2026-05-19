# frozen_string_literal: true
require File.expand_path('../../spec_helper', __FILE__)

# Parse an RBS source string and populate the Registry.
def parse_rbs(src)
  YARD::Registry.clear
  parser = YARD::Parser::SourceParser.new(:rbs)
  parser.file = '(rbs)'
  parser.parse(StringIO.new(src))
end
