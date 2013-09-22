#!/usr/bin/env ruby
require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/rubysite.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/util_test_module.rb"
require "#{File.expand_path(File.dirname(__FILE__))}/util_test_no_singleton.rb"

# Provides test functions for use with Rubysite
module UtilTestComposite
  include UtilTestModule

  include UtilTestNoSingleton

  # A test_command in a composite console
  #
  # @param [String] test_arg a test argument
  # @return [String] the test arg
  def self.test_composite_command(test_arg)
    test_arg
  end

  include Rubysite
end
