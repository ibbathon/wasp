FROM ruby:2.6.3
RUN apt-get update -qq && apt-get install -y --no-install-recommends nodejs cron
WORKDIR /wasp
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .

ENTRYPOINT ["./entrypoint.sh"]
CMD cron && rails server -b 0.0.0.0
