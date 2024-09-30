require "csv"
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]  
end

def clean_phone_number(phone_number)
  phone_number.to_s.strip.gsub(/[^0-9]/, "")
  
  if phone_number.length == 11
    # If number is 11 digits but starts with 1: Trim the 1 and used the remaining 10 digits
    if phone_number[0] == 1
      phone_number[1..10]
    else
      # If number is 11 digits and doesn't start with 1 = bad number
      "Invalid or no phone number available"
    end

    # If number is less than 10 digits = bad number
    # If number is more than 11 digits = bad number
    
  elsif phone_number.length > 11 || phone_number.length < 10
    "Invalid or no phone number available"

  else
    # If number equals 10 digits = good number
    phone_number
  end
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
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts "EventManager Initialized!\n\n"

contents = CSV.open(
  'event_attendees.csv',
  headers: true, 
  header_converters: :symbol
  )
  
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
date_array = Array.new
weekday_array = Array.new


contents.each do |row|
  id = row[0]
  first_name = row[:first_name]
  last_name = row[:last_name]
  date_time = row[:regdate]
  format_time = "%m/%d/%Y %H:%M"
  day_names = { 0 => "Sunday", 1 => "Monday", 2 => "Tuesday", 3 => "Wednesday", 4 => "Thursday", 5 => "Friday", 6 => "Saturday" }

  date = DateTime.strptime(date_time, format_time)
  weekday = day_names[date.wday]

  date_array << weekday
  weekday_array << date.hour

  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])

  puts "ID# #{id}: #{last_name}, #{first_name}"
  puts "Home Phone: #{phone_number}"
  puts "Time: #{date_time}"
  puts "Day: #{weekday}"
  puts

  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)

  
end

puts "Most people registered in this hour: #{weekday_array.max_by { |x| weekday_array.count(x) } }:00"
puts "Most people registered on this day: #{date_array.max_by { |x| date_array.count(x) } }"
puts
puts "EventManager finished..."
puts


