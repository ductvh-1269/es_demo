class PostsIndex < Chewy::Index
  index_scope Post.includes(:author)
  
  field :author do
    field :name
  end

  field :content
  field :title
end