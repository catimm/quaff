module FriendSearch
  extend ActiveSupport::Concern
  def friend_search(friend_search_term)
      @friend_search_results = User.search friend_search_term,
      misspellings: {edit_distance: 2},
      limit: 30,
      operator: 'or',
      fields: [{ 'username^10' => :word_middle }, 'first_name', 'last_name', 'email^10']
     
    #Rails.logger.debug("Search results: #{@friend_search_results.inspect}")
  
  end # end of friend_search method  

end