require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'features/vcr'
  c.ignore_localhost = true
  c.hook_into :webmock
end

VCR.cucumber_tags do |t|
  t.tag '@vcr', use_scenario_name: true 
end