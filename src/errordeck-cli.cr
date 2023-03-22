# TODO: Write documentation for `Errordeck::Cli`
require "option_parser"
require "./client"
require "log"

module Errordeck::Cli
  VERSION = "0.1.0"

  def self.validate_env_vars
    required_vars = %w(ERRORDECK_API_KEY ERRORDECK_ORG ERRORDECK_PROJECT)
    missing_vars = required_vars.select { |var| !ENV[var]? }

    if !missing_vars.empty?
      puts "Error: The following environment variables are missing:"
      missing_vars.each { |var| puts "  - #{var}" }
      exit 1
    end
  end

  OptionParser.parse do |parser|
    parser.banner = "Usage: errodeck-cli [command] [options]"

    parser.on("-h", "--help", "Show this help") do
      puts parser
      exit
    end

    parser.on("-v", "--version", "Show vers ion") do
      puts "Errordeck CLI #{VERSION}"
      exit
    end

    parser.on("create-release", "Create a new release") do
      parser.banner = "Usage: errordeck-cli create-release [version]"
      validate_env_vars
      version = ARGV.shift
      Errordeck::Client.new.create_release(version)
    end

    parser.on("upload-sourcemaps", "Upload sourcemaps for a release") do
      parser.banner = "Usage: errordeck-cli upload-sourcemaps [version] [path] [framework]"
      validate_env_vars
      version = ARGV.shift
      framework = ARGV.shift?
      path = ARGV.shift || "."
      Errordeck::Client.new.upload_sourcemaps(version, path, framework)
    end

    parser.on("finalize-release", "Finalize a release") do
      parser.banner = "Usage: errordeck-cli finalize-release [version]"
      validate_env_vars
      version = ARGV.shift
      Errordeck::Client.new.finalize_release(version)
    end
  end
end
