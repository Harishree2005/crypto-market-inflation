# ============================================================
# STAGE 3: DATA ACQUISITION (FINAL FIXED VERSION)
# ============================================================

library(httr)
library(jsonlite)
library(dplyr)
library(readr)
library(lubridate)
library(dotenv)

cat("🚀 Starting Data Acquisition...\n")

# ─────────────────────────────────────────────────────────────
# CREATE REQUIRED FOLDERS
# ─────────────────────────────────────────────────────────────
dir.create("data",recursive=TRUE,showWarnings=FALSE)
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("logs", recursive = TRUE, showWarnings = FALSE)

# ─────────────────────────────────────────────────────────────
# LOAD API KEYS
# ─────────────────────────────────────────────────────────────
load_dot_env(".env")

cmc_key  <- Sys.getenv("CMC_API_KEY")
fred_key <- Sys.getenv("FRED_API_KEY")

if (cmc_key == "") stop("❌ Missing CMC API Key")
if (fred_key == "") stop("❌ Missing FRED API Key")

cat("✅ API keys loaded\n")

# ─────────────────────────────────────────────────────────────
# API LOGGER
# ─────────────────────────────────────────────────────────────
log_api <- function(endpoint, status, rows) {
  msg <- paste(Sys.time(), "|", endpoint, "|", status, "|", rows)
  write(msg, "logs/api_calls.log", append = TRUE)
  cat("📡", msg, "\n")
}

# ============================================================
# PART 1: COINMARKETCAP (TOP 200)
# ============================================================

fetch_cmc <- function() {
  
  all_data <- list()
  
  for (start in c(1, 101)) {
    
    cat("🔄 Fetching coins", start, "to", start + 99, "\n")
    
    res <- tryCatch({
      GET(
        "https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest",
        add_headers("X-CMC_PRO_API_KEY" = cmc_key),
        query = list(start = start, limit = 100, convert = "USD"),
        timeout(20)
      )
    }, error = function(e) NULL)
    
    if (is.null(res) || status_code(res) != 200) {
      cat("❌ Failed at", start, "\n")
      next
    }
    
    txt <- content(res, "text", encoding = "UTF-8")
    data <- fromJSON(txt, flatten = TRUE)$data
    
    df <- data.frame(
      id     = data$id,
      name   = data$name,
      symbol = data$symbol,
      rank   = data$cmc_rank,
      
      price      = data$quote.USD.price,
      market_cap = data$quote.USD.market_cap,
      volume_24h = data$quote.USD.volume_24h,
      
      change_24h = data$quote.USD.percent_change_24h,
      change_7d  = data$quote.USD.percent_change_7d,
      
      last_updated = data$quote.USD.last_updated,
      stringsAsFactors = FALSE
    )
    
    all_data[[length(all_data) + 1]] <- df
    log_api(paste0("CMC_", start), status_code(res), nrow(df))
    
    Sys.sleep(1)
  }
  
  bind_rows(all_data)
}

crypto <- fetch_cmc()
write_csv(crypto, "data/raw/crypto_listings.csv")
cat("✅ Saved crypto listings\n")

# ============================================================
# PART 2: COINCAP (HISTORICAL)
# ============================================================

fetch_history <- function(coin) {
  
  cat("🔄 Fetching history:", coin, "\n")
  
  end   <- as.numeric(Sys.time()) * 1000
  start <- end - (365 * 24 * 60 * 60 * 1000)
  
  res <- tryCatch({
    GET(
      paste0("https://api.coincap.io/v2/assets/", coin, "/history"),
      query = list(interval = "d1", start = start, end = end),
      timeout(20)
    )
  }, error = function(e) NULL)
  
  if (is.null(res) || status_code(res) != 200) {
    cat("❌ Failed:", coin, "\n")
    return(NULL)
  }
  
  txt <- content(res, "text", encoding = "UTF-8")
  data <- fromJSON(txt)$data
  
  if (is.null(data) || nrow(data) == 0) {
    cat("⚠ No data for:", coin, "\n")
    return(NULL)
  }
  
  df <- data.frame(
    date   = as.Date(as.POSIXct(data$time / 1000, origin = "1970-01-01")),
    price  = as.numeric(data$priceUsd),
    volume = as.numeric(data$volumeUsd),
    coin   = coin
  )
  
  log_api(paste0("CoinCap_", coin), status_code(res), nrow(df))
  return(df)
}

coins <- c("bitcoin", "ethereum", "solana", "binance-coin", "tether")

history <- bind_rows(lapply(coins, function(cn) {
  Sys.sleep(0.5)
  fetch_history(cn)
}))

write_csv(history, "data/raw/historical_prices.csv")
cat("✅ Saved historical data\n")

# ============================================================
# PART 3: FRED MACRO DATA
# ============================================================

fetch_fred <- function(series) {
  
  cat("🔄 Fetching FRED:", series, "\n")
  
  res <- GET(
    "https://api.stlouisfed.org/fred/series/observations",
    query = list(
      series_id = series,
      api_key   = fred_key,
      file_type = "json"
    )
  )
  
  if (status_code(res) != 200) {
    cat("❌ Failed FRED:", series, "\n")
    return(NULL)
  }
  
  txt <- content(res, "text", encoding = "UTF-8")
  data <- fromJSON(txt)$observations
  
  if (is.null(data) || nrow(data) == 0) {
    cat("⚠ No FRED data for:", series, "\n")
    return(NULL)
  }
  
  df <- data.frame(
    date   = as.Date(data$date),
    value  = suppressWarnings(as.numeric(data$value)),
    series = series
  )
  
  log_api(paste0("FRED_", series), status_code(res), nrow(df))
  return(df)
}

fred <- bind_rows(
  fetch_fred("CPIAUCSL"),
  fetch_fred("FEDFUNDS")
)

write_csv(fred, "data/raw/fred_macro.csv")
cat("✅ Saved macro data\n")

# ============================================================
# FINAL
# ============================================================

cat("\n🎉 STAGE 3 COMPLETE!\n")
cat("Files created:\n")
cat(" - data/raw/crypto_listings.csv\n")
cat(" - data/raw/historical_prices.csv\n")
cat(" - data/raw/fred_macro.csv\n")
cat(" - logs/api_calls.log\n")