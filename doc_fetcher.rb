require 'nokogiri'
require 'fetcher'

module DocFetcher
  include Fetcher

  def doc_fetch(url, cache_file=nil)
    Nokogiri.parse(get_data(url, cache_file))
  end

  def xpath_fetch(xpath, url, cache_file=nil)
    doc_fetch(url, cache_file).xpath(xpath)
  end
end
