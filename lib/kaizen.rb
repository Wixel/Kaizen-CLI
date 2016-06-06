require 'yaml'
require 'tmpdir'
require 'net/http'
require 'uri'
require 'tempfile'
require 'zip'
require 'paint'

module Kaizen
  class CLI
    attr_reader :directory
    attr_reader :overwrite

    def initialize(directory, overwrite = false)
      @directory = directory
      @overwrite = overwrite

      if !File.directory? @directory
        Kaizen::CLI.pout(:error, "Error: The directory '#{@directory}' does not exist")
      else
        fetch
      end
    end

    private

    def fetch
      unzip_to(download_archive!)
    end

    def download_archive!
      save_to_tempfile('https://codeload.github.com/Wixel/Kaizen/zip/master')
    end

    ##
    # Unzip the Kaizen zip file to a destination
    #
    # @param File archive
    # @param String destination
    # @param Boolean force
    def unzip_to(archive)
      Zip::File.open(archive.path) do |zip_file|

        manifest = zip_file.glob('Kaizen-master/*.yml').first

        if manifest.nil?
          raise ArgumentError, 'The manifest object is null or non-existent'
        end

        allowed = YAML.load(manifest.get_input_stream.read)

        zip_file.each do |f|
          sanitized = f.name.gsub('Kaizen-master', '')

          next if sanitized == '/'

          fpath = File.join(@directory, sanitized)

          if !allowed.include?(sanitized)
            Kaizen::CLI.pout(:not_set, fpath)
            next
          end

          if !File.exist?(fpath)
            zip_file.extract(f, fpath)
          else
            if @overwrite
              zip_file.extract(f, fpath) { true }
            else
              Kaizen::CLI.pout(:exists, fpath)
            end
          end
        end
      end
    end

    ##
    # Download a path and save it to a temp directory
    #
    # @param String url
    def save_to_tempfile(url)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      http.start do |http|
        resp = http.get(uri.path)
        file = Tempfile.new('master.zip')
        file.binmode
        file.write(resp.body)
        file.flush
        file.close
        file
      end
    end

    ##
    # Output helper
    #
    # @param Symbol optn
    # @param String p
    def self.pout(optn, ps = nil)
      case optn
      when :not_set
        puts "Excluded from manifest: #{Paint[ps, :blue]}"
      when :exists
        puts "File already exists: #{Paint[ps, :red]}"
      when :error
        puts Paint[ps, :red]
      when :default
        puts ps
      end
    end

  end
end
