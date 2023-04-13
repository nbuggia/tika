# Tika
A personal static site generator in python

## Notes

* Supports 1-level of categories.
* Deploys through GitHub or GitLab Pages. 

## TODO

[ ] Refactor the Jinja templates. Redundant footer content in each page. 
[ ] Where do we pull the date from? URL or from Frontmatter?
[ ] Archived page
[ ] Category pages
[ ] Make the articles directory name configurable
[ ] How do we deploy? 
[ ] Make "clean" build directory an option somewhere

## Dev notes

### Setup environment

Install dependent modules

    pip3 install -r requirements.txt 
    python3 -m pip install --upgrade pip

### Data structures

Example of the articles array:

    [{
        'slug': '2020-10-25-Beef-Stew', 
        'build_path': './build/articles/recipes/soups/2020-10-25-Beef-Stew.html', 
        'url': './articles/recipes/soups/2020-10-25-Beef-Stew.html', 
        'category': 'Recipies',
        'date': datetime.datetime(2020, 10, 25, 0, 0), 
        'content_html': 'HTML_PAGE_CONTENT', 
        'title': 'Beef Stew', 
        'ingredients': '4 tablespoons bacon fat or butter; 1 large onion, diced; 
            2 stalks celery, diced; 2 carrots, diced; 2 garlic cloves, thinly 
            sliced; 2 tablespoons tomato paste; 12 cups chicken stock or water; 
            2 cups French lentils; 1 pound boneless, skinless chicken thighs 
            (See Recipe Note); Grated Parmesan or Romano cheese, for serving'
    }]
