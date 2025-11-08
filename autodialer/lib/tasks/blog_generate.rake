namespace :blog do
    desc "Generate articles from titles.txt (app root). Usage: rails blog:generate FILE=./titles.txt"
    task generate: :environment do
      file = ENV['FILE'] || Rails.root.join('titles.txt')
      unless File.exist?(file)
        puts "Titles file not found: #{file}"
        exit 1
      end
      titles = File.read(file).split(/\r?\n/).map(&:strip).reject(&:empty?).first(50)
      gen = AiBlogGenerator.new(provider: ENV['AI_PROVIDER'] || 'openai')
      titles.each do |t|
        puts "Generating: #{t}"
        begin
          body = gen.generate!(title: t, word_count: 600)
          BlogPost.create!(title: t, body: body, source: ENV['AI_PROVIDER'] || 'openai')
          sleep 1
        rescue => e
          puts "Failed #{t}: #{e.message}"
        end
      end
      puts "Done."
    end
  end
  