module ApplicationHelper

  def ratings_sort(title, rating_type)
    link_to title, :ratings_sort => rating_type
  end
  
  def checkbox_sort(type, name)
    check_box_tag "type[#{name}]", name, false
  end
  
  def sortable(column, title = nil)
    Rails.logger.debug("this is firing #{column.inspect}")
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    Rails.logger.debug("direction is #{direction.inspect}")
    link_to title, {:sort => column, :direction => direction}, {:class => css_class}
  end #end of sortable helper method
  
end
