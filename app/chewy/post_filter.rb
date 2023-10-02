class PostFilter
  include CustomFilter

  def find_by_keyword keyword
    PostsIndex.query(multi_match(keyword))
  end

  def test keyword



    PostsIndex.query(
      {
        "multi_match": 
          {
            "query": "#{keyword}"
          }
      }
  )


  
  end
end