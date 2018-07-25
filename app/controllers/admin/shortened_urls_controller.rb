class Admin::ShortenedUrlsController < ApplicationController
  before_action :verify_admin
  before_action :find_url, only: [:show, :shortened]
  skip_before_action :verify_authenticity_token
  
  def show
    redirect_to @url.sanitize_url
  end # end show method
  
  def new
    @url = ShortenedUrl.new
  end # end index method
  
  def create
    @url = ShortenedUrl.new
    @url.original_url = params[:shortened_url][:original_url]
    @url.sanitize
    if @url.new_url?
      if @url.save
        redirect_to shortened_path(@url.short_url)
      else
        flash[:error] = "Check the error below:"
        render 'new'
      end
    else
      flash[:notice] = "A short link for this URL is already in the DB"
      redirect_to shortened_path(@url.find_duplicate.short_url)
    end
  end # end create method
  
  def shortened
    @url = ShortenedUrl.find_by_short_url(params[:short_url])
    host = request.host_with_port
    @original_url = @url.sanitize_url
    @short_url = host + '/' + @url.short_url
  end # end shortened method
  
  def fetch_original_url
    fetch_url = ShortenedUrl.find_by_short_url(params[:short_url])
    redirect_to fetch_url.sanitize_url
  end # end fetch_original_url method
  
  private
  def find_url
    @url = ShortenedUrl.find_by_short_url(params[:short_url])
  end # end of find_url method
  
  def url_params
    params.require(:url).permit(:original_url)
  end # end of url_params method
  
  def verify_admin
    redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2
  end
    
end
