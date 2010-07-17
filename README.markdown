# The MIFF challenge:

[Melbourne International Film Festival](http://www.melbournefilmfestival.com.au) ([scraped](http://nokogiri.org) and remixed into a [datamapper](http://datamapper.org)/[sinatra](http://www.sinatrarb.com) app)


[http://www.melbournefilmfestival.com.au](http://www.melbournefilmfestival.com.au)
                |
                V
[http://github.com/yertto/miff](http://github.com/yertto/miff)
                |
                V
 * [http://miffatra.heroku.com](http://miffatra.heroku.com)
 * ...
 * ...
  
The challenge is out there, but you'd better get to it
as MIFF is running from Thu 22nd July - Sat 7th July, 2010

## Create your own MIFF app

    git clone http://github.com/yertto/miff.git
    cd miff

install required gems using [bundle](http://gembundler.com/bundle_install.html):

    bundle install --without production

fetch the data:

    ./miff_fetcher.rb

start your app:

    ./server.rb


## Host it on heroku

install [heroku](http://docs.heroku.com/heroku-command#installation):

    sudo gem install heroku
    heroku keys:add

:

    Enter your Heroku credentials.
    Email: joe@example.com
    Password: 
    Uploading ssh public key /Users/joe/.ssh/id_rsa.pub

[create](http://docs.heroku.com/creating-apps) your own app:

    heroku create miff-joe
    git push heroku master

[push](http://docs.heroku.com/taps#import-push-to-heroku) data to it:

    heroku db:push sqlite://devel.db

add a link to your app on the [wiki](http://wiki.github.com/yertto/miff/)
