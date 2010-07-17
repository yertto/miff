# The MIFF challenge:

[http://www.melbournefilmfestival.com.au](http://www.melbournefilmfestival.com.au)
                |
                V
[http://github.com/yertto/miff](http://github.com/yertto/miff)
                |
                V
 * [http://miffatra.heroku.com](http://miffatra.heroku.com)
 * ?????
 * ?????
 * ?????
  
The challenge is out there, but you'd better get to it
as MIFF runs from Thu 22nd July - Sat 7th July, 2010

## Create your own MIFF app

    git clone http://github.com/yertto/miff.git
    cd miff

[install required gems](http://gembundler.com/bundle_install.html):

    bundle install --without production

fetch the data:

    ./miff_fetcher.rb

start your app:

    ./server.rb


## Host it on heroku

[install heroku](http://docs.heroku.com/heroku-command#installation):

    sudo gem install heroku
    heroku keys:add

:

    Enter your Heroku credentials.
    Email: joe@example.com
    Password: 
    Uploading ssh public key /Users/joe/.ssh/id_rsa.pub

[create your app](http://docs.heroku.com/creating-apps):

    heroku create miff-joe
    git push heroku master

[push data to it](http://docs.heroku.com/taps#import-push-to-heroku):

    heroku db:push sqlite://devel.db

