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
  haml sym, :locals => {
    sym => key.nil? ? resource.all : resource.first(key => params[key])
   }
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
    "%a(href='#{route}')> all #{name}" :
    "%a(href='#{m.captures[0]}#"+"{#{name}.#{key}}#{m.captures[2]}')= #{name}"
	create_partial "_#{name}_a".to_sym, partial
end


def link_to(object)
  unless object.nil?
    name = Extlib::Inflection::singular(object.class.storage_name)
    haml "_#{name}_a".to_sym, :locals => { name.to_sym => object }
  end
end


# XXX --- film specific ---
def create_film_resource(res)
  names = res.storage_name
  name = Extlib::Inflection::singular(names)
  create_get "/#{names}"             , res
  create_get "/#{names}/:name/films" , res

  template names.to_sym, &lambda { """
%h1 #{names.capitalize}
%table
  %tr
    %th films
    %th name
  - #{names}.each do |x|
    %tr
      %td= x.films.count
      %td= link_to x"""
  }
  template name.to_sym, &lambda { """
%h1= \"<a href='/films'>Films</a>: \#{#{name}} (\#{haml :_#{names}_a}) \"
%div.list= haml :_film_list, :locals => { :films => #{name}.films }"""
  }
end

