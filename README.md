## LinkedIn Scraper

This project logs into LinkedIn using Selenium and scrapes basic profile info from URLs listed in `linkedin_scraper/profiles_sample.txt`, writing results to `linkedin_profiles.csv`.

### Setup

1) Create a virtualenv and install deps:

```bash
cd /home/chandravijay/space/Aerolead-Assignments
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
```

2) Configure credentials and options:

- Copy `linkedin_scraper/env.example` to `.env` (in the same `linkedin_scraper` folder) and fill values:

```bash
cp linkedin_scraper/env.example linkedin_scraper/.env
```

Supported keys:
- `LINKEDIN_EMAIL`
- `LINKEDIN_PASSWORD`
- `HTTP_PROXY` (optional; supports http/https/socks5)
- `HEADLESS=true` (optional)

Alternatively, pass flags at runtime: `--email`, `--password`, `--proxy`, `--headless`.

### Run

```bash
source venv/bin/activate
python linkedin_scraper/linkedin_scraper.py --headless --proxy http://user:pass@host:port
```

Outputs: `linkedin_profiles.csv` in the repo root.

### Notes and Tips

- The script uses Selenium Manager by default; it falls back to `webdriver-manager` if needed.
- Sets a realistic User-Agent and disables obvious automation flags.
- Randomized small delays help reduce blocking. Keep rate low.
- Use a test LinkedIn account; ensure you have permission to access profiles.

### Troubleshooting

- If Chrome/Driver mismatch occurs, ensure Chrome is installed, or let `webdriver-manager` download a compatible driver.
- If blocked by LinkedIn, try: headful mode (remove `--headless`), a residential proxy, or longer delays.

