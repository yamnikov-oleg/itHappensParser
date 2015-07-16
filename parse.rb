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

page_url = "http://ithappens.me/page/#{last_page}"
document = Nokogiri::HTML(open(page_url))
document.css('.story').each do |element|
    puts parse_story element
end

=begin
while story[:id] <= last_story_id do

    story_url = "http://ithappens.me/story/#{story[:id]}"
    story[:url] = story_url

    document = Nokogiri::HTML(open(story_url))
    element = document.css('.story')[0];

    puts parse_story element, story   

    story[:id] += 1

    sleep(1)

end
=end

