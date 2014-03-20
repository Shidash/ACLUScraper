require 'nokogiri'
require 'open-uri'
require 'json'
require 'uploadconvert'

class ACLUScraper
  def initialize(url)
    @url = url
    @casearray = Array.new
  end

  # Get all the case documents
  def scrapeCase
    html = Nokogiri::HTML(open(@url))
    prevdate = ""

    html.css("tbody").each do |t|
      t.css("tr").each do |r|
        if !r.css("a").empty?
          dochash = Hash.new
          
          # Get date for filing
          if r.css("td")[0].text == "\u00a0"
            dochash[:date] = prevdate
          else
            prevdate = r.css("td")[0].text.to_s
            dochash[:date] = r.css("td")[0].text.to_s
          end

          a = r.css("a")
          dochash[:title] = a.text

          # Get URL
          if a[0]["href"].to_s.include? "https://"
            dochash[:url] = a[0]["href"]
          else
            dochash[:url] = "https://www.aclu.org" + a[0]["href"]
          end
          
          # Download documents
          `wget #{dochash[:url]}`
          path = dochash[:url].split("/")
          dochash[:path] = path[path.length-1].chomp.strip

          # Extract metadata and text
          begin
            u = UploadConvert.new(dochash[:path])
            metadata = u.extractMetadataPDF
            metadata.each{|k, v| dochash[k] = v}
            dochash[:text] = u.detectPDFType
            @casearray.push(dochash)
          rescue
          end
        end
      end
    end
    
    JSON.pretty_generate(@casearray)
  end
end
