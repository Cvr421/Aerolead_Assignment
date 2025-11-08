# Autodialer

A Ruby on Rails application that can make automated phone calls to a list of Indian phone numbers using Twilio. Features include:

- Bulk upload of phone numbers via paste or file upload
- Natural language command interface ("call this number...")
- Call status tracking and logging
- Background job processing for making calls
- Test mode using toll-free numbers
- AI-powered voice synthesis support

## Requirements

- Ruby 3.2.3
- Rails 6.1.7
- Redis (for Sidekiq)
- SQLite3 (development/test) or PostgreSQL (production)
- Node.js & Yarn (for webpacker)

## Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   yarn install
   ```

3. Set up environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your Twilio credentials
   ```

4. Set up the database:
   ```bash
   bin/rails db:prepare
   ```

5. Start the services:
   ```bash
   redis-server                  # Start Redis
   bundle exec sidekiq          # Start Sidekiq
   bin/rails server             # Start Rails
   ```

6. Visit http://localhost:3000

## Usage

### Upload Numbers

1. Navigate to the home page
2. Paste numbers in the text area (one per line) or upload a file
3. Numbers should be in any of these formats:
   - 10 digits: 9876543210
   - With country code: +919876543210
   - With leading zero: 09876543210

### Making Calls

Two ways to initiate calls:

1. Batch mode:
   - Upload numbers
   - Enter a message
   - Click "Start Calls"

2. AI Prompt mode:
   - Type natural language command like:
     - "call 1800123456 and say Hello"
     - "make calls to all pending numbers"

### Testing

For testing, use toll-free numbers like:
- 1800-XXX-XXXX
- 1888-XXX-XXXX

Never use real phone numbers during testing!

## Configuration

Key environment variables:

```bash
TWILIO_ACCOUNT_SID=     # Your Twilio Account SID
TWILIO_AUTH_TOKEN=      # Your Twilio Auth Token
TWILIO_FROM=           # Your Twilio phone number
OPENAI_API_KEY=        # Optional: For AI prompt parsing
PUBLIC_HOST=          # Your public server URL
```

## Development

The application uses:

- Sidekiq for background job processing
- Twilio Ruby gem for making calls
- Phonelib for number validation
- OpenAI for natural language command parsing (optional)
- Webpacker for JavaScript management

## Monitoring

- View job status: /sidekiq (development only)
- View call logs: Main dashboard
- Monitor Twilio logs: Twilio Console
