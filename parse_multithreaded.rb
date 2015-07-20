require 'open-uri'
require 'nokogiri'
require 'json'

# constant
MAX_THREADS_RUNNING = 100

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

def parse_page(page)
    # open a page
    page_url = "http://ithappens.me/page/#{page}"
    document = Nokogiri::HTML(open(page_url))
    
    # parse all stories and save 'em to file
    stories = document.css('.story')
    stories.reverse_each do |element|
        $fileAccess.synchronize do
            $file.puts parse_story(element)+","
        end
    end
end

# open home page and find last page number
document = Nokogiri::HTML(open("http://ithappens.me/"))
last_page = document.css('.nav .prev')[0].text.to_i + 1

# notification about multithreading
puts "[WARNING] Max number of running threads is set to #{MAX_THREADS_RUNNING}. Change it in script code, if you need."

# is file exists...
if File.file?('ithappens.json')
    puts "[WARNING] File 'ithappens.json' already exists, overwriting it."
end

# open the file to write to
$file = File.open('ithappens.json', 'w')
puts "Writing to 'ithappens.json'"
$file.puts "[\n"

# mutexes for thread-safety
$fileAccess = Mutex.new

# process all the pages
1.upto last_page do |page|
    
    # wow doge so much threads wow
    while Thread.list.size >= MAX_THREADS_RUNNING
        sleep 0.1
    end

    # parse and save the page
    thread = Thread.new(page){|page| parse_page(page)}
    thread.abort_on_exception = true
    
    # notify with progress
    if page % 10 == 0 
        puts "Processed up to #{page} pages (#{page*9} stories)"
    end
    
end

Thread.list.each { |t| t.join if t != Thread.main }

# final bracket
$file.puts "]"
$file.close

puts "All #{last_page} pages has been parsed"