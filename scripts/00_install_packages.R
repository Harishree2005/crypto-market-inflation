# ============================================================
# STAGE 2: INSTALL ALL REQUIRED PACKAGES
# Run this script ONCE before anything else
# ============================================================

# List of all packages needed
packages_needed <- c(
  # API & Data Collection
  "httr",        # Makes HTTP requests to APIs
  "jsonlite",    # Parses JSON responses from APIs
  "rvest",       # Web scraping
  "xml2",        # Helps rvest parse HTML pages
  "dotenv",      # Reads API keys from .env file
  
  # Data Wrangling
  "dplyr",       # Data manipulation (filter, select, mutate)
  "tidyr",       # Reshaping data (pivot_wider, pivot_longer)
  "lubridate",   # Working with dates easily
  "readr",       # Fast CSV read/write
  "stringr",     # String manipulation
  "zoo",         # Rolling averages and time series tools
  
  # Visualization
  "ggplot2",     # Main plotting library
  "scales",      # Formats numbers (dollar, percent)
  "corrplot",    # Correlation heatmaps
  "treemapify",  # Treemap charts
  "factoextra",  # Cluster visualization
  "ggthemes",    # Extra ggplot2 themes
  "gridExtra",   # Combine multiple plots
  "RColorBrewer",# Color palettes
  
  # Modelling
  "forecast",    # ARIMA time series forecasting
  "randomForest",# Random Forest regression
  "cluster",     # K-means clustering
  "caret",       # Model training framework
  "Metrics",     # RMSE, MAE evaluation metrics
  
  # Sentiment Analysis
  "tidytext",    # Text mining tools
  "syuzhet"      # Sentiment scoring
)

# Install only the ones not already installed
new_packages <- packages_needed[!(packages_needed %in% installed.packages()[,"Package"])]

if (length(new_packages) > 0) {
  cat("📦 Installing", length(new_packages), "packages...\n")
  install.packages(new_packages)
} else {
  cat("✅ All packages already installed!\n")
}

# Load all packages to confirm they work
cat("\n🔄 Loading all packages to verify...\n")
for (pkg in packages_needed) {
  tryCatch({
    library(pkg, character.only = TRUE)
    cat("✅ Loaded:", pkg, "\n")
  }, error = function(e) {
    cat("❌ Failed to load:", pkg, "\n")
  })
}

cat("\n🎉 All packages ready!\n")