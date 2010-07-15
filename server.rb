#!/usr/local/bin/ruby -rrubygems
require 'sinatra'

require 'db'
require 'helpers'

use Rack::Auth::Basic do |username, password|
  [username, password] == ['admin', 'openhub']
end

create_get '/films'                    , Film
create_get '/films/:id'                , Film
create_get '/sessions'                 , Session
create_get '/sessions/:id'             , Session
# Create get routes and their rendering code based on a resource and the route...
#
# NB. matching views need to be created
# eg.
#   create_get '/countries/:name/films' , Country  # renders a country object to a 'country' view
#                                                  # (it also creates a 'country' view,
#                                                     and a '_country_a' partial)
#   create_get '/countries'             , Country  # renders all country objects to a 'countries' view
#                                                  # (it also creates the 'countries' view,
#                                                  #  and a '_countries_a' partial)
#
RESOURCES = [Section, Category, Venue, Country, Language, Subtitle, Distributor, Director, Writer, Producer]
RESOURCES.each { |res|
  create_film_resource res
}  


create_partial :_media_a , '%a(href="/medias/#{media}/films")= media'
get '/medias' do
  repository(:default).adapter.select('SELECT DISTINCT media from films').collect { |media|
    haml :_media_a, :locals => { :media => media }
  }
end
get '/medias/:media/films' do
  haml :films, :locals => { :title => params[:media], :title_type => 'medias', :films => Film.all(:media => params[:media]) }
end

create_partial :_year_a , '%a(href="/years/#{year}/films")= year'
get '/years/:year/films' do
  haml :films, :locals => { :title => params[:year], :title_type => 'years', :films => Film.all(:year => params[:year]) }
end

# special cases ...
create_partial :_date_a , '%a(href="/sessions/date/#{date}")= date.strftime("%a %b %d %Y")'

get '/sessions/date/:date' do
  haml :sessions_date, :locals => { :date => params[:date], :sessions => Session.all(:date => params[:date]) }
end



get '/' do
  'Hello World'
end


__END__


@@ _sessions_table
%div.filmSessions
  %h2 Sessions
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
        %td= session.films.collect { |film| "#{link_to(film)} (#{film.duration} mins) <br/>" }
        %td.session_day= haml :_date_a, :locals => { :date => Date.parse(session.time.strftime('%Y/%m/%d')) }
        %td.session_time= session.time.strftime("%l.%M%P")
        %td.session_venue= link_to(session.venue)


@@ _film
%div.film
  %h1= haml :_film_a, :locals => { :film => film }
  %span.countries= film.countries.collect { |x| link_to x }.join('| ')
  = ", #{film.year}"
  - if film.section
    %span.sections= "(#{link_to film.section})"
  - if film.category
    %span.sections= "(#{link_to film.category})"

@@ _film_list
- films.each do |film|
  = haml :_film, :locals => { :film => film }


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


@@ film
= haml :_film, :locals => { :film => film }
%img(src="#{film.still_url}")
%p
  %b&= film.tagline
%div.synopsis= film.synopsis
= haml :_film_details  , :locals => { :film => film }
= haml :_sessions_table, :locals => { :sessions => film.sessions }


@@ films
- if locals.has_key? :title
  %h1= "<a href='/films'>Films</a> : #{title} (<a href='/#{title_type}'>all #{title_type}</a>)"
- else
  %h1 Films
%div.list= haml :_film_list, :locals => { :films => films }


@@ session
%h1= "Session #{session.id}"
%div.list= haml :_sessions_table, :locals => { :sessions => [session] }


@@ sessions_date
%h1= "Sessions on #{date}"
%div.list= haml :_sessions_table, :locals => { :sessions => sessions }



@@ layout
%html
  %head
    %title Miff
    %link{:rel => 'stylesheet', :type => 'text/css', :href => '/css/reset.css'  , :media => 'screen projection'}
    %link{:rel => 'stylesheet', :type => 'text/css', :href => '/css/grid.css'   , :media => 'screen projection'}
    %link{:rel => 'stylesheet', :type => 'text/css', :href => '/css/layout.css' , :media => 'screen projection'}
    %link{:rel => 'stylesheet', :type => 'text/css', :href => '/css/program.css', :media => 'screen projection'}
  %body
    %div.header= RESOURCES.collect { |res| haml "_#{res.storage_name}_a".to_sym }.join(' | ')
    = yield
