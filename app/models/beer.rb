# == Schema Information
#
# Table name: beers
#
#  id                   :integer          not null, primary key
#  beer_name            :string(255)
#  beer_type_old_name   :string(255)
#  beer_rating_one      :float
#  number_ratings_one   :integer
#  created_at           :datetime
#  updated_at           :datetime
#  brewery_id           :integer
#  beer_abv             :float
#  beer_ibu             :integer
#  beer_image           :string(255)
#  speciality_notice    :string(255)
#  original_descriptors :text
#  hops                 :text
#  grains               :text
#  brewer_description   :text
#  beer_type_id         :integer
#  beer_rating_two      :float
#  number_ratings_two   :integer
#  beer_rating_three    :float
#  number_ratings_three :integer
#  rating_one_na        :boolean
#  rating_two_na        :boolean
#  rating_three_na      :boolean
#  user_addition        :boolean
#  touched_by_user      :integer
#  collab               :boolean
#  short_beer_name      :string
#  vetted               :boolean
#  touched_by_location  :integer
#  cellar_note          :text
#  gluten_free          :boolean
#  slug                 :string
#

class Beer < ApplicationRecord
  #include PgSearch
  # searchkick word_middle: [:full_beer_name]
  include DescriptorExtend
  # to strip white spaces from each beer added to this table
  strip_attributes
  
  # include friendly id
  extend FriendlyId
  belongs_to :brewery
  friendly_id :brewery_and_beer_name, use: :slugged
  
  # to implement descriptor tags on each beer
  acts_as_taggable_on :descriptors
  attr_reader :descriptor_list_tokens
  
  belongs_to :beer_type, optional: true
  
  has_many :alt_beer_names
  has_many :beer_locations
  has_many :locations, through: :beer_locations
  has_many :inventories
  has_many :size_formats, through: :inventories
  
  has_many :blog_posts
  has_many :beer_formats
  has_many :size_formats, through: :beer_formats
  accepts_nested_attributes_for :beer_formats, :allow_destroy => true  
  
  has_many :user_beer_ratings
  has_many :users, through: :user_beer_ratings
  has_many :wishlists
  has_many :beer_brewery_collabs
  has_many :user_drink_recommendations
  has_many :user_fav_drinks
  has_many :user_supplies
  has_many :account_deliveries
  has_many :admin_account_deliveries
  has_many :projected_ratings
  
  # the first 8 are for the suggested beer rating formula
  attr_accessor :best_guess
  attr_accessor :ultimate_rating # this will hold a user's rating and/or best_guess to sort by highest rating
  attr_accessor :user_rating # hold the user's ratings
  attr_accessor :number_of_ratings # to hold the number of times a user has rated this beer
  attr_accessor :likes_style # to hold drink style liked/disliked by user
  attr_accessor :this_beer_descriptors # to hold list of descriptors user typically likes/dislikes
  attr_accessor :top_descriptor_list # to hold list of top drink descriptors
  attr_accessor :beer_style_name_one
  attr_accessor :beer_style_name_two
  attr_accessor :recommendation_rationale # to note if recommendation is based on style or type
  attr_accessor :is_hybrid # to note if recommendation is based on style and drink is a hybrid
  # these next three are for when a user suggests to add a new beer
  attr_accessor :associated_brewery
  attr_accessor :rate_beer_now
  attr_accessor :track_beer_now
  attr_accessor :in_wishlist # temporarily holds if drink is in user's wishlist
  attr_accessor :in_cellar # temporarily holds if drink is in user's cellar

  #pg_search_scope :beer_search, :against => :beer_name,
  #                :associated_against => { :brewery => :brewery_name },
  #                :using => { :tsearch => {:prefix => true} }
  
  # update slug
  def should_generate_new_friendly_id?
    new_record? || slug.blank? || beer_name_changed? || slug.nil?
  end
  
  # define slug
  def brewery_and_beer_name
      "#{brewery.brewery_name} #{beer_name}"
  end
  
  # put beer name and id together into one variable
  def connect_deleted_beer
    "#{beer_name} [id: #{id}]"
  end
  
  # join long maker and drink name together
  def join_drink_name
    if brewery.short_brewery_name.nil?
      "#{brewery.brewery_name} #{beer_name}"
    else
      "#{brewery.short_brewery_name} #{beer_name}"
    end
  end
  
  def drink_style
    
  end
  
  def should_index?
    # there are some beers in the db with no corresponding breweries
    !brewery.nil?
  end

  # searchkick word_middle: [:beer_name], autocomplete: [:brewery_name, :beer_name]

  searchkick mappings: {
    beer: {
      properties: {
        brewery_name: {type: "string", analyzer: "standard"},
        short_brewery_name: {type: "string", analyzer: "standard"},
        beer_name: {type: "string", analyzer: "standard"},
        brewery_name_special: {type: "string", analyzer: "start_text_analyzer"},
        short_brewery_name_special: {type: "string", analyzer: "start_text_analyzer"},
        beer_name_special: {type: "string", analyzer: "middle_text_analyzer"}
      }
    }
  }, settings: {
    analysis: {
      analyzer: {
        "middle_text_analyzer": {
          type: "custom",
          tokenizer: "keyword",
          filter: ["lowercase", "ngram"]
        },
        "start_text_analyzer": {
          type: "custom",
          tokenizer: "keyword",
          filter: ["lowercase", "edgeNGram"]
        }
      },
    },
    filter: {
      edge_ngram: {
          type: "edgeNGram",
          min_gram: 1,
          max_gram: 15
      },
      ngram: {
          type: "ngram",
          min_gram: 3,
          max_gram: 10
      },
    }
  }

  def search_data
    {
      brewery_name: brewery.brewery_name,
      short_brewery_name: brewery.short_brewery_name,
      beer_name: beer_name,
      brewery_name_special: brewery.brewery_name,
      short_brewery_name_special: brewery.short_brewery_name,
      beer_name_special: beer_name
    }
  end
  
  # scope cellar drinks
  scope :cellar_drinks, -> {
    joins(:beer_type).merge(BeerType.cellarable) 
  }
  
  # scope non-cellar (cooler) drinks
  scope :cooler_drinks, -> {
    joins(:beer_type).merge(BeerType.non_cellarable) 
  }
  
  # scope all beers connected with a brewery (whether a collab beer or not)
  scope :all_brewery_beers, ->(brewery_id) {
    collab_test = BeerBreweryCollab.where(brewery_id: brewery_id).pluck(:beer_id)
    #Rails.logger.debug("brewrey test: #{collab_test.inspect}")
    if !collab_test.empty?
      #Rails.logger.debug("first option fired")
      combined_array = non_collab_beers(brewery_id) << collab_beers(collab_test)[0]
      combined_array.sort_by{|e| e[:beer_name]}
    else
      #Rails.logger.debug("second option fired")
      non_collab_beers(brewery_id).order(:beer_name)
    end
  }

  # scope order beers by name for inventory management
  scope :order_by_drink_name, -> {
    joins(:brewery).merge(Brewery.order_by_brewery_name).
    order(:beer_name) 
  }
  
  # scope all non-collab beers
  scope :non_collab_beers, ->(brewery_id) {
    where(brewery_id: brewery_id)
  }
  # scope all collab beers
  scope :collab_beers, ->(beer_id) {
    where(id: beer_id) 
  }
  
  # scope brewery name view for collabs
  scope :collab_brewery_name, ->(beer_id) {
    collab_breweries = BeerBreweryCollab.where(beer_id: beer_id)
    collab_brewery_names = ""
    collab_breweries.each do |collab, index|
      brewery = Brewery.find_by_id(collab.brewery_id)
      if !brewery.nil?
        if !brewery.short_brewery_name.nil?
          if collab == collab_breweries.last
            collab_brewery_names = collab_brewery_names + brewery.short_brewery_name
          else
            collab_brewery_names = collab_brewery_names + brewery.short_brewery_name + "/"
          end
        else
          if collab == collab_breweries.last
            collab_brewery_names = collab_brewery_names + brewery.brewery_name
          else
            collab_brewery_names = collab_brewery_names + brewery.brewery_name + "/"
          end
        end
      end
    end
    collab_brewery_names  
  }
  
  # get related drink styles for drinks
  def self.drink_style(drinks)
    style_list = []
    
    drinks.each do |drink|
      if drink.beer_type.beer_style_id == 27
        @relationships = BeerTypeRelationship.where(beer_type_id: drink.beer_type_id).first
        style_list << @relationships.relationship_one
        style_list << @relationships.relationship_two
      else
        style_list << drink.beer_type.beer_style_id
      end
    end
    style_list = style_list.flatten.uniq
  end
  
  # scope current drinks in stock
  scope :current_inventory_drinks, -> {
    joins(:inventories).merge(Inventory.available_current_inventory_drinks)
  }
  
  # scope current beer in stock
  scope :current_inventory_beers, -> {
    joins(:inventories).merge(Inventory.available_current_inventory_beers)
  }
  
  # scope beers based on style chosen
  scope :current_inventory_beers_based_by_style, ->(type_ids){
    current_inventory_beers.
    where(beer_type_id: type_ids)
  }
  
  # scope current ciders in stock
  scope :current_inventory_ciders, -> {
    joins(:inventories).merge(Inventory.available_current_inventory_ciders)
  }
  
  # scope beers based on style chosen
  scope :current_inventory_ciders_based_by_style, ->(type_ids){
    current_inventory_ciders.
    where(beer_type_id: type_ids)
  }
  # scope all drinks ever in inventory 
  scope :inventory_drinks, -> { 
    joins(:inventories).merge(Inventory.ever_in_stock)
  }
  
  # scope all drinks in stock 
  scope :drinks_in_stock, -> { 
    joins(:inventories).merge(Inventory.in_stock)
  }
  
  # scope packaged drinks in stock 
  scope :packaged_drinks_in_stock, -> { 
    joins(:inventories).merge(Inventory.packaged_in_stock)
  }
  # scope draft drinks in stock 
  scope :draft_drinks_in_stock, -> { 
    joins(:inventories).merge(Inventory.draft_in_stock)
  }
  
  # scope all drinks not in stock
  scope :drinks_not_in_inventory, -> { 
    joins(:inventories).merge(Inventory.not_in_inventory)
  }
  
  # scope packaged drinks not in stock
  scope :packaged_drinks_not_in_inventory, -> { 
    joins(:beer_formats).merge(BeerFormat.packaged_drinks).
    joins(:inventories).merge(Inventory.not_in_inventory)
  }
  
  # scope packaged drinks not in stock
  scope :packaged_drinks_not_in_stock, -> { 
    joins(:beer_formats).merge(BeerFormat.packaged_drinks).
    joins(:inventories).merge(Inventory.packaged_not_in_stock)
  }
  
  # scope draft drinks not in stock
  scope :draft_drinks_not_in_inventory, -> { 
    joins(:beer_formats).merge(BeerFormat.draft_drinks).
    joins(:inventories).merge(Inventory.not_in_inventory)
  }
  # scope drinks rated from same brewery
  scope :rating_group_brewery, ->(user_id) {
    joins(:user_beer_ratings).
    group('beers.brewery_id').
    select('sum(user_beer_ratings.user_beer_rating) as brewery_rating').
    order('brewery_rating desc').
    limit(5)
  }
  
  # scope only all drinks shown in admin pages 
  scope :all_live_beers, -> { 
    joins(:beer_locations).merge(BeerLocation.all_current)
  }
  
  # scope only drinks currently available at a particular location
  scope :live_beers_at_location, ->(location_id) { 
    joins(:beer_locations).merge(BeerLocation.active_beers(location_id)) 
  }

  # scope beers that don't have all related info in the DB
  scope :need_attention_beers, -> { 
    includes(:beer_formats).where(beer_formats: { beer_id: nil })     
    }
  # scope beers that have all related info in the DB
  scope :complete_beers, -> { 
    where("rating_one_na = ? OR beer_rating_one IS NOT NULL", true).
    where("rating_two_na = ? OR beer_rating_two IS NOT NULL", true).
    where("rating_three_na = ? OR beer_rating_three IS NOT NULL", true).
    where.not(beer_type_id: nil).
    joins(:beer_formats).
    where('beer_formats.beer_id IS NOT NULL') }
  
  def ready_for_curation
    # check first rating
    if rating_one_na == true || !beer_rating_one.nil?
      @ready = true
    else
      @ready = false
    end
    # if still true, check second rating
    if @ready == true
      if rating_two_na == true || !beer_rating_two.nil?
        @ready = true
      else
        @ready = false
      end
    end
    # if still true, check third rating
    if @ready == true
      if rating_three_na == true || !beer_rating_three.nil?
        @ready = true
      else
        @ready = false
      end
    end
    # if still true, check ABV
    if @ready == true
      if !beer_abv.nil?
        @ready = true
      else
        @ready = false
      end
    end
    # if still true, check Beer Type ID
    if @ready == true
      if !beer_type_id.nil?
        @ready = true
      else
        @ready = false
      end
    end
    # if still true, check Drink Formats
    if @ready == true
      if !self.beer_formats.blank?
        @ready = true
      else
        @ready = false
      end
    end
    # if still true, check Drink Descriptors
    if @ready == true
      if !self.descriptors.blank?
        @ready = true
      else
        @ready = false
      end
    end
    # provide final result
    @ready
  end
  
  # scope beers that have descriptors
  scope :drinks_with_descriptors, -> {
    drink_ids = []
    if !self.descriptors.blank?
      drink_ids << self.id
    end
    drink_ids
  }
  
  # scope beers that have partial related info in the DB
  scope :usable_incomplete_beers, -> {
    where("rating_one_na = ? OR beer_rating_one IS NOT NULL OR beer_type_id IS NOT NULL", true)
    where("rating_two_na IS NULL OR rating_two_na = ?", false).
    where("rating_three_na IS NULL OR rating_three_na = ?", false).
    where(beer_rating_two: nil, beer_rating_three: nil).
    joins(:beer_formats).
    where('beer_formats.beer_id IS NOT NULL')
  }
  
  # get unique beer descriptors
  scope :beer_descriptors, ->(how_many) {
    # create empty array to hold top descriptors list for beer being rated
    @this_beer_descriptors = Array.new
    # find all descriptors for this drink
    @this_beer_all_descriptors = self.descriptors
    # Rails.logger.debug("this beer's descriptors: #{@this_beer_all_descriptors.inspect}")
    @this_beer_all_descriptors.each do |descriptor|
      @descriptor = descriptor["name"]
      @this_beer_descriptors << @descriptor
    end
    
    # attach count to each descriptor type to find the drink's most common descriptors
    @this_beer_descriptor_count = @this_beer_descriptors.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
    # put descriptors in descending order of importance
    @this_beer_descriptor_count = Hash[@this_beer_descriptor_count.sort_by{ |_, v| -v }]
    # grab top 5 of most common descriptors for this drink
    @this_beer_descriptor_count.first(how_many)
  }
  
  # get unique beer descriptors
  def top_drink_descriptors(how_many)
    # create empty array to hold top descriptors list for beer being rated
    @this_beer_descriptors = Array.new
    # find all descriptors for this drink
    @this_beer_all_descriptors = self.descriptors
    # Rails.logger.debug("this beer's descriptors: #{@this_beer_all_descriptors.inspect}")
    @this_beer_all_descriptors.each do |descriptor|
      @descriptor = descriptor["name"]
      @this_beer_descriptors << @descriptor
    end
    
    # attach count to each descriptor type to find the drink's most common descriptors
    @this_beer_descriptor_count = @this_beer_descriptors.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
    # put descriptors in descending order of importance
    @this_beer_descriptor_count = Hash[@this_beer_descriptor_count.sort_by{ |_, v| -v }]
    # grab top 5 of most common descriptors for this drink
    @this_beer_descriptor_count.first(how_many)
  end
  
  # save actual tags without quotes
  def descriptor_list_tokens=(tokens)
     self.descriptor_list = tokens.gsub("'", "")
  end
  # aggregate total number of beer ratings
  def number_ratings
    if number_ratings_one.nil? && number_ratings_two.nil? && number_ratings_three.nil?
      0
    # else, combine the public ratings according to algorithm below
    else  
      if  number_ratings_one && number_ratings_two && number_ratings_three
        (number_ratings_one + number_ratings_two + number_ratings_three)
      elsif number_ratings_one && number_ratings_two
        (number_ratings_one + number_ratings_two)
      elsif number_ratings_one && number_ratings_three
        (number_ratings_one + number_ratings_three)
      elsif number_ratings_two && number_ratings_three
        (number_ratings_two + number_ratings_three)
      elsif number_ratings_one
        number_ratings_one
      elsif number_ratings_two
        number_ratings_two
      else
        number_ratings_three
      end
    end
  end       
  
  #create beer rating algorithm
  def beer_rating
    # if all three public rating sources are nil, provide a "zero" rating for this beer
    if beer_rating_one.blank? && beer_rating_two.blank? && beer_rating_three.blank?
      (3.25*2).round(2)
    # else, combine the public ratings according to algorithm below
    else  
      # determine if a large number of people have provided ratings on this beer
      if number_ratings_one 
        first_ratings = number_ratings_one
      else
        first_ratings = 0
      end
      if number_ratings_two 
        second_ratings = number_ratings_two
      else
        second_ratings = 0
      end
      if number_ratings_three
        third_ratings = number_ratings_three
      else
        third_ratings = 0
      end
      # calculate total number of ratings 
      number_of_ratings = (first_ratings + second_ratings + third_ratings)
      # if a significant number (>500) have rated this beer, don't discount the rating
      if number_of_ratings >= 500
        if  beer_rating_one && beer_rating_two && beer_rating_three
          (((((beer_rating_one * number_ratings_one) + (beer_rating_two * number_ratings_two) + (beer_rating_three * number_ratings_three)) / (number_of_ratings))*1)*2).round(2)
        elsif beer_rating_one && beer_rating_two
          (((((beer_rating_one * number_ratings_one) + (beer_rating_two * number_ratings_two)) / (number_ratings_one + number_ratings_two))*1)*2).round(2)
        elsif beer_rating_one && beer_rating_three
          (((((beer_rating_one * number_ratings_one) + (beer_rating_three * number_ratings_three)) / (number_ratings_one + number_ratings_three))*1)*2).round(2)
        elsif beer_rating_two && beer_rating_three
          (((((beer_rating_two * number_ratings_two) + (beer_rating_three * number_ratings_three)) / (number_ratings_two + number_ratings_three))*1)*2).round(2)
        elsif beer_rating_one
          ((((beer_rating_one * number_ratings_one) / (number_ratings_one))*1)*2).round(2)
        elsif beer_rating_two
          ((((beer_rating_two * number_ratings_two) / (number_ratings_two))*1)*2).round(2)
        else
          ((((beer_rating_three * number_ratings_three) / (number_ratings_three))*1)*2).round(2)
        end
      else
        # if a non-significant number (<500) have rated this beer, discount the rating by 10%
        if  beer_rating_one && beer_rating_two && beer_rating_three
          (((((beer_rating_one * number_ratings_one) + (beer_rating_two * number_ratings_two) + (beer_rating_three * number_ratings_three)) / (number_of_ratings))*0.9)*2).round(2)
        elsif beer_rating_one && beer_rating_two
          (((((beer_rating_one * number_ratings_one) + (beer_rating_two * number_ratings_two)) / (number_ratings_one + number_ratings_two))*0.9)*2).round(2)
        elsif beer_rating_one && beer_rating_three
          (((((beer_rating_one * number_ratings_one) + (beer_rating_three * number_ratings_three)) / (number_ratings_one + number_ratings_three))*0.9)*2).round(2)
        elsif beer_rating_two && beer_rating_three
          (((((beer_rating_two * number_ratings_two) + (beer_rating_three * number_ratings_three)) / (number_ratings_two + number_ratings_three))*0.9)*2).round(2)
        elsif beer_rating_one
          ((((beer_rating_one * number_ratings_one) / (number_ratings_one))*0.9)*2).round(2)
        elsif beer_rating_two
          ((((beer_rating_two * number_ratings_two) / (number_ratings_two))*0.9)*2).round(2)
        else
          ((((beer_rating_three * number_ratings_three) / (number_ratings_three))*0.9)*2).round(2)
        end
      end
    end
  end
  
end # end of controller