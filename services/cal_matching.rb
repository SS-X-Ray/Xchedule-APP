require 'dry-monads'
require 'dry-container'
require 'dry-transaction'
require 'date'

# Class for Calendar Matching, call CalMatching.compare and pass in a hash.
class CalMatching
  extend Dry::Monads::Either::Mixin
  extend Dry::Container::Mixin

  A_MIN = 60
  A_HOUR = 3600
  A_DAY = 86_400

  # duration_hash = { start: 'Date1', end: 'Date2' }, class = string
  # limitation_hash = { up: Time1, low: Time2 } of a day, class = float
  #   e.g. Time1 = 8    (upper limit equals to 08:00 a.m.)
  #        Time2 = 18.5 (lower limit equals to 18:30 p.m.)
  # activity_length class = integer (unit: minutes)
  # accounts = an array of accounts, e.g. [acc1, acc2, acc3]
  # account should include array of hashes with string values
  #   e.g. [ {"start": "2017-06-02T08:30:00Z", "end": "2017-06-02T09:30:00Z"},
  #          {"start": "2017-06-11T05:30:00Z", "end": "2017-06-11T09:00:00Z"} ]
  def self.compare(params)
    Dry.Transaction(container: self) do
      step :set_duration
      step :set_limitation
      step :remove_each_account_busy
      step :compare_similar_time
      step :chunk_time_segments
    end.call(params)
  end

  def self.date_2_i(date)
    Date.parse(date).to_time.to_i
  end

  def self.datetime_2_i(datetime)
    DateTime.parse(datetime).to_time.to_i
  end

  def self.daily_limitation(param, start_date, end_date)
    limitation = []
    (start_date..end_date).step(A_DAY) do |date|
      limitation << (date..(date + (param[:up] * A_HOUR)).to_i).to_a
      limitation << ((date + (param[:low] * A_HOUR).to_i)..(date + A_DAY)).to_a
    end
    limitation.flatten
  end

  register :set_duration, lambda { |params|
    begin
      start_date = date_2_i(params[:duration_hash][:start])
      end_date = date_2_i(params[:duration_hash][:end]) + A_DAY - A_MIN

      params[:duration] = (start_date..end_date).step(A_MIN).to_a
      params[:start_date] = start_date
      params[:end_date] = end_date

      Right(params)
    rescue => e
      Left("Fail to set duration: #{e.inspect}")
    end
  }

  register :set_limitation, lambda { |params|
    begin
      limitation = daily_limitation(params[:limitation_hash],
                                    params[:start_date],
                                    params[:end_date])
      params[:limitated_template] = params[:duration] - limitation

      Right(params)
    rescue => e
      Left("Fail to set limitation: #{e.inspect}")
    end
  }

  register :remove_each_account_busy, lambda { |params|
    begin
      num_of_cal = params[:accounts].length
      all_accounts_time = Array.new(num_of_cal, params[:limitated_template])

      params[:accounts].each_with_index do |account, index|
        account.busy_time.each do |event|
          start_datetime_i = datetime_2_i(event['start'])
          end_datetime_i = datetime_2_i(event['end']) - A_MIN
          event_i = (start_datetime_i..end_datetime_i).step(A_MIN).to_a
          all_accounts_time[index] -= event_i
        end
      end

      params[:accounts_busy_removed] = all_accounts_time

      Right(params)
    rescue => e
      Left("Fail to remove each account's busy time: #{e.inspect}")
    end
  }

  register :compare_similar_time, lambda { |params|
    begin
      # Set first account's time as master to compare with other accounts
      master_account_time = params[:accounts_busy_removed].first
      params[:accounts_busy_removed].each do |account_time|
        master_account_time &= account_time
      end

      params[:compared_time] = master_account_time

      Right(params)
    rescue => e
      Left("Fail to compare similar time between accounts: #{e.inspect}")
    end
  }

  register :chunk_time_segments, lambda { |params|
    begin
      chunked_time = params[:compared_time].chunk_while { |i, j| i + 60 == j }
                                           .to_a
      chunked_time.delete_if { |a| a.length < params[:activity_length] }

      chunked_time.map! do |possible_time|
        [Time.at(possible_time.first), Time.at(possible_time.last)]
      end

      # Force it to fail if no matched available time
      chunked_time + 1 if chunked_time.empty?

      # Returns an array of arrays of time.
      # => e.g. [[start_datetime1, end_datetime1],
      # =>       [start_datetime1, end_datetime1]]
      Right(chunked_time)
    rescue => e
      Left("Fail to chunk time and reture compared results: #{e.inspect}")
    end
  }
end
