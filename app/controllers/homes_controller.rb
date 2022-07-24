class HomesController < ApplicationController

  # GET /homes
  def index
    @homes = { a: 2 }
    render json: @homes
  end

end
