# frozen_string_literal: true

require_relative 'option_parser'
require 'curb'
require 'csv'
require 'nokogiri'
require 'ruby-progressbar'

class Parser
  CATEGORY_XPATH = "//*[@id='subcategories']/ul/li"
  PRODUCTS_XPATH = "//*[@id='product_list']/li"
  PRODUCT_LINK_XPATH = 'div[1]/div/div[1]/a'
  NAME_XPATH = "//*[@id='center_column']/div/div/div[2]//h1"
  ITEMS_XPATH = "//*[@id='attributes']/fieldset/div/ul/li"
  IMG_XPATH = "//*[@id='bigpic']"
  OPTION_XPATH = 'label/span[1]'
  PRICE_XPATH = 'label/span[2]'

  PRICE_REGEXP = /[0-9]+\.[0-9]+/.freeze
  NAME_REGEXP = /([A-Za-z0-9\+\-]+\s)+/.freeze

  attr_reader :options

  def initialize(args)
    @options = OptionParser.new(args)
  end

  def perform
    threads = prepare_threads

    CSV.open("#{options.file}.csv", 'w') do |csv|
      puts 'Perfoming requests...'
      pages = threads.map(&:value).flatten!
      progressbar = ProgressBar.create(total: pages.size)

      puts 'Writing data...'
      pages.each do |page|
        progressbar.increment
        next if page.nil?
        csv_rows_from(page).each { |row| csv << row }
      end
    end
  end

  def csv_rows_from(page)
    rows = []
    name = page.xpath(NAME_XPATH).text.match(NAME_REGEXP)[0].strip.capitalize
    img = page.xpath(IMG_XPATH).attribute('src').value
    items = page.xpath(ITEMS_XPATH)

    items.each do |item|
      option = item.xpath(OPTION_XPATH).text.gsub('.', '')
      price = item.xpath(PRICE_XPATH).text.match(PRICE_REGEXP)[0]

      rows << [name + ' - ' + option, price, img]
    end
    rows
  end

  def prepare_threads
    sliced_requests_by(1).map do |requests|
      Thread.new do
        requests.map do |curl|
          curl.perform
          Nokogiri::HTML(curl.body_str) if curl.response_code == 200
        end
      end
    end
  end

  def product_urls
    pagination = 1
    product_urls = []

    while (c = Curl::Easy.perform(pagination == 1 ? options.link : "#{options.link}?p=#{pagination}")).response_code == 200
      page = Nokogiri::HTML(c.body_str)

      pagination += 1

      product_urls << page.xpath(PRODUCTS_XPATH).map do |product|
        product.xpath(PRODUCT_LINK_XPATH).attribute('href').value
      end
    end
    product_urls.flatten!
  end

  def sliced_requests_by(slice_count)
    product_urls.map do |product_url|
      Curl::Easy.new(product_url)
    end.each_slice(slice_count)
  end
end
