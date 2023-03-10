---
title: Browser View Controller (iPhone)
---

Github source: [Browser View Controller](https://github.com/nbuggia/Browser-View-Controller--iPhone-)

iPhone apps often have the need to show a web page, and the easiest way to implement this is to have the page opened in Safari. The problem with this, is that now your customer is stuck in Safari, and they might not know how to get back into your app. This project gives you all the boilerplate code you need to create a smooth experience opening web pages within your app, and seamlessly get back with one click.

<img alt="screen shot 1" src="/images/articles/Browser-View-Controller_thumb1.png">
<img style="padding-left:2em;" alt="screen shot 2" src="/images/articles/Browser-View-Controller-1_thumb.png">

Here are the scenarios implemented:

* **Opening a URL** from within a method – useful for opening links triggered by a UIButton or UITableView.
* **Opening a URL from within a UITextView** – useful for links embedded within text strings that UITextView can automatically identify and turn into clickable hyperlinks.
* **Opening a URL from within a UIWebView** – useful for when you are using a UIWebView to render formatted text in your application with hyperlinks.

##Getting Started

Please see GitHub for instructions on using the library:
<a href="https://github.com/nbuggia/Browser-View-Controller--iPhone-">https://github.com/nbuggia/Browser-View-Controller--iPhone-</a>

Please let me know if there are any additional features you would like to see in the comment section below!

##Thanks

I’d like to thank [Joseph Wain](http://penandthink.com/) of [Glypish](http://glyphish.com/) fame for providing the arrow icons, and making them freely available to everyone. Go buy the [best iphone icons](http://glyphish.com/) from Glypish!

I’d also like to thank [Chen-I Lim](http://www.qrayon.com/) for the fix for getting this to work with the Facebook auth system. Go check out his many wonderful apps from Qrayon.

## Other options

There is one well-known library that does this today: [TTWebController](https://github.com/facebook/three20/blob/master/src/Three20UI/Sources/TTWebController.m), which is part of the well known [Three20](https://github.com/facebook/three20) iOS library published by Facebook as open source. The only problem with this library is that it requires you to incorporate the whole of Three20 in your app, and doesn’t help with opening links in UIWebViews or UITextViews. However, it is still a solid, well written library you should consider.

References

[How to Intercept Clicks on Links in UITextView](http://stackoverflow.com/questions/2543967/how-to-intercept-click-on-link-in-uitextview) – stackoverflow.com