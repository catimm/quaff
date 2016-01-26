class DrinkCategoriesController < ApplicationController
  
  def new
    # add retailer info in case form upload doesn't work and form gets shown again 
    @retail_id = session[:retail_id]
    @retailer = Location.find(@retail_id)
    # get draft info
    @draft = DraftBoard.find_by_id(session[:draft_board_id])
    @drink_categories = @draft.drink_categories.build
    @drink_category_status = "new"
    @this_path = "create"
    @this_method = ":post"
  end # end of new method
  
  def create
    # add new data to drink categories table
    params[:draft_board][:drink_categories_attributes].each do |drink|
      # first make sure this item should be added (ie wasn't deleted)
        @destroy = drink[1][:_destroy]
        if @destroy != "1"
            @new_drink_category = DrinkCategory.new(draft_board_id: drink[1][:draft_board_id], 
                                         category_name: drink[1][:category_name], category_position: drink[1][:category_position])
            @new_drink_category.save
        end # end of test to make sure the info wasn't deleted by the user
    end # end of looping through each category
  
    redirect_to retailer_path(session[:retail_id])
  end # end of create method
  
  def edit
    # add retailer info in case form upload doesn't work and form gets shown again 
    @retail_id = session[:retail_id]
    @retailer = Location.find(@retail_id)
    # get draft info
    @draft = DraftBoard.find_by_id(session[:draft_board_id])
    @drink_categories = DrinkCategory.where(draft_board_id: session[:draft_board_id])
    @last_drink_categories_update = @drink_categories.order(:updated_at).reverse_order.first
    @drink_category_status = "edit"
    @this_path = "update"
    @this_method = ":patch"
  end # end of edit method
  
  def update 
    # first delete all the old data
    @drink_categories = DrinkCategory.where(draft_board_id: session[:draft_board_id])
    @drink_categories.destroy_all
    
    # add new data to drink categories table
    params[:draft_board][:drink_categories_attributes].each do |drink|
      # first make sure this item should be added (ie wasn't deleted)
        @destroy = drink[1][:_destroy]
        if @destroy != "1"
            @new_drink_category = DrinkCategory.new(draft_board_id: drink[1][:draft_board_id], 
                                         category_name: drink[1][:category_name], category_position: drink[1][:category_position])
            @new_drink_category.save
        end # end of test to make sure the info wasn't deleted by the user
    end # end of looping through each category
  
    redirect_to retailer_path(session[:retail_id])
  end # end of update method
  
end # end of controller