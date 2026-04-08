# ============================================================
# STAGE 6: EXPLORATORY DATA ANALYSIS & VISUALIZATIONS
# Creates 7 publication-quality charts using ggplot2
# All saved to visuals/ folder
# ============================================================

library(ggplot2)
library(dplyr)
library(readr)
library(scales)
library(corrplot)
library(treemapify)
library(gridExtra)
library(RColorBrewer)

cat("📊 Starting EDA and visualization...\n")

# Load processed data
crypto  <- read_csv("data/processed/crypto_clean.csv",   show_col_types = FALSE)
history <- read_csv("data/processed/history_clean.csv",  show_col_types = FALSE)
btc     <- read_csv("data/processed/btc_macro.csv",      show_col_types = FALSE)

# ── CUSTOM DARK THEME ─────────────────────────────────────────────
# Professional dark theme for all charts
theme_crypto <- theme_minimal(base_size = 13) +
  theme(
    plot.title       = element_text(face = "bold", hjust = 0.5,
                                    size = 16, color = "white"),
    plot.subtitle    = element_text(hjust = 0.5, color = "grey70", size = 11),
    plot.caption     = element_text(color = "grey50", size = 9),
    plot.background  = element_rect(fill = "#0f1117", color = NA),
    panel.background = element_rect(fill = "#0f1117", color = NA),
    panel.grid.major = element_line(color = "#1e2130", linewidth = 0.5),
    panel.grid.minor = element_blank(),
    text             = element_text(color = "white"),
    axis.text        = element_text(color = "grey70"),
    axis.title       = element_text(color = "grey90"),
    legend.background = element_rect(fill = "#0f1117"),
    legend.text      = element_text(color = "grey80"),
    legend.title     = element_text(color = "white")
  )


# ════════════════════════════════════════════════════════════════
# PLOT 1: Bitcoin Price with Moving Averages
# Shows price trend + 7d and 30d smoothed averages
# ════════════════════════════════════════════════════════════════

cat("📈 Creating Plot 1: BTC price with moving averages...\n")

btc_plot <- history %>%
  filter(coin == "bitcoin") %>%
  filter(!is.na(ma_7d), !is.na(ma_30d))

p1 <- ggplot(btc_plot, aes(x = date)) +
  
  # Shaded area under price line
  geom_area(aes(y = price), fill = "#f7931a", alpha = 0.1) +
  
  # Actual price line
  geom_line(aes(y = price, color = "Actual Price"), linewidth = 0.8) +
  
  # 7-day moving average
  geom_line(aes(y = ma_7d,  color = "7-Day MA"),  linewidth = 1.0, linetype = "dashed") +
  
  # 30-day moving average
  geom_line(aes(y = ma_30d, color = "30-Day MA"), linewidth = 1.0, linetype = "dotted") +
  
  # Color scheme
  scale_color_manual(values = c(
    "Actual Price" = "#f7931a",
    "7-Day MA"     = "#00d4ff",
    "30-Day MA"    = "#ff6b6b"
  )) +
  
  # Y-axis in dollar format
  scale_y_continuous(labels = dollar_format(scale = 1e-3, suffix = "K")) +
  
  # Labels
  labs(
    title    = "Bitcoin Price Trend with Moving Averages",
    subtitle = "365-Day View | Orange=Actual | Blue=7D MA | Red=30D MA",
    x        = "Date",
    y        = "Price (USD)",
    color    = "Legend",
    caption  = "Source: CoinCap API"
  ) +
  theme_crypto

ggsave("visuals/p1_btc_price_ma.png", p1, width = 14, height = 6,
       dpi = 150, bg = "#0f1117")
cat("✅ Saved: visuals/p1_btc_price_ma.png\n")


# ════════════════════════════════════════════════════════════════
# PLOT 2: Market Cap Treemap — Top 20 Coins
# Each box = one coin, size = market cap, color = 24h change
# ════════════════════════════════════════════════════════════════

cat("📊 Creating Plot 2: Market cap treemap...\n")

top20 <- crypto %>%
  top_n(20, market_cap_bil) %>%
  mutate(label = paste0(symbol, "\n$", round(market_cap_bil, 1), "B"))

p2 <- ggplot(top20, aes(
  area  = market_cap_bil,
  fill  = change_24h,
  label = label
)) +
  geom_treemap() +
  geom_treemap_text(
    color    = "white",
    fontface = "bold",
    place    = "centre",
    size     = 10
  ) +
  scale_fill_gradient2(
    low      = "#ff4444",
    mid      = "grey30",
    high     = "#00cc44",
    midpoint = 0,
    labels   = function(x) paste0(x, "%")
  ) +
  labs(
    title    = "Top 20 Cryptocurrencies — Market Cap Treemap",
    subtitle = "Box size = Market Cap | Color = 24h % Change",
    fill     = "24h Change",
    caption  = "Source: CoinMarketCap API"
  ) +
  theme_crypto +
  theme(legend.position = "right")

