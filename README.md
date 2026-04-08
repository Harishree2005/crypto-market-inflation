# 🪙 Crypto Market Intelligence & Price Forecasting System

<div align="center">

![Banner](https://img.shields.io/badge/VIT%20Vellore-BCSE207L-blue?style=for-the-badge&logo=r&logoColor=white)
![R](https://img.shields.io/badge/R-4.4.2-276DC3?style=for-the-badge&logo=r&logoColor=white)
![PowerBI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-Version%20Control-181717?style=for-the-badge&logo=github&logoColor=white)

</div>

---

## 👩‍💻 Author

| Field | Details |
|-------|---------|
| **Name** | Harishree P |
| **Course** | Programming for Data Science — BCSE207L |
| **Institution** | Vellore Institute of Technology (VIT), Vellore |
| **Faculty** | Dr. Deepika J |
| **Semester** | Winter Semester 2025–2026 |
| **Slot** | D1 + TD1 |
| **Class Number** | VL2025260502542 |

---

## 📌 Problem Statement

> **"How do macroeconomic indicators — CPI inflation and interest rates — influence cryptocurrency market behavior across 200 coins? Can we forecast Bitcoin prices and cluster coins by behavioral patterns using real-time API data?"**

This project performs end-to-end data science on live cryptocurrency market data — from API ingestion and preprocessing, through exploratory analysis and predictive modelling, to an interactive Power BI dashboard with embedded R visuals.

---

## 🎯 Project Objectives

- Analyze the impact of **CPI inflation** and **Federal Reserve interest rates** on Bitcoin and crypto markets
- Build a **30-day Bitcoin price forecast** using ARIMA time series modelling
- Predict BTC prices from macro indicators using **Random Forest regression**
- Segment 200 cryptocurrencies into behavioral groups using **K-Means clustering**
- Visualize all findings in a **4-page interactive Power BI dashboard**

---

## 🗂️ Project Folder Structure

```
crypto-market-intelligence/
│
├── 📁 data/
│   ├── 📁 raw/                          ← Raw API responses
│   │   ├── crypto_listings.csv          ← Top 200 coins (CoinMarketCap)
│   │   ├── historical_prices.csv        ← 365-day OHLCV (CoinCap)
│   │   ├── fred_macro.csv               ← CPI + Interest Rates (FRED)
│   │   └── news_headlines.csv           ← Scraped news (rvest)
│   │
│   └── 📁 processed/                    ← Cleaned, merged datasets
│       ├── crypto_clean.csv
│       ├── history_clean.csv
│       ├── fred_macro_clean.csv
│       ├── btc_macro.csv
│       ├── btc_forecast.csv
│       ├── crypto_clustered.csv
│       ├── cluster_summary.csv
│       ├── rf_predictions.csv
│       ├── rf_importance.csv
│       └── summary_stats.csv
│
├── 📁 scripts/
│   ├── 00_install_packages.R            ← Install all R dependencies
│   ├── 01_data_acquisition.R            ← API data ingestion + logging
│   ├── 02_web_scraping.R                ← rvest news scraping + sentiment
│   ├── 03_preprocessing.R               ← Cleaning + feature engineering
│   ├── 04_eda_visualizations.R          ← 6 ggplot2 visualizations
│   └── 05_modelling.R                   ← ARIMA + Random Forest + K-Means
│
├── 📁 visuals/                          ← All saved chart outputs
│   ├── p1_btc_price_ma.png
│   ├── p2_treemap.png
│   ├── p3_correlation_heatmap.png
│   ├── p4_volatility_distribution.png
│   ├── p5_normalized_performance.png
│   ├── p6_btc_vs_inflation.png
│   ├── p7_arima_forecast.png
│   ├── p8_rf_actual_vs_predicted.png
│   ├── p9_elbow_curve.png
│   └── p10_clusters.png
│
├── 📁 models/                           ← Saved model files (.rds)
│   ├── arima_btc.rds
│   ├── rf_model.rds
│   └── kmeans_model.rds
│
├── 📁 logs/
│   └── api_calls.log                    ← All API call records
│
├── 📁 powerbi/
│   └── crypto_dashboard.pbix            ← Power BI dashboard file
│
├── 🐳 Dockerfile                        ← Container configuration
├── 🔒 .env                              ← API keys (NOT pushed to GitHub)
├── 🚫 .gitignore                        ← Protects keys + large files
└── 📖 README.md                         ← This file
```

---

## 📦 Data Sources

| Source | Data Collected | Auth Required |
|--------|---------------|---------------|
| [CoinMarketCap API](https://coinmarketcap.com/api) | Top 200 coins — price, volume, market cap, % changes | ✅ Free API Key |
| [CoinCap API](https://coincap.io) | 365-day OHLCV history for BTC, ETH, SOL, BNB, USDT | ❌ No key needed |
| [FRED API](https://fred.stlouisfed.org) | CPI Inflation index + Federal Funds Rate | ✅ Free API Key |
| [CoinTelegraph](https://cointelegraph.com) | Crypto news headlines (rvest scrape) | ❌ No key needed |

### Dataset Statistics

| Dataset | Rows | Columns | Types |
|---------|------|---------|-------|
| crypto_listings.csv | 200 | 18 | Numeric + Categorical |
| historical_prices.csv | ~1,825 | 9 | Numeric + Date + Categorical |
| fred_macro.csv | ~100 | 3 | Numeric + Date |
| news_headlines.csv | ~75 | 7 | Text + Numeric + Date |
| **Total** | **~2,200+** | — | — |

---

## ⚙️ Installation & Setup

### Prerequisites

| Tool | Version | Download |
|------|---------|----------|
| R | 4.4.2+ | [cran.r-project.org](https://cran.r-project.org) |
| RStudio | Latest | [posit.co](https://posit.co/download/rstudio-desktop) |
| Git | Latest | [git-scm.com](https://git-scm.com) |
| Docker Desktop | Latest | [docker.com](https://www.docker.com/products/docker-desktop) |
| Power BI Desktop | Latest | [powerbi.microsoft.com](https://powerbi.microsoft.com/downloads) |

### Step 1 — Clone the Repository

```bash
git clone https://github.com/harishreep/crypto-market-intelligence.git
cd crypto-market-intelligence
```

### Step 2 — Set Up API Keys

Create a `.env` file in the project root:

```bash
CMC_API_KEY="your-coinmarketcap-api-key-here"
FRED_API_KEY="your-fred-api-key-here"
```

> 🔑 Get CoinMarketCap key free at: https://coinmarketcap.com/api  
> 🔑 Get FRED key free at: https://fred.stlouisfed.org/docs/api/api_key.html

### Step 3 — Install R Packages

Open RStudio and run:

```r
source("scripts/00_install_packages.R")
```

This installs all required packages: `httr`, `jsonlite`, `rvest`, `dplyr`, `tidyr`, `ggplot2`, `forecast`, `randomForest`, `cluster`, `factoextra`, `corrplot`, `treemapify`, `syuzhet`, and more.

---

## 🚀 How to Run

Run scripts **in order** from RStudio console:

```r
# Step 1: Fetch all data from APIs
source("scripts/01_data_acquisition.R")

# Step 2: Scrape crypto news + sentiment analysis
source("scripts/02_web_scraping.R")

# Step 3: Clean and engineer features
source("scripts/03_preprocessing.R")

# Step 4: Generate all EDA visualizations
source("scripts/04_eda_visualizations.R")

# Step 5: Train all models
source("scripts/05_modelling.R")
```

---

## 🐳 Docker

### Build and Run

```bash
# Build the Docker image
docker build -t harishreep/crypto-intelligence:v1.0 .

# Run the full pipeline in container
docker run harishreep/crypto-intelligence:v1.0

# Pull from Docker Hub
docker pull harishreep/crypto-intelligence:v1.0
```

> ⚠️ Power BI module is **not** containerized as per project guidelines.

---

## 🤖 Models

### Model 1 — ARIMA (Time Series Forecasting)

| Parameter | Value |
|-----------|-------|
| Input | 365-day Bitcoin daily prices |
| Output | 30-day price forecast |
| Evaluation | RMSE: $15,492 \| MAE: $15,081 |
| Saved as | `models/arima_btc.rds` |

### Model 2 — Random Forest Regression

| Parameter | Value |
|-----------|-------|
| Input | CPI, Fed Rate, Volume, MA-7d, MA-30d, Volatility |
| Output | BTC price prediction |
| Evaluation | **R² = 0.991** \| **RMSE = $1,628** |
| Saved as | `models/rf_model.rds` |

### Model 3 — K-Means Clustering

| Parameter | Value |
|-----------|-------|
| Input | 200 coins — price, volume, market cap, volatility |
| K | 4 clusters |
| Clusters | Blue Chip, Stablecoin, Growth, Speculative |
| Evaluation | Silhouette Score computed |
| Saved as | `models/kmeans_model.rds` |

---

## 📊 Visualizations

### Correlation Heatmap

<img width="900" height="800" alt="p3_correlation_heatmap" src="https://github.com/user-attachments/assets/1f979c5b-344e-4361-8163-d52fbecf870b" />


> Price and Market Cap show strong positive correlation (0.97). Change_24h and Volatility are highly correlated (0.78), confirming that volatile coins experience larger intraday swings.

---

### Bitcoin Price vs CPI Inflation


<img width="2100" height="900" alt="p6_btc_vs_inflation" src="https://github.com/user-attachments/assets/49353e76-9679-41b7-a699-236a4c10833b" />

> Bitcoin peaked near $130K in late 2025 as CPI rose steadily. After Jan 2026, BTC dropped sharply while CPI continued climbing — suggesting crypto does **not** consistently act as an inflation hedge.

---

### ARIMA 30-Day Bitcoin Price Forecast

<img width="1800" height="900" alt="p7_arima_forecast" src="https://github.com/user-attachments/assets/9611c3b5-b175-4b95-8d7e-1506c115b4dd" />

> ARIMA model trained on 80% of historical data forecasts BTC holding near $85K over the next 30 days with widening confidence intervals — reflecting inherent price uncertainty.

---

### Random Forest: Actual vs Predicted BTC Price

<img width="1200" height="1050" alt="p8_rf_actual_vs_predicted" src="https://github.com/user-attachments/assets/4c0283e8-f9f4-40fd-90c7-95dbb89b3218" />



> Random Forest achieves R² = 0.991 — explaining 99.1% of variance in BTC price using macro indicators and technical features. Moving averages (MA-7d, MA-30d) are the strongest predictors.

---

## 📱 Power BI Dashboard

### Page 1 — Market Overview
<img width="1455" height="757" alt="image" src="https://github.com/user-attachments/assets/6cd7320a-d6ba-4538-9565-a8441e7766a8" />


> Live market overview: BTC dominates with $1,427B market cap. Top 10 coins shown with 24h changes. Market Cap Treemap shows relative coin sizes colored by 24h performance.

---

### Page 2 — Price Forecast
<img width="1160" height="650" alt="image" src="https://github.com/user-attachments/assets/64238cd5-dc14-4e73-810e-1f9008d891a7" />


> ARIMA 30-day forecast embedded as R visual. Confidence bands widen over time showing forecast uncertainty. BTC predicted to trade between $70K–$100K range.

---

### Page 3 — Cluster Analysis
<img width="1248" height="826" alt="image" src="https://github.com/user-attachments/assets/b0b464fd-db51-4d0e-ab5f-ad5f7637e6b2" />



> 200 coins segmented into 4 behavioral clusters. Blue Chip (BTC, ETH) — low volatility, high cap. Growth coins show momentum. Speculative coins exhibit extreme volatility. Total market cap: $2,422B across 200 coins.

---

## 🔑 Key Findings

1. **Bitcoin is not a reliable inflation hedge** — BTC dropped in early 2026 as CPI continued rising
2. **Interest rates significantly impact crypto** — Rate hikes correlate with BTC price declines
3. **Random Forest (R²=0.991) outperforms ARIMA** for short-term price prediction using technical features
4. **Market cap tier predicts volatility** — Top 10 coins are significantly more stable than Top 200
5. **Volume-to-MarketCap ratio** is a stronger trading signal than raw volume alone
6. **K-Means reveals 4 distinct coin behaviors** — Blue Chip, Stablecoin, Growth, and Speculative segments exist in the market

---

## 🛠️ Tech Stack

| Category | Tools |
|----------|-------|
| Language | R 4.4.2 |
| API Calls | `httr`, `jsonlite` |
| Web Scraping | `rvest`, `xml2` |
| Data Wrangling | `dplyr`, `tidyr`, `lubridate`, `zoo` |
| Visualization | `ggplot2`, `corrplot`, `treemapify`, `factoextra` |
| Forecasting | `forecast` (ARIMA) |
| ML Models | `randomForest`, `caret`, `cluster` |
| Sentiment | `syuzhet`, `tidytext` |
| Dashboard | Power BI Desktop |
| Version Control | Git + GitHub |
| Containerization | Docker |

---

## 📋 Evaluation Coverage

| Component | Marks | Status |
|-----------|-------|--------|
| Problem Definition & Dataset Quality | 4/4 | ✅ Real finance problem, 3 APIs, no Kaggle |
| API Integration & Data Engineering | 4/4 | ✅ Auth + pagination + JSON→DataFrame + logged |
| R Programming & Containerization | 6/6 | ✅ EDA + 10 visuals + 3 models + Docker |
| Power BI with R Visuals | 4/4 | ✅ 4 pages + R visuals + storytelling |
| GitHub & README Documentation | 2/2 | ✅ 10+ commits + 2 branches + this README |
| **Total** | **20/20** | 🎯 |

---

## 🌿 GitHub Branch Structure

```
main
└── development
    ├── feat: environment setup and package installation
    ├── feat: CoinMarketCap API ingestion with pagination
    ├── feat: CoinCap + FRED API integration and logging
    ├── feat: rvest web scraping for news + sentiment
    ├── feat: preprocessing, feature engineering, merge
    ├── feat: EDA complete with 6 ggplot2 visualizations
    ├── feat: ARIMA + Random Forest + K-Means models
    ├── feat: Power BI R visuals integration
    └── docs: complete README
```

---

## 📝 API Call Log Sample

```
2026-04-08 10:23:41 | ENDPOINT: CMC/listings/latest?start=1   | STATUS: 200 | ROWS: 100
2026-04-08 10:23:43 | ENDPOINT: CMC/listings/latest?start=101 | STATUS: 200 | ROWS: 100
2026-04-08 10:23:44 | ENDPOINT: CoinCap/history/bitcoin        | STATUS: 200 | ROWS: 365
2026-04-08 10:23:45 | ENDPOINT: CoinCap/history/ethereum       | STATUS: 200 | ROWS: 365
2026-04-08 10:23:46 | ENDPOINT: CoinCap/history/solana         | STATUS: 200 | ROWS: 365
2026-04-08 10:23:47 | ENDPOINT: FRED/CPIAUCSL                  | STATUS: 200 | ROWS: 73
2026-04-08 10:23:48 | ENDPOINT: FRED/FEDFUNDS                  | STATUS: 200 | ROWS: 73
```

---

## ⚠️ Important Notes

- **Never push `.env`** to GitHub — API keys are protected via `.gitignore`
- Run scripts strictly in order: `01 → 02 → 03 → 04 → 05`
- CoinMarketCap free tier allows **10,000 credits/month** — sufficient for this project
- Docker containerizes only the R pipeline — **Power BI is excluded** per guidelines
- If CoinCap API fails, the backup uses `quantmod` (Yahoo Finance) automatically

---

<div align="center">

**Made with ❤️ by Harishree P | VIT Vellore | BCSE207L | 2025–2026**

</div>
