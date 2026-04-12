require "erb"

module Tika
  # Adapted from Baron's PageController. Renders an ERB partial inside the
  # layout template, passing a shared context object to both.
  class Renderer
    def initialize(config)
      @config     = config
      @theme_dir  = File.join("themes", config["theme"], "templates")
    end

    # Render a named template wrapped in the layout.
    # +locals+ hash is made available inside templates via instance variables.
    def render(template_name, locals = {})
      # Build a context object that templates can read from
      ctx = RenderContext.new(@config, locals)
      content = render_template(template_name, ctx)
      render_template("layout.html.erb", ctx) { content }
    end

    # Render without wrapping in layout (e.g. feed.xml.erb)
    def render_partial(template_name, locals = {})
      ctx = RenderContext.new(@config, locals)
      render_template(template_name, ctx)
    end

    private

    def render_template(name, ctx, &block)
      path = File.join(@theme_dir, name)
      raise "Template not found: #{path}" unless File.exist?(path)
      erb = ERB.new(File.read(path), trim_mode: "-")
      erb.result(ctx.binding_for(block))
    end
  end

  # Holds all template-visible variables. Templates access these as
  # @config, @articles, @article, etc.
  class RenderContext
    attr_accessor :config, :content_block

    def initialize(config, locals)
      @config = config
      locals.each { |k, v| instance_variable_set(:"@#{k}", v) }
    end

    def binding_for(content_block)
      @content_block = content_block
      binding
    end

    # Called inside layout.html.erb to insert the page content
    def yield_content
      @content_block&.call
    end
  end
end
