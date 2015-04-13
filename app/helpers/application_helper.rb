module ApplicationHelper

  def ratings_sort(title, rating_type)
    link_to title, :ratings_sort => rating_type
  end
  
  def checkbox_sort(type, name)
    check_box_tag "type[#{name}]", name, false
  end
end
