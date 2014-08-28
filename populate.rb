require 'uri'
require 'net/http'
require 'fileutils'

BOWER_URL = 'https://bower-component-list.herokuapp.com/'
DOWNLOAD_DIR = './downloaded'
DOWNLOAD_FILENAME = "#{DOWNLOAD_DIR}/bower_components.json"

    class BowerComponentPopulator

  def initialize(output_path)
    @output_path = output_path
  end

  def download
    puts "Starting download ..."

    FileUtils.mkpath(DOWNLOAD_DIR)
    uri = URI.parse(BOWER_URL)
    response = Net::HTTP.get_response(uri)
    File.write(DOWNLOAD_FILENAME, response.body)

    puts "Done downloading!"
  end

  def populate
    File.open(@output_path, 'w:UTF-8') do |out|
      out.write <<-eos
{
  "metadata" : {
    "mapping" : {
      "_all" : {
        "enabled" : false
      },
      "properties" : {
        "name" : {
          "type" : "multi_field",
          "path" : "just_name",
          "fields" : {
             "rawName" : { "type" : "string", "index" : "not_analyzed" },
             "name" : { "type" : "string", "index" : "analyzed" }
          }
        },
        "description" : {
          "type" : "string",
          "index" : "analyzed"
        },
        "owner" : {
          "type" : "string",
          "index" : "not_analyzed"
        },
        "website" : {
          "type" : "string",
          "index" : "not_analyzed"
        },
        "forks" : {
          "type" : "integer",
          "store" : true
        },
        "stars" : {
          "type" : "integer",
          "store" : true
        },
        "created" : {
          "type" : "date",
          "store" : true
        },
        "updated" : {
          "type" : "date",
          "store" : true
        }
      }
    }
  },
  "updates" :
    eos

      out.write(File.read(DOWNLOAD_FILENAME))
      out.write("\n}")
    end
  end
end

output_filename = 'bower_components.json'

download = false

ARGV.each do |arg|
  if arg == '-d'
    download = true
  else
    output_filename = arg
  end
end

populator = BowerComponentPopulator.new(output_filename)

if download
  populator.download()
end

populator.populate()
system("bzip2 -kf #{output_filename}")