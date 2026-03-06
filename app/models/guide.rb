class Guide
  require "net/http"

  CONTENT_PATH = Rails.root.join("app", "content", "guides")
  CACHE_TTL = ENV.fetch("GUIDE_CACHE_TTL", "300").to_i.seconds

  attr_reader :slug, :metadata

  def initialize(slug)
    @slug = slug
    parse_file
  end

  def self.find(slug)
    new(slug)
  end

  def self.all
    if github_repo
      github_list
    else
      Dir.glob(CONTENT_PATH.join("*.md")).map do |file|
        new(File.basename(file, ".md"))
      end.sort_by(&:position)
    end
  end

  def self.github_repo
    ENV["GITHUB_REPO"]
  end

  def self.github_branch
    ENV.fetch("GITHUB_BRANCH", "main")
  end

  def self.github_list
    Rails.cache.fetch("guides/list", expires_in: CACHE_TTL) do
      uri = URI("https://api.github.com/repos/#{github_repo}/contents/app/content/guides?ref=#{github_branch}")
      response = github_get(uri)
      return [] unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
        .select { |f| f["name"].end_with?(".md") }
        .map { |f| new(File.basename(f["name"], ".md")) }
        .sort_by(&:position)
    end
  end

  def self.github_get(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      req = Net::HTTP::Get.new(uri)
      req["Accept"] = "application/vnd.github.v3+json"
      req["User-Agent"] = "ARCAkit Documentation"
      req["Authorization"] = "Bearer #{ENV["GITHUB_TOKEN"]}" if ENV["GITHUB_TOKEN"]
      http.request(req)
    end
  end

  def title
    metadata["title"] || slug.titleize
  end

  def description
    metadata["description"] || ""
  end

  def section
    metadata["section"] || "General"
  end

  def position
    metadata["position"] || 999
  end

  def body_html
    @body_html ||= render_markdown
  end

  def chapters
    @chapters ||= extract_chapters
  end

  private

  def load_content
    if (repo = self.class.github_repo)
      Rails.cache.fetch("guides/content/#{@slug}", expires_in: CACHE_TTL) do
        branch = self.class.github_branch
        uri = URI("https://raw.githubusercontent.com/#{repo}/#{branch}/app/content/guides/#{@slug}.md")
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.get(uri.request_uri) }
        raise ActiveRecord::RecordNotFound, "Guide not found: #{@slug}" unless response.is_a?(Net::HTTPSuccess)
        response.body
      end
    else
      path = CONTENT_PATH.join("#{@slug}.md")
      raise ActiveRecord::RecordNotFound, "Guide not found: #{@slug}" unless path.exist?
      path.read
    end
  end

  def parse_file
    content = load_content

    if content.start_with?("---")
      parts = content.split("---", 3)
      @metadata = YAML.safe_load(parts[1]) || {}
      @body = parts[2].strip
    else
      @metadata = {}
      @body = content
    end
  end

  def render_markdown
    html = Commonmarker.to_html(@body, options: {
      parse: { smart: true },
      render: { unsafe: true, github_pre_lang: true },
      extension: {
        strikethrough: true,
        table: true,
        autolink: true,
        tasklist: true,
        header_ids: ""
      }
    }, plugins: {
      syntax_highlighter: { theme: "base16-ocean.dark" }
    })

    post_process(html)
  end

  def post_process(html)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)

    # Wrap code blocks in Rails Guides style container
    doc.css("pre").each do |pre|
      next if pre.parent&.classes&.include?("interstitial")

      wrapper = doc.document.create_element("div")
      wrapper["class"] = "interstitial code"
      pre.replace(wrapper)
      wrapper.add_child(pre)
    end

    # Add IDs and anchor links to headings
    doc.css("h2, h3, h4, h5, h6").each do |node|
      id = node["id"] || node.text.strip.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/-$/, "")
      node["id"] = id
      node.inner_html = "<a class='anchorlink' href='##{id}'>#{node.inner_html}</a>"
    end

    # Note/Tip/Warning boxes
    doc.css("p").each do |p|
      text = p.inner_html
      if text.start_with?("NOTE:")
        p.replace("<div class='interstitial note'><p>#{text.sub('NOTE:', '').strip}</p></div>")
      elsif text.start_with?("TIP:")
        p.replace("<div class='interstitial info'><p>#{text.sub('TIP:', '').strip}</p></div>")
      elsif text.start_with?("WARNING:")
        p.replace("<div class='interstitial warning'><p>#{text.sub('WARNING:', '').strip}</p></div>")
      end
    end

    doc.to_html
  end

  def extract_chapters
    doc = Nokogiri::HTML::DocumentFragment.parse(body_html)
    chapters = []

    doc.css("h2, h3").each do |node|
      entry = { id: node["id"], title: node.text }

      if node.name == "h2"
        entry[:subchapters] = []
        chapters << entry
      elsif node.name == "h3" && chapters.any?
        chapters.last[:subchapters] << entry
      end
    end

    chapters
  end
end
