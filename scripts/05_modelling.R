# ============================================================
# STAGE 7: PREDICTIVE MODELLING
#
# Model 1 — ARIMA: Bitcoin 30-day price forecast
# Model 2 — Random Forest: BTC price prediction using macro
# Model 3 — K-Means: Cluster 200 coins by behavior
# ============================================================

library(forecast)      # ARIMA
library(randomForest)  # Random Forest
library(cluster)       # K-means
library(factoextra)    # Cluster visualization
library(dplyr)
library(readr)
library(ggplot2)
library(Metrics)       # RMSE calculation
library(caret)         # Train/test split

cat("🤖 Starting modelling...\n")

# Load data
btc    <- read_csv("data/processed/btc_macro.csv",    show_col_types = FALSE)
crypto <- read_csv("data/processed/crypto_clean.csv", show_col_types = FALSE)


# ════════════════════════════════════════════════════════════════
# MODEL 1: ARIMA — Bitcoin 30-Day Price Forecast
# ARIMA = AutoRegressive Integrated Moving Average
# Best for time series data like daily prices
# ════════════════════════════════════════════════════════════════

cat("\n📈 Model 1: ARIMA Time Series Forecasting...\n")

# Prepare time series — use only BTC price column
btc_prices <- btc %>%
  arrange(date) %>%
  filter(!is.na(price)) %>%
  pull(price)

# Split into train (80%) and test (20%)
n          <- length(btc_prices)
train_size <- floor(0.8 * n)
train_ts   <- ts(btc_prices[1:train_size],         frequency = 7)
test_ts    <- ts(btc_prices[(train_size + 1):n],   frequency = 7)

cat("  📊 Training on", train_size, "days, testing on", n - train_size, "days\n")

# Fit ARIMA — auto.arima() finds the best p,d,q parameters
cat("  🔄 Fitting ARIMA model (this takes ~30 seconds)...\n")
arima_model <- auto.arima(
  train_ts,
  seasonal     = TRUE,
  stepwise     = FALSE,   # Test more models (better accuracy)
  approximation = FALSE
)

cat("  ✅ ARIMA model fitted:", arima_model$arma, "\n")
cat("  📋 Model summary:\n")
print(summary(arima_model))

# Forecast 30 days ahead
forecast_30 <- forecast(arima_model, h = 30)

# Evaluate on test set
test_forecast <- forecast(arima_model, h = length(test_ts))
rmse_arima    <- rmse(as.numeric(test_ts),
                      as.numeric(test_forecast$mean))
mae_arima     <- mae(as.numeric(test_ts),
                     as.numeric(test_forecast$mean))

cat("  📊 ARIMA Evaluation:\n")
cat("     RMSE:", round(rmse_arima, 2), "\n")
cat("     MAE: ", round(mae_arima,  2), "\n")

# Build forecast data frame for Power BI
last_date    <- max(btc$date, na.rm = TRUE)
forecast_df  <- data.frame(
  date        = seq(last_date + 1, by = "day", length.out = 30),
  predicted   = as.numeric(forecast_30$mean),
  lower_80    = as.numeric(forecast_30$lower[, 1]),
  upper_80    = as.numeric(forecast_30$upper[, 1]),
  lower_95    = as.numeric(forecast_30$lower[, 2]),
  upper_95    = as.numeric(forecast_30$upper[, 2]),
  model       = "ARIMA",
  rmse        = round(rmse_arima, 2)
)

write_csv(forecast_df, "data/processed/btc_forecast.csv")
saveRDS(arima_model,   "models/arima_btc.rds")

# Plot forecast
p_arima <- autoplot(forecast_30) +
  labs(
    title    = "Bitcoin 30-Day Price Forecast (ARIMA)",
    subtitle = paste0("RMSE: $", round(rmse_arima, 0),
                      " | MAE: $", round(mae_arima, 0)),
    x        = "Time",
    y        = "Price (USD)"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))

ggsave("visuals/p7_arima_forecast.png", p_arima,
       width = 12, height = 6, dpi = 150)
cat("  ✅ ARIMA forecast saved\n")


