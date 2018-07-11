class BlogPostsController < ApplicationController
  before_action :verify_admin, except: [:index, :show]
  before_action :authenticate_user!, except: [:index, :show]
  
  def index
    if user_signed_in? 
      if current_user.role_id == 1
        @blog_posts = BlogPost.all.order("published_at DESC").page(params[:page])  
      else
        @blog_posts = BlogPost.where(status: 'published').order("published_at DESC").page(params[:page])
      end
    else
      @blog_posts = BlogPost.where(status: 'published').order("published_at DESC").page(params[:page])
    end
  end # end of index method
  
  def show
    @blog_post = BlogPost.friendly.find(params[:id]) 
    @in_stock = Inventory.where(beer_id: @blog_post.beer_id, currently_available: true)
  end # end of show method
  
  def new
    # prepare for new blog
    @blog_post = BlogPost.new
    # pull full list of drinks--to pair with drink in DB
    @drink_options = Beer.all.order(beer_name: :desc, id: :asc).to_a
    
  end # end of new method
  
  def create
    # get params and create
    @blog_post = BlogPost.create!(blog_post_params)
    
    # redirect
    redirect_to blog_path(@blog_post.slug)
    
  end # end of create method
  
  def edit
    # prepare to edit blog post
    @blog_post = BlogPost.find(params[:id])
    
  end # end of edit method
  
  def update
    # get params and create
    @blog_post = BlogPost.find(params[:id])
    @blog_post.update(blog_post_params)
    
    # redirect
    redirect_to blog_path(@blog_post[0].slug)
  end # end of update method
  
  private
    def blog_post_params
      params.require(:blog_post).permit(:title, :subtitle, :status, :content, :content_opening, 
                                        :image_url, :brewers_image_url, :user_id, :published_at,
                                        :beer_id, :untappd_url, :ba_url)
    end
    
    def verify_admin
      redirect_to root_url unless current_user.role_id == 1 || current_user.role_id == 2
    end
     
end