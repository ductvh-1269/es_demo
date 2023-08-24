class PostController < ApplicationController
  def index
    binding.pry
    render json: Chewy::CustomFilter::PostsFilter.find_by_keyword(params[:keyword]).to_json
  end
end