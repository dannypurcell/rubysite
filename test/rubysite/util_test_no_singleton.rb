require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/rubysite.rb"

module UtilTestNoSingleton
  def test_method
    "TEST_NON_SINGLETON_METHOD"
  end

  include Rubysite
end