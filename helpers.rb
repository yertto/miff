require 'haml'
require 'extlib'

module Sinatra::Templates
  alias :haml_orig :haml
  def haml(template, options={})
    options = options.merge!(:layout => false) if template.to_s.start_with? '_'
    haml_orig template, options
  end
end

def render_objects(sym, resource, key=nil)
  #cache_key = "#{resource.storage_name}.#{key}"
  response["Cache-Control"] = "max-age=3600, public"
  objects = key.nil? ? resource.all : resource.first(key => params[key])
  haml sym, :locals => { sym => objects }
end

def create_partial(sym, code)
  p code
  template sym, &lambda { code }
end

PAT_ROUTEKEY = Regexp.compile('(.*):([^/]+)(.*?$)')
def create_get(route, resource)
  m = PAT_ROUTEKEY.match(route)
  key = m && m.captures[1].to_sym
	name = names = resource.storage_name
  name = Extlib::Inflection::singular(name) unless key.nil?
  get route, &lambda { render_objects name.to_sym, resource, key }
  partial = m.nil? ?
    "%a(href='#{route}')> #{names.capitalize}" : "\
- if #{name}
  %a(href='#{m.captures[0]}#"+"{#{name}.#{key}}#{m.captures[2]}')= #{name}"
	create_partial "_#{name}_a".to_sym, partial
end


def link_to(object, options=nil)
  unless object.nil?
    name = Extlib::Inflection::singular(object.class.storage_name)
    haml "_#{name}_a".to_sym, :locals => { name.to_sym => object }
  end
end

def current_section(url)
  # Match the first part of the request url with our own url
  #(request.path =~ Regexp.new("#{url}/*")) ? 'current' : ''
  request.path == url ? 'current' : ''
end
