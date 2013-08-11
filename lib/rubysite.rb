require 'rubycom'
require 'sinatra'
require "sinatra/reloader" if development?

# Provides a web interface for including modules
module Rubysite
  class SiteError < StandardError;
  end

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
  def self.run(base, args=[])
    args = [args] if args.class == String
    base = Kernel.const_get(base.to_sym) if base.class == String
    begin
      raise SiteError, "Invalid base class invocation: #{base}" if base.nil?
      Sinatra::Base::set :port, '8080'
      Sinatra::Base::set :port, args[1] if !args[0].nil? && args[0] == '--port'
      Sinatra::Base::set :port, args[0].split('=').last if !args[0].nil? && args[0].include?('--port=')

      Rubysite.define_routes(base)

      Sinatra::Base::run!
    rescue SiteError => e
      $stderr.puts e
    end
  end

  # Recursively defines routes for the web service according to the commands included in the given base Module.
  # Starts at '/'. Additionally defines any default routes required by the web service.
  #
  # @param [Module] the Module for which a web interface should be generated
  # @return [Array] a String array listing the routes which were defined for the given base Module
  def self.define_routes(base)
    base = Kernel.const_get(base.to_sym) if base.class == String
    site_map = Rubysite.define_module_route(base)
    Sinatra::Base::get "/" do
      <<-eos.gsub(/^ {6}/,'')
      <html>
        <body>
          <h1>#{base.to_s}</h1>
          <br />
          <ul>
            <li><a href='/#{base.to_s}'>#{base.to_s}</a></li>
            <li><a href='/help'>help</a></li>
          </ul>
        </body>
      </html>
      eos
    end
    Sinatra::Base::get "/help" do
      <<-eos.gsub(/^ {6}/,'')
      <html>
        <body>
          <h1>#{base.to_s} Help</h1>
          <br />
          <h3>Site Map</h3>
          <ul>
            #{site_map.map{|route|
                "<li><a href='#{route}'>#{route}</a></li>"
              }.join("\n")
            }
          </ul>
        </body>
      </html>
      eos
    end
    site_map
  end

  # Recursively defines routes for the web service according to the commands included in the given base Module.
  # Starts at the given route_prefix.
  #
  # @param [Module] the Module for which a web interface should be generated
  # @param [String] a route pattern to prefix on routes which will be generated in response to this call
  # @return [Array] a String array listing the routes which were defined for the given base Module
  def self.define_module_route(base, route_prefix='/')
    base = Kernel.const_get(base.to_sym) if base.class == String
    defined_routes = ["#{route_prefix.chomp('/')}/#{base.to_s}"]

    commands = Rubycom::Commands.get_top_level_commands(base).select{|sym| sym != :Rubysite} || []

    commands = commands.map{|command_sym|
      if base.included_modules.map { |mod| mod.name.to_sym }.include?(command_sym)
        defined_routes << Rubysite.define_module_route(base.included_modules.select{|mod| mod.name == command_sym.to_s }.first, defined_routes[0])
      else
        defined_routes << Rubysite.define_method_route(base, command_sym, defined_routes[0])
      end
      {
          command_sym => " " << Rubycom::Documentation.get_command_summary(base, command_sym, Rubycom::Documentation.get_separator(command_sym, Rubycom::Commands.get_longest_command_name(base).length)).gsub(command_sym.to_s,'')
      }
    }.reduce(&:merge) || {}

    Sinatra::Base::get defined_routes[0] do
      <<-eos.gsub(/^ {6}/,'')
      <html>
        <body>
          <h1>#{base.to_s}</h1>
          <a href='#{route_prefix}'>back</a>
          <br />
          <h4>#{Rubycom::Documentation.get_module_doc(base.to_s)}</h4>
          <br />
          <h3>Commands:</h3>
          <br />
          <ul>
            #{commands.map{|command_sym, doc| "<li><a href='#{defined_routes[0]}/#{command_sym}'>#{command_sym}</a>#{doc}</li>"}.join("\n")}
          </ul>
          <br />
        </body>
      </html>
      eos
    end
    defined_routes.flatten
  end

  # Defines the route for the given command on the given base. The resulting route will be prefixed with the given route_prefix.
  #
  # @param [Module] base the Module which contains the specified command Method
  # @param [Symbol] command the symbol representing the name of the command for which an interface should be generated
  # @param [String] route_prefix a route pattern to prefix on routes which will be generated in response to this call
  # @return [Array] a String array listing the routes which were defined for the given base Module
  def self.define_method_route(base, command, route_prefix='/')
    base = Kernel.const_get(base.to_sym) if base.class == String
    defined_route = "#{route_prefix}/#{command.to_s}"
    Sinatra::Base::get defined_route do
      {
          docs: Rubycom::Documentation.get_doc(base.public_method(command)),
          params: Rubycom::Arguments.get_param_definitions(base.public_method(command))
      }
    end
    defined_route
  end

end
