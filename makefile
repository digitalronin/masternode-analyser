APP := masternode-analyser

run:
	PORT=5000 ruby app.rb

setup-heroku:
	heroku create $(APP)
	heroku stack:set container
	heroku addons:create heroku-postgresql:hobby-dev

deploy:
	git push heroku master
