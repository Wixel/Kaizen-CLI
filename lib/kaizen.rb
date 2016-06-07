require 'yaml'
require 'tmpdir'
require 'net/http'
require 'uri'
require 'tempfile'
require 'zip'
require 'paint'
require 'bourbon'

module Kaizen
  class CLI
    attr_reader :directory
    attr_reader :overwrite
    attr_reader :verbose

    ##
    # Initializer
    #
    def initialize(directory, overwrite = false, verbose = false)
      @directory = File.expand_path(directory)
      @overwrite = overwrite
      @verbose   = verbose

      if !File.directory? @directory
        Kaizen::CLI.pout(:error, "The directory does not exist: #{@directory}")
      else
        Kaizen::CLI.pout(:info, "Installing to: #{@directory}")

        start!
      end
    end

    private

    def verbose(m)
      Kaizen::CLI.pout(:debug, m) if @verbose
    end

    ##
    # Invoke the fetch and unzip process
    #
    def start!
      verbose('Starting...')

      process_kaizen_archive(
        save_to_tempfile('https://codeload.github.com/Wixel/Kaizen/zip/master')
      )

      process_normalize_archive(
        save_to_tempfile('https://codeload.github.com/necolas/normalize.css/zip/master')
      )

      install_bourbon!
    end

    ##
    # Install the bourbon items
    #
    def install_bourbon!
      verbose("Installing Bourbon")

      path = "#{@directory}/scss/vendor/"

      Kaizen::CLI.pout(:info, "Running: bourbon install --path #{path}")

      `bourbon install --path #{path}`
    end

    ##
    # Unzip the Kaizen zip file to the specified destination
    #
    def process_kaizen_archive(archive)

      verbose("Processing Kaizen archive: #{archive.path}")

      Zip::File.open(archive.path) do |zip_file|
        manifest = zip_file.glob('Kaizen-master/*.yml').first

        next if manifest.nil?

        allowed = YAML.load(manifest.get_input_stream.read)

        zip_file.each do |f|
          sanitized = f.name.gsub('Kaizen-master', '')

          next if sanitized == '/'

          path = File.join(@directory, sanitized)

          if !allowed.include?(sanitized)
            Kaizen::CLI.pout(:warn, "Excluded: #{path}")
            next
          end

          if !File.exist?(path)
            zip_file.extract(f, path)
          else
            if @overwrite
              zip_file.extract(f, path) { true }
            else
              Kaizen::CLI.pout(:error, "File already exists: #{path}")
            end
          end
        end
      end
    end

    ##
    # Download and install the normalize.css archive
    #
    def process_normalize_archive(archive)

      verbose("Processing normalize.css archive #{archive.path}")

      Zip::File.open(archive.path) do |zip_file|
        zip_file.each do |f|
          if f.name == "normalize.css-master/normalize.css"
            path = File.join(@directory, 'scss/vendor/normalize.scss')
            begin
              zip_file.extract(f, path) if !File.exist? path
            rescue Exception => e
              Kaizen::CLI.pout(:error, "Unable to write #{path}")
            end
          end
        end
      end
    end

    ##
    # Download a path and save it to a temp directory
    #
    def save_to_tempfile(url)
      verbose("Downloading #{url}")

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

        verbose("Saved to #{file.path}")

        file
      end
    end

    ##
    # Output helper
    #
    def self.pout(optn, msg)
      format = '%d/%m/%Y %H:%M'

      case optn
      when :error
        puts "#{Time.now.strftime(format)} #{Paint[msg, :red]}"
      when :info
        puts "#{Time.now.strftime(format)} #{Paint[msg, :green]}"
      when :warn
        puts "#{Time.now.strftime(format)} #{Paint[msg, :yellow]}"
      when :debug
        puts "#{Time.now.strftime(format)} #{Paint[msg, :cyan]}"
      when :default
        puts msg
      end
    end

    ##
    # Watch the provided directory
    #
    def self.watch(path)
      path = File.expand_path(path)

      if File.exist? path
        Kaizen::CLI.pout(:info, "Watching: #{path}")

        `sass --watch #{path}/scss:#{path}/css --style compressed`
      else
        Kaizen::CLI.pout(:error, "Path does not exist: #{path}")
      end
    end

  end
end
