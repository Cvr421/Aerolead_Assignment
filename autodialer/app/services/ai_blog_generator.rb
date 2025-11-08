# app/services/ai_blog_generator.rb
require 'net/http'
require 'json'
require 'uri'

class AiBlogGenerator
  def initialize(provider: ENV.fetch("AI_PROVIDER", "perplexity"))
    @provider = provider.downcase
    # @openai_key = ENV['OPENAI_API_KEY']
    # @gemini_key = ENV['GEMINI_API_KEY']
    @perplexity_key = ENV['PERPLEXITY_API_KEY']
  end

  # options: title (required), word_count: Integer (approx), language: String
  def generate!(title:, word_count: 600, language: "English")
    raise ArgumentError, "title is required" if title.to_s.strip.empty?

    case @provider
    # when 'openai', 'chatgpt'
    #   generate_openai(title: title, word_count: word_count, language: language)
    # when 'gemini'
    #   generate_gemini(title: title, word_count: word_count, language: language)
    when 'perplexity'
      generate_perplexity(title: title, word_count: word_count, language: language)
    else
      raise "Unsupported AI_PROVIDER=#{@provider}"
    end
  end

  private

  # -----------------------
  # OpenAI Chat completions
  # -----------------------
#   def generate_openai(title:, word_count:, language:)
#     raise "OPENAI_API_KEY missing" unless @openai_key.present?

#     prompt = <<~PROMPT
#       Write a practical, well-structured technical article in #{language} of about #{word_count} words titled: "#{title}".
#       - Use headings (H2/H3) and short paragraphs.
#       - Include at least one short code example (JavaScript or Ruby or Java) relevant to the topic.
#       - Use bullets or numbered steps where helpful.
#       - End with a short conclusion and next steps.
#       - Return only the article body (HTML or plain text with basic markup is fine).
#     PROMPT

#     uri = URI("https://api.openai.com/v1/chat/completions")
#     req = Net::HTTP::Post.new(uri)
#     req['Content-Type'] = 'application/json'
#     req['Authorization'] = "Bearer #{@openai_key}"
#     req.body = {
#       model: ENV.fetch("OPENAI_MODEL", "gpt-4o-mini"),
#       messages: [
#         { role: "system", content: "You are a helpful, accurate technical writer." },
#         { role: "user", content: prompt }
#       ],
#       temperature: 0.2,
#       max_tokens: 2000
#     }.to_json

#     res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 120) do |http|
#       http.request(req)
#     end

#     raise "OpenAI error: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)

#     parsed = JSON.parse(res.body) rescue {}
#     content = parsed.dig("choices", 0, "message", "content")
#     content.to_s.strip
#   end

  # -----------------------
  # Gemini (HTTP example)
  # Replace URL/payload with exact Gemini HTTP API if different
  # -----------------------
#   def generate_gemini(title:, word_count:, language:)
#     raise "GEMINI_API_KEY missing" unless @gemini_key.present?

#     prompt = <<~PROMPT
#       Write a practical #{word_count}-word technical article titled "#{title}" in #{language}.
#       Include headings and at least one short code example.
#     PROMPT

#     uri = URI("https://gemini.googleapis.com/v1/models/text-bison:generate") # example; check actual endpoint for your access
#     req = Net::HTTP::Post.new(uri)
#     req['Content-Type'] = 'application/json'
#     req['Authorization'] = "Bearer #{@gemini_key}"
#     req.body = {
#       prompt: {
#         text: prompt
#       },
#       temperature: 0.2,
#       maxOutputTokens: 1500
#     }.to_json

#     res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 120) do |http|
#       http.request(req)
#     end
#     raise "Gemini error: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)
#     parsed = JSON.parse(res.body) rescue {}
#     # adjust extraction to actual Gemini response shape:
#     parsed.dig("candidates", 0, "content", 0, "text") || parsed.to_s
#   end

  # -----------------------
  # Perplexity PRO (HTTP example)
  # Replace URL/payload with their exact API doc format
  # -----------------------
#   def generate_perplexity(title:, word_count:, language:)
#     raise "PERPLEXITY_API_KEY missing" unless @perplexity_key.present?

#      prompt = <<~PROMPT
#         Write a practical #{word_count}-word technical article titled "#{title}" in #{language}.
#         - Use headings (H2/H3) and short paragraphs.
#         - Include at least one short code example relevant to the topic.
#         - End with a short conclusion and next steps.
#      PROMPT

#     uri = URI("https://api.perplexity.ai/chat/completions") # example; replace with the actual endpoint & headers
#     req = Net::HTTP::Post.new(uri)
#     req['Content-Type'] = 'application/json'
#     req['Authorization'] = "Bearer #{@perplexity_key}"
#     req.body = { query: prompt, length: word_count }.to_json

#     res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 120) do |http|
#       http.request(req)
#     end
#     raise "Perplexity error: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)
#     parsed = JSON.parse(res.body) rescue {}
#     parsed.dig("answer") || parsed.to_s
#   end



  # inside app/services/ai_blog_generator.rb
def generate_perplexity(title:, word_count:, language:)
    raise "PERPLEXITY_API_KEY missing" unless @perplexity_key.present?
  
    prompt = <<~PROMPT
       Write a practical, well-structured technical article in #{language} of about #{word_count} words titled: "#{title}".
        - Use headings (H2/H3) and short paragraphs.
        - Include at least one short code example (JavaScript or Ruby or Java) relevant to the topic.
        - Use bullets or numbered steps where helpful.
        - End with a short conclusion and next steps.
        - Return only the article body (HTML or plain text with basic markup is fine).
    PROMPT
  
    uri = URI("https://api.perplexity.ai/chat/completions")
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req['Authorization'] = "Bearer #{@perplexity_key}"
  
    body = {
      model: ENV.fetch("PERPLEXITY_MODEL", "sonar-pro"), # sonar-pro or sonar
      messages: [
        { role: "system",  content: "You are a helpful, accurate technical writer." },
        { role: "user",    content: prompt }
      ],
      # optional parameters:
      temperature: 0.2,
      max_tokens: 2000,
      stream: false
    }
  
    req.body = body.to_json
  
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 120) do |http|
      http.request(req)
    end
  
    # helpful debug on errors
    unless res.is_a?(Net::HTTPSuccess)
      raise "Perplexity error: #{res.code} #{res.body}"
    end
  
    parsed = JSON.parse(res.body) rescue {}
    # Perplexity returns a structure similar to OpenAI: choices[0].message.content
    parsed.dig("choices", 0, "message", "content") ||
      parsed.dig("choices", 0, "text") ||
      parsed.dig("result") ||
      parsed.to_s
  end
  







end
