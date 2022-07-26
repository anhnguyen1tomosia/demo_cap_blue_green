class HomesController < ApplicationController

  # GET /homes
  def index
    @homes = { a: 1 }
    render json: @homes
  end
end
