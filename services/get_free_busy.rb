require 'http'

# Get freeBusy schedule by passing user access_token and duration_hash
class GetFreeBusy
  def self.parse_string_date(string_date)
    DateTime.parse(string_date).to_s
  end

  # return an array of hashes with string values
  #  e.g. [ {"start": "2017-06-02T08:30:00Z", "end": "2017-06-02T09:30:00Z"},
  #         {"start": "2017-06-11T05:30:00Z", "end": "2017-06-11T09:00:00Z"} ]
  def self.call(access_token, duration_hash)
    # parse duration_hash from Date to DateTime
    duration_hash.each { |k, v| duration_hash[k] = parse_string_date(v) }

    # forming request for API call
    request = { 'timeMin' => duration_hash[:start],
                'timeMax' => duration_hash[:end],
                'items' => [{ 'id' => 'primary' }] }

    # Post and parse response body
    response = HTTP.post('https://www.googleapis.com/calendar/v3/freeBusy',
                         params: { access_token: access_token }, json: request)
    JSON.parse(response.body)['calendars']['primary']['busy']
  end
end
