# ============================================================
# STAGE 5: NEWS SCRAPING + SENTIMENT ANALYSIS (SAFE VERSION)
# ============================================================

library(rvest)
library(httr)
library(dplyr)
library(readr)
library(stringr)
library(syuzhet)

cat("📰 Starting Crypto News Sentiment Collection...\n")

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# SAFE SCRAPER FUNCTION
# ------------------------------------------------------------
scrape_page <- function(url, page_no) {
  cat("🌐 Scraping page", page_no, ":", url, "\n")
  
  page <- tryCatch({
    read_html(url)
  }, error = function(e) {
    cat("❌ Error scraping page", page_no, ":", e$message, "\n")
    return(NULL)
  })
  
  if (is.null(page)) return(NULL)
  
  headlines <- page %>%
    html_elements("a span, h2, h3, .post-card-inline__title") %>%
    html_text(trim = TRUE)
  
  headlines <- headlines[nchar(headlines) > 30]
  headlines <- unique(headlines)
  
  if (length(headlines) == 0) {
    cat("⚠ No headlines found on page", page_no, "\n")
    return(NULL)
  }
  
  df <- data.frame(
    headline = headlines,
    source = "Cointelegraph",
    page = page_no,
    stringsAsFactors = FALSE
  )
  
  cat("✅ Found", nrow(df), "headlines\n")
  Sys.sleep(2)
  return(df)
}

# ------------------------------------------------------------
# TRY MULTIPLE PAGES (but tolerate failures)
# ------------------------------------------------------------
urls <- c(
  "https://cointelegraph.com/tags/bitcoin",
  "https://cointelegraph.com/tags/ethereum",
  "https://cointelegraph.com/tags/solana"
)

all_headlines <- bind_rows(lapply(seq_along(urls), function(i) {
  scrape_page(urls[i], i)
}))

# ------------------------------------------------------------
# FALLBACK IF SCRAPING FAILS
# ------------------------------------------------------------
if (nrow(all_headlines) == 0) {
  cat("⚠ Live scraping failed. Using fallback sample headlines...\n")
  
  all_headlines <- data.frame(
    headline = c(
      "Bitcoin price surges as institutional demand rises",
      "Ethereum network upgrade boosts investor confidence",
      "Solana gains momentum in DeFi ecosystem",
      "Crypto market volatility increases amid macro uncertainty",
      "Stablecoins remain resilient during market fluctuations",
      "Analysts predict bullish momentum for major cryptocurrencies",
      "Federal Reserve policy impacts digital asset sentiment",
      "Bitcoin ETF inflows strengthen crypto market outlook"
    ),
    source = "Fallback",
    page = 0,
    stringsAsFactors = FALSE
  )
}

# ------------------------------------------------------------
# CLEAN HEADLINES
# ------------------------------------------------------------
headlines_clean <- all_headlines %>%
  distinct(headline, .keep_all = TRUE) %>%
  filter(!str_detect(headline, "^$")) %>%
  mutate(
    sentiment_score = get_sentiment(headline, method = "syuzhet"),
    sentiment_label = case_when(
      sentiment_score > 0 ~ "Positive",
      sentiment_score < 0 ~ "Negative",
      TRUE ~ "Neutral"
    )
  )

# ------------------------------------------------------------
# SAVE
# ------------------------------------------------------------
write_csv(headlines_clean, "data/raw/news_headlines.csv")

cat("\n✅ Web scraping complete!\n")
cat("📰 Headlines collected:", nrow(headlines_clean), "\n")
cat("😊 Positive:", sum(headlines_clean$sentiment_label == "Positive"), "\n")
cat("😐 Neutral:", sum(headlines_clean$sentiment_label == "Neutral"), "\n")
cat("😟 Negative:", sum(headlines_clean$sentiment_label == "Negative"), "\n")