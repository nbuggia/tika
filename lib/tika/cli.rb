require "optparse"
require "date"
require_relative "config"
require_relative "builder"
require_relative "server"

module Tika
  class CLI
    def self.start(args)
      new.run(Array(args).dup)
    end

    def run(args)
      command = args.shift || "help"
      command = "serve" if command == "run"

      case command
      when "build"                then cmd_build(args)
      when "init"                 then cmd_init(args)
      when "new"                  then cmd_new(args)
      when "serve"                then cmd_serve(args)
      when "test"                 then cmd_test(args)
      when "deploy"               then cmd_deploy(args)
      when "help", "--help", "-h" then print_help
      else
        $stderr.puts "Unknown command: #{command}. Run `tika help` for usage."
        exit 1
      end
    end

    private

    def say(msg, color = nil)
      case color
      when :green  then $stdout.puts "\e[32m#{msg}\e[0m"
      when :yellow then $stdout.puts "\e[33m#{msg}\e[0m"
      when :red    then $stdout.puts "\e[31m#{msg}\e[0m"
      else              $stdout.puts msg
      end
    end

    def ask(prompt)
      $stdout.print "#{prompt} "
      $stdin.gets.to_s.chomp
    end

    # -------------------------------------------------------------------------
    # build
    # -------------------------------------------------------------------------
    def cmd_build(_args)
      config = Config.load
      stats  = Builder.new(config).build
      say "Built #{stats[:articles]} article(s) and #{stats[:pages]} page(s) → #{config["build_dir"]}/", :green
    end

    # -------------------------------------------------------------------------
    # init
    # -------------------------------------------------------------------------
    def cmd_init(args)
      name = args.first || ask("Site directory name:")
      name = name.strip

      if Dir.exist?(name)
        say "Directory '#{name}' already exists.", :red
        exit 1
      end

      assets_root  = File.expand_path("../../assets", __dir__)
      example_site = File.join(assets_root, "example-site")
      themes_src   = File.join(assets_root, "themes")

      FileUtils.mkdir_p(File.join(name, "content", "articles"))
      FileUtils.mkdir_p(File.join(name, "content", "pages"))
      FileUtils.mkdir_p(File.join(name, "content", "drafts"))
      FileUtils.mkdir_p(File.join(name, "content", "images"))
      FileUtils.cp(File.join(example_site, "config.yml"), File.join(name, "config.yml"))
      FileUtils.cp_r(File.join(themes_src, "."), File.join(name, "themes"))

      say "Created new site in '#{name}/'", :green
      say "  1. Edit #{name}/config.yml to set your title, author, etc."
      say "  2. Add articles to #{name}/content/articles/"
      say "  3. Run: cd #{name} && tika build"
    end

    # -------------------------------------------------------------------------
    # new
    # -------------------------------------------------------------------------
    def cmd_new(args)
      title      = args.first || ask("Article title:")
      slug       = title.downcase.strip.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
      filename   = "#{Date.today}-#{slug}.md"
      config     = Config.load
      drafts_dir = File.join(config["content_dir"], "drafts")
      FileUtils.mkdir_p(drafts_dir)
      path = File.join(drafts_dir, filename)

      if File.exist?(path)
        say "Draft already exists: #{path}", :yellow
        return
      end

      File.write(path, <<~FRONTMATTER)
        ---
        title: #{title}
        author: #{config["author"]}
        ---

      FRONTMATTER

      say "Created: #{path}", :green
    end

    # -------------------------------------------------------------------------
    # serve (aliased as "run")
    # -------------------------------------------------------------------------
    def cmd_serve(args)
      port = 4000
      OptionParser.new do |opts|
        opts.on("-p", "--port PORT", Integer, "Port to listen on (default: 4000)") { |p| port = p }
      end.parse!(args)
      config = Config.load
      Server.new(config, port: port).start
    end

    # -------------------------------------------------------------------------
    # test
    # -------------------------------------------------------------------------
    def cmd_test(_args)
      config  = Config.load
      out_dir = config["build_dir"]

      unless Dir.exist?(out_dir)
        say "Build directory '#{out_dir}' not found. Run `tika build` first.", :red
        exit 1
      end

      html_files = Dir.glob(File.join(out_dir, "**", "*.html"))
      errors     = []

      html_files.each do |file|
        content = File.read(file)
        links   = content.scan(/(?:href|src)="(\/[^"#?]*)/).flatten
        links.each do |link|
          candidates = [
            File.join(out_dir, link),
            File.join(out_dir, link, "index.html"),
            File.join(out_dir, link.sub(%r{/\z}, "")),
          ]
          unless candidates.any? { |c| File.exist?(c) }
            errors << "#{file.sub("#{out_dir}/", "")}: broken link → #{link}"
          end
        end
      end

      if errors.empty?
        say "All links OK (checked #{html_files.size} files)", :green
      else
        errors.each { |e| say e, :red }
        say "\n#{errors.size} broken link(s) found", :red
        exit 1
      end
    end

    # -------------------------------------------------------------------------
    # deploy
    # -------------------------------------------------------------------------
    def cmd_deploy(args)
      target = "rsync"
      dest   = nil
      OptionParser.new do |opts|
        opts.on("-t", "--target TARGET", "Deployment target: rsync (default) or ghpages") { |t| target = t }
        opts.on("-d", "--dest DEST",     "Rsync destination, e.g. user@host:/var/www/html") { |d| dest = d }
      end.parse!(args)

      config = Config.load
      out    = config["build_dir"]

      unless Dir.exist?(out)
        say "Build directory '#{out}' not found. Run `tika build` first.", :red
        exit 1
      end

      case target
      when "rsync"
        unless dest
          say "Provide a destination with --dest user@host:/path", :red
          exit 1
        end
        cmd = "rsync -avz --delete #{out}/ #{dest}"
        say "Deploying via rsync: #{cmd}"
        system(cmd) || exit(1)

      when "ghpages"
        say "Deploying to GitHub Pages (gh-pages branch)..."
        cmds = [
          "git -C #{out} init -b gh-pages 2>/dev/null || true",
          "git -C #{out} add -A",
          "git -C #{out} commit -m 'Deploy #{Time.now.strftime("%Y-%m-%d %H:%M")}'",
          "git -C #{out} push -f origin gh-pages",
        ]
        cmds.each { |c| system(c) || exit(1) }

      else
        say "Unknown target '#{target}'. Use rsync or ghpages.", :red
        exit 1
      end

      say "Deployed!", :green
    end

    # -------------------------------------------------------------------------
    # help
    # -------------------------------------------------------------------------
    def print_help
      $stdout.puts <<~HELP
        Usage: tika <command> [options]

        Commands:
          build             Build the static site into the build/ directory
          init [NAME]       Create a new Tika site in a new directory
          new [TITLE]       Create a new draft article
          serve             Build the site and serve it locally
          test              Validate the built site for broken internal links
          deploy            Deploy the built site
          help              Show this help message

        Options for serve:
          -p, --port PORT   Port to listen on (default: 4000)

        Options for deploy:
          -t, --target      Deployment target: rsync (default) or ghpages
          -d, --dest        Rsync destination, e.g. user@host:/var/www/html
      HELP
    end
  end
end
