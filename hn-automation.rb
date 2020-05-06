require 'selenium-webdriver'
require 'pry'
require 'csv'
require 'json'

# Custom user agents
USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1.2 Safari/605.1.15'
  @agent ||= Selenium::WebDriver.for :chrome, :switches => %W[--user-agent=#{USER_AGENT}]

# Enter full screen mode
@agent.manage.window.maximize

# Go to Hacker News
@agent.get('https://news.ycombinator.com')

# Get the data off Hacker News frontpage
elements = @agent.find_elements(class: 'athing')

hn_data = elements.each_with_object([]) do |item, obj|
  id = item.attribute('id')

  obj << {
    id: id,
    title: item.find_element(class: 'storylink').text,
    url: item.find_element(class: 'storylink').attribute('href'),
    comments: @agent.find_elements(xpath: "//*[@href='item?id=#{id}']").last.text,
    comments_link: @agent.find_element(xpath: "//*[@href='item?id=#{id}']").attribute('href')
  }
end

# Save to JSON file
File.open('hn_data.json', "w") { |f| f.puts hn_data.to_json }

# Convert to Sheets friendly format
hn_data_csv = CSV.generate do |csv|
  JSON.parse(File.open('hn_data.json').read).each do |hash|
    csv << hash.values
  end
end

File.open('hn_data.csv', "w") { |f| f.puts hn_data_csv }
  sleep(2)

# Open a new tab
@agent.execute_script("window.open()")
  @agent.switch_to.window(@agent.window_handles.last)

# Google Sign In
@agent.get('https://www.google.com')
  sleep(2)
    @agent.find_element(link_text: 'Sign in').click

# Enter email address
@agent.find_element(id: 'identifierId').send_keys(ENV['EMAIL_ADDRESS'])
  sleep(3)
    @agent.find_element(id: 'identifierNext').click
      sleep(3)

# Enter password
@agent.find_element(xpath: "//*[@type='password']").send_keys(ENV['EMAIL_PASSWORD'])
  sleep(3)
    @agent.find_element(id: 'passwordNext').click
      sleep(3)

# Go to the Sheets app
@agent.get('https://docs.google.com/spreadsheets/?usp=sheets_alc&authuser=0')
  sleep(3)

# Create a blank sheet
@agent.find_element(id: ':1g').click
  sleep(3)

# Select import new file
@agent.find_element(id: 'docs-file-menu').click
  sleep(2)
    @agent.find_element(xpath: "//*[@aria-label='Import i']").click

# Get the correct iFrame
iframe_name = @agent.find_elements(tag_name: 'iframe').last.attribute('name')
  @agent.switch_to.frame(iframe_name)
    sleep(3)

# Select the upload button
@agent.find_element(id: ':8').click

# Attach the file for upload
@agent.find_element(xpath: '//*[@type="file"]').send_keys("#{Dir.pwd}/hn_data.csv")
  sleep(3)

# Return from iFrame
@agent.switch_to.default_content
  sleep(3)

# Import the file
@agent.find_element(class: 'goog-buttonset-action').click
  sleep(3)

# Add title for the file
@agent.find_element(class: 'docs-title-input').click
  sleep(2)
    @agent.find_element(class: 'docs-title-input').send_keys("Hacker News Frontpage" + " #{Time.now.strftime("%d-%m-%y-%H:%M:%S")}")
      @agent.find_element(class: 'docs-title-input').send_keys:return

puts 'Task Completed.'