# ════════════════════════════════════════════════════════════════
# MODEL 2: RANDOM FOREST — Price Prediction from Macro Indicators
# Better than linear regression — captures non-linear effects
# ════════════════════════════════════════════════════════════════

cat("\n🌲 Model 2: Random Forest Regression...\n")

# Prepare features — select macro + technical indicators
rf_data <- btc %>%
  select(
    price,           # TARGET variable (what we predict)
    cpi,             # CPI inflation
    fed_rate,        # Interest rate
    volume,          # Trading volume
    ma_7d,           # 7-day moving average
    ma_30d,          # 30-day moving average
    daily_return,    # Previous day's return
    volatility_30d,  # 30-day volatility
    real_rate        # Real interest rate
  ) %>%
  na.omit()          # Remove any rows with NA

cat("  📊 Dataset for RF:", nrow(rf_data), "rows,",
    ncol(rf_data) - 1, "features\n")

# Train/Test Split (80/20)
set.seed(42)  # For reproducibility
train_idx <- createDataPartition(rf_data$price, p = 0.8, list = FALSE)
rf_train  <- rf_data[ train_idx, ]
rf_test   <- rf_data[-train_idx, ]

cat("  🔄 Training Random Forest (500 trees)...\n")

rf_model <- randomForest(
  price ~ .,          # Predict price using all other columns
  data       = rf_train,
  ntree      = 500,   # Number of trees
  mtry       = 3,     # Features to consider at each split
  importance = TRUE   # Calculate feature importance
)

# Make predictions on test set
rf_predictions <- predict(rf_model, rf_test)

# Evaluate
rmse_rf <- rmse(rf_test$price, rf_predictions)
mae_rf  <- mae(rf_test$price,  rf_predictions)
r2_rf   <- cor(rf_test$price,  rf_predictions)^2

cat("  📊 Random Forest Evaluation:\n")
cat("     RMSE:", round(rmse_rf, 2), "\n")
cat("     MAE: ", round(mae_rf,  2), "\n")
cat("     R²:  ", round(r2_rf,   4), "\n")

# Feature Importance — which variables matter most?
importance_df <- data.frame(
  feature   = rownames(importance(rf_model)),
  importance = importance(rf_model)[, "%IncMSE"],
  row.names  = NULL
) %>%
  arrange(desc(importance))

cat("\n  🏆 Feature Importance (top predictors):\n")
print(importance_df)

# Save results
rf_results <- rf_test %>%
  mutate(
    predicted = rf_predictions,
    residual  = price - predicted
  )

write_csv(rf_results,   "data/processed/rf_predictions.csv")
write_csv(importance_df,"data/processed/rf_importance.csv")
saveRDS(rf_model,       "models/rf_model.rds")

# Plot: Actual vs Predicted
p_rf <- ggplot(rf_results, aes(x = price, y = predicted)) +
  geom_point(color = "#f7931a", alpha = 0.6, size = 1.5) +
  geom_abline(slope = 1, intercept = 0, color = "white",
              linetype = "dashed", linewidth = 1) +
  scale_x_continuous(labels = dollar_format()) +
  scale_y_continuous(labels = dollar_format()) +
  labs(
    title    = "Random Forest: Actual vs Predicted BTC Price",
    subtitle = paste0("R² = ", round(r2_rf, 3),
                      " | RMSE = $", round(rmse_rf, 0)),
    x        = "Actual Price",
    y        = "Predicted Price"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))

ggsave("visuals/p8_rf_actual_vs_predicted.png", p_rf,
       width = 8, height = 7, dpi = 150)
cat("  ✅ Random Forest model saved\n")


# ════════════════════════════════════════════════════════════════
# MODEL 3: K-MEANS CLUSTERING — Group 200 Coins by Behavior
# Groups coins into 4 clusters based on market characteristics
# ════════════════════════════════════════════════════════════════

cat("\n🔵 Model 3: K-Means Clustering...\n")

# Select features for clustering
cluster_features <- crypto %>%
  select(
    symbol,
    price,
    volume_bil,
    market_cap_bil,
    change_24h,
    change_7d,
    volatility_score,
    volume_to_mcap
  ) %>%
  na.omit()

