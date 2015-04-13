module ApplicationHelper

  def ratings_sort(title, rating_type)
    link_to title, :ratings_sort => rating_type
  end
end
