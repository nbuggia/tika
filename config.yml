###
# Baron configuration

require 'baron'

baron = Baron::Server.new do  
  set :title, 'nathan buggia'
  set :author, 'nathan'
  set :date, lambda {|now| now.strftime("#{now.day} %b %Y") }
  set :url, 'http://www.nathanbuggia.com/'
  set :theme, 'typography'
  set :permalink_date_format, :no_date
  set :header_image, '/images/instagram.png'
  set :header_image_small, '/images/instagram-small.png'
  set :article_max, 10
  set :permalink_prefix, 'posts'
  set :date, lambda {|now| now.strftime("#{now.day} %b %Y") }
  set :google_analytics, 'UA-251437-3'
  set :google_webmaster, 'gjIWOZBn8AegBXIAIxn-gNJw1uLpcGOC4yl102DpGVs'
  set :disqus_shortname, 'nathanbuggiablog'
  set :feed_show_full_article, :true 
end
 
###
# Rack configuration

use Rack::Static, :urls => ['/themes', '/downloads', '/images']
use Rack::CommonLogger

if ENV['RACK_ENV'] == 'development'
  use Rack::ShowExceptions
end

# RUN!
run baron