ggsave("visuals/p2_treemap.png", p2, width = 12, height = 7,
       dpi = 150, bg = "#0f1117")
cat("✅ Saved: visuals/p2_treemap.png\n")


# ════════════════════════════════════════════════════════════════
# PLOT 3: Correlation Heatmap
# Shows relationships between all numeric variables
# ════════════════════════════════════════════════════════════════

cat("🔥 Creating Plot 3: Correlation heatmap...\n")

corr_vars <- crypto %>%
  select(
    Price        = price,
    Volume_24h   = volume_bil,
    Market_Cap   = market_cap_bil,
    Change_1h    = change_1h,
    Change_24h   = change_24h,
    Change_7d    = change_7d,
    Volatility   = volatility_score,
    Momentum     = momentum,
    Vol_to_MCap  = volume_to_mcap
  )

# Keep numeric only
corr_vars <- corr_vars %>% select(where(is.numeric))

# Remove columns with all NA
corr_vars <- corr_vars[, colSums(!is.na(corr_vars)) > 5, drop = FALSE]

# Remove constant columns
corr_vars <- corr_vars[, sapply(corr_vars, function(x) length(unique(na.omit(x))) > 1), drop = FALSE]

# Safe correlation
if (ncol(corr_vars) >= 2) {
  
  corr_matrix <- cor(corr_vars, use = "pairwise.complete.obs")
  
  corr_matrix[is.na(corr_matrix)] <- 0
  corr_matrix[is.infinite(corr_matrix)] <- 0
  
} else {
  stop("❌ Not enough valid data for correlation matrix")
}

png("visuals/p3_correlation_heatmap.png",
    width = 900, height = 800, bg = "#0f1117")
par(bg = "#0f1117", col.main = "white", col.lab = "white")

corrplot(
  corr_matrix,
  method     = "color",
  type       = "upper",
  tl.col     = "white",
  tl.cex     = 0.9,
  col        = colorRampPalette(c("#ff4444", "#0f1117", "#00cc44"))(200),
  addCoef.col = "white",
  number.cex  = 0.7,
  title       = "Cryptocurrency Feature Correlation Matrix",
  mar         = c(0, 0, 2, 0)
)
dev.off()
cat("✅ Saved: visuals/p3_correlation_heatmap.png\n")


# ════════════════════════════════════════════════════════════════
# PLOT 4: Volatility Distribution by Category
# Shows which market cap tiers are most volatile
# ════════════════════════════════════════════════════════════════

cat("📉 Creating Plot 4: Volatility distribution...\n")

p4 <- ggplot(crypto, aes(x = volatility_score, fill = category)) +
  
  geom_histogram(
    bins     = 35,
    alpha    = 0.85,
    position = "stack",
    color    = "transparent"
  ) +
  
  # Vertical line at median
  geom_vline(
    xintercept = median(crypto$volatility_score, na.rm = TRUE),
    color = "white", linetype = "dashed", linewidth = 0.8
  ) +
  
  annotate("text",
           x     = median(crypto$volatility_score, na.rm = TRUE) + 0.5,
           y     = Inf, vjust = 2,
           label = paste0("Median: ",
                          round(median(crypto$volatility_score, na.rm = TRUE), 1), "%"),
           color = "white", size = 3.5
  ) +
  
  scale_fill_manual(values = c(
    "Top 10"  = "#f7931a",
    "Top 50"  = "#627eea",
    "Top 100" = "#00d4ff",
    "Top 200" = "#9945ff"
  )) +
  
  scale_x_continuous(labels = function(x) paste0(x, "%")) +
  
  labs(
    title    = "Volatility Distribution Across Market Cap Categories",
    subtitle = "Volatility = Absolute 24h % Change",
    x        = "Volatility Score (|24h % Change|)",
    y        = "Number of Coins",
    fill     = "Market Cap Tier",
    caption  = "Source: CoinMarketCap API"
  ) +
  theme_crypto

ggsave("visuals/p4_volatility_distribution.png", p4,
       width = 12, height = 6, dpi = 150, bg = "#0f1117")
cat("✅ Saved: visuals/p4_volatility_distribution.png\n")


# ════════════════════════════════════════════════════════════════
# PLOT 5: Normalized Price Performance Comparison
# All coins rebased to 100 on day 1 for fair comparison
# ════════════════════════════════════════════════════════════════

cat("📈 Creating Plot 5: Normalized price performance...\n")

