APP := masternode-analyser

server:
	. .env; ruby app.rb

setup-heroku:
	heroku create $(APP)
	heroku stack:set container
	heroku addons:create heroku-postgresql:hobby-dev

deploy:
	git push heroku master
