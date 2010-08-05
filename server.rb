#!/usr/local/bin/ruby -rrubygems
require 'sinatra'
require 'xml-sitemap'

require 'helpers'

require 'db'

use Rack::Auth::Basic do |username, password|
  [username, password] == ['admin', ENV['SITE_PASSWORD']]
end if ENV['SITE_PASSWORD']



MY_VERSION = File.open(File.dirname(__FILE__) + "/VERSION").read.strip

RESOURCES = [Session, Section, Category, Venue, Country, Year, Medium, Language, Subtitle, Distributor, Director, Writer, Producer]
RESOURCES_ALL = [Film]+RESOURCES

def get_res(item)
  RESOURCES_ALL.detect { |res| res.storage_name == item }
end

def create_film_resource(res)
  # helper method to creat
  names = res.storage_name
  name = Extlib::Inflection::singular(names)
  key = res == Session ? :id : :name 
  create_get "/films/#{names}"         , res
  create_get "/films/#{names}/:#{key}" , res

  unless names == "sessions"
    template names.to_sym, &lambda { """
%table.list
  - #{names}.each do |x|
    %tr
      %td= x.films.count
      %td= link_to x"""
    }
    template name.to_sym, &lambda { """
%div.list= haml :_film_table, :locals => { :films => #{name}.films }"""
    }
  end
end

# Create views and routes for the following resources.
RESOURCES.each { |res|
  create_film_resource res
}  


# Create get routes and their rendering code based on a resource and the route...
#
# NB. matching views need to be created
# eg.
#   create_get '/films/:id' , Film  # renders a film object to a 'film' view
#                                   # (it also creates a 'film' view, and a '_film_a' partial)
#   create_get '/films'     , Film  # renders all film objects to a 'films' view
#                                   # (it also creates the 'films' view, and a '_films_a' partial)
#
create_get '/films'                    , Film
create_get '/films/:id'                , Film

# special cases ...
create_partial :_date_a , '%a(href="/films/sessions/dates/#{date}")= date.strftime("%a %b %d")'

get '/films/sessions/dates/:date' do
  date = Date.parse(params[:date])
  haml :sessions, :locals => { :date => date, :sessions => Session.all(:date => date) }
end

get '/robots.txt' do
  headers['Content-Type'] = 'text/plain'
  """\
User-agent: *
Disallow:
Sitemap: http://miff.heroku.com/sitemap.xml
"""
end

get '/sitemap.xml' do
  headers['Content-Type'] = 'text/xml'
  map = XmlSitemap::Map.new('miff.heroku.com')
  Film.all.each { |f| map.add(:url => "/films/#{f.id}") }
  map.render
end

get '/' do
  redirect '/films/languages' , 301
end


__END__

  Film.all.inject( XmlSitemap::Map.new('domain.com') ) { |m| m.add(:url => "/films/#{f.id}") }.render

@@ _film_table
%table
  %thead
    %tr
      - %w(Name Duration Year Trailer Countries Languages Subtitles Director Writers Distributor Medium Sessions).each do |th|
        %th.heading= th
  %tbody
    - films.each do |film|
      %tr
        %td= haml :_film_a_popup, :locals => { :film => film }
        %td= "#{film.duration} mins"
        %td= link_to film.year
        %td
          -if film.trailer_url
            %a{:href=>film.trailer_url, :target=>'trailers'} trailer
        %td= film.countries.collect { |country|  link_to country  }
        %td= film.languages.collect { |language| link_to language }
        %td= link_to film.subtitle
        %td= film.directors.collect { |director| link_to director }
        %td= film.writers.collect   { |writer|   link_to writer   }
        %td= link_to film.distributor
        %td
          = link_to film.medium
          = film.three_d ? ' (3D)' : ''
        %td
          %ul
            - film.sessions.each do |session|
              %li= "#{link_to session} (#{haml :_date_a, :locals => {:date=>session.date}})"


