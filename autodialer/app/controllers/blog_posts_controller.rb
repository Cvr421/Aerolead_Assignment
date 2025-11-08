class BlogPostsController < ApplicationController
    protect_from_forgery with: :exception
  
    def index
      @posts = BlogPost.order(created_at: :desc).limit(50)
    end
  
    def show
      @post = BlogPost.find_by(slug: params[:id]) || BlogPost.find(params[:id])
    end
  
    def generate_ui
      # renders app/views/blog_posts/generate_ui.html.erb
    end
  
    def generate
      titles_raw = params[:titles].to_s
      word_count = params[:word_count].to_i
      word_count = 600 if word_count <= 0
      titles = titles_raw.split(/\r?\n/).map(&:strip).reject(&:blank?).first(20)
  
      if titles.empty?
        redirect_back fallback_location: root_path, alert: "Please paste titles (one per line)."
        return
      end
  
      generator = AiBlogGenerator.new(provider: ENV['AI_PROVIDER'] || 'perplexity')
      created = []
  
      titles.each do |t|
        begin
          body = generator.generate!(title: t, word_count: word_count)
          p = BlogPost.create!(title: t, body: body, source: ENV['AI_PROVIDER'] || 'perplexity')
          created << p
          sleep 1 # small throttle to avoid rate limits
        rescue => e
          Rails.logger.error("[AI-GEN] Failed '#{t}': #{e.message}")
        end
      end
  
      if created.any?
        redirect_to blog_posts_path, notice: "Created #{created.count} posts."
      else
        redirect_back fallback_location: root_path, alert: "No posts created. Check logs."
      end
    end
  end
  