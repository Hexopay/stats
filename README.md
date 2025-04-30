# Stats (Hexostats)
Loading data and publish to elasticsearch

## Setup for WLS app

### Install
Put in Gemfile:
```
#Gemfile

gem 'stats', git: 'https://github.com/Hexopay/stats.git', branch: 'main'
```
then do `bundle install`


### Create rake task
```
#lib/tasks/stats.rake

# frozen_string_literal: true

namespace :stats do
  desc 'Load and publish stats:load_and_publish[date=[2025-05-09]]'
  task :load_and_publish, [:period] => :environment do |_t, args|
    %w[daily_figures merchant_order_stats].each do |report_type|
      Stats::Stats.new(report_type: report_type, period: args.fetch(:period)).run
    end
  end
end
```


### Include rake task in crontab
```
#config/schedule.rb

every 1.day, at: '03:00' do
  rake 'stats:load_and_publish[yesterday]'
end
```






