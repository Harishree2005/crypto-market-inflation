# ============================================================
# STAGE 5: PREPROCESSING & FEATURE ENGINEERING
# ============================================================

library(dplyr)
library(tidyr)
library(readr)
library(lubridate)
library(zoo)
library(stringr)

cat("🔄 Starting preprocessing...\n")

# ── CREATE FOLDER ────────────────────────────────────────────
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

# ── LOAD RAW DATA ────────────────────────────────────────────
cat("\n📂 Loading raw data files...\n")

crypto   <- read_csv("data/raw/crypto_listings.csv",   show_col_types = FALSE)
history  <- read_csv("data/raw/historical_prices.csv", show_col_types = FALSE)
fred     <- read_csv("data/raw/fred_macro.csv",        show_col_types = FALSE)
news     <- read_csv("data/raw/news_headlines.csv",    show_col_types = FALSE)

cat("✅ Loaded crypto listings:  ", nrow(crypto),  "rows\n")
cat("✅ Loaded historical prices:", nrow(history), "rows\n")
cat("✅ Loaded FRED macro:       ", nrow(fred),    "rows\n")
cat("✅ Loaded news headlines:   ", nrow(news),    "rows\n")


# ════════════════════════════════════════════════════════════════
# PART 1: CLEAN CRYPTO LISTINGS
# ════════════════════════════════════════════════════════════════

cat("\n🧹 Cleaning crypto listings...\n")

# add missing columns safely if absent
if (!"change_1h" %in% names(crypto)) crypto$change_1h <- NA
if (!"change_30d" %in% names(crypto)) crypto$change_30d <- NA
if (!"max_supply" %in% names(crypto)) crypto$max_supply <- NA
if (!"circulating_supply" %in% names(crypto)) crypto$circulating_supply <- NA

crypto_clean <- crypto %>%
  filter(!is.na(price), price > 0) %>%
  filter(!is.na(market_cap), market_cap > 0) %>%
  mutate(
    last_updated = as.Date(substr(last_updated, 1, 10)),
    
    market_cap_bil = round(market_cap / 1e9, 4),
    volume_bil     = round(volume_24h / 1e9, 4),
    volatility_score = abs(change_24h),
    
    supply_used_pct = ifelse(
      !is.na(max_supply) & max_supply > 0 & !is.na(circulating_supply),
      round(circulating_supply / max_supply * 100, 2),
      NA
    ),
    
    momentum = change_7d - change_1h,
    volume_to_mcap = round(volume_24h / market_cap * 100, 4),
    
    category = case_when(
      rank <= 10  ~ "Top 10",
      rank <= 50  ~ "Top 50",
      rank <= 100 ~ "Top 100",
      TRUE        ~ "Top 200"
    ),
    
    trend_24h = case_when(
      change_24h >= 5   ~ "Strong Up",
      change_24h >= 1   ~ "Up",
      change_24h >= -1  ~ "Stable",
      change_24h >= -5  ~ "Down",
      TRUE              ~ "Strong Down"
    )
  ) %>%
  select(rank, id, name, symbol, category, price, market_cap_bil,
         volume_bil, change_1h, change_24h, change_7d, change_30d,
         volatility_score, momentum, volume_to_mcap, supply_used_pct,
         trend_24h, last_updated)

cat("✅ Crypto listings cleaned:", nrow(crypto_clean), "rows,",
    ncol(crypto_clean), "columns\n")

