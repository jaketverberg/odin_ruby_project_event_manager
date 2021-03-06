require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_num)
  num = phone_num.to_s.gsub(/\D+/, '')
  return num if num.length == 10

  num.length == 11 && num[0] == '1' ? num[1..-1] : '0000000000'
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'
registered_hours_count = Hash.new
registered_days_of_week = Hash.new

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone = clean_phone_number(row[:homephone])

  reg_date = row[:regdate]
  reg_date = DateTime.strptime(reg_date, "%m/%d/%y %H:%M")
  registered_hours_count[reg_date.hour] += 1
  registered_days_of_week[reg_date.wday] += 1

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)

  puts "#{name} #{zipcode} #{phone}"
end

puts "Hour of the day people registered: #{registered_hours_count}"
puts "Days of the week people registered: #{registered_days_of_week}"
