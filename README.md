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
  rake 'stats:load_and_publish[yesterday,daily_figures]'
end

every 1.day, at: '03:30' do
  rake 'stats:load_and_publish[yesterday,merchant_order_stats]'
end
```

create the empty index
curl -X PUT --user "elastic:ELASTIC_SEARCH_PASSWORD" -H "Content-Type: application/json" --data-binary {} http://ELASTIC_SEARCH_IP:9200/[index_name]
send update the mappings using the daily_figures_mappings.json  file

curl -X PUT --user "elastic:uIjXFICZh8pi2gZzeCWv" -H "Content-Type: application/json" --data-binary {} http://192.168.1.201:9200/staging_daily_figures
curl -X PUT --user "elastic:uIjXFICZh8pi2gZzeCWv" -H "Content-Type: application/json" --data-binary @daily_figures_mappings.json http://192.168.1.201:9200/staging_daily_figures/_mapping

curl -X PUT --user "elastic:uIjXFICZh8pi2gZzeCWv" -H "Content-Type: application/json" --data-binary {} http://192.168.1.201:9200/staging_merchant_order_stats
curl -X PUT --user "elastic:uIjXFICZh8pi2gZzeCWv" -H "Content-Type: application/json" --data-binary @merchant_order_stats_mappings.json http://192.168.1.201:9200/staging_merchant_order_stats/_mapping

Testing:
s = OpenStruct.new(proxy_url: 'http://10.10.0.103:3142', elastic: OpenStruct.new(url: "http://18.203.232.22:9200", credentials: "elastic:uIjXFICZh8pi2gZzeCWv" ) )
class Env; class << self; def production?; true; end; end; end
p = Stats::Publisher.new('daily_figures', [{data: ddd[0..3]}], s)






