#!/usr/local/bin/ruby -rrubygems
require 'sinatra'

require 'db'
require 'helpers'


use Rack::Auth::Basic do |username, password|
  [username, password] == ['admin', ENV['SITE_PASSWORD']]
end if ENV['SITE_PASSWORD']


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

# Use the above helper to create views and routes for the following resources.
RESOURCES = [Session, Section, Category, Venue, Country, Year, Medium, Language, Subtitle, Distributor, Director, Writer, Producer]
RESOURCES.each { |res|
  create_film_resource res
}  
RESOURCES_ALL = [Film]+RESOURCES


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


get '/' do
  redirect '/films/countries'
end


__END__


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
  

@@ _header
%header
  %div.wrapper
    %nav
      %ul
        - RESOURCES_ALL.each do |res|
          %li
            - name = res.storage_name
            - url = ['films'].include?(name) ? "/#{name}" : "/films/#{name}"
            %a{:href=>url, :class=>current_section(url)}= name.capitalize


@@ _breadcrumb
%form{:name=>'jump'}
  %select{:name=>'films', :onChange=>"location=document.jump.films.options[document.jump.films.selectedIndex].value;", :value=>"GO"}
    %option{:value=>'/films'} Films
    - Film.all.each do |film|
      - path = "/films/#{film.id}"
      - t = film.title
      %option{:value=>path, :selected=>(request.path == path)}= t.size > 20 ? "#{t[0..15]}...#{t[-4..-1]}" : t
  = "/"
  %select{:name=>'films_child', :onChange=>"location=document.jump.films_child.options[document.jump.films_child.selectedIndex].value;", :value=>"GO"}
    %option{:value=>'/films', :selected=>(request.path == '/films')}
    - RESOURCES.each do |res|
      - name = res.storage_name
      - path = "/films/#{name}"
      %option{:value=>path, :selected=>(request.path.scan(path).size > 0)}= name.capitalize
  = "/"
  - if m = /(?:(\/films\/(.*?))(?:(?:\/)(.*))?$)/.match(request.path)
    - child_path, child, grandchild = m.captures
    %select{:name=>'films_grandchild', :onChange=>"location=document.jump.films_grandchild.options[document.jump.films_grandchild.selectedIndex].value;", :value=>"GO"}
      %option{:value=>child_path, :selected=>(request.path.scan(child_path).size > 0)}
      - res = RESOURCES.detect { |res| res.storage_name == child }
      - if res
        - if res == Session
          %option{:value=>child_path, :selected=>(request.path.scan(child_path).size > 0)} Dates
        - res.all.each do |item|
          - path = "#{child_path}/#{URI.escape(item.to_s)}"
          %option{:value=>path, :selected=>(request.path == path)}= item
    - if (res == Session) and grandchild and (grandchild.scan('dates').size > 0)
      = "/"
      %select{:name=>'films_greatgrandchild', :onChange=>"location=document.jump.films_greatgrandchild.options[document.jump.films_greatgrandchild.selectedIndex].value;", :value=>"GO"}
        - grandchild, greatgrandchild = grandchild.split('/')
        - grandchild_path = "#{child_path}/#{grandchild}"
        %option{:value=>child_path, :selected=>(request.path == grandchild_path)}
        - dates = repository(:default).adapter.select('SELECT DISTINCT date FROM sessions')
        - dates.each do |item|
          - path = "#{grandchild_path}/#{URI.escape(item.to_s)}"
          - date = item.is_a?(String) ? Date.parse(item) : item
          %option{:value=>path, :selected=>(request.path == path)}= date.strftime('%a %b %d')
      


@@ layout
%html
  %head
    %meta{"http-equiv" => "Content-Type", :content => "text/html; charset=utf-8"}
    %title Miff
    %link{:rel => 'stylesheet', :type => 'text/css', :href => '/css/01-reset.css' , :media => 'screen projection'}
    %link{:rel => 'stylesheet', :type => 'text/css', :href => '/css/02-forms.css' , :media => 'screen projection'}
    %link{:rel => 'stylesheet', :type => 'text/css', :href => '/css/03-miff.css'  , :media => 'screen projection'}
    %link{:rel => 'stylesheet', :type => 'text/css', :href => '/css/04-popup.css' , :media => 'screen projection'}
  %body
    /= haml :_header
    /%div.main
    /  %div.wrapper
    /    = haml :_breadcrumb
    /    = yield
    = haml :_breadcrumb
    = yield
    %footer
      %div.wrapper
        %p MIFF underground

