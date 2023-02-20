#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import frontmatter
import markdown
import shutil

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
PERMALINK_PREFIX = 'posts'
FEED_SHOW_FULL_ARTICLE = 'true' 

###
# Script
###

# make sure the output folder is created
if not os.path.exists ('build'):
    os.mkdir('build')

print('** POSTS **')

# loop through all the MD files in the content directory
for dirpath, dirs, files in os.walk("./content/posts"):
    for file in files:
        file_name_path = os.path.join(dirpath, file)
        if file_name_path.endswith('.md'):
            with open(file_name_path) as file_stream:
                raw = file_stream.read()
                # front matter is the YAML attributes prepended to the MD file
                front_matter, content_md = frontmatter.parse(raw)
                content_html = markdown.markdown(content_md)
                print(' -> ', front_matter.keys())

                # splits the directory path into pieces and keeps all but the first one
                destination_path = './build' \
                    + os.path.sep \
                    + os.path.join(*(dirpath.split(os.path.sep)[2:])) \
                    + os.path.sep \
                    + os.path.splitext(file)[0] \
                    + '.html'
                print(' ---> ', destination_path)

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

print('** CUSTOM PAGES **')

# loop through all the custom pages
for dirpath, dirs, files in os.walk("./content/pages"): 
    for file in files:
        file_name_path = os.path.join(dirpath, file)
        if file_name_path.endswith('.html'):
            with open(file_name_path) as file_stream:
                raw = file_stream.read()
                print(' -) ', file_name_path)
                page_title = os.path.splitext(file)[0].title()

                # splits the directory path into pieces and keeps all but the first one
                destination_path = './build' \
                    + os.path.sep \
                    + file
                print(' ---) ', file)

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

print('** ASSETS **')
                    
# copy image assests
if os.path.exists("./build/images"):
    shutil.rmtree("./build/images")
shutil.copytree("./content/images/", "./build/images")
print(' -> ./build/images/')

# copy download assets
if os.path.exists("./build/downloads"):
    shutil.rmtree("./build/downloads")
shutil.copytree("./content/downloads/", "./build/downloads")
print(' -> ./build/downloads/')

# copy theme - everything except the rendering template
if os.path.exists("./build/theme"):
    shutil.rmtree("./build/theme")
os.mkdir("./build/theme")
shutil.copytree("./themes/default/css/", "./build/theme/css")
shutil.copytree("./themes/default/img/", "./build/theme/img")
shutil.copytree("./themes/default/js/", "./build/theme/js")
print(' -> ./build/theme/')


def main(): 
	"""Launcher.""" 
	# init the GUI or anything else 
	pass 
 
if __name__ == "__main__": 
	main() 