---
title: Basic Blog Framework in Ruby
---

For my hobby project this winter, I wanted to try out a new language, something that was distinctly non-microsoft. I decided to try out Ruby to learn about the language before trying out a bigger project in Rails. I have been a fan of ASP.net MVC, so it was exciting to learn more about where these designs came from. I created a simple blog framework on top of Rack.

1. [Blog Template on GitHub](https://github.com/nbuggia/baron-blog)
2. [Blog Framework Gem on GitHub](https://github.com/nbuggia/baron-blog-engine-gem)

So far I like Ruby a lot. It has all the benefits of an inturpretted language. It also has a large and active community that has built everything you can imagine, open sources and complete with unit tests and documentation. 

The packaging system is called [GEMs](https://rubygems.org), also written in Ruby. Works really well. I used a gem (called [Jeweler](https://rubygems.org/gems/jeweler)) to encapsulate all the logic of the blog engine and publish the [blog engine](https://rubygems.org/gems/baron) to the packaging system library. The Blog Template project includes the blog template and content. It refrences the blog engine gem.

One of the principles of the Ruby community is that languages should be easy to read and expressive. To support that, they use the concept of domain specific languages (DSL) to create special purpose, expressive languages for everything. My favorite was [Cucumber](https://cucumber.io/), a langauge for expressing use cases and aligning them with automated tests. Another application, RSpec, is used for testing. 

The Ruby language has some functionality that make it very productive. In the example method below, `get_all_categories`, the `map` method takes the list of folders inside your blog, builds a poor-man's struct (e.g. JSON) to turn each one into a category object, and then sorts them by their name property. It may not be the fastest, but the productivity gains are a worthwhile tradeoff in many cases. 

	def get_all_categories
		Dir["#{get_articles_path}/*/"].map do |a| 
		folder_name = File.basename(a)
		{
			name: titlecase(folder_name),
			node_name: folder_name.gsub(' ', '-'),
			path: "/#{@config[:permalink_prefix]}/#{folder_name.gsub(' ', '-')}/".squeeze('/'),
			count: Dir["#{get_articles_path}/#{folder_name}/*"].count 
		}
		end .
		sort_by { |hash| hash[:name] }
	end

The community is very active. There were a lot of great resources to get me started. A few unique to the ruby community include: 

* Railscasts: [http://railscasts.com/](http://railscasts.com/)
* Rails for zombies: [http://railsforzombies.org/](http://railsforzombies.org/) 
* Rspec: [http://rspec.info/](http://rspec.info/)

This was a particularly memorable project because I wrote it while on a brief sabbatical I took in Barcelona to complete a Spanish immersion program. For a month over Christmas 2013, I stayed with the welcoming and generous Fernandez family just outside of Eixample, where the Sagrada Familia is almost complete. I would have breakfast with the family, go to classes until 1pm, and then I would go to a library for a couple hours to code, before walking around the city until midnight. A couple of my favorite places were [La Foixarda](https://www.google.com/search?q=La+Foixarda), the [Gothic Quarter](https://www.google.com/search?q=gothic+quarter+barcelona) and [Montjuic](https://en.wikipedia.org/wiki/Montju%C3%AFc).