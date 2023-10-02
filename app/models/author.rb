class Author < ApplicationRecord
  has_many :posts

  update_index('posts') { posts }
end