norm_data <- history %>%
  filter(coin %in% c("bitcoin", "ethereum", "solana", "binance-coin")) %>%
  group_by(coin) %>%
  arrange(date) %>%
  mutate(
    # Normalize: start at 100, show % gain/loss from day 1
    price_norm = round(price / first(price) * 100, 2)
  ) %>%
  ungroup() %>%
  mutate(
    coin_label = case_when(
      coin == "bitcoin"      ~ "Bitcoin (BTC)",
      coin == "ethereum"     ~ "Ethereum (ETH)",
      coin == "solana"       ~ "Solana (SOL)",
      coin == "binance-coin" ~ "Binance Coin (BNB)"
    )
  )

p5 <- ggplot(norm_data, aes(x = date, y = price_norm, color = coin_label)) +
  
  # Reference line at 100 (starting point)
  geom_hline(yintercept = 100, color = "grey40",
             linetype = "dashed", linewidth = 0.6) +
  
  geom_line(linewidth = 0.9, alpha = 0.9) +
  
  annotate("text", x = min(norm_data$date), y = 102,
           label = "Start (Base = 100)", color = "grey60", size = 3) +
  
  scale_color_manual(values = c(
    "Bitcoin (BTC)"      = "#f7931a",
    "Ethereum (ETH)"     = "#627eea",
    "Solana (SOL)"       = "#9945ff",
    "Binance Coin (BNB)" = "#f0b90b"
  )) +
  
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  
  labs(
    title    = "Normalized Price Performance — 365 Days",
    subtitle = "All coins rebased to 100 on Day 1 for fair comparison",
    x        = "Date",
    y        = "Normalized Price (Base = 100)",
    color    = "Cryptocurrency",
    caption  = "Source: CoinCap API"
  ) +
  theme_crypto

ggsave("visuals/p5_normalized_performance.png", p5,
       width = 14, height = 6, dpi = 150, bg = "#0f1117")
cat("✅ Saved: visuals/p5_normalized_performance.png\n")


# ════════════════════════════════════════════════════════════════
# PLOT 6: BTC vs CPI Inflation Overlay
# Dual axis — BTC price on left, CPI on right
# ════════════════════════════════════════════════════════════════

cat("📊 Creating Plot 6: BTC vs Inflation overlay...\n")

btc_filtered <- btc %>%
  filter(!is.na(cpi), !is.na(price)) %>%
  mutate(
    # Scale CPI to BTC price range for overlay
    cpi_scaled = (cpi - min(cpi)) /
      (max(cpi) - min(cpi)) *
      (max(price) - min(price)) + min(price)
  )

p6 <- ggplot(btc_filtered, aes(x = date)) +
  
  geom_area(aes(y = price), fill = "#f7931a", alpha = 0.15) +
  geom_line(aes(y = price,      color = "Bitcoin Price"), linewidth = 0.9) +
  geom_line(aes(y = cpi_scaled, color = "CPI Inflation"), linewidth = 1.1,
            linetype = "dashed") +
  
  scale_color_manual(values = c(
    "Bitcoin Price" = "#f7931a",
    "CPI Inflation" = "#ff6b6b"
  )) +
  
  scale_y_continuous(
    name   = "Bitcoin Price (USD)",
    labels = dollar_format(),
    sec.axis = sec_axis(
      ~ (. - min(btc_filtered$price)) /
        (max(btc_filtered$price) - min(btc_filtered$price)) *
        (max(btc_filtered$cpi) - min(btc_filtered$cpi)) + min(btc_filtered$cpi),
      name = "CPI Index"
    )
  ) +
  
  labs(
    title    = "Bitcoin Price vs CPI Inflation",
    subtitle = "Analyzing the inflation hedge hypothesis",
    x        = "Date",
    color    = "Indicator",
    caption  = "Sources: CoinCap API + FRED API"
  ) +
  theme_crypto

ggsave("visuals/p6_btc_vs_inflation.png", p6,
       width = 14, height = 6, dpi = 150, bg = "#0f1117")
cat("✅ Saved: visuals/p6_btc_vs_inflation.png\n")


# ── SUMMARY STATISTICS TABLE ──────────────────────────────────────
cat("\n📋 Summary Statistics:\n")
summary_stats <- history %>%
  group_by(coin) %>%
  summarise(
    avg_price    = round(mean(price, na.rm = TRUE), 2),
    max_price    = round(max(price,  na.rm = TRUE), 2),
    min_price    = round(min(price,  na.rm = TRUE), 2),
    avg_return   = round(mean(daily_return, na.rm = TRUE), 4),
    avg_volatility = round(mean(volatility_30d, na.rm = TRUE), 4),
    .groups = "drop"
  )
print(summary_stats)
write_csv(summary_stats, "data/processed/summary_stats.csv")

cat("\n", paste(rep("═", 50), collapse=""), "\n")
cat("✅ STAGE 6 COMPLETE — 6 visualizations saved to visuals/\n")
cat(paste(rep("═", 50), collapse=""), "\n")