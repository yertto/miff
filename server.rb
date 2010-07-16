#!/usr/local/bin/ruby -rrubygems
require 'sinatra'

require 'db'
require 'helpers'


use Rack::Auth::Basic do |username, password|
  [username, password] == ['admin', 'admin']
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
%h2= \"<a href='/films'>Films</a>: \#{haml :_#{names}_a}\"
%table.list
  - #{names}.each do |x|
    %tr
      %td= x.films.count
      %td= link_to x"""
    }
    template name.to_sym, &lambda { """
%h2= \"<a href='/films'>Films</a>: \#{haml :_#{names}_a}: \#{#{name}}\"
%div.list= haml :_film_table, :locals => { :films => #{name}.films }"""
    }
  end
end

# Use the above helper to create views and routes for the following resources.
RESOURCES = [Session, Section, Category, Venue, Country, Year, Media, Language, Subtitle, Distributor, Director, Writer, Producer]
RESOURCES.each { |res|
  create_film_resource res
}  
RESOURCES_ALL = [Film]+RESOURCES


# Create get routes and their rendering code based on a resource and the route...
#
# NB. matching views need to be created
# eg.
#   create_get '/sessions/:id' , Session  # renders a session object to a 'session' view
#                                         # (it also creates a 'session' view, and a '_session_a' partial)
#   create_get '/sessions'     , Session  # renders all session objects to a 'sessions' view
#                                         # (it also creates the 'sessions' view, and a '_sessions_a' partial)
#
create_get '/films'                    , Film
create_get '/films/:id'                , Film

# special cases ...
create_partial :_date_a , '%a(href="/films/sessions/date/#{date}")= date.strftime("%a %b %d %Y")'

get '/films/sessions/date/:date' do
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
      - %w(Name Duration Year Countries Languages Subtitles Director Writers Distributor Media Sessions).each do |th|
        %th.heading= th
  %tbody
    - films.each do |film|
      %tr
        %td= haml :_film_a_popup, :locals => { :film => film }
        %td= "#{film.duration} mins"
        %td= link_to film.year
        %td= film.countries.collect { |country|  link_to country  }
        %td= film.languages.collect { |language| link_to language }
        %td= film.subtitle
        %td= film.directors.collect { |director| link_to director }
        %td= film.writers.collect   { |writer|   link_to writer   }
        %td= film.distributor
        %td= film.media
        %td= film.sessions.collect { |session| link_to session }


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
  = "TD #{haml :_media_a, :locals => {:media => film.media}}/#{haml :_year_a, :locals => {:year => film.year}}" 


@@ _film_a_popup
%a{:href=>"/films/#{film.id}", :class=>"thumbnail"}
  = film.title
  %span
    %div.tagline= film.tagline
    %img{:src=>"#{film.still_url}"}


@@ film
%article
  %h1= haml :_film_a, :locals => { :film => film }
  %img(src="#{film.still_url}")
  %div.tagline= film.tagline
  %div.col1
    %div.year
      %h2 Year
      = film.year
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
%h2
  - if locals.has_key? :title
    = "<a href='/films'>Films</a> : #{title} (<a href='/#{title_type}'>all #{title_type}</a>)"
  - else
    Films
%div.list= haml :_film_table, :locals => { :films => films }


@@ _sessions_table
%table.sessionTable
  %thead
    %tr
      - %w(Code Films Date Time Venue).each do |th|
        %th.heading(valign="top")= th
  %tbody
    %tr
    - sessions.each do |session|
      %tr
        %td.session_code= link_to(session)
        %td= session.films.collect { |film| "#{haml :_film_a_popup, :locals => {:film => film}} (#{film.duration} mins) <br/>" }
        %td.session_day= haml :_date_a, :locals => { :date => Date.parse(session.time.strftime('%Y/%m/%d')) }
        %td.session_time= session.time.strftime("%l.%M%P")
        %td.session_venue= link_to(session.venue)



@@ session
%h2= "<a href='/films'>Films</a>: #{haml :_sessions_a} : #{session.id}"
%div.list= haml :_sessions_table, :locals => { :sessions => [session] }


@@ sessions
%h2
  - if locals.has_key? :date
    = "<a href='/films'>Films</a>: #{haml :_sessions_a}: #{haml :_date_a, :locals => {:date => date}}"
  - else
    = "<a href='/films'>Films</a>: #{haml :_sessions_a}"
%div.list= haml :_sessions_table, :locals => { :sessions => sessions }
  

@@ _header
%header
  %div.wrapper
    %nav
      %ul
        - RESOURCES_ALL.each do |res|
          %li
            - name = res.storage_name
            - url = ['films', 'sessions'].include?(name) ? "/#{name}" : "/films/#{name}"
            %a{:href=>url, :class=>current_section(url)}= name.capitalize


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
    = haml :_header
    %div.main
      %div.wrapper
        = yield
    %footer
      %div.wrapper
        %p MIFF underground

