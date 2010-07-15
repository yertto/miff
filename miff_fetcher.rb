#!/usr/bin/ruby -rrubygems
require 'doc_fetcher'
require 'db'
require 'fixes'
USE_FIXES = true

HOST = 'http://www.melbournefilmfestival.com.au'


module Miff
  extend DocFetcher

  def self.cache_dir
    @cache_dir ||= Pathname.new(".cache")
  end

  def self.fetch_films
    i = 0
    xpath_fetch('//td[@class="snippet"]/h3/a', HOST+'/films/browse?grp=all').collect { |a|
      i+=1
      Film.parse_doc(doc_fetch(HOST+a.attributes['href'].value)) #if i < 3
      #Film.parse_doc(doc_fetch(HOST+a.attributes['href'].value)) if a.attributes['href'].value == '/films/view?film_id=109640'
    }.compact
  end

  def self.fetch_countries
    xpath_fetch('//a[contains(@href, "/films/view?country=")]',
      HOST+'/films/program_2010/browse_by_country').collect { |node|
      name = node.text.strip
      if name.size > 0
        item = Country.first_or_create(:name => name)
        item.films = xpath_fetch('//h3/a[contains(@href, "/films/view?film_id=")]',
          HOST+node.attributes['href'].value
        ).collect { |a| Film.parse_anchor(a)
        }
        raise "Invalid country: #{item.inspect}" unless item.valid?
        item.save
        item
      end
    }.compact
  end

  def self.fetch_sections
    # NB. very similar to fetch_countries (refactor candidate?)
    cache_file = Pathname.new('.cache/program/sections.html') # XXX need to hard-code a cache_file for this one.
    xpath_fetch('//h3/a[contains(@href, "/program/sections/")]',
      HOST+'/program/sections', cache_file).collect { |node|
      name = node.text.strip
      if name.size > 0
        item = Section.first_or_create(:name => node.text.strip)
        item.films = xpath_fetch('//h3/a[contains(@href, "/films/view?film_id=")]',
          HOST+node.attributes['href'].value
        ).collect { |a| Film.parse_anchor(a)
        }
        raise "Invalid section: #{item.inspect}" unless item.valid?
        item.save
        item
      end
    }.compact
  end

  def self.parse
    puts fetch_films
    puts fetch_countries
    puts fetch_sections
  end
end


class Film

  PAT_SYNOPSIS = Regexp.compile('<\!-- Start Film Synopsis -->(.*)<\!-- End Film Synopsis -->', Regexp::MULTILINE)

  def self.parse_doc(doc)
    # XXX - refactor candidate
    still = doc.xpath('//img[@class="movie-still"]/@src').text
    if still.size > 0
      still_url = HOST+still
      film_id = still_url.split('/')[-2].to_i
      film = Film.first_or_create(:id => film_id)
      h = get_details(doc.xpath('//div[@class="filmdetails"]').text.strip)
      if h
        # has n associations
        [Director, Producer, Writer, Language].each { |res|
          sym = (n = res.storage_name).to_sym
          film.send((n+'=').to_sym, h.delete(sym).collect { |x| res.first_or_create(:name => x.strip) }) if h[sym]
        }
        # belongs_to associations
        [Distributor, Subtitle].each { |res|
          sym = (n = res.name.downcase).to_sym
          film.send((n+'=').to_sym, res.first_or_create(:name => h.delete(sym)).strip ) if h[sym]
        }
        film.attributes = h
      end
      film.still_url = still_url
      film.title = doc.xpath('//h3[@class="movieTitle"]').text
      film.countries = doc.xpath('//a[contains(@href, "/films/view?country=")]').collect { |node|
        Country.first_or_create(:name => node.text.strip)
      }
      film.section = doc.xpath('//a[contains(@href, "/program/sections/")]').collect { |node|
        Section.first_or_create(:name => node.text.strip)
      }.first
      film.category = doc.xpath('//a[contains(@href, "/films/view?category=")]').collect { |node|
        Category.first_or_create(:name => node.text.strip)
      }.first
      trailer = doc.xpath('//a[@class="trailerlink"]/@href')
      film.trailer_url = HOST+trailer.text.strip if trailer.text.size > 0
      if m = PAT_SYNOPSIS.match(doc.to_s)
        synopsis = Nokogiri.parse("<html>#{m[1].strip}</html>").xpath('/html/body').children
        tagline = (synopsis/:p).first
        film.tagline = tagline.text.strip if tagline
        synopsis = synopsis.to_s.split(tagline.to_s)[1]
        film.synopsis = synopsis.strip if synopsis
      end
      #_film = doc.xpath('//tr/td[@valign="top"]/strong/a[contains(@href, "/films/view?film_id=")]').first
      #film.duration = _film.parent.next.text[3..-6].to_i if _film
      film.sessions = doc.xpath('//tr/td[@class="session_code"]').collect { |session_code_node|
        #h = parse_session_node(session_code_node.parent)
        #Session.first_or_create({:id => h[:id]}, h)
        Session.parse_row(session_code_node.parent)
      }
      raise "Invalid film: #{film.inspect}" unless film.valid?
      film.save
      film
    end
  end

  def self.parse_anchor(a)
    first_or_create(:id => a.attributes['href'].value.split('=')[1].to_i)
  end

  PAT_DETAILS = Regexp.compile('^(?:D(/P)?(/S)? (.*?))(?: P (.*?)\s*)?(?: S (.*?))?(?: (Dist|WS) (.*?))?(?: L (.*?)(?: w/(.*) subtitles)?)?\s+TD\s+(3D\s+)?(?:(16mm|35mm|betacamsp|digibeta|DCP|HDCAM)\s*/)?(\d{4})$')

  def self.get_details(details)
    # XXX - refactor candidate
    if details.size > 0
      details = Details::fix(details) if USE_FIXES
      if m = PAT_DETAILS.match(details)
        h = Hash[ [:p, :s, :directors, :producers, :writers, :distributor_type, :distributor, :languages, :subtitle, :three_d, :media, :year].zip(m.captures) ]
        [:directors, :producers, :writers, :languages].each { |x| h[x] = h[x].split(', ') if h[x] }
        h[:producers] = h[:directors] if h.delete(:p)
        h[:writers]   = h[:directors] if h.delete(:s)
        h[:three_d  ] = !h[:three_d].nil?
        Hash[h.select { |k,v| !v.nil? }]  # get rid of nilled attributes
      else
        warn "WARNING Parseing error for details: #{details.inspect}"
      end
    end
  end
end


class Session
  def self.parse_row(row)
    result = first_or_create(
      :id        => row.xpath('td[@class="session_code"]').text.strip.to_i,
      :date      => Date.parse(
        "#{row.xpath('td[@class="session_day"]/a').text} 2010"
      ),
      :time      => Time.parse(
        "#{row.xpath('td[@class="session_time"]').text} #{row.xpath('td[@class="session_day"]/a').text} 2010"
      ),
      :venue     => Venue.first_or_create(:name => row.xpath('td[@class="session_venue"]').text.strip)
    )
    result.films = row.xpath('td/strong/a[contains(@href, "/films/view?film_id=")]').collect { |a|
      film = Film.parse_anchor(a)
      film.duration = a.parent.next.text[3..-6].to_i
      film
    }
    result
  end
end

if __FILE__ == $0
  #MIFF = Festival.first_or_new(:name => 'MIFF', :year => 2010) # XXX - this transaction attempt is too slow

  Miff.parse
  #p Country.all
end

