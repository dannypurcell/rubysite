require 'rubycom'

module Rubysite
  module Arguments
    def self.convert_params(param_defs, params)
      params.map { |key, val|
        if param_defs.keys.include?(key.to_sym) && param_defs[key.to_sym][:type] == :req
          "#{val}"
        else
          "--#{key}=#{val.to_s.gsub(/\s+/, "")}"
        end
      }
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
  end
end
