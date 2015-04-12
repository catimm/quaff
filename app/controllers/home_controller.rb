class HomeController < ApplicationController
  has_scope :beer_type
  
  def index  
    @time = Time.current - 30.minutes
    @current_beers = BeerLocation.where(beer_is_current: "yes").pluck(:beer_id)
    Rails.logger.debug("Current Beers: #{@current_beers.inspect}")
    @beers = Beer.where(id: @current_beers).order(:beer_rating).order(:number_ratings).reverse
    Rails.logger.debug("Beer list: #{@beers.inspect}")
    @location_ids = BeerLocation.where(beer_is_current: "yes").pluck(:location_id)
    @locations = Location.where(id: @location_ids).order(:name)
    Rails.logger.debug("Location list: #{@locations.inspect}")
    @beer_types = @beers.map{|x| x[:beer_type]}.uniq
    Rails.logger.debug("Beer types: #{@beer_types.inspect}")
    
 
  end
  
  def update
    require 'nokogiri'
    require 'open-uri'
    
    doc_pb = Nokogiri::HTML(open('http://www.pineboxbar.com/'))
    Rails.logger.debug("Doc info: #{doc_pb.inspect}")
    
    doc_pb.search("li.beer_odd", "li.beer_even").each do |node|
      node.css("div").remove
      pb_beers = node.text.strip.gsub(/\n  +/, " ") 
      Rails.logger.debug("Pine Box Beers: #{pb_beers.inspect}")
    end
    
    doc_bj = Nokogiri::HTML(open('http://seattle.taphunter.com/widgets/locationWidget?orderby=category&breweryname=on&format=images&brewerylocation=on&onlyBody=on&location=The-Beer-Junction&width=925&updatedate=on&servingsize=on&servingprice=on'))
    Rails.logger.debug("Doc info: #{doc_bj.inspect}")
    
    doc_bj.search("a.beername").each do |node|
      bj_beers = node.text.strip.gsub(/\n  +/, " ") 
      Rails.logger.debug("Beer Junction Beers: #{bj_beers.inspect}")
    end

  end
  
end