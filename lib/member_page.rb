# frozen_string_literal: true
require 'scraped'

class MemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::AbsoluteUrls

  field :id do
    url.to_s.split('/')[-2]
  end

  field :name do
    noko.css('p.person-name').text.tidy
  end

  field :faction do
    noko.css('p.person-support').text.tidy
  end

  field :image do
    noko.css('.person-img img/@src').text
  end

  field :term do
    '6'
  end

  field :phone do
    infotable.xpath('.//th[.="Телефон:"]//following-sibling::td').text
  end

  field :source do
    url.to_s
  end

  private

  def infotable
    noko.css('table.person-inform-table')
  end
end
