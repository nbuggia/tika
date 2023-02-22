#!/usr/bin/env python3
# -*- coding: utf-8 -*-

""" Tika: A static site generator in python for personal blogs or whatever.

This script will parse the content directory and use the theme directory to 
render a static site. Still need to figure out the mechanism for deployment.

Typical usage example:

$ ./tika.py
"""

import os
import frontmatter
import markdown
import shutil
import datetime

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
DATE_SOURCE = "SLUG"

DIR_ARTICLES = './content/articles'

###
# Article()
###

class Article():
    """ Data structure used to represent an article """
    
    def __init__(self, slug, date, frontmatter, article):
        self.slug = slug
        self.date = date
        self.frontmatter = frontmatter
        self.article = article        


###
# TikaEngine()
###

class TikaEngine():
    """ Contains workflow logic """

    def __init__(self):
        pass

    def __createDestinationPath(self, type, dirpath, file):
        """ Computes the path for the asset in the build directory """
        sep = os.path.sep

        if "articles" == type:
            path = os.path.join(*(dirpath.split(sep)[2:]))
            file_without_ext = os.path.splitext(file)[0]
            return './build' + sep + path + sep + file_without_ext + '.html'
        elif "custom" == type:
            return './build' + sep + file


    def __parseDate(self, slug):
        """ Extracts the date from the slug """
        # TODO - this should implement from SLUG or FRONTMATTER, move into the 
        # Articles Object

        dateString = slug[0:10].strip()
        return datetime.datetime.strptime(dateString, '%Y-%m-%d')


    def __processArticles(self):
        articles = []

        # loop through all the markdown files in the content directory
        for dirpath, dirs, files in os.walk(DIR_ARTICLES):
            for file in files:
                file_name_path = os.path.join(dirpath, file)
                if file_name_path.endswith('.md'):
                    with open(file_name_path) as file_stream:
                        raw = file_stream.read()
                        front_matter, content_md = frontmatter.parse(raw)
                        content_html = markdown.markdown(content_md)
                        slug = os.path.splitext(file)[0]
                        destination_path = self.__createDestinationPath("articles", dirpath, file)

                        # add the post to our list of articles
                        articles.append(Article(slug, self.__parseDate(slug), front_matter, content_html))

                        # creates the directories if they do not already exist
                        os.makedirs(os.path.dirname(destination_path), exist_ok=True)

                        # writes out the rendered HTML file to the build directory
                        with open(destination_path, 'w') as file:
                            file.write(r'''
                                <!DOCTYPE html>
                                <html lang="en">
                                    <head>
                                        <meta charset="utf-8"/>
                                        <title>
                            ''')
                            if 'title' in front_matter.keys():
                                file.write(front_matter['title'])
                            file.write(r'''
                                        </title>
                                    </head>
                                    <body>
                            ''')
                            file.write(content_html)
                            file.write(r'''
                                    </body>
                                </html>
                            ''')
        
        return articles


    def __processCustomPages(self):
        # loop through all the custom pages
        for dirpath, dirs, files in os.walk("./content/pages"): 
            for file in files:
                file_name_path = os.path.join(dirpath, file)
                if file_name_path.endswith('.html'):
                    with open(file_name_path) as file_stream:
                        raw = file_stream.read()
                        page_title = os.path.splitext(file)[0].title()
                        destination_path = self.__createDestinationPath("custom", dirpath, file)

                        # writes out the rendered custom page to the build directory
                        with open(destination_path, 'w') as file:
                            file.write(r'''
                                <!DOCTYPE html>
                                <html lang="en">
                                    <head>
                                        <meta charset="utf-8"/>
                                        <title>
                            ''')
                            file.write(page_title)
                            file.write(r'''
                                        </title>
                                    </head>
                                    <body>
                            ''')
                            file.write(raw)
                            file.write(r'''
                                    </body>
                                </html>
                            ''')

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
        # make sure the output folder is created
        if not os.path.exists ('build'):
            os.mkdir('build')

        articles = self.__processArticles()
        self.__processCustomPages()
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