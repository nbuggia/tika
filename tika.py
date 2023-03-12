#!/usr/bin/env python3
# -*- coding: utf-8 -*-

""" Tika: A static site generator in python for personal blogs or whatever.

This script will parse the content directory and use the theme directory to 
render a static site. Still need to figure out the mechanism for deployment.

Typical usage example:
$ pip3 install -r requirements.txt 
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

TITLE = 'Nathan Buggia'
AUTHOR = 'nathan'
URL = 'https://www.nathanbuggia.com/'
THEME = 'default'

# used for pagination across the site
MAX_ARTICLES_PER_PAGE = 10

FEED_MAX_ARTICLES = 10
FEED_SHOW_FULL_ARTICLE = 'true' 

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
        self.index_template = environment.get_template("index.html")

    def renderArticles(self, articles):
        """ Render an html page in the build directory for each article """
        for article in articles:
            os.makedirs(os.path.dirname(article['destination_path']), exist_ok=True)
            with open(article['destination_path'], mode="w", encoding="utf-8") as out_file:
                out_file.write(self.article_template.render(article))
    
    def renderCustomPages(self, pages):
        """ Render an html page in the build directory for each custom page """
        for page in pages:
            with open(page['destination_path'], mode="w", encoding="utf-8") as out_file:
                out_file.write(self.article_template.render(page))

    def renderIndexHtml(self, articles, pages):
        """ Render a homepage to index.html in the build directory """
        # fancy python code to chunk articles into one array per page
        articles_by_page = [articles[i:i+MAX_ARTICLES_PER_PAGE] for i in range(0, len(articles), MAX_ARTICLES_PER_PAGE)]
        for i, page_x in enumerate(articles_by_page):
            page_content = {}
            page_content['title'] = TITLE
            page_content['page_articles'] = page_x
            if i > 0: 
                # only show prev link if we're not on the first page. 
                page_content['prev_link'] = "foobar"
                # compute the name each subsequent page
                page_filename = './build/index%s.html' % (i+1)
            else:
                page_filename = "./build/index.html"
            if i < len(articles_by_page)-1:
                page_content['next_link'] = "foobar"
            with open(page_filename, mode="w", encoding="utf-8") as out_file:
                out_file.write(self.index_template.render(page_content))

    def renderCategoryPages(self, articles):
        pass

    def renderArchivePage(self, articles):
        pass

    def renderFeed(self, articles):
        pass

###
# TikaEngine()
###

class TikaEngine():
    """ Contains workflow logic """

    def __init__(self):
        pass

    def __createDestinationPath(self, type, dirpath, file):
        """ Computes the build directory path for each content type """
        if "articles" == type:
            path = os.path.join(*(dirpath.split(os.path.sep)[2:]))
            file_without_ext = os.path.splitext(file)[0]
            return './build' + os.path.sep + path + os.path.sep + file_without_ext + '.html'
        elif "custom" == type:
            return './build' + os.path.sep + file

    def __parseDate(self, slug):
        """ Extracts the date from the slug """
        dateString = slug[0:10].strip()
        return datetime.datetime.strptime(dateString, '%Y-%m-%d')

    def __parseCategory(self, path):
        """ Extracts the the Category name from the path """
        category = ""
        # An article path in the build directory is 5 segments if a category is specified
        if len(path.split(os.path.sep)) == 5:
            category = (path.split(os.path.sep)[3]).title()
        return category

    def __processArticles(self):
        """ Loads all markdown files from ./content/articles into array """
        articles = []
        for dirpath, dirs, files in os.walk('./content/articles'):
            for file in files:
                file_name_path = os.path.join(dirpath, file)
                if not file_name_path.endswith('.md'):
                    continue
                article = {}                        
                article['slug'] = os.path.splitext(file)[0]
                article['destination_path'] = self.__createDestinationPath("articles", dirpath, file)
                article['category'] = self.__parseCategory(article['destination_path'])
                article['date'] = self.__parseDate(article['slug'])
                with open(file_name_path) as file_stream:
                    raw = file_stream.read()
                    front_matter, content_md = frontmatter.parse(raw)
                    article['content_html'] = markdown.markdown(content_md)
                    # front matter attributes are appended so they are accessible in the template
                    article.update(front_matter)
                # convert all keys to lowercase for consistency
                article = {k.lower(): v for k, v in article.items()}
                articles.append(article)
        # sort descending by date
        articles.sort(key = lambda x:x['date'], reverse = True)
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
        """ Move all static assets into the build directory """
        if os.path.exists("./build/images"):
            shutil.rmtree("./build/images")
        shutil.copytree("./content/images/", "./build/images")

        if os.path.exists("./build/downloads"):
            shutil.rmtree("./build/downloads")
        shutil.copytree("./content/downloads/", "./build/downloads")

        # copy theme - everything except the rendering template
        if os.path.exists("./build/theme"):
            shutil.rmtree("./build/theme")
        os.mkdir("./build/theme")
        shutil.copytree("./themes/default/css/", "./build/theme/css")
        shutil.copytree("./themes/default/img/", "./build/theme/img")
        shutil.copytree("./themes/default/js/", "./build/theme/js")

    def run(self):
        renderer = Renderer()
        renderer.loadTemplates("./themes/default/templates/")

        # TODO - make 'clean' an option somewhere
        if os.path.exists("./build"):
            shutil.rmtree("./build")

        if not os.path.exists ("./build"):
            os.mkdir("./build")

        self.__processAssets()

        pages = self.__processCustomPages()
        renderer.renderCustomPages(pages)

        articles = self.__processArticles()
        renderer.renderArticles(articles)

        renderer.renderIndexHtml(articles, pages)

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