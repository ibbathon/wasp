FROM ruby:2.6.3
RUN apt-get update -qq && apt-get install -y nodejs
WORKDIR /wasp
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .

CMD ["rails", "server", "-b", "0.0.0.0"]
