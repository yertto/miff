require 'haml'
require 'extlib'

CACHE_MAX_AGE=36000

module Sinatra::Templates
  alias :haml_orig :haml
  def haml(template, options={})
    options = options.merge!(:layout => false) if template.to_s.start_with? '_'
    haml_orig template, options
  end
end

def render_objects(sym, resource, key=nil)
  #cache_key = "#{resource.storage_name}.#{key}"
  response["Cache-Control"] = "max-age=#{CACHE_MAX_AGE}, public"
  objects = key.nil? ? resource.all : resource.first(key => params[key])
  haml sym, :locals => { sym => objects }
end

def create_partial(sym, code)
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

def get_resource(res_name)
  RESOURCES_ALL.detect { |res| res.storage_name == res_name }
end

def object
  @object ||= unless @object
    bits = request.path.split('/')
    res = get_resource(bits[-2])
    object = res.get(bits[-1]) if res
  end
end

def title
  @title ||= unless @title
    bits = request.path.split('/')
    res = get_resource(bits[-2])
    if res
      object = res.get(bits[-1])
      "#{res.name} | #{res.get(bits[-1])}"
    else
      res = get_resource(bits[-1])
      if res
        "#{res.storage_name.capitalize}"
      else
        "#{bits[-1]}"
      end
    end
  end
end
