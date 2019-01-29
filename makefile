APP := masternode-analyser

run:
	PORT=5000 ruby app.rb

setup-heroku:
	heroku create $APP
	heroku stack:set container

deploy:
	git push heroku master
