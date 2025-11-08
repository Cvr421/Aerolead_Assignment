class BlogPost < ApplicationRecord
    validates :title, :body, presence: true
    before_create :set_slug
  
    def set_slug
      self.slug ||= title.to_s.parameterize[0..150]
    end
  end
  