class FitbitWorker
  include Sidekiq::Worker
  sidekiq_options queue: "external_api"

  def perform date, user_id
    user = User.find(user_id)
    accounts = user.fitbit_accounts.select { |a| a.activated }
    accounts.each do |account|
      client = create_client_for account
      save_sleep_entries_on date, client, user_id, account.id
      save_activity_entries_on date, client, user_id, account.id
      save_weight_entries_on date, client, user_id, account.id
    end
  end

  def create_client_for account
    client = Fitgem::Client.new(
      consumer_key: ENV['FITBIT_CONSUMER_KEY'],
      consumer_secret: ENV['FITBIT_CONSUMER_SECRET'],
      oauth_token: "default",
      oauth_secret: "default"
    )
    client.reconnect(account.oauth_token, account.oauth_secret)
    client
  end

  def user_sleep_on date, client
    sleep_data = client.sleep_on_date date.to_s[0..9]
    { minutes_asleep: sleep_data['sleep'].first['minutesAsleep'],
      minutes_awake: sleep_data['sleep'].first['minutesAwake'],
      minutes_to_fall_asleep: sleep_data['sleep'].first['minutesToFallAsleep'],
      efficiency: sleep_data['sleep'].first['efficiency'],
      times_awake: sleep_data['sleep'].first['awakeningsCount'],
      sleep_start_time: sleep_data['sleep'].first['startTime']
    } if !sleep_data['sleep'].empty?
  end

  def user_weight client
    user_info = client.user_info
    { weight: user_info['user']['weight'], weight_unit: user_info['user']['weightUnit'] }
  end

  def user_activity_on date, client
    activities = client.activities_on_date date.to_s[0..9]
    { calories: activities['summary']['caloriesOut'],
      distance: activities['summary']['distances'].first['distance'],
      steps: activities['summary']['steps'],
      active_minutes: activities['summary']['veryActiveMinutes']
    }
  end

  def save_sleep_entries_on date, client, user_id, account_id
    sleep_data = user_sleep_on date, client
    return if !sleep_data
    unless FitbitSleepEntry.exists?(date: date.to_s[0..9], user_id: user_id)
      FitbitSleepEntry.create(
        minutes_asleep: sleep_data[:minutes_asleep],
        minutes_awake: sleep_data[:minutes_awake],
        minutes_to_fall_asleep: sleep_data[:minutes_to_fall_asleep],
        efficiency: sleep_data[:efficiency],
        times_awake: sleep_data[:times_awake],
        start_time: sleep_data[:sleep_start_time],
        date: date.to_s[0..9],
        user_id: user_id,
        fitbit_account_id: account_id
      )
    end
  end

  def save_activity_entries_on date, client, user_id, account_id
    activity_data = user_activity_on date, client
    unless FitbitActivityEntry.exists?(date: date.to_s[0..9], user_id: user_id)
      FitbitActivityEntry.create(
        calories: activity_data[:calories],
        distance: activity_data[:distance],
        steps: activity_data[:steps],
        active_minutes: activity_data[:active_minutes],
        date: date.to_s[0..9],
        user_id: user_id,
        fitbit_account_id: account_id
      )
    end
  end

  def save_weight_entries_on date, client, user_id, account_id
    weight_data = user_weight client
    return if !weight_data[:weight]
    unless FitbitWeightEntry.exists?(date: date.to_s[0..9], user_id: user_id)
      FitbitWeightEntry.create(
        weight: weight_data[:weight],
        weight_unit: weight_data[:weight_unit],
        date: date.to_s[0..9],
        user_id: user_id,
        fitbit_account_id: account_id
      )
    end
  end
end
