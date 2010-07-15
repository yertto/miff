require 'date'
require 'open-uri'
require 'pathname'

SLEEP_TIME = 0  # Be nice to the host and sleep between http requests

module Fetcher

  def cache_dir
    @cache_dir ||= Pathname.new(".cache/#{Date.today.strftime('%y%m%d')}")
  end

  def _get_cache_file_and_data(url, cache_file=nil)
    url = URI.parse(url) unless url.is_a? URI::HTTP
    unless cache_file
      cache_file = cache_dir.join(url.path[1..-1])
      cache_file = cache_file.join(url.query) if url.query
    end
    cache_file.dirname.mkpath unless cache_file.dirname.exist?
    data = if cache_file.exist?
      STDERR.puts "Reading data from #{cache_file} ..."
      cache_file.read
    else
      cache_file.open('w') { |f|
        data = open(url).read
        STDERR.puts "Caching data to #{cache_file} ..."
        f.write(data)
        STDERR.puts "Sleeping for #{SLEEP_TIME} seconds ..."; sleep SLEEP_TIME 
        data
      }
    end
    [cache_file, data]
  end

  def get_cache_file(url, cache_file=nil)
    _get_cache_file_and_data(url, cache_file)[0]
  end

  def get_data(url, cache_file=nil)
    _get_cache_file_and_data(url, cache_file)[1]
  end
end
