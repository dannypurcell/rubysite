require 'kramdown'

module Rubysite
  module Helpers
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

    def self.get_breadcrumbs(route_string)
      return {} if route_string.nil? || route_string.empty?
      route_parts = route_string.split('/')
      route_string.split('/').each_with_index.map { |_, index|
        {link: route_parts[0..index].join('/'), name: route_parts[index]}
      }.select { |p| !p[:link].nil? && !p[:link].empty? }
    end

    def self.get_layout_vars(nav_bar_links=[], side_bar_links=[], route_string='')
      {
          nav_bar_links: (nav_bar_links.nil?) ? [] : nav_bar_links.compact,
          side_bar_links: (side_bar_links.nil?) ? [] : side_bar_links.compact,
          breadcrumbs: Rubysite::Helpers.get_breadcrumbs(route_string),
      }
    end
  end
end
