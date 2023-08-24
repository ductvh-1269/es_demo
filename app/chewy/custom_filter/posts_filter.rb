class PostsFilter < Chewy::CustomFilter::BaseFilter
  class << self
    def find_by_keyword key
      PostsIndex.query(multi_match(key))
    end
end
