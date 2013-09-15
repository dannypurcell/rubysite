require 'rubycom'
require 'sinatra'
require "sinatra/reloader"
require 'json'
require 'yaml'
require 'kramdown'

require "#{File.dirname(__FILE__)}/rubysite/html.rb"

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
      $stdout.sync=true
      raise SiteError, "Invalid base class invocation: #{base}" if base.nil?
      Rubysite.set_defaults()
      Rubysite.set_configuration(Rubysite.parse_args(args))
      Rubysite.define_routes(base)
      puts "Starting Server:"
      $stdout.sync=false
      Sinatra::Base::run!
    rescue SiteError => e
      $stderr.puts e
    end
  end

  def self.set_defaults()
    Sinatra::Base::set :port, '8080'
    Sinatra::Base::set :root, Proc.new { File.join(File.expand_path(File.dirname(__FILE__)), 'rubysite') }
    Sinatra::Base::set :public_folder, Proc.new { File.join(File.expand_path(File.dirname(__FILE__)), 'rubysite', 'public') }
    Sinatra::Base::set :views, Proc.new { File.join(File.expand_path(File.dirname(__FILE__)), 'rubysite', 'views') }
    Sinatra::Base::set :app_name, Proc.new { File.basename($0, ".*").capitalize }
    Sinatra::Base::set :readme, Proc.new { Dir.glob(File.absolute_path("#{$0}/../**/*readme*")).first }
    Sinatra::Base::enable :logging
  end

  def self.set_configuration(parsed_args)
    parsed_args.each { |key, val|
      if Sinatra::Base::settings.respond_to?(key)
        puts <<-END.gsub(/^ {8}/, '')
        Overwriting: #{key}
          Previous Value: #{Sinatra::Base::settings.public_method(key).call}
               New Value: #{val}
        END
      else
        puts "Setting #{key}: #{val}"
      end
      Sinatra::Base::set(key, val)
    }
    if Sinatra::Base::settings.respond_to?(:conf_file) && File.exist?(Sinatra::Base.settings.conf_file)
      YAML.load_file(Sinatra::Base.settings.conf_file).each { |key, val|
        if Sinatra::Base::settings.respond_to?(key)
          puts <<-END.gsub(/^ {8}/, '')
          Overwriting: #{key}
          Previous Value: #{Sinatra::Base::settings.public_method(key).call}
               New Value: #{val}
          END
        else
          puts "Setting #{key}: #{val}"
        end
        Sinatra::Base::set(key, val)
      }
    end
  end

  def self.parse_args(args)
    args.map { |arg|
      Rubycom::Arguments.parse_arg(arg)
    }.reduce({}) { |acc, arg|
      if arg[:rubycom_non_opt_arg].nil?
        acc.merge(arg)
      else
        acc[:args] = [] if acc[:args].nil?
        acc[:args] << arg[:rubycom_non_opt_arg]
        acc
      end
    }
  end

  def self.get_layout_vars(nav_bar_links=[], side_bar_links=[], route_string='')
    {
        nav_bar_links: (nav_bar_links.nil?) ? [] : nav_bar_links.compact,
        side_bar_links: (side_bar_links.nil?) ? [] : side_bar_links.compact,
        breadcrumbs: Rubysite.get_breadcrumbs(route_string),
    }
  end

  def self.get_breadcrumbs(route_string)
    return {} if route_string.nil? || route_string.empty?
    route_parts = route_string.split('/')
    route_string.split('/').each_with_index.map { |_, index|
      {link: route_parts[0..index].join('/'), name: route_parts[index]}
    }.select { |p| !p[:link].nil? && !p[:link].empty? }
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
    defined_routes = (Rubysite.define_module_route(base) + default_routes)||[]

    Sinatra::Base::get "/?" do
      base_route = defined_routes.select { |link| link[:name]==base.to_s }
      index = {
          readme: Rubysite.parse_readme(settings.readme)
      }
      return {service: settings.app_name, routes: defined_routes}.to_json if request.accept?('application/json')
      erb(:index, locals: {layout: Rubysite.get_layout_vars(default_routes, base_route), index: index})
    end

    Sinatra::Base::get "/server/?" do
      server_info = {
          name: "Default Server"
      }
      return server_info.to_json if request.accept?('application/json')
      erb(:server_info, locals: {layout: Rubysite.get_layout_vars(default_routes), server_info: server_info})
    end

    Sinatra::Base::get "/help/?" do
      return defined_routes.to_json if request.accept?('application/json')
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
    route_string = "#{route_prefix.chomp('/')}/#{base.to_s}"
    module_link = {
        link: route_string,
        name: base.to_s,
        doc: Rubycom::Documentation.get_module_doc(base.to_s).strip,
        type: :module
    }
    method_links = []
    defined_routes = ([module_link] << (Rubycom::Commands.get_top_level_commands(base).select { |sym|
      sym != :Rubysite
    }.map { |command_sym|
      if base.included_modules.map { |mod| mod.name.to_sym }.include?(command_sym)
        Rubysite.define_module_route(base.included_modules.select { |mod| mod.name == command_sym.to_s }.first, route_string)
      else
        method_link = Rubysite.define_method_route(base, command_sym, route_string)
        method_links << method_link
        method_link
      end
    } || [])).flatten

    Sinatra::Base::get "#{route_string}/?" do
      mod = {
          doc: Rubycom::Documentation.get_module_doc(base.to_s.to_sym),
          command_list: method_links
      }
      sidebar_links = defined_routes.flatten.select { |item|
        (item[:type] == :module) && (item[:name] != base.to_s)
      } << {link: route_prefix, name: 'Back', doc: ''}
      return mod.to_json if request.accept?('application/json')
      erb(:"module/command_list", locals: {layout: Rubysite.get_layout_vars([], sidebar_links, route_string), mod: mod})
    end

    defined_routes
  end

  # Defines the route for the given command on the given base. The resulting route will be prefixed with the given route_prefix.
  #
  # @param [Module] base the Module which contains the specified command Method
  # @param [Symbol] command the symbol representing the name of the command for which an interface should be generated
  # @param [String] route_prefix a route pattern to prefix on routes which will be generated in response to this call
  # @return [Array] a String array listing the routes which were defined for the given base Module
  def self.define_method_route(base, command, route_prefix='/')
    base = Kernel.const_get(base.to_sym) if base.class == String
    route_string = "#{route_prefix}/#{command.to_s}"
    docs = Rubycom::Documentation.get_doc(base.public_method(command)) || {}
    param_defs = Rubycom::Arguments.get_param_definitions(base.public_method(command)).map { |key, val|
      val[:doc] = (docs[:param].nil?) ? [{type: '', name: '', text: ''}] : docs[:param].select { |line|
        line.split(' ')[1] == key.to_s || line.split(' ')[0] == key.to_s
      }.map { |line|
        {
            type: line.match(/\[\w+\]/).to_s.chomp(']').reverse.chomp('[').reverse,
            name: line.sub(/\[\w+\]/, '').split(' ').first.to_sym,
            text: line.sub(/\[\w+\]/, '').sub(key.to_s, '').strip.capitalize
        }
      }
      {key => val}
    }.reduce(&:merge) || {}
    sidebar_links = [
        {link: route_prefix, name: 'Back', doc: ''}
    ]

    Sinatra::Base::get "#{route_string}/?" do
      form = {
          command_name: command.to_s.split('_').map { |word| word.capitalize }.join(' '),
          docs: (docs[:desc].nil?)? '' : docs[:desc].join('\n'),
          name: "#{route_string.gsub('/', '_')}_form",
          action: "#{route_string}",
          method: 'post',
          fields: param_defs.map { |key, val_hsh|
            param_doc = val_hsh[:doc].first || {}
            {
                label: key.to_s.split('_').map { |word| word.capitalize }.join(' ')+':',
                type: param_doc[:type],
                name: "#{key.to_s}",
                doc_name: param_doc[:name],
                value: val_hsh[:default],
                doc: param_doc[:text]
            }
          }
      }
      return form.to_json if request.accept?('application/json')
      erb(:"method/form", locals: {layout: Rubysite.get_layout_vars([], sidebar_links, route_string), form: form})
    end

    Sinatra::Base::post "#{route_string}/?" do
      method_call_params = Rubysite.convert_params(param_defs, params)
      result = Rubysite.run_command(base, command, method_call_params)
      return result.to_json if request.accept?('application/json')
      if result[:has_error]
        erb(:"method/error", locals: {layout: Rubysite.get_layout_vars([], sidebar_links, route_string), error: result})
      else
        erb(:"method/result", locals: {layout: Rubysite.get_layout_vars([], sidebar_links, route_string), result: result})
      end
    end

    {
        link: route_string,
        name: command.to_s,
        doc: (docs[:desc] || []).join("\n"),
        type: :command
    }
  end

  def self.run_command(base, command, method_call_params)
    $stdout.sync=true
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

      {
          base: base,
          command: command,
          method_call_params: method_call_params,
          output: rubysite_out,
          error: rubysite_err
      }

    rescue Exception => e
      {
          has_error: true,
          base: base,
          command: command,
          method_call_params: method_call_params,
          message: e.message,
          stack_trace: e.backtrace.join("\n")
      }
    ensure
      $stdout = o_stdout
      $stderr = o_stderr
    end
  end

  def self.convert_params(param_defs, params)
    params.map { |key, val|
      (param_defs.keys.include?(key.to_sym) && param_defs[key.to_sym][:type] == :req) ? "#{val}" : "--#{key}=#{val.to_s.gsub(/\s+/, "")}"
    }
  end

  def self.parse_readme(readme_path)
    return '' if readme_path.nil? || readme_path.empty?
    return "<h6 style='color: #D11B1B'>Readme render failed: #{readme_path} does not exist.</h6>" unless File.exist?(readme_path)
    case File.extname(readme_path).downcase
      when '.md'
        Kramdown::Document.new(File.read(readme_path)).to_html
      else
        "<pre>#{File.read(readme_path)}</pre>"
    end
  end
end
