# tika
personal static cms generator in python



TODO
3. Create home page
4. Create custom pages
https://www.sumukhbarve.com/build-python-template-engine







## Python environment

Install dependent modules

    pip3 install -r requirements.txt 
    python3 -m pip install --upgrade pip

To run the app:

    ./tika.py


## GitHub configuration

Set git email to the GitHub privacy account: 594357+nbuggia@users.noreply.github.com

Provision a developer access token, use that as your password






###
# Redirect Config File
#
# Use this file to list all of the redirections you'd like the blog to process
# using the same file-format as Apache.
#
# http://support.google.com/webmasters/bin/answer.py?hl=en&answer=40132

###
# Handles de-duping of pagination with root (keep this!)
Redirect 301 /page/1 /
Redirect 301 /page/1/ /

###
# Add your redirects here

Redirect 301 /cooking/bens-kale/ /posts/cooking/bens-kale/
Redirect 301 /cooking/bens-kale /posts/cooking/bens-kale/
Redirect 301 /cooking/applesauce-cake-with-spiced-cream-cheese-frosting/ /posts/cooking/applesauce-cake-with-spiced-cream-cheese-frosting/
Redirect 301 /cooking/applesauce-cake-with-spiced-cream-cheese-frosting /posts/cooking/applesauce-cake-with-spiced-cream-cheese-frosting/

Redirect 301 /posts/coq-au-vin/ /posts/cooking/coq-au-vin/
Redirect 301 /posts/category/code /posts/code/
Redirect 301 /posts/category/code/ /posts/code/
Redirect 301 /posts/category/finance /posts/finance/
Redirect 301 /posts/category/finance/ /posts/finance/

Redirect 301 /posts/2008/04/ /archive
Redirect 301 /posts/2007/09/ /archive
Redirect 301 /posts/2008/09/ /archive
Redirect 301 /posts/2008/05/Share /
Redirect 301 /posts/2011/09 /archive
Redirect 301 /posts/author/nathan /about

Redirect 301 /?page=2 /page/2/

Redirect 301 /post/Custom-Site-Search-Engine-Using-the-Live-Search-API.aspx /
Redirect 301 /post/Generating-a-CSV-File-from-ASPNet.aspx /posts/code/generating-a-csv-file-from-asp-net/
Redirect 301 /default.aspx /
Redirect 301 /blog/category/SEO.aspx /posts/search/

Redirect 301 /project/sitesearch/default.aspx?q=ajax /posts/code/custom-site--search-engine-using-the-bing-api/

Redirect 301 /posts/browser-view-controller/ /posts/projects/browser-view-controller-iphone/
Redirect 301 /posts/code/browser-view-controller-iphone/ /posts/projects/browser-view-controller-iphone/

###
# Broken download links from BlogEngine.net

Redirect 301 /file.axd?file=Web_20_NYC_2008.pptx /downloads/Web_20_NYC_2008.pptx
Redirect 301 /file.axd?file=mortage-schedule.xls /downloads/mortage-planning-tool.xls

###
# Bugs in baron
Redirect 301 //feed.rss /feed.atom
Redirect 301 /feed.rss /feed.atom