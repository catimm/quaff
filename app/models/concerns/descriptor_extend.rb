module DescriptorExtend
  extend ActiveSupport::Concern

  included do
    scope :by_tag_name, -> name { where("name like ?", "%#{name}%") }

  end

end