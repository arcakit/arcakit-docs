class GuidesController < ApplicationController
  def index
    @guides = Guide.all
  end

  def show
    @guide = Guide.find(params[:id])
  rescue Guide::NotFound
    render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
  end
end
