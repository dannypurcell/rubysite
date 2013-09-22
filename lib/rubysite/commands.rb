require 'fileutils'
require 'rubycom'
require 'sinatra'

module Rubysite
  module Commands
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

    def self.clean_log_dir(log_dir, logs_to_keep, matcher)
      logs = Dir["#{log_dir}/*"]
      logs.select { |file| file.match(matcher).nil? }.each { |log_file|
        File.delete(log_file)
      }
      logs.select { |file| !file.match(matcher).nil? }.sort_by { |f| File.mtime(f) }.reverse.last(logs.length-logs_to_keep).each { |log_file|
        File.delete(log_file)
      } if logs.length > logs_to_keep
      Dir.rmdir(log_dir) if Dir.exists?(log_dir) && (Dir.entries(log_dir) - %w[ . .. ]).empty?
      FileUtils.remove_dir(Sinatra::Base.settings.log_dir) if Dir["#{Sinatra::Base.settings.log_dir}/**/*"].map { |f| Dir["#{f}/*"].select { |file| !File.directory?(file) }.empty? }.reduce(&:&)
    end

    def self.log_command(log_dir, log_ext, logs_to_keep, route_string, result)
      begin
        FileUtils.mkdir_p("#{log_dir}#{route_string}")
        File.open("#{log_dir}#{route_string}/#{Time.now.strftime("%Y-%m-%d_%H-%M-%S-%L")}#{log_ext}", 'a+') { |f|
          f.write(result.to_yaml)
        }
      rescue Exception => e
        $stderr.sync = true
        $stderr.puts e
        $stderr.sync = false
      end unless logs_to_keep <= 0
      Rubysite::Commands.clean_log_dir("#{log_dir}#{route_string}", logs_to_keep, /\d+-\d+-\d+_\d+-\d+-\d+-\d+\.\w+/)
    end
  end
end
