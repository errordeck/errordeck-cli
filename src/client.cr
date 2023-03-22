require "http"
require "json"
module Errordeck
  class Client

    BASE_URL = "https://api.errordeck.com/api/v1"

    property api_key : String
    property org : String
    property project : String

    def initialize
      @api_key = ENV["ERRORDECK_API_KEY"]
      @org = ENV["ERRORDECK_ORG"]
      @project = ENV["ERRORDECK_PROJECT"]
    end

    def create_release(version : String)
      url = "#{BASE_URL}/organizations/#{org}/releases/"
    
      headers = HTTP::Headers{
        "Authorization" => "Bearer #{api_key}",
        "Content-Type" => "application/json"
      }
    
      body = {
        "version": version,
        "projects": [project]
      }.to_json

      response = HTTP::Client.post(url, headers: headers, body: body)
    
      if response.success?
        Log.info { "Release #{version} created successfully" }
      else
        Log.error { "Error creating release: #{response.status_code} - #{response.body}" }
        exit 1  
      end
    end

    def finalize_release(version : String)
      url = "#{BASE_URL}/organizations/#{org}/releases/#{version}/"

      headers = HTTP::Headers{
        "Authorization" => "Bearer #{api_key}",
        "Content-Type" => "application/json"
      }

      body = {
        "status": "completed"
      }.to_json
    
      response = HTTP::Client.put(url, headers: headers, body: body)
    
      if response.success?
        Log.info { "Release #{version} finalized successfully" }
      else
        Log.error { "Error finalizing release: #{response.status_code} - #{response.body}" }
        exit 1
      end
    end
    
    def upload_sourcemaps(version : String, path : String, framework : String? = nil)
      url = "#{BASE_URL}/projects/#{org}/#{project}/releases/#{version}/files/"

      patterns = case framework
      when "nextjs"
        ["#{path}/.next/static/chunks/**/*.{js,js.map}"]
      when "react"
        ["#{path}/build/static/js/*.{js,js.map}"]
      when "angular"
        ["#{path}/dist/**/*.js", "#{path}/dist/**/*.js.map"]
      when "vuejs"
        ["#{path}/dist/js/*.{js,js.map}"]
      else
        ["#{path}/**/*.{js,js.map}"]
      end
      
      patterns.each do |pattern|
        Dir.glob(patterns) do |file|
          io = IO::Memory.new
          form_data = HTTP::FormData.build(io) do |builder|
            builder.field("file", File.open(file), headers: HTTP::Headers{"Content-Type" => "application/octet-stream"})
            builder.field("name", "/#{File.basename(file)}")
          end

          p! form_data

          headers = HTTP::Headers{
            "Authorization" => "Bearer #{api_key}",
            "Content-Type" => "multipart/form-data"
          }

          response = HTTP::Client.post(url, headers: headers, body: io)
      
          if response.success?
            Log.info { "Uploaded #{file}" }
          else
            Log.error { "Error uploading #{file}: #{response.status_code} - #{response.body}" }
            exit 1
          end
        end
      end
    end
  end
end