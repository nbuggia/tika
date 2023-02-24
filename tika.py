#!/usr/bin/env python3
# -*- coding: utf-8 -*-

""" Tika: A static site generator in python for personal blogs or whatever.

This script will parse the content directory and use the theme directory to 
render a static site. Still need to figure out the mechanism for deployment.

Typical usage example:

$ ./tika.py
"""

import os
import shutil
import datetime
import frontmatter
import markdown
import jinja2

###
# Configuration
###

TITLE = 'nathan buggia'
AUTHOR = 'nathan'
DATE = 'lambda {|now| now.strftime("#{now.day} %b %Y") }'
URL = 'http://www.nathanbuggia.com/'
THEME = 'typography'

PERMALINK_DATE_FORMAT = "NO_DATE"

HEADER_IMAGE = "/images/instagram.png"
HEADER_IMAGE_SMALL = '/images/instagram-small.png'

ARTICLE_MAX = 10
FEED_SHOW_FULL_ARTICLE = 'true' 

# Where should we extract the date from? SLUG or FRONT_MATTER
# FrontMatter only
DATE_SOURCE = "SLUG"

###
# Renderer()
###

class Renderer():
    """ Renders content into HTML based on your theme """

    def __init__(self):
        pass

    def loadTemplates(self, templates_path):
        """ Loads Jinja rendering templates from the theme directory """
        environment = jinja2.Environment(loader=jinja2.FileSystemLoader(templates_path))
        self.base_template = environment.get_template("base.html")
        self.article_template = environment.get_template("article.html")

    def renderArticles(self, articles):
        """ Render an html page in the build directory for each article """
        for article in articles:
            with open(article['destination_path'], mode="w", encoding="utf-8") as out_file:
                os.makedirs(os.path.dirname(article['destination_path']), exist_ok=True)
                out_file.write(self.article_template.render(article))
    
    def renderCustomPages(self, pages):
        """ Render an html page in the build directory for each custom page """
        for page in pages:
            with open(page['destination_path'], mode="w", encoding="utf-8") as out_file:
                os.makedirs(os.path.dirname(page['destination_path']), exist_ok=True)
                out_file.write(self.article_template.render(page))

###
# TikaEngine()
###

class TikaEngine():
    """ Contains workflow logic """

    def __init__(self):
        pass

    def __createDestinationPath(self, type, dirpath, file):
        """ Computes the build directory path for each content type """
        sep = os.path.sep
        if "articles" == type:
            path = os.path.join(*(dirpath.split(sep)[2:]))
            file_without_ext = os.path.splitext(file)[0]
            return './build' + sep + path + sep + file_without_ext + '.html'
        elif "custom" == type:
            return './build' + sep + file

    def __parseDate(self, slug):
        """ Extracts the date from the slug """
        dateString = slug[0:10].strip()
        return datetime.datetime.strptime(dateString, '%Y-%m-%d')


    def __processArticles(self):
        """ Loads all markdown files from ./content/articles into array """
        articles = []
        for dirpath, dirs, files in os.walk('./content/articles'):
            for file in files:
                file_name_path = os.path.join(dirpath, file)
                if file_name_path.endswith('.md'):
                    article = {}                        
                    article['slug'] = os.path.splitext(file)[0]
                    article['destination_path'] = self.__createDestinationPath("articles", dirpath, file)
                    article['date'] = self.__parseDate(article['slug'])
                    with open(file_name_path) as file_stream:
                        raw = file_stream.read()
                        front_matter, content_md = frontmatter.parse(raw)
                        article['content_html'] = markdown.markdown(content_md)
                        # front matter attributes are also added so they are accessible in the template
                        article.update(front_matter)
                    # convert all keys to lowercase for consistency
                    article = {k.lower(): v for k, v in article.items()}
                    articles.append(article)
        return articles


    def __processCustomPages(self):
        """ Loads all custom pages from ./content/pages directory into array """
        pages = []
        for dirpath, dirs, files in os.walk("./content/pages"): 
            for file in files:
                file_name_path = os.path.join(dirpath, file)
                if file_name_path.endswith('.html'):
                    page = {}
                    page['title'] = os.path.splitext(file)[0].title()
                    page['destination_path'] = self.__createDestinationPath("custom", dirpath, file)
                    with open(file_name_path) as file_stream: 
                        page['content_html'] = file_stream.read()
                    pages.append(page)
        return pages


    def __processAssets(self):
        # copy image assests
        if os.path.exists("./build/images"):
            shutil.rmtree("./build/images")
        shutil.copytree("./content/images/", "./build/images")
        #print(' -> ./build/images/')

        # copy download assets
        if os.path.exists("./build/downloads"):
            shutil.rmtree("./build/downloads")
        shutil.copytree("./content/downloads/", "./build/downloads")
        #print(' -> ./build/downloads/')

        # copy theme - everything except the rendering template
        if os.path.exists("./build/theme"):
            shutil.rmtree("./build/theme")
        os.mkdir("./build/theme")
        shutil.copytree("./themes/default/css/", "./build/theme/css")
        shutil.copytree("./themes/default/img/", "./build/theme/img")
        shutil.copytree("./themes/default/js/", "./build/theme/js")
        #print(' -> ./build/theme/')


    def run(self):
        renderer = Renderer()
        renderer.loadTemplates("./themes/default/templates/")

        # make sure the output folder is created
        if not os.path.exists ('build'):
            os.mkdir('build')

        articles = self.__processArticles()
        renderer.renderArticles(articles)

        posts = self.__processCustomPages()
        renderer.renderCustomPages(posts)

        self.__processAssets()

###
# main()
###

def main(): 
    tika = TikaEngine()
    tika.run()
 
###
# run main
###

if __name__ == "__main__": 
	main() 