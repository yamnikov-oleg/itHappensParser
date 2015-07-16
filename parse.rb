DELAY_BETWEEN_REQUESTS = 1

require 'open-uri'
require 'nokogiri'
require 'json'

def parse_story(element)
    story = {}

    story[:id] = element.css('.id').text.to_i
    story[:title] = element.css('h2').text.strip
    story[:url] = "http://ithappens.me" + element.css('h2 a')[0][:href]
    story[:date] = element.css('.date-time').text.strip
    story[:rating] = element.css('.rating').text.to_i

    story[:tags] = []
    tags = element.css('.tags a')
    tags.each do |tag|
        story[:tags].push({name: tag.text.strip, url: "http://ithappens.me#{tag[:href]}"})
    end

    story[:text] = element.css('.text').text.strip

    return JSON.pretty_generate story
end

document = Nokogiri::HTML(open("http://ithappens.me/"))
last_story_id = document.css('.story .id')[0].text.to_i
last_page = document.css('.nav .prev')[0].text.to_i + 2

page = 1

file = File.open('ithappens.json', 'w')
file.puts "[\n"
comma = ","

last_page = 3

while page <= last_page do

    page_url = "http://ithappens.me/page/#{page}"
    document = Nokogiri::HTML(open(page_url))

    stories = document.css('.story')
    stories.reverse_each do |element|
        if page == last_page and element == stories.first
            comma = ""
        end
        file.puts parse_story(element)+comma
    end

    page += 1
    sleep(DELAY_BETWEEN_REQUESTS)

end

file.puts "]"

