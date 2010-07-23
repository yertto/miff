#!/bin/sh
wget "http://www.google.com/webmasters/tools/ping?sitemap=http://miff.heroku.com/sitemap.xml"                &&
wget "http://search.yahooapis.com/SiteExplorerService/V1/ping?sitemap=http://miff.heroku.com/sitemap.xml"    &&
wget "http://submissions.ask.com/ping?sitemap=http://miff.heroku.com/sitemap.xml"                            &&
wget "http://webmaster.live.com/ping.aspx?siteMap=http://miff.heroku.com/sitemap.xml"
