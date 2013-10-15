require File.expand_path(File.dirname(__FILE__) + '/rubysite/arguments.rb')
require File.expand_path(File.dirname(__FILE__) + '/rubysite/commands.rb')
require File.expand_path(File.dirname(__FILE__) + '/rubysite/configuration.rb')
require File.expand_path(File.dirname(__FILE__) + '/rubysite/helpers.rb')
require File.expand_path(File.dirname(__FILE__) + '/rubysite/html.rb')
require File.expand_path(File.dirname(__FILE__) + '/rubysite/routes.rb')

require 'rubycom'
require 'sinatra'

# Provides a web interface for including modules
module Rubysite
  class SiteError < StandardError;
  end

  # Detects that Rubysite was included in another module and calls Rubysite#run
  #
  # @param [Module] base the module which invoked 'include Rubysite'
  def self.included(base)
    base_file_path = caller.first.gsub(/:\d+:.+/, '')
    if base.class == Module && (base_file_path == $0 || Rubycom.is_executed_by_gem?(base_file_path))
      base.module_eval {
        Rubysite.run(base, ARGV)
      }
    end
  end

  # Defines routes for all commands found in the including module and starts the web server
  #
  # @param [Module] base the module which invoked 'include Rubysite'
  # @param [Array] args a String Array representing environment settings for the web server
  def self.run(base=File.basename($0, ".*").split('_').map(&:capitalize).join, args=[])
    args = [args] if args.class == String
    base = Kernel.const_get(base.to_sym) if base.class == String
    begin
      raise SiteError, "Invalid base class invocation: #{base}" if base.nil?
      Rubysite::Configuration.set_configuration(
          Rubysite::Arguments.parse_args(args),
          Rubysite::Configuration.get_defaults(File.join(File.expand_path(File.dirname(__FILE__)), 'rubysite')),
          Sinatra::Base
      )
      Rubysite::Routes.define_routes(base)
      Sinatra::Base::run!
    rescue SiteError => e
      $stderr.puts e
    end
  end
end
