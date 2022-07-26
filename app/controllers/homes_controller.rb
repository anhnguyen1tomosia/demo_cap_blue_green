class HomesController < ApplicationController

  # GET /homes
  def index
    @homes = { a: 3 }
    render json: @homes
  end
end
