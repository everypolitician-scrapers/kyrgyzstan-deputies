#!/bin/env ruby
# encoding: utf-8

require 'scraped'
require 'scraperwiki'
require 'nokogiri'
require 'open-uri'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::AbsoluteUrls

  field :members do
    noko.xpath('//table[@class="table"]//tr[td]').map do |tr|
      fragment tr => MemberRow
    end
  end

  class MemberRow < Scraped::HTML
    field :number do
      tds[0].text.tidy
    end

    field :id do
      url.split('/')[-2]
    end

    field :name do
      tds[1].text.tidy
    end

    field :url do
      tds[1].css('a/@href').text
    end

    field :faction do
      tds[2].text.tidy
    end

    field :faction_url do
      tds[2].css('a/@href').text
    end

    field :faction_id do
      faction_url.split('/')[-3]
    end

    private

    def tds
      noko.css('td')
    end
  end

end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  kg = MembersPage.new(response: Scraped::Request.new(url: url).response)
  kg.members.each { |mem| scrape_person mem.url }
end

def scrape_person(url)
  warn url
  noko = noko_for(url)

  data = {
    id: url.to_s.split('/')[-2],
    name: noko.css('p.person-name').text.tidy,
    # name_ru: name_ru.tidy,

    party: noko.css('p.person-support').text.tidy,
    # party_ru: party_ru.to_s.sub('депутатская группа','').sub('Фракция', '').tidy,

    image: noko.css('.person-img img/@src').text,
    term: '6',

    phone: noko.css('table.person-inform-table').xpath('.//th[.="Телефон:"]//following-sibling::td').text,
    source: url.to_s,
  }
  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
  puts data
  ScraperWiki.save_sqlite([:id, :term], data)
end

scrape_list('http://www.kenesh.kg/ky/deputy/list/35')
