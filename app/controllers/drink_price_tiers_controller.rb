class DrinkPriceTiersController < ApplicationController
  
  def show
    
  end # end of show method
  
  def new 
    # add retailer info in case form upload doesn't work and form gets shown again 
    @retail_id = session[:retail_id]
    @retailer = Location.find(@retail_id)
    # get draft info
    @draft = DraftBoard.find_by_id(params[:format])
    @drink_price_tiers = @draft.drink_price_tiers.build
    @drink_price_tier_details = @drink_price_tiers.drink_price_tier_details.build
    @drink_price_status = "new"
    @this_path = "create_drink_price_tier_path"
  end # end of new method
  
  def create
    
  end # end of create method
  
  def edit
    # add retailer info in case form upload doesn't work and form gets shown again 
    @retail_id = session[:retail_id]
    @retailer = Location.find(@retail_id)
    # get draft info
    @draft = DraftBoard.find_by_id(params[:id])
    @drink_price_tiers = DrinkPriceTier.where(draft_board_id: params[:id])
    @drink_price_tier_details = DrinkPriceTierDetail.where(drink_price_tier_id: @drink_price_tiers[0].id)
    @last_drink_prices_update = DrinkPriceTier.where(draft_board_id: params[:id]).order(:updated_at).reverse_order.first
    @this_path = ""
  end # end of edit method
  
  def update
    # find if pricing information already exists
    @price_tiers = DrinkPriceTier.where(draft_board_id: params[:draft_board][:drink_price_tiers_attributes]["0"][:draft_board_id])
    # if it does exist, delete it all
    if !@price_tiers.blank?
      @price_tiers.each do |tier|
        @price_tier_details = DrinkPriceTierDetail.where(drink_price_tier_id: tier.id)
        if !@price_tier_details.blank?
          @price_tier_details.destroy_all
        end
      end
      @price_tiers.destroy_all
    end
    
    # now get new information and insert it
    params[:draft_board][:drink_price_tiers_attributes].each do |drink|
        # first make sure this item should be added (ie wasn't deleted)
        @destroy = drink[1][:_destroy]
        if @destroy != "1"
            @new_price_tier = DrinkPriceTier.new(draft_board_id: drink[1][:draft_board_id], 
                                         tier_name: drink[1][:tier_name])
            @new_price_tier.save
               # add size/cost of new draft drink
               if !drink[1][:drink_price_tier_details_attributes].blank?
                drink[1][:drink_price_tier_details_attributes].each do |details|
                   # first make sure this item should be added (ie wasn't deleted)
                   @destroy_details = details[1][:_destroy]
                   if @destroy_details != "1"
                     @new_price_details = DrinkPriceTierDetail.new(drink_price_tier_id: @new_price_tier.id, 
                                           drink_size: details[1][:drink_size], 
                                           drink_cost: details[1][:drink_cost])
                     if @new_price_details.save
                       # Rails.logger.debug("Draft Details saved")
                     else 
                       @draft = DraftBoard.find_by(location_id: @retail_id)
                       @beer_location_info = BeerLocation.find_by(draft_board_id: @draft.id)
                       @beer_location_info.destroy!
                       @draft.destroy!
                       @draft_board_form = "edit"
                       flash[:error] = "Something went wrong; your draft info didn't save. Please try again!"
                       @draft = DraftBoard.new(drink_params)
                       render :edit  and return # render to fill fields after error message
                     end # end DraftDetail 'if save'
                   end # end of test to determine if drink details "row" was deleted and should be ignored 
                 end # end of loop to add drink details
              end # end validation that drink details exist     
          else
            @draft = DraftBoard.find_by(location_id: @retail_id)
            @draft.destroy!
            @draft_board_form = "edit"
            flash[:error] = "Something went wrong; your draft info didn't save. Please try again!"
            @draft = DraftBoard.new(drink_params)
            render :edit  and return # render to fill fields after error message
        end # end of test to determine if drink "row" was deleted and should be ignored
      end # end of loop to run through each drink in the saved params
      
      redirect_to retailer_path(session[:retail_id])
  end # end of update method
  
end # end of controller