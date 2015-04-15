class HomeController < ApplicationController
  helper_method :ratings_sorter
  
  def index  
    @time = Time.current - 30.minutes
    @filterrific = initialize_filterrific(
      Beer,
      params[:filterrific],
      select_options: {
        sorted_by: Beer.options_for_sorted_by,
        with_any_location_ids: Location.options_for_select,
        with_beer_type: Beer.options_for_beer_type.uniq,
        beer_abv_lte: Beer.options_for_beer_abv,
        with_special: Beer.options_for_special_beer.uniq
      },
      persistence_id: 'shared_key',
      default_filter_params: {},
      available_filters: [],
    ) or return
    @beers = @filterrific.find.page(params[:page])
    
 
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
  
  private
  
  def ratings_sorter
    Beer.column_names.include?(params[:ratings_sort]) ? params[:ratings_sort] : "beer_rating"
  end
  
end