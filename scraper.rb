#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
  # Nokogiri::HTML(open(url).read, nil, 'utf-8')
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('td#ContentCell ul li a/@href').each do |link|
    mp_url = URI.join(url, link)
    scrape_person(mp_url)
  end
end

def scrape_person(url)
  noko = noko_for(url)

  id, details = File.basename(url.path, '.aspx').split('-', 2)
  name, party = details.split(/deputatskaya_gruppa|Frakciya/, 2).map { |str| str.tr('_', ' ').tidy } 

  details_ru = noko.css('div.HeaderCaption').text
  # name_ru, party_ru = details_ru.split(/депутатская группа |Фракция/, 2).map { |str| str.tr('_', ' ').tidy } 
  name_ru, party_ru = details_ru.split(/\s*-\s*/, 2)

  data = { 
    id: id,
    name: name,
    name_ru: name_ru.tidy,
    party: party.to_s,
    party_ru: party_ru.to_s.sub('депутатская группа','').sub('Фракция', '').tidy,
    image: noko.css('div.MiddlePanel img[@align="left"]/@src').text,
    term: '6',
    source: url.to_s,
  }
  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
  puts data[:name]
  ScraperWiki.save_sqlite([:id, :term], data)
end

scrape_list('http://www.kenesh.kg/RU/Folders/31642-Deputaty_ZHogorku_Kenesha_VI_sozyva.aspx')