# missing report
missing_report <- crypto_clean %>%
  summarise(across(everything(), ~sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "column", values_to = "missing_count") %>%
  filter(missing_count > 0)

if (nrow(missing_report) > 0) {
  cat("\n⚠️ Missing values found:\n")
  print(missing_report)
} else {
  cat("✅ No missing values in key columns\n")
}


# ════════════════════════════════════════════════════════════════
# PART 2: CLEAN HISTORICAL PRICES
# ════════════════════════════════════════════════════════════════

cat("\n🧹 Cleaning historical price data...\n")

history_clean <- history %>%
  filter(!is.na(price), price > 0) %>%
  mutate(date = as.Date(date)) %>%
  arrange(coin, date) %>%
  group_by(coin) %>%
  mutate(
    ma_7d = round(rollmean(price, k = 7, fill = NA, align = "right"), 2),
    ma_30d = round(rollmean(price, k = 30, fill = NA, align = "right"), 2),
    daily_return = round((price - lag(price)) / lag(price) * 100, 4),
    volatility_30d = round(
      rollapply(daily_return, width = 30, FUN = sd, fill = NA, align = "right"),
      4
    ),
    cumulative_return = round((price / first(price) - 1) * 100, 2),
    price_vs_ma30 = round(price / ma_30d, 4)
  ) %>%
  ungroup()

cat("✅ Historical data cleaned:", nrow(history_clean), "rows,",
    ncol(history_clean), "columns\n")


# ════════════════════════════════════════════════════════════════
# PART 3: CLEAN FRED MACRO DATA
# ════════════════════════════════════════════════════════════════

cat("\n🧹 Cleaning FRED macro data...\n")

fred_wide <- fred %>%
  filter(!is.na(value), !is.na(date)) %>%
  mutate(date = as.Date(date)) %>%
  pivot_wider(
    names_from = series,
    values_from = value
  ) %>%
  arrange(date) %>%
  fill(everything(), .direction = "down")

# rename safely
if ("CPIAUCSL" %in% names(fred_wide)) {
  fred_wide <- fred_wide %>% rename(cpi = CPIAUCSL)
}
if ("FEDFUNDS" %in% names(fred_wide)) {
  fred_wide <- fred_wide %>% rename(fed_rate = FEDFUNDS)
}

fred_wide <- fred_wide %>%
  mutate(
    cpi_change = round(cpi - lag(cpi), 4),
    inflation_trend = case_when(
      cpi_change > 0  ~ "Rising",
      cpi_change < 0  ~ "Falling",
      TRUE            ~ "Stable"
    ),
    rate_trend = case_when(
      fed_rate > lag(fed_rate) ~ "Hiking",
      fed_rate < lag(fed_rate) ~ "Cutting",
      TRUE                     ~ "Holding"
    )
  )

cat("✅ FRED macro cleaned:", nrow(fred_wide), "rows\n")


# ════════════════════════════════════════════════════════════════
# PART 4: MERGE BTC HISTORY + MACRO DATA
# ════════════════════════════════════════════════════════════════

cat("\n🔗 Merging Bitcoin history with macro data...\n")

btc_macro <- history_clean %>%
  filter(coin == "bitcoin") %>%
  left_join(fred_wide, by = "date") %>%
  fill(cpi, fed_rate, cpi_change, inflation_trend, rate_trend,
       .direction = "down") %>%
  filter(!is.na(cpi), !is.na(fed_rate)) %>%
  mutate(
    cpi_lag30 = lag(cpi, 30),
    fed_rate_lag30 = lag(fed_rate, 30),
    real_rate = round(fed_rate - (cpi_change * 12), 4)
  )

cat("✅ BTC + Macro merged:", nrow(btc_macro), "rows,",
    ncol(btc_macro), "columns\n")


# ════════════════════════════════════════════════════════════════
# PART 5: SAVE ALL PROCESSED FILES
# ════════════════════════════════════════════════════════════════

cat("\n💾 Saving processed files...\n")

write_csv(crypto_clean,  "data/processed/crypto_clean.csv")
write_csv(history_clean, "data/processed/history_clean.csv")
write_csv(fred_wide,     "data/processed/fred_macro_clean.csv")
write_csv(btc_macro,     "data/processed/btc_macro.csv")

cat("✅ Saved: data/processed/crypto_clean.csv\n")
cat("✅ Saved: data/processed/history_clean.csv\n")
cat("✅ Saved: data/processed/fred_macro_clean.csv\n")
cat("✅ Saved: data/processed/btc_macro.csv\n")

# ── FINAL SUMMARY ─────────────────────────────────────────────
cat("\n", paste(rep("═", 50), collapse=""), "\n")
cat("✅ STAGE 5 COMPLETE — PREPROCESSING SUMMARY\n")
cat(paste(rep("═", 50), collapse=""), "\n")
cat("📊 crypto_clean:   ", nrow(crypto_clean),  "rows,", ncol(crypto_clean),  "cols\n")
cat("📈 history_clean:  ", nrow(history_clean), "rows,", ncol(history_clean), "cols\n")
cat("📉 fred_macro:     ", nrow(fred_wide),     "rows,", ncol(fred_wide),     "cols\n")
cat("🔗 btc_macro:      ", nrow(btc_macro),     "rows,", ncol(btc_macro),     "cols\n")
cat(paste(rep("═", 50), collapse=""), "\n")