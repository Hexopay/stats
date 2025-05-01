# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/numeric'
require 'date'
require_relative 'env'


# Handle command line arguments
class ArgsHandler
  #include Env
  REPORT_TYPES = %w[daily_figures merchant_order_stats].freeze
  PERIODS = {
    default: 'yesterday',
    # yesterday by default
    'yesterday' => proc do |_|
      [(Date.today - 1.day)]
    end,
    'today' => proc do |_|
      [Date.today]
    end,

    # date=2019-10-10

    'date=' => proc do |period|
      [Date.parse(period.split('=')[1])]
    end,

    # date_offset=1 -> 1 day ago
    'date_offset=' => proc do |period|
      [(Date.today - period.split('=')[1].to_i)]
    end,

    'last_month' => proc do |_period|
      from_date = Date.new(Date.today.prev_month.year, Date.today.prev_month.month, 1)
      to_date = Date.new(Date.today.year, Date.today.month, 1) - 1
      (from_date..to_date).map { |d| d }
    end,

    # date_range=2019-10-10~2019-10-11
    'date_range=' => proc do |period|
      from, to = period.split('=')[1].split('~')
      from_date = Date.parse(from)
      to_date = Date.parse(to)
      (from_date..to_date).map { |d| d }
    end
  }.freeze

  attr_reader :report_type, :period_type, :dates, :env, :args

  # Command args Array: [Env, ReportType, PeriodStr]
  # where
  #   ReportType: [daily_figures|merchant_gateway_order_stats]
  #   Period one of:
  #     - yesterday - DEFAULT value
  #     - today
  #     - date=Date, Date like 2019-12-31
  #     - date_offset=n, n: [1|2|3...]
  #     - date_range=DatesString, DatesString like 2019-10-10~2019-10-11
  #   Env -> [development|test|staging|production]
  #

  # Parsing ARGV as follow:
  # ARGV                                                            env_name     report_type         period
  # %w[env=test]                                                 -> test,        daily_figures,        yesterday
  # %w[env=test daily_figures]                                     -> test,        daily_figures,        yesterday
  # %w[env=test merchant_gateway_order_stats]                    -> test,        merchant_g...stats, yesterday
  # %w[env=test merchant_gateway_order_stats today]              -> test,        merchant_g...stats, today
  # %w[         merchant_gateway_order_stats today]              -> development, merchant_g...stats, today
  # %w[         merchant_gateway_order_stats date_range=[d1-d2]] -> development, merchant_g...stats, date_ragne=...
  def initialize(args = %w[daily_figures yesterday])
    @args = args
  end

  def handle
    @report_type = _parse_arg(arr: REPORT_TYPES, default_value: REPORT_TYPES.first)
    period_arg =  _parse_arg(arr: PERIODS.keys, default_value:  PERIODS[:default])
    @period_type = period_arg.include?('=') ? "#{period_arg.split('=')[0]}=" : period_arg
    @dates = PERIODS[period_type]&.call(period_arg)
    # @env = _parse_and_set_env
    self
  end

  private

  def _parse_arg(opts)
    args
      .select { |arg| opts[:arr].index { |item|
        arg =~ /#{item}/
      } }
      .first || opts[:default_value]
  end

  def _parse_and_set_env
    Env.send(
      args
      &.select { |i| i.include?('env') }
      &.first
      &.split('=')
      &.second || Env.default # development
    )
  end
end
