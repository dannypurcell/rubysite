require 'sinatra'
require 'yaml'

module Rubysite
  module Configuration
    def self.set_configuration(parsed_args={}, defaults={}, conf_setter=Sinatra::Base)
      raise "conf_setter must respond to set(key, val)" unless conf_setter.respond_to?(:set)

      conf = Rubysite::Configuration.get_configuration(defaults, parsed_args).each { |key, val|
        conf_setter.set(key, val)
      }

      if conf[:write_config_file] &&
          conf.select { |key, _| ![:write_config_file, :config_file, :conf_output_file].include?(key) }.length > 0
        Rubysite::Configuration.write_conf(conf[:conf_output_file], conf)
      end
    end

    def self.get_defaults(root_path)
      app_name = File.basename($0, ".*").split('_').map(&:capitalize).join
      app_base_route = File.dirname(File.absolute_path($0))
      {
          port: '8080',
          root: root_path,
          public_folder: File.join(root_path, 'public'),
          views: File.join(root_path, 'views'),
          app_name: app_name,
          readme: Dir.glob(File.absolute_path("#{$0}/../**/*readme*")).first,
          logging: true,
          log_ext: '.log',
          log_commands: true,
          logs_to_keep: 0,
          log_dir: "#{app_base_route}/#{app_name}_logs",
          conf_output_file: "#{app_base_route}/#{app_name}_config.yaml"
      }
    end

    def self.get_configuration(defaults, parsed_args)
      defaults.merge(parsed_args)
      .merge(
          if File.exists?(parsed_args[:config_file] || '')
            YAML.load_file(parsed_args[:config_file]).map { |k, v| {k.to_s.to_sym => v} }.reduce(&:merge).select { |_, v| !v.nil? }
          else
            {}
          end
      )
    end

    def self.write_conf(conf_file_path, conf)
      File.open(conf_file_path, 'w+') { |f|
        f.write(conf.select { |key, _| ![:write_config_file, :write_config_file, :config_file].include?(key) }.to_yaml)
      }
    end
  end
end
