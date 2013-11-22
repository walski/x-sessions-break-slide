class BreakController < ApplicationController
  def index
    @schedule = Schedule.new
  end
end