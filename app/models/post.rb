class Post < ApplicationRecord
  belongs_to :author

  update_index('posts') { self }
end
