class PostController < ApplicationController
  def index
    # render json: PostFilter.new.find_by_keyword(params[:keyword])
    render json: test
  end

  def show
    render json: test
  end

  def ok
  end

  private

  def test
    puts "HERE"
    @test ||= Post.first
  end
end