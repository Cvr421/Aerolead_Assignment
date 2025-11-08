import time
import csv
import os
import argparse
import random
from selenium import webdriver
try:
    from selenium.webdriver.common.by import By
except Exception:
    class By:
        ID = "id"
        XPATH = "xpath"
        LINK_TEXT = "link text"
        PARTIAL_LINK_TEXT = "partial link text"
        NAME = "name"
        TAG_NAME = "tag name"
        CLASS_NAME = "class name"
        CSS_SELECTOR = "css selector"
try:
    from selenium.webdriver.chrome.options import Options
except Exception:
    class Options:
        def __init__(self):
            self._args = []
        def add_argument(self, arg):
            self._args.append(arg)
from selenium.common.exceptions import NoSuchElementException
try:
    from selenium.webdriver.support.ui import WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC
except Exception:
    WebDriverWait = None
    EC = None

try:
    from dotenv import load_dotenv
except Exception:
    def load_dotenv(*_args, **_kwargs):
        return False

INPUT = "profiles_sample.txt"
OUTPUT = "linkedin_profiles.csv"

DEFAULT_USER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/128.0.0.0 Safari/537.36"
)

driver = None
_LAST_EMAIL = None
_LAST_PASSWORD = None

def jitter_sleep(base_seconds): #“There are helper functions to make the scraping smoother:
    time.sleep(base_seconds + random.uniform(0.3, 1.2))

def create_driver(proxy_url=None, headless=False, user_agent=DEFAULT_USER_AGENT):
    chrome_options = Options()
    chrome_options.add_argument("--window-size=1200,800")
    chrome_options.add_argument("--disable-blink-features=AutomationControlled")
    chrome_options.add_argument("--no-first-run")
    chrome_options.add_argument("--disable-notifications")
    chrome_options.add_argument("--disable-infobars")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument(f"--user-agent={user_agent}")
    if headless:
        chrome_options.add_argument("--headless=new")
    if proxy_url:
        chrome_options.add_argument(f"--proxy-server={proxy_url}")
    try:
        return webdriver.Chrome(options=chrome_options)  # Selenium Manager handles driver
    except Exception:
        try:
            from webdriver_manager.chrome import ChromeDriverManager
            from selenium.webdriver.chrome.service import Service
            service = Service(ChromeDriverManager().install())
            return webdriver.Chrome(service=service, options=chrome_options)
        except Exception as e:
            raise RuntimeError(f"Failed to initialize Chrome driver: {e}")

def login(email, password):
    print("\n=== Starting Login Process ===")
    print("1. Accessing Google first...")
    driver.get("https://www.google.com")
    jitter_sleep(1)
    
    print("2. Navigating to LinkedIn login page...")
    driver.get("https://www.linkedin.com/login")
    jitter_sleep(2)
    
    print("3. Entering credentials...")
    driver.find_element(By.ID, "username").send_keys(email)
    print(f"   Email used: {email}")
    driver.find_element(By.ID, "password").send_keys(password)
    print("   Password: " + "*" * len(password))
    
    print("4. Clicking login button...")
    driver.find_element(By.XPATH, "//button[@type='submit']").click()
    
    print("5. Waiting for login completion...")
    if WebDriverWait and EC:
        try:
            WebDriverWait(driver, 12).until(
                EC.any_of(
                    EC.presence_of_element_located((By.ID, "global-nav")),
                    EC.url_contains("/feed/")
                )
            )
            print("   ✓ Login page redirect detected")
        except Exception:
            print("   ⚠ Timeout waiting for login redirect")
    
    jitter_sleep(2)
    
    print("6. Verifying login status...")
    if "feed" in driver.current_url:
        print("   ✓ Successfully logged in! On feed page")
    elif "mynetwork" in driver.current_url:
        print("   ✓ Successfully logged in! On network page")
    else:
        print(f"   ⚠ Unknown login status. Current URL: {driver.current_url}")
    print("=== Login Process Complete ===\n")

def _is_authwall_or_join_page():
    try:
        current = driver.current_url
    except Exception:
        current = ""
    if "authwall" in current:
        return True
    try:
        # Many gated pages show a prominent "Join LinkedIn" header
        h1_text = driver.find_element(By.CSS_SELECTOR, "h1").text.strip()
        if h1_text.lower().startswith("join linkedin"):
            return True
    except Exception:
        pass
    return False

def _retry_login_and_reload(url):
    # Attempt one re-login using last known credentials, then reload the URL
    global _LAST_EMAIL, _LAST_PASSWORD
    if not _LAST_EMAIL or not _LAST_PASSWORD:
        return False
    try:
        login(_LAST_EMAIL, _LAST_PASSWORD)
        driver.get(url)
        jitter_sleep(2)
        return not _is_authwall_or_join_page()
    except Exception:
        return False

