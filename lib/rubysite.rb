require 'rubycom'
require 'sinatra'
require "sinatra/reloader" if development?
require 'json'
require 'yaml'

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
  def self.run(base, args=[])
    args = [args] if args.class == String
    base = Kernel.const_get(base.to_sym) if base.class == String
    begin
      raise SiteError, "Invalid base class invocation: #{base}" if base.nil?
      Sinatra::Base::set :port, '8080'
      Sinatra::Base::set :port, args[1] if !args[0].nil? && args[0] == '--port'
      Sinatra::Base::set :port, args[0].split('=').last if !args[0].nil? && args[0].include?('--port=')
      Sinatra::Base::set :root, Proc.new { File.join(File.expand_path(File.dirname(__FILE__)), 'rubysite') }
      Sinatra::Base::set :public_folder, Proc.new { File.join(File.expand_path(File.dirname(__FILE__)), 'rubysite', 'public') }
      Sinatra::Base::set :views, Proc.new { File.join(File.expand_path(File.dirname(__FILE__)), 'rubysite', 'views') }
      Sinatra::Base::set :app_name, Proc.new {
        app_name_arg = args.select { |arg| arg.include?("app_name") }.first || "app_name=#{base.to_s}"
        app_name_arg.split(/\=|\s/).last
      }

      Rubysite.define_routes(base)

      Sinatra::Base::run!
    rescue SiteError => e
      $stderr.puts e
    end
  end

  def self.get_layout_vars(nav_bar_links=[], side_bar_links=[], breadcrumbs=[])
    {
        nav_bar_links: (nav_bar_links.nil?) ? [] : nav_bar_links.compact,
        side_bar_links: (side_bar_links.nil?) ? [] : side_bar_links.compact,
        breadcrumbs: (breadcrumbs.nil?) ? [] : breadcrumbs.compact,
    }
  end

  # Recursively defines routes for the web service according to the commands included in the given base Module.
  # Starts at '/'. Additionally defines any default routes required by the web service.
  #
  # @param [Module] base the Module for which a web interface should be generated
  # @return [Array] a String array listing the routes which were defined for the given base Module
  def self.define_routes(base)
    base = Kernel.const_get(base.to_sym) if base.class == String
    default_routes = [
        {link: "/server", name: "Server Info", doc: "Information about the server this console is running on."},
        {link: "/help", name: "Help", doc: "Interface documentation"}
    ]
    defined_routes = (Rubysite.define_module_route(base).compact + default_routes.map { |item| item[:link] })||[]

    Sinatra::Base::get "/?" do

      erb(:index, locals: {layout: Rubysite.get_layout_vars(default_routes)})
    end

    Sinatra::Base::get "/server" do
      server_info = {
          name: "Default Server"
      }
      erb(:server_info, locals: {layout: Rubysite.get_layout_vars(default_routes), server_info: server_info})
    end

    Sinatra::Base::get "/help" do
      erb(:help, locals: {layout: Rubysite.get_layout_vars(default_routes), site_map: defined_routes})
    end

    defined_routes
  end

  # Recursively defines routes for the web service according to the commands included in the given base Module.
  # Starts at the given route_prefix.
  #
  # @param [Module] base the Module for which a web interface should be generated
  # @param [String] route_prefix a route pattern to prefix on routes which will be generated in response to this call
  # @return [Array] a String array listing the routes which were defined for the given base Module
  def self.define_module_route(base, route_prefix='/')
    base = Kernel.const_get(base.to_sym) if base.class == String
    #TODO update these to {:link,:name,:doc}
    defined_routes = ["#{route_prefix.chomp('/')}/#{base.to_s}"]
    route_parts = defined_routes[0].split('/')
    commands = Rubycom::Commands.get_top_level_commands(base).select { |sym| sym != :Rubysite } || []

    commands = commands.map { |command_sym|
      if base.included_modules.map { |mod| mod.name.to_sym }.include?(command_sym)
        defined_routes << Rubysite.define_module_route(base.included_modules.select { |mod| mod.name == command_sym.to_s }.first, defined_routes[0])
      else
        defined_routes << Rubysite.define_method_route(base, command_sym, defined_routes[0])
      end
      {
          link: "#{defined_routes[0]}/#{command_sym.to_s}",
          link_name: "#{command_sym.to_s}",
          doc: Rubycom::Documentation.get_command_summary(base, command_sym, Rubycom::Documentation.get_separator(command_sym, Rubycom::Commands.get_longest_command_name(base).length)).gsub(command_sym.to_s, '')
      }
    } || []

    Sinatra::Base::get "#{defined_routes[0]}/?" do
      command_list = {
          name: "#{base}",
          back_link: route_prefix,
          doc: Rubycom::Documentation.get_module_doc(base.to_s),
          bread_crumbs: route_parts.each_with_index.map { |_, index| route_parts[0..index].join('/') }.select { |p| !p.empty? },
          nav_entries: [
              {link: route_prefix, link_name: route_prefix.split('/').last || 'Home', doc: 'Back'},
          ] + commands + [{link: "/help", link_name: "Help", doc: 'Interface documentation'}],
          command_list: commands
      }
      erb(:"module/command_list", locals: {command_list: command_list})
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
    route_parts = defined_route.split('/')
    docs = Rubycom::Documentation.get_doc(base.public_method(command))
    param_defs = Rubycom::Arguments.get_param_definitions(base.public_method(command))

    Sinatra::Base::get "#{defined_route}/?" do
      method_call_params = params.map { |key, val| (param_defs.keys.include?(key.to_sym) && param_defs[key.to_sym][:type] == :req) ? "#{val}" : "--#{key}=#{val}" }

      if params.nil? || params.empty?
        layout = {
            app_name: settings.app_name,
            name: "#{base}",
            back_link: route_prefix,
            bread_crumbs: route_parts.each_with_index.map { |_, index| route_parts[0..index].join('/') }.select { |p| !p.empty? },
            nav_entries: [
                {link: route_prefix, link_name: route_prefix.split('/').last || 'Home', doc: 'Parent Module'},
                {link: "/help", link_name: "Help", doc: 'Interface documentation'}
            ]
        }
        form = {
            base: base,
            params: params,
            param_defs: param_defs,
            method_call_params: method_call_params,
            docs: docs,
            name: "#{defined_route}_form",
            action: "#{defined_route}",
            method: 'get',
            fields: param_defs.map { |key, val_hsh|
              {
                  label: key.to_s.split('_').map { |word| word.capitalize }.join(' ')+':',
                  type: (docs[:param].nil?) ? 'text' : docs[:param].map { |str| {type: str.match(/\[\w+\]/), name: str.gsub(/\[\w+\]/, '').split(' ').first} }.reduce(&:merge),
                  name: "#{key.to_s}",
                  value: (val_hsh[:default] == :nil_rubycom_required_param) ? '' : val_hsh[:default]
              }
            }
        }
        erb(:"method/form", locals: {layout: layout, form: form})
      else
        begin
          rubysite_out = ''

          def rubysite_out.write(data)
            self << data
          end

          rubysite_err = ''

          def rubysite_err.write(data)
            self << data
          end

          o_stdout, $stdout = $stdout, rubysite_out
          o_stderr, $stderr = $stderr, rubysite_err

          puts Rubycom.call_method(base, command, method_call_params)

          layout = {
              app_name: settings.app_name,
              name: "#{base}",
              back_link: route_prefix,
              nav_entries: [
                  {link: route_prefix, link_name: route_prefix.split('/').last || 'Home', doc: 'Parent Module'},
                  {link: "/help", link_name: "Help", doc: 'Interface documentation'}
              ]
          }
          result = {
              base: base,
              params: params,
              param_defs: param_defs,
              method_call_params: method_call_params,
              docs: docs,
              output: rubysite_out,
              error: rubysite_err
          }
          erb(:"method/result", locals: {layout: layout, result: result})

        rescue Exception => e
          layout = {
              app_name: settings.app_name,
              name: "#{base}",
              back_link: route_prefix,
              bread_crumbs: route_parts.each_with_index.map { |_, index| route_parts[0..index].join('/') }.select { |p| !p.empty? },
              nav_entries: [
                  {link: route_prefix, link_name: route_prefix.split('/').last || 'Home', doc: 'Parent Module'},
                  {link: "/help", link_name: "Help", doc: 'Interface documentation'}
              ]
          }
          error = {
              base: base,
              params: params,
              param_defs: param_defs,
              method_call_params: method_call_params,
              message: e.message,
              stack_trace: e.backtrace
          }
          erb(:"method/error", locals: {layout: layout, error: error})
        ensure
          $stdout = o_stdout
          $stderr = o_stderr
        end
      end
    end
    defined_route
  end
end
