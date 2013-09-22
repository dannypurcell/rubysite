require File.expand_path(File.dirname(__FILE__) + '/arguments.rb')
require File.expand_path(File.dirname(__FILE__) + '/commands.rb')
require File.expand_path(File.dirname(__FILE__) + '/helpers.rb')

require 'json'
require 'rubycom'
require 'sinatra'
require 'yaml'


module Rubysite
  module Routes
    # Defines the route for the given command on the given base. The resulting route will be prefixed with the given route_prefix.
    #
    # @param [Module] base the Module which contains the specified command Method
    # @param [Symbol] command the symbol representing the name of the command for which an interface should be generated
    # @param [String] route_prefix a route pattern to prefix on routes which will be generated in response to this call
    # @return [Array] a String array listing the routes which were defined for the given base Module
    def self.define_method_routes(base, command, route_prefix='/')
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
          {link: "#{route_string}/runs", name: 'Runs', doc: ''},
          {link: route_prefix, name: 'Back', doc: ''}
      ]

      Sinatra::Base::get "#{route_string}/?" do
        form = {
            command_name: command.to_s.split('_').map { |word| word.capitalize }.join(' '),
            docs: (docs[:desc].nil?) ? '' : docs[:desc].join('\n'),
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
        erb(:"method/form", locals: {layout: Rubysite::Helpers.get_layout_vars([], sidebar_links, route_string), form: form})
      end

      runs_sb_links = [
          {link: route_string, name: 'Back', doc: ''}
      ]

      Sinatra::Base::get "#{route_string}/runs/?" do
        log_ext = settings.log_ext
        run_list = {
            doc: '',
            links: Dir["#{settings.log_dir}#{route_string}/*"].select { |file|
              File.extname(file) == log_ext
            }.map { |file|
              parts = File.basename(file).chomp(log_ext).split('_')
              time_parts = parts.last.split('-')
              timestamp = Time.parse("#{parts.first} #{time_parts[0..-2].join(':')}.#{time_parts.last}")
              {link: "#{route_string}/runs/#{File.basename(file).chomp(log_ext)}", name: timestamp, doc: ''}
            }
        }
        return run_list.to_json if request.accept?('application/json')
        erb(:"method/run_list", locals: {layout: Rubysite::Helpers.get_layout_vars([], runs_sb_links, "#{route_string}/runs"), run_list: run_list})
      end

      run_sb_links = [
          {link: "#{route_string}/runs", name: 'Back', doc: ''}
      ]

      Sinatra::Base::get "#{route_string}/runs/:id/?" do
        run_log = "#{settings.log_dir}#{route_string}/#{params[:id]}#{settings.log_ext}"
        result = (File.exists?(run_log)) ? YAML.load_file(run_log) : {has_error: true, message: "No saved run for id: #{run_id}"}
        return result.to_json if request.accept?('application/json')

        if result[:has_error]
          erb(:"method/error", locals: {layout: Rubysite::Helpers.get_layout_vars([], run_sb_links, "#{route_string}/runs/#{params[:id]}"), error: result})
        else
          erb(:"method/result", locals: {layout: Rubysite::Helpers.get_layout_vars([], run_sb_links, "#{route_string}/runs/#{params[:id]}"), result: result})
        end
      end

      Sinatra::Base::post "#{route_string}/?" do
        method_call_params = Rubysite::Arguments.convert_params(param_defs, params)
        result = Rubysite::Commands.run_command(base, command, method_call_params)
        Rubysite::Commands.log_command(settings.log_dir,
                                       settings.log_ext,
                                       settings.logs_to_keep,
                                       route_string,
                                       result) if Sinatra::Base.settings.log_commands
        return result.to_json if request.accept?('application/json')
        if result[:has_error]
          erb(:"method/error", locals: {layout: Rubysite::Helpers.get_layout_vars([], sidebar_links, route_string), error: result})
        else
          erb(:"method/result", locals: {layout: Rubysite::Helpers.get_layout_vars([], sidebar_links, route_string), result: result})
        end
      end

      {
          link: route_string,
          name: command.to_s,
          doc: (docs[:desc] || []).join("\n"),
          type: :command
      }
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
          Rubysite::Routes.define_module_route(base.included_modules.select { |mod| mod.name == command_sym.to_s }.first, route_string)
        else
          method_link = Rubysite::Routes.define_method_routes(base, command_sym, route_string)
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
        erb(:"module/command_list", locals: {layout: Rubysite::Helpers.get_layout_vars([], sidebar_links, route_string), mod: mod})
      end

      defined_routes
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
      defined_routes = (Rubysite::Routes.define_module_route(base) + default_routes)||[]

      Sinatra::Base::get "/?" do
        base_route = defined_routes.select { |link| link[:name]==base.to_s }
        index = {
            readme: (settings.readme) ? Rubysite::Helpers.parse_readme(settings.readme) : ''
        }
        return {service: settings.app_name, routes: defined_routes}.to_json if request.accept?('application/json')
        erb(:index, locals: {layout: Rubysite::Helpers.get_layout_vars(default_routes, base_route), index: index})
      end

      Sinatra::Base::get "/server/?" do
        server_info = {
            name: "Default Server"
        }
        return server_info.to_json if request.accept?('application/json')
        erb(:server_info, locals: {layout: Rubysite::Helpers.get_layout_vars(default_routes), server_info: server_info})
      end

      Sinatra::Base::get "/help/?" do
        return defined_routes.to_json if request.accept?('application/json')
        erb(:help, locals: {layout: Rubysite::Helpers.get_layout_vars(default_routes), site_map: defined_routes})
      end

      defined_routes
    end
  end
end
