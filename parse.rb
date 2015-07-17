require 'open-uri'
require 'nokogiri'
require 'json'

# parses DOM element of a story and returns a JSON string
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

# open home page and find last page number
document = Nokogiri::HTML(open("http://ithappens.me/"))
last_page = document.css('.nav .prev')[0].text.to_i + 2

# is file exists...
if File.file?('ithappens.json')
    puts "[WARNING] File 'ithappens.json' already exists, overwriting it."
end

# open the file to write to
file = File.open('ithappens.json', 'w')
puts "Writing to 'ithappens.json'"
file.puts "[\n"
comma = ","

# process all the pages
1.upto last_page do |page|
    
    # open a page
    page_url = "http://ithappens.me/page/#{page}"
    document = Nokogiri::HTML(open(page_url))
    
    # parse all stories and save 'em to file
    stories = document.css('.story')
    stories.reverse_each do |element|
        # if a story is last to parse, it should not be followed by comma
        if page == last_page and element == stories.first
            comma = ""
        end
        # parse and save
        file.puts parse_story(element)+comma
    end
    
    #notify with progress
    if page % 10 == 0 
        puts "Processed up to #{page} pages (#{page*9} stories)"
    end
    
end

# final bracket
file.puts "]"
file.close

puts "All #{last_page} pages has been parsed"