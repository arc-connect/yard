# frozen_string_literal: true
require File.dirname(__FILE__) + '/spec_helper'

RSpec.describe YARD::Handlers::RBS::MixinHandler do
  it "registers include as instance mixin" do
    parse_rbs <<-RBS
module Helpers
end
class Foo
  include Helpers
end
    RBS
    expect(Registry.at('Foo').mixins(:instance).map(&:path)).to include('Helpers')
  end

  it "registers extend as class mixin" do
    parse_rbs <<-RBS
module ClassMethods
end
class Foo
  extend ClassMethods
end
    RBS
    expect(Registry.at('Foo').mixins(:class).map(&:path)).to include('ClassMethods')
  end

  it "registers prepend as instance mixin" do
    parse_rbs <<-RBS
module Before
end
class Foo
  prepend Before
end
    RBS
    expect(Registry.at('Foo').mixins(:instance).map(&:path)).to include('Before')
  end
end
