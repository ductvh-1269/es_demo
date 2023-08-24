class PostController < ApplicationController
  def index
    render json: {"OK": "OK"}
  end
end