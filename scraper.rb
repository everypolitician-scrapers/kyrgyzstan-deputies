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

class MemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::AbsoluteUrls

  field :id do
    url.to_s.split('/')[-2]
  end

  field :name do
    noko.css('p.person-name').text.tidy
  end

  field :party do
    noko.css('p.person-support').text.tidy
  end

  field :image do
    noko.css('.person-img img/@src').text
  end

  field :term do
    '6'
  end

  field :phone do
    noko.css('table.person-inform-table').xpath('.//th[.="Телефон:"]//following-sibling::td').text
  end

  field :source do
    url.to_s
  end
end

def scrape_list(url)
  MembersPage.new(response: Scraped::Request.new(url: url).response)
end

def scrape_person(url)
  data = MemberPage.new(response: Scraped::Request.new(url: url).response).to_h
  puts data
  ScraperWiki.save_sqlite([:id, :term], data)
end

kg = scrape_list('http://www.kenesh.kg/ky/deputy/list/35')
kg.members.each { |mem| scrape_person mem.url }