def _get_first_text(selectors):
    for by, sel in selectors:
        try:
            el = driver.find_element(by, sel)
            text = el.text.strip()
            if text:
                return text
        except Exception:
            continue
    return ""

def _scroll_into_view(css_selector):
    try:
        el = driver.find_element(By.CSS_SELECTOR, css_selector)
        driver.execute_script("arguments[0].scrollIntoView({block: 'center'});", el)
        jitter_sleep(1)
    except Exception:
        pass

# def _expand_about_if_collapsed():
#     # Try common variants of the "show more" button in About
#     candidates = [
#         (By.CSS_SELECTOR, "section[id^='about'] button[aria-label*='more']"),
#         (By.CSS_SELECTOR, "section[id*='about'] button[aria-label*='more']"),
#         (By.XPATH, "//section[contains(@id,'about')]//button[contains(@aria-label,'more')]"),
#         (By.XPATH, "//section[contains(@id,'about')]//button[contains(text(),'more')]"),
#         (By.CSS_SELECTOR, "section[id*='about'] button[class*='inline-show-more-text']"),
#     ]
#     for by, sel in candidates:
#         try:
#             btn = driver.find_element(by, sel)
#             if btn.is_displayed():
#                 driver.execute_script("arguments[0].scrollIntoView({block: 'center'});", btn)
#                 jitter_sleep(0.5)
#                 driver.execute_script("arguments[0].click();", btn)
#                 jitter_sleep(1.5)
#                 break
#         except Exception:
#             continue

def scrape_profile(url):
    print(f"\n=== Starting Profile Scrape: {url} ===")
    print("1. Loading profile page...")
    driver.get(url)
    
    print("2. Waiting for initial page load...")
    if WebDriverWait and EC:
        try:
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.TAG_NAME, "body"))
            )
            print("   ✓ Basic page structure loaded")
        except Exception:
            print("   ⚠ Timeout waiting for basic page load")
    jitter_sleep(3)
    
    print("3. Ensuring page is scrolled to top...")
    driver.execute_script("window.scrollTo(0, 0);")
    jitter_sleep(1)
    
    print("4. Waiting for main content...")
    if WebDriverWait and EC:
        try:
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, "main, [role='main']"))
            )
            print("   ✓ Main content area detected")
        except Exception:
            print("   ⚠ Timeout waiting for main content")
    jitter_sleep(2)

    # If we hit an auth wall or public join page, try one re-login, then bail
    print("5. Checking for auth/login walls...")
    if _is_authwall_or_join_page():
        print("   ⚠ Auth wall detected! Attempting re-login...")
        if not _retry_login_and_reload(url):
            print("   ✕ Re-login failed - cannot access profile")
            raise RuntimeError("Encountered LinkedIn auth wall / join page")
        print("   ✓ Re-login successful")
    else:
        print("   ✓ Profile page accessible")

    data = {"url": url}
    print("\n6. Scraping profile data...")
    try:
        print("   - Scrolling to profile header...")
        _scroll_into_view("div[data-view-name='profile-topcard'], section.pv-top-card")
        
        print("   - Waiting for name section...")
        if WebDriverWait and EC:
            try:
                WebDriverWait(driver, 8).until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, "h1, .text-heading-xlarge"))
                )
                print("     ✓ Name section loaded")
            except Exception:
                print("     ⚠ Timeout waiting for name section")
        print("   - Extracting name...")
        topcard_name_selectors = [
            (By.CSS_SELECTOR, "div[data-view-name='profile-topcard'] h1"),
            (By.CSS_SELECTOR, "section.pv-top-card h1"),
            (By.CSS_SELECTOR, ".text-heading-xlarge"),
            (By.CSS_SELECTOR, "main h1"),
            (By.CSS_SELECTOR, "h1"),
        ]
        data["name"] = _get_first_text(topcard_name_selectors)
        if data["name"]:
            print(f"     ✓ Found name: {data['name']}")
        else:
            print("     ⚠ Could not find name")
    except (NoSuchElementException, Exception) as e:
        data["name"] = ""
        print(f"     ✕ Error getting name: {str(e)}")
    print("   - Looking for headline...")
    if WebDriverWait and EC:
        try:
            WebDriverWait(driver, 5).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, ".text-body-medium, .top-card-layout__headline"))
            )
            print("     ✓ Headline section loaded")
        except Exception:
            print("     ⚠ Timeout waiting for headline section")
    
    headline_selectors = [
        (By.CSS_SELECTOR, "div[data-view-name='profile-topcard'] div.text-body-medium"),
        (By.CSS_SELECTOR, "div.text-body-medium.break-words"),
        (By.CSS_SELECTOR, ".top-card-layout__headline"),
        (By.CSS_SELECTOR, ".pv-text-details__left-panel .text-body-medium"),
        (By.CSS_SELECTOR, "section.pv-top-card div.text-body-medium"),
        (By.CSS_SELECTOR, ".text-body-medium"),
    ]
    data["headline"] = _get_first_text(headline_selectors)
    if data["headline"]:
        print(f"     ✓ Found headline: {data['headline']}")
    else:
        print("     ⚠ Could not find headline")
        
        
        
    # Location scraping disabled per request
    # data["location"] = ""
    # # About scraping disabled per request
    # data["about"] = ""
    # print("   - Collecting experience entries...")
    # experiences = []
    # try:
    #     _scroll_into_view("section[id*='experience']")
    #     print("     ✓ Scrolled to experience section")
    #     exp_elems = driver.find_elements(By.CSS_SELECTOR, "section[id*='experience'] li")
    #     if exp_elems:
    #         print(f"     ✓ Found {len(exp_elems)} experience entries")
    #         for i, e in enumerate(exp_elems[:5], 1):
    #             exp_text = e.text.replace("\n", " | ")
    #             experiences.append(exp_text)
    #             print(f"       {i}. {exp_text[:100]}...")
    #     else:
    #         print("     ⚠ No experience entries found")
    # except Exception as e:
    #     print(f"     ✕ Error getting experiences: {str(e)}")
    
    # data["experiences"] = " || ".join(experiences)
    # print("\n=== Profile Scrape Complete ===")
    return data

