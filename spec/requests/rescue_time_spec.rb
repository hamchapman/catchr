require 'spec_helper'

describe "RescueTimeAPI" do 

  it "returns daily data in JSON object", :vcr, record: :once do
    uri = URI("https://www.rescuetime.com/anapi/data?key=B63EMB8ooHFTiaqAOMRwE402lyzpfFGrYOuIfiue&format=json")
    response = Net::HTTP.get(uri)
    expect(response).to include "\"row_headers\":[\"Rank\",\"Time Spent (seconds)\",\"Number of People\",\"Activity\",\"Category\",\"Productivity\"]"
    expect(JSON.parse(response)['rows'].class).to eq Array
  end
  
end