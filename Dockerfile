FROM ruby:2.5.1

WORKDIR /app
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install --system --without development

ADD . /app
RUN bundle install --system --without development

CMD ["ruby", "app.rb"]