@@ _film_details
%div.filmdetails
  = "D #{film.directors.collect { |x| link_to x }.join(', ')} "
  = "P #{film.producers.collect { |x| link_to x }.join(', ')} "
  = "#{film.distributor_type} "
  = "#{link_to(film.distributor)} "
  - if film.languages.size > 0
    = "L #{film.languages.collect { |x| link_to x }.join(', ')} "
  - if film.subtitle
    = "w/#{link_to film.subtitle} subtitles"
  = "TD #{film.three_d ? '3D ' : ''}#{haml :_medium_a, :locals => {:medium => film.medium}}/#{haml :_year_a, :locals => {:year => film.year}}" 


@@ _film_a_popup
%a{:href=>"/films/#{film.id}", :class=>"thumbnail"}
  = film.title
  %span
    %img{:src=>film.thumb_url}
    %div.tagline= film.tagline


@@ film
%article
  %h1= haml :_film_a, :locals => { :film => film }
  %img(src="#{film.still_url}")
  %div.tagline= film.tagline
  %div.col1
    %div.year
      %h2 Year
      = haml :_year_a, :locals => {:year => film.year}
    %div(class="countries section")
      %h2 Countries
      %span.countries= film.countries.collect { |x| link_to x }.join('| ')
    - if film.section
      %h2 Section
      %div(class="category section")
        %span.sections= link_to film.section
    - if film.category
      %h2 Category
      %div(class="category section")
        %span.sections= link_to film.category
  %div.col2
    %div(class="synopsis section")= film.synopsis
    %div(class="details section")= haml :_film_details, :locals => { :film => film }
  %div(class="sessions section")
    = haml :_sessions_table, :locals => { :sessions => film.sessions }


@@ films
%div.list= haml :_film_table, :locals => { :films => films }


@@ _sessions_table
%table.sessionTable
  %thead
    %tr
      - %w(Code Films Date Time).each do |th|
        %th.heading(valign="top")= th
  %tbody
    %tr
    - venue_sessions = sessions.inject({}) { |h, session| h[session.venue] = h[session.venue] ? h[session.venue] << session :[session] ; h }
    - venues = venue_sessions.keys.sort
    - venues.each do |venue|
      - sessions = venue_sessions[venue]
      %tr
        %th{:class=>'session_venue', :colspan=>4}= link_to(venue)
      - sessions.each do |session|
        %tr
          %td.session_code= link_to(session)
          %td= session.films.collect { |film| "#{haml :_film_a_popup, :locals => {:film => film}} (#{film.duration} mins) <br/>" }
          %td.session_day= haml :_date_a, :locals => { :date => Date.parse(session.time.strftime('%Y/%m/%d')) }
          %td.session_time= session.time.strftime("%l.%M%P")



@@ session
%div.list= haml :_sessions_table, :locals => { :sessions => [session] }


@@ sessions
%div.list= haml :_sessions_table, :locals => { :sessions => sessions }
  