# Scale features (important for K-means — all on same scale)
cluster_scaled <- cluster_features %>%
  select(-symbol) %>%
  scale()  # Converts to mean=0, sd=1

cat("  📊 Clustering", nrow(cluster_scaled), "coins\n")

# Find optimal K using Elbow Method
cat("  🔄 Finding optimal number of clusters...\n")
set.seed(42)
wss <- sapply(2:8, function(k) {
  kmeans(cluster_scaled, centers = k, nstart = 25)$tot.withinss
})

# Plot elbow curve
elbow_df <- data.frame(k = 2:8, wss = wss)
p_elbow <- ggplot(elbow_df, aes(x = k, y = wss)) +
  geom_line(color = "#f7931a", linewidth = 1.2) +
  geom_point(color = "#f7931a", size = 3) +
  geom_vline(xintercept = 4, color = "#00d4ff",
             linetype = "dashed", linewidth = 0.8) +
  annotate("text", x = 4.2, y = max(wss) * 0.9,
           label = "Optimal K=4", color = "#00d4ff") +
  labs(title    = "Elbow Method — Optimal Number of Clusters",
       x        = "Number of Clusters (K)",
       y        = "Within Sum of Squares") +
  theme_minimal()

ggsave("visuals/p9_elbow_curve.png", p_elbow, width = 8, height = 5)

# Fit K-means with K=4
set.seed(42)
km_model <- kmeans(cluster_scaled, centers = 4, nstart = 25)

# Add cluster labels back to data
cluster_features$cluster <- km_model$cluster
cluster_features$cluster_name <- case_when(
  cluster_features$cluster == 1 ~ "Blue Chip",
  cluster_features$cluster == 2 ~ "Stablecoin",
  cluster_features$cluster == 3 ~ "Growth",
  cluster_features$cluster == 4 ~ "Speculative"
)

# Calculate silhouette score
sil       <- silhouette(km_model$cluster, dist(cluster_scaled))
sil_score <- round(mean(sil[, 3]), 3)
cat("  📊 Silhouette Score:", sil_score,
    "(closer to 1 = better separation)\n")

# Cluster summary
cluster_summary <- cluster_features %>%
  group_by(cluster_name) %>%
  summarise(
    n_coins      = n(),
    avg_price    = round(mean(price, na.rm = TRUE), 2),
    avg_mcap     = round(mean(market_cap_bil, na.rm = TRUE), 2),
    avg_vol_24h  = round(mean(volatility_score, na.rm = TRUE), 2),
    .groups      = "drop"
  )

cat("\n  📋 Cluster Summary:\n")
print(cluster_summary)

# Save
crypto_clustered <- crypto %>%
  left_join(
    cluster_features %>% select(symbol, cluster, cluster_name),
    by = "symbol"
  )

write_csv(crypto_clustered,  "data/processed/crypto_clustered.csv")
write_csv(cluster_summary,   "data/processed/cluster_summary.csv")
saveRDS(km_model,            "models/kmeans_model.rds")

# Cluster visualization
p_cluster <- fviz_cluster(
  km_model,
  data          = cluster_scaled,
  palette       = c("#f7931a", "#627eea", "#9945ff", "#00cc44"),
  geom          = "point",
  ellipse.type  = "convex",
  ggtheme       = theme_minimal()
) +
  labs(
    title    = paste0("Cryptocurrency Clusters (K=4)"),
    subtitle = paste0("Silhouette Score: ", sil_score,
                      " | Coins: ", nrow(cluster_features))
  ) +
  theme(plot.title = element_text(face = "bold"))

ggsave("visuals/p10_clusters.png", p_cluster,
       width = 10, height = 7, dpi = 150)

cat("\n", paste(rep("═", 50), collapse=""), "\n")
cat("✅ STAGE 7 COMPLETE — ALL MODELS TRAINED\n")
cat(paste(rep("═", 50), collapse=""), "\n")
cat("📈 ARIMA RMSE:           $", round(rmse_arima, 0), "\n")
cat("🌲 Random Forest R²:     ", round(r2_rf, 3), "\n")
cat("🔵 K-Means Silhouette:   ", sil_score, "\n")
cat("💾 All models saved to models/\n")
cat(paste(rep("═", 50), collapse=""), "\n")