require "webrick"
require_relative "builder"

module Tika
  class Server
    def initialize(config, port: 4000)
      @config = config
      @port   = port
      @out    = config["build_dir"]
    end

    def start
      build!

      server = WEBrick::HTTPServer.new(
        Port:        @port,
        DocumentRoot: @out,
        Logger:      WEBrick::Log.new($stdout, WEBrick::Log::INFO),
        AccessLog:   [[
          $stdout,
          %(%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b),
        ]],
      )

      # Serve 404.html for missing files if it exists
      server.mount_proc("/") do |req, res|
        file = File.join(@out, req.path)
        file = File.join(file, "index.html") if File.directory?(file)

        if File.exist?(file)
          res.body        = File.read(file)
          res.content_type = mime_type(file)
        elsif File.exist?(File.join(@out, "404.html"))
          res.status      = 404
          res.body        = File.read(File.join(@out, "404.html"))
          res.content_type = "text/html"
        else
          res.status = 404
          res.body   = "404 Not Found"
        end
      end

      puts "Tika server running at http://localhost:#{@port}"
      puts "Press Ctrl-C to stop."
      trap("INT") { server.shutdown }
      server.start
    end

    private

    def build!
      stats = Builder.new(@config).build
      puts "Built #{stats[:articles]} article(s) and #{stats[:pages]} page(s) → #{@out}/"
    end

    def mime_type(path)
      case File.extname(path).downcase
      when ".html" then "text/html"
      when ".css"  then "text/css"
      when ".js"   then "application/javascript"
      when ".xml", ".atom" then "application/xml"
      when ".png"  then "image/png"
      when ".jpg", ".jpeg" then "image/jpeg"
      when ".gif"  then "image/gif"
      when ".svg"  then "image/svg+xml"
      else "application/octet-stream"
      end
    end
  end
end
