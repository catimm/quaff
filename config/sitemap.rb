# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://www.drinkknird.com"

SitemapGenerator::Sitemap.create do
  add '/contact_us'
  add '/gift_certificates/new'
  add '/create_drink_profile/drink_categories'
  add '/faqs'
  add '/membership_plans'
  add '/about_us'
  add '/privacy'
  add '/terms'
  add '/cdn-cgi/l/email-protection'
  
  Brewery.find_each do |brewery|
    add brewery_path(brewery), :lastmod => brewery.updated_at
  end
  
  Beer.find_each do |beer|
    add beer_path(beer), :lastmod => beer.updated_at
  end
  
  BlogPost.find_each do |blog|
    add blog_path(blog), :lastmod => blog.updated_at
  end
  
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end
end
