require 'rubygems'
require 'yaml'
require 'tmpdir'
require 'net/http'
require 'uri'
require 'tempfile'
require 'zip'
require 'paint'
require 'bourbon'
require 'rack'

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

        if manifest.nil?
          Kaizen::CLI.pout(:error, "Manifest file 'cli.yml' not found")
          next
        end

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
            path = File.join(@directory, 'scss/vendor/_normalize.scss')
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
      date_format = '%d/%m/%Y %H:%M'

      case optn
      when :error
        puts "#{Time.now.strftime(date_format)} #{Paint[msg, :red]}"
      when :info
        puts "#{Time.now.strftime(date_format)} #{Paint[msg, :green]}"
      when :warn
        puts "#{Time.now.strftime(date_format)} #{Paint[msg, :yellow]}"
      when :debug
        puts "#{Time.now.strftime(date_format)} #{Paint[msg, :cyan]}"
      when :default
        puts msg
      end
    end

    ##
    # Watch the provided directory
    #
    def self.watch(path)
      path = File.expand_path(path)

      CLI.path_exists?(path) do
        Kaizen::CLI.pout(:info, "Watching: #{path}")

        options = {
          :syntax     => :scss,
          :style      => :compressed,
          :cache    =>   false,
          :read_cache => false
        }

        Sass::Engine::DEFAULT_OPTIONS[:load_paths].tap do |load_paths|
          load_paths << "#{path}/scss"
        end

        css_directory = "#{path}/css"

        if !File.exist?(css_directory)
          Dir.mkdir(css_directory)
        end

        has_error = false

        main_file = "#{path}/scss/main.scss"

        CLI.path_exists?(main_file) do
          loop do
            css = Sass::Engine.new(File.read(main_file), options)

            begin
              File.open("#{css_directory}/main.css", "w") do |f|
                f.write css.render
              end

              if has_error
                Kaizen::CLI.pout(:debug, "You fixed the issue, thanks :)")
                has_error = false
              end

              sleep 3
            rescue Sass::SyntaxError => e
              Kaizen::CLI.pout(:error, e.message)
              has_error = true
              sleep 10
            end
          end
        end
      end
    end

    ##
    # Serve the specified path via the web server
    #
    def self.serve(path)
      path = File.expand_path(path)

      CLI.path_exists?(path) do
        Kaizen::KZNServer.set_load_path(path)

        Rack::Server.start({
          :app  => Kaizen::KZNServer,
          :Port => 9191
        })
      end
    end

    ##
    # Helper to clean up path checking
    #
    def self.path_exists?(path)
      if File.exist? path
        yield
      else
        Kaizen::CLI.pout(:error, "'#{path}' does not exist")
      end
    end
  end

  class KZNServer

    def self.set_load_path(p)
      @@server_path = p
    end

    def self.request_path(path)
      parts = path.split('/')

      if parts.size == 0
        parts << "index.html"
      end

      return "#{@@server_path}/#{parts.join('/')}"
    end

    def self.mime_for(file)
      supported_mimes = {
        ".avi"   => :"video/x-msvideo",
        ".bmp"   => :"image/bmp",
        ".css"   => :"text/css",
        ".csv"   => :"text/csv",
        ".doc"   => :"application/msword",
        ".docm"  => :"application/vnd.ms-word.document.macroEnabled.12",
        ".docx"  => :"application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        ".flv"   => :"video/x-flv",
        ".gz"    => :"application/x-gzip",
        ".htm"   => :"text/html",
        ".html"  => :"text/html",
        ".ico"   => :"image/x-icon",
        ".jpe"   => :"image/jpeg",
        ".jpeg"  => :"image/jpeg",
        ".jpg"   => :"image/jpeg",
        ".js"    => :"application/x-javascript",
        ".m4a"   => :"audio/m4a",
        ".m4v"   => :"video/x-m4v",
        ".mov"   => :"video/quicktime",
        ".movie" => :"video/x-sgi-movie",
        ".mp2"   => :"video/mpeg",
        ".mp2v"  => :"video/mpeg",
        ".mp3"   => :"audio/mpeg",
        ".mp4"   => :"video/mp4",
        ".mp4v"  => :"video/mp4",
        ".mpa"   => :"video/mpeg",
        ".mpeg"  => :"video/mpeg",
        ".mpg"   => :"video/mpeg",
        ".png"   => :"image/png",
        ".rar"   => :"application/octet-stream",
        ".tar"   => :"application/x-tar",
        ".tif"   => :"image/tiff",
        ".tiff"  => :"image/tiff",
        ".ttf"   => :"application/octet-stream",
        ".tts"   => :"video/vnd.dlna.mpeg-tts",
        ".txt"   => :"text/plain",
        ".wav"   => :"audio/wav",
        ".wsdl"  => :"text/xml",
        ".xhtml" => :"application/xhtml+xml",
        ".xml"   => :"text/xml",
        ".xsd"   => :"text/xml",
        ".xsf"   => :"text/xml",
        ".xsl"   => :"text/xml",
        ".xslt"  => :"text/xml",
        ".xsn"   => :"application/octet-stream",
        ".zip"   => :"application/x-zip-compressed"
      }

      ext = File.extname(file)

      if supported_mimes.key?(ext)
        supported_mimes[ext].to_s
      else
        'text/html'
      end
    end

    def self.call(env)
      requested_file = request_path(Rack::Request.new(env).path)

      response = Rack::Response.new

      response['Content-Type']  = mime_for(requested_file)
      response['Cache-Control'] = "no-cache, no-store, must-revalidate"
      response['Pragma']        = "no-cache"
      response['Expires']       = "0"

      if File.file?(requested_file)
        response.write(File.read(requested_file))
        response.status = 200
      else
        response.status = 404
      end

      response.finish
    end
  end
end
