## Create your own MIFF app

  git clone http://github.com/yertto/miff.git
  cd miff

  bundle install --without production

  ./miff_fetcher.rb
  ./server.rb


## Push it to heroku

  sudo gem install heroku
  heroku keys:add

  Enter your Heroku credentials.
  Email: joe@example.com
  Password: 
  Uploading ssh public key /Users/joe/.ssh/id_rsa.pub

  heroku create miff-joe
  git push heroku master

  heroku db:push sqlite://devel.db