def parse_args():
    parser = argparse.ArgumentParser(description="LinkedIn profile scraper")
    parser.add_argument("--email", dest="email", help="LinkedIn email")
    parser.add_argument("--password", dest="password", help="LinkedIn password")
    parser.add_argument("--proxy", dest="proxy", help="Proxy URL, e.g. http://user:pass@host:port")
    parser.add_argument("--headless", dest="headless", action="store_true", help="Run Chrome in headless mode")
    return parser.parse_args()

def resolve_credentials(args):
    load_dotenv()  # no-op if unavailable
    email = args.email or os.getenv("LINKEDIN_EMAIL")
    password = args.password or os.getenv("LINKEDIN_PASSWORD")
    if not email:
        email = input("Enter your LinkedIn email: ")
    if not password:
        password = input("Enter your LinkedIn password: ")
    # Keep last credentials for potential mid-run re-login
    global _LAST_EMAIL, _LAST_PASSWORD
    _LAST_EMAIL, _LAST_PASSWORD = email, password
    return email, password

def resolve_runtime_options(args):
    proxy = args.proxy or os.getenv("HTTP_PROXY")
    headless_env = os.getenv("HEADLESS", "").lower() in ("1", "true", "yes")
    headless = args.headless or headless_env
    return proxy, headless

def main():
    global driver
    print("\n=== LinkedIn Profile Scraper Starting ===")
    
    print("\n1. Initializing...")
    args = parse_args()
    email, password = resolve_credentials(args)
    proxy, headless = resolve_runtime_options(args)
    
    print("\n2. Setting up Chrome driver...")
    driver = create_driver(proxy_url=proxy, headless=headless)
    print("   ✓ Chrome driver initialized")
    
    try:
        print("\n3. Starting login process...")
        login(email, password)
        
        print("\n4. Reading profile URLs...")
        with open(INPUT) as f:
            urls = [l.strip() for l in f if l.strip()]
        print(f"   ✓ Found {len(urls)} URLs to process")
        
        rows = []
        print("\n5. Beginning profile scraping...")
        for idx, url in enumerate(urls, 1):
            print(f"\n--- Processing Profile {idx}/{len(urls)} ---")
            try:
                profile_data = scrape_profile(url)
                rows.append(profile_data)
                print(f"   ✓ Successfully scraped profile {idx}")
            except Exception as e:
                print(f"   ✕ Error scraping profile {idx}: {str(e)}")
                jitter_sleep(2)
                print("   Adding empty row for failed profile")
                rows.append({
                    "url": url,
                    "name": "",
                    "headline": "",
                    "location": "",
                    "about": "",
                    "experiences": "",
                })
                
        print("\n6. Saving results to CSV...")
        with open(OUTPUT, "w", newline="", encoding="utf-8") as csvfile:
            fieldnames = ["url","name","headline","location","about","experiences"]
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            for r in rows:
                writer.writerow(r)
        print(f"   ✓ Data saved to: {OUTPUT}")
        print(f"   ✓ Processed {len(rows)} profiles total")
        
        print("\n=== LinkedIn Profile Scraper Complete ===\n")
    finally:
        try:
            if driver is not None:
                driver.quit()
        except Exception:
            pass

if __name__ == "__main__":
    main()
