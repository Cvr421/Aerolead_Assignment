# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
# sample safe numbers for testing - toll-free like numbers (demo only)
(1..100).each do |i|
  num = "1800" + (1000000 + i).to_s[-7..-1]  # creates 1800xxxxxxx
  formatted = "+1" + num  # you can choose +91 for India, but 1800 numbers are safer in tests
  PhoneNumber.create!(number: formatted, status: :pending, last_log: "seeded")
end
puts "Seeded 100 sample numbers"



articles = {
  "Building a Robust REST API in Java: Best Practices and Examples" => <<~HTML,
    <h2>Design and resource modeling</h2>
    <p>Start by modeling resources around nouns ...</p>
    <pre><code class="language-java">/* example Java controller snippet */</code></pre>
    <h3>Conclusion</h3><p>Start small and structure for scale.</p>
  HTML

  "Modern Concurrency Patterns in Java (CompletableFuture & Virtual Threads)" => <<~HTML,
    <h2>CompletableFuture basics</h2>
    <p>CompletableFuture supports composition...</p>
    <pre><code class="language-java">CompletableFuture.supplyAsync(() -> fetch())</code></pre>
    <h3>Conclusion</h3><p>Use completable futures and virtual threads wisely.</p>
  HTML

  "How to Design Clean React Component Libraries with TypeScript" => <<~HTML,
    <h2>API design</h2><p>Design minimal props, use TypeScript...</p>
    <pre><code class="language-ts">type ButtonProps = ...</code></pre>
    <h3>Conclusion</h3><p>Ship components that are well-typed and documented.</p>
  HTML

  "Database Indexing Strategies for High-Scale PostgreSQL" => <<~HTML,
    <h2>Choose the right index type</h2><p>B-tree, GIN, GiST...</p>
    <h3>Conclusion</h3><p>Profile and iterate.</p>
  HTML

  "Introduction to Event-Driven Architectures with Kafka and Node.js" => <<~HTML,
    <h2>Core concepts</h2><p>Producers, topics, consumers...</p>
    <pre><code class="language-js">const { Kafka } = require('kafkajs')</code></pre>
    <h3>Conclusion</h3><p>Use schema registry and idempotency.</p>
  HTML

  "Practical Guide to Dockerizing a Rails Application for Production" => <<~HTML,
    <h2>Dockerfile essentials</h2><pre><code>FROM ruby:3.2-slim</code></pre>
    <h3>Conclusion</h3><p>Keep images small and configs secure.</p>
  HTML

  "Terraform Best Practices for AWS Infrastructure at Scale" => <<~HTML,
    <h2>State management</h2><p>Use remote state, lock with DynamoDB...</p>
    <h3>Conclusion</h3><p>Adopt modular, reviewable infra-as-code.</p>
  HTML

  "Building Secure Authentication with JWT, Refresh Tokens, and Secure Cookies" => <<~HTML,
    <h2>Access + refresh tokens</h2><p>Short-lived access tokens...</p>
    <h3>Conclusion</h3><p>Rotate and track refresh tokens.</p>
  HTML

  "Observability 101: Tracing, Metrics, and Logs for Microservices" => <<~HTML,
    <h2>Traces</h2><p>Use OpenTelemetry...</p>
    <h3>Conclusion</h3><p>Correlate traces, metrics, and logs.</p>
  HTML

  "A Fast Guide to Writing High-Performance Algorithms in Java" => <<~HTML,
    <h2>Algorithmic complexity</h2><p>Measure and profile first...</p>
    <h3>Conclusion</h3><p>Optimize after profiling.</p>
  HTML
}

articles.each do |title, body|
  BlogPost.find_or_create_by!(title: title) do |p|
    p.body = body
    p.source = "seed-ai"
    p.slug = title.parameterize
  end
end

puts "Seeded sample blog posts (#{articles.keys.count})"
