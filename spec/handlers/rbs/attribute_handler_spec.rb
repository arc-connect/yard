# frozen_string_literal: true
require File.dirname(__FILE__) + '/spec_helper'

RSpec.describe YARD::Handlers::RBS::AttributeHandler do
  def parse_ruby(src)
    YARD::Registry.clear
    YARD.parse_string(src)
  end

  def attribute_snapshot(namespace_path, attr_name, scope = :instance)
    namespace = Registry.at(namespace_path)
    attribute = namespace.attributes[scope][attr_name]
    read = attribute[:read]
    write = attribute[:write]

    {
      :read_path => read && read.path,
      :write_path => write && write.path,
      :read_docstring => read ? read.docstring.to_s : nil,
      :write_docstring => write ? write.docstring.to_s : nil,
      :read_signature => read && read.signature,
      :write_signature => write && write.signature,
      :write_parameters => write && write.parameters,
      :read_is_attribute => read && read.is_attribute?,
      :write_is_attribute => write && write.is_attribute?
    }
  end

  it "registers a reader method for attr_reader" do
    parse_rbs <<-RBS
class Foo
  attr_reader name: String
end
    RBS
    obj = Registry.at('Foo#name')
    expect(obj).to be_a(CodeObjects::MethodObject)
    expect(obj.tag(:return).types).to eq ['String']
  end

  it "registers attr_reader as a YARD attribute like Ruby parsing does" do
    parse_rbs <<-RBS
class Foo
  attr_reader name: String
end
    RBS

    rbs_snapshot = attribute_snapshot('Foo', :name)
    reader = Registry.at('Foo#name')

    expect(reader.attr_info[:read]).to eq reader
    expect(reader.attr_info[:write]).to be_nil
    expect(reader.is_attribute?).to be true

    parse_ruby <<-RUBY
class Foo
  attr_reader :name
end
    RUBY

    expect(attribute_snapshot('Foo', :name)).to eq rbs_snapshot
  end

  it "registers a writer method for attr_writer" do
    parse_rbs <<-RBS
class Foo
  attr_writer name: String
end
    RBS
    obj = Registry.at('Foo#name=')
    expect(obj).to be_a(CodeObjects::MethodObject)
    expect(obj.tag(:param).types).to eq ['String']
  end

  it "registers both reader and writer for attr_accessor" do
    parse_rbs <<-RBS
class Foo
  attr_accessor age: Integer
end
    RBS
    expect(Registry.at('Foo#age')).to be_a(CodeObjects::MethodObject)
    expect(Registry.at('Foo#age=')).to be_a(CodeObjects::MethodObject)
  end

  it "registers class-side attr_accessor as a YARD attribute like Ruby parsing does" do
    parse_rbs <<-RBS
class Foo
  attr_accessor self.count: Integer
end
    RBS

    rbs_snapshot = attribute_snapshot('Foo', :count, :class)
    reader = Registry.at('Foo.count')
    writer = Registry.at('Foo.count=')

    expect(reader.attr_info[:read]).to eq reader
    expect(reader.attr_info[:write]).to eq writer
    expect(writer.is_attribute?).to be true

    parse_ruby <<-RUBY
class Foo
  class << self
    attr_accessor :count
  end
end
    RUBY

    expect(attribute_snapshot('Foo', :count, :class)).to eq rbs_snapshot
  end

  it "registers a class-side reader for attr_reader self.name" do
    parse_rbs <<-RBS
class Foo
  attr_reader self.count: Integer
end
    RBS
    obj = Registry.at('Foo.count')
    expect(obj).to be_a(CodeObjects::MethodObject)
    expect(obj.tag(:return).types).to eq ['Integer']
  end

  it "preserves docstring for attributes" do
    parse_rbs <<-RBS
class Foo
  # The user's name.
  attr_reader name: String
end
    RBS
    expect(Registry.at('Foo#name').docstring).to eq "The user's name."
  end

  it "links an existing complementary method into attr_info" do
    parse_rbs <<-RBS
class Foo
  def name: () -> String
  attr_writer name: String
end
    RBS

    writer = Registry.at('Foo#name=')
    expect(writer.attr_info[:read]).to eq Registry.at('Foo#name')
    expect(writer.attr_info[:write]).to eq writer
  end

  it "handles nullable attribute type" do
    parse_rbs <<-RBS
class Foo
  attr_reader nickname: String?
end
    RBS
    expect(Registry.at('Foo#nickname').tag(:return).types).to eq ['String', 'nil']
  end

  it "parses attr declarations without space after colon" do
    parse_rbs <<-RBS
class Foo
  attr_reader count:Integer
end
    RBS
    obj = Registry.at('Foo#count')
    expect(obj).to be_a(CodeObjects::MethodObject)
    expect(obj.tag(:return).types).to eq ['Integer']
  end

  it "ignores inline comments on attr declarations" do
    parse_rbs <<-RBS
class Foo
  attr_reader name: String # the name
end
    RBS
    obj = Registry.at('Foo#name')
    expect(obj.tag(:return).types).to eq ['String']
  end
end
