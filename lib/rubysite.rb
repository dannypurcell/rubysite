require 'rubycom'
require 'sinatra'
require "sinatra/reloader" if development?

module Rubysite

  def self.included(base)
    base_file_path = caller.first.gsub(/:\d+:.+/, '')
    if base.class == Module && (base_file_path == $0 || self.is_executed_by_gem?(base_file_path))
      base.module_eval {
        Rubycom.run(base, ARGV)
      }
    end
  end


end