@@ _breadcrumb
- path_items = request.path.split('/')
%form{:name=>'jump'}
  %select{:name=>'path_items1', :onChange=>"location=document.jump.path_items1.options[document.jump.path_items1.selectedIndex].value;", :value=>"GO"}
    %option{:value=>"/#{path_items[1]}"}= path_items[1].capitalize
    - get_res(path_items[1]).all.each do |item|
      - path = "/#{path_items[1]}/#{item.id}"
      - v = item.to_s
      %option{:value=>path, :selected=>(request.path == path)}= v.size > 20 ? "#{v[0..15]}...#{v[-4..-1]}" : v
  = "/"
  %select{:name=>'path_items2', :onChange=>"location=document.jump.path_items2.options[document.jump.path_items2.selectedIndex].value;", :value=>"GO"}
    %option{:value=>"/#{path_items[1]}", :selected=>(request.path == "/#{path_items[1]}")}
    - RESOURCES.each do |res|
      - name = res.storage_name
      - path = "/#{path_items[1]}/#{name}"
      %option{:value=>path, :selected=>(request.path.scan(path).size > 0)}= name.capitalize
  - if path_items.size > 2
    %select{:name=>'path_items3', :onChange=>"location=document.jump.path_items3.options[document.jump.path_items3.selectedIndex].value;", :value=>"GO"}
      - child_path = path_items[0..2].join('/')
      %option{:value=>child_path, :selected=>(request.path.scan(child_path).size > 0)}
      - res = get_res(path_items[2])
      - if res
        - if res == Session
          %option{:value=>child_path, :selected=>(request.path.scan(child_path).size > 0)} Dates
        - res.all.each do |item|
          - path = "#{child_path}/#{URI.escape(item.to_s)}"
          %option{:value=>path, :selected=>(request.path == path)}= item
    - if (res == Session) and path_items.size > 4 and (path_items[3] == 'dates')
      = "/"
      %select{:name=>'path_item4', :onChange=>"location=document.jump.path_item4.options[document.jump.path_item4.selectedIndex].value;", :value=>"GO"}
        - grandchild_path = path_items[0..3].join('/')
        %option{:value=>child_path, :selected=>(request.path == grandchild_path)}
        - dates = repository(:default).adapter.select('SELECT DISTINCT date FROM sessions')
        - dates.each do |item|
          - path = "#{grandchild_path}/#{URI.escape(item.to_s)}"
          - date = item.is_a?(String) ? Date.parse(item) : item
          %option{:value=>path, :selected=>(request.path == path)}= date.strftime('%a %b %d')


@@ _header
= haml :_breadcrumb


@@ _footer
%footer
  %div.wrapper
    %p
      Powered by
      %a{:href=>"http://github.com/yertto/miff/blob/v#{MY_VERSION}/server.rb"} this code
      , from
      %a{:href=>"http://melbournefilmfestival.com.au"} official MIFF website
      , hosted by
      %a{:href=>"http://heroku.com"} heroku
      , supported by
      %a{:href=>"http://newfangled.com.au"} newfangled
      ,
      %a{:href=>"http://www.twitter.com/yertto"}
        %img{:src=>"http://twitter-badges.s3.amazonaws.com/t_mini-a.png", :alt=>"Follow yertto on Twitter"}
  :javascript
    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', 'UA-17600890-1']);
    _gaq.push(['_trackPageview']);
    (function() {
      var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    })();


@@ layout
%html
  %head
    %title= "MIFF index | #{title}"
    %meta{:name => 'google-site-verification', :content => 'EgzsWP5RBxl62mI6WvVwz3Buhyql9zzt5PMDF6aCDko'}
    %meta{"http-equiv" => "Content-Type", :content => "text/html; charset=utf-8"}
    %meta{:name => 'title', :content => "MIFF index | #{title}"}
    - keywords = title.split(' | ')+'Melbourne,film,film festival,Melbourne International Film Festival,MIFF,index,alternative,underground'.split(',')
    - description = "  Melbourne International Film Festival (MIFF).  (from an alternative, more indexed website than the official website.)"
    - if object.is_a? Film
      - description = object.tagline + description
      - keywords += [:title, :year, :medium, :category, :section, :distributor].map { |x| [x, object.send(x)] }
      - keywords += [:countries, :languages, :directors, :producers, :writers].map { |x| [x, object.send(x)] }
    %meta{"name" => "description", :content => description.strip}
    %meta{"name" => "keywords", :content => keywords.flatten.compact.uniq.join(', ') }
    %link{:rel => 'stylesheet', :type => 'text/css', :href => '/css/01-reset.css' , :media => 'screen projection'}
    %link{:rel => 'stylesheet', :type => 'text/css', :href => '/css/02-forms.css' , :media => 'screen projection'}
    %link{:rel => 'stylesheet', :type => 'text/css', :href => '/css/03-miff.css'  , :media => 'screen projection'}
    %link{:rel => 'stylesheet', :type => 'text/css', :href => '/css/04-popup.css' , :media => 'screen projection'}
  %body
    = haml :_header
    = yield
    = haml :_footer
