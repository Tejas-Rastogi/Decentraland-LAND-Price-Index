# Load required packages
library(tempdisagg)
library(zoo)
library(dplyr)
library(lubridate)

# Set working directory
setwd("C:/Users/tejas/OneDrive/Tejas - Old Documents/Virtual Real Estate")

# --- Process Daily Indicator Data ---
# Parse the daily data (assuming it's saved as "daily_data.csv")
daily_df <- read.csv("daily_data.csv", stringsAsFactors = FALSE)
names(daily_df) <- make.names(names(daily_df))  # Ensure valid column names
daily_df$Dates <- as.Date(daily_df$Dates, format = "%d-%m-%Y")

# Create a complete date sequence from 2020-01-01 to 2024-12-31
all_days <- data.frame(Dates = seq.Date(from = as.Date("2020-01-01"), 
                                        to = as.Date("2024-12-31"), 
                                        by = "day"))
daily_merged <- merge(all_days, daily_df[, c("Dates", "Average.sale.price")], 
                      by = "Dates", all.x = TRUE)
daily_merged <- daily_merged[order(daily_merged$Dates), ]

# --- Cubic Spline with Noise Imputation ---
monthly_df <- read.csv("Monthly_Index.csv", stringsAsFactors = FALSE)
names(monthly_df) <- make.names(names(monthly_df))
monthly_df$MonthDate <- as.yearmon(monthly_df$Month, "%b-%y")
monthly_df <- monthly_df[order(monthly_df$MonthDate), ]
monthly_dates <- as.Date(monthly_df$MonthDate, frac = 0)
monthly_index_zoo <- zoo(monthly_df$Index.Value..Exp, order.by = monthly_dates)

# Initial cubic spline interpolation
daily_indicator_filled <- na.spline(daily_merged$Average.sale.price)
daily_indicator_zoo <- zoo(daily_indicator_filled, order.by = daily_merged$Dates)

# Add volatility based on monthly index
monthly_volatility <- sd(monthly_df$Index.Value..Exp, na.rm = TRUE) / 30
daily_noise <- rnorm(length(daily_indicator_filled), mean = 0, sd = monthly_volatility)
daily_indicator_filled <- daily_indicator_filled + daily_noise

# Cap extreme values
upper_cap <- quantile(monthly_df$Index.Value..Exp, 0.99, na.rm = TRUE) * 1.5
lower_cap <- quantile(monthly_df$Index.Value..Exp, 0.01, na.rm = TRUE) * 0.5
daily_indicator_filled <- pmax(lower_cap, pmin(upper_cap, daily_indicator_filled))

daily_indicator_zoo <- zoo(daily_indicator_filled, order.by = daily_merged$Dates)
log_daily_indicator <- log(daily_indicator_zoo)

# --- Apply Chow-Lin Disaggregation ---
model_cl <- td(
  log(monthly_index_zoo) ~ log_daily_indicator,
  method = "chow-lin-maxlog",
  conversion = "average"
)

# Save model summary
sink("ChowLin_Summary_CubicSplineNoise.txt")
cat("Chow-Lin Model Summary (Cubic Spline with Noise):\n")
summary(model_cl)
sink()

cat("Chow-Lin Model Summary (Cubic Spline with Noise, also saved to ChowLin_Summary_CubicSplineNoise.txt):\n")
summary(model_cl)

# Predict and exponentiate
log_disaggregated_daily <- predict(model_cl)
disaggregated_daily <- exp(log_disaggregated_daily)

# Save and display Daily Index
daily_output <- data.frame(Dates = index(disaggregated_daily), 
                           Daily_Index = coredata(disaggregated_daily))
write.csv(daily_output, "Daily_Index_CubicSplineNoise.csv", row.names = FALSE)
cat("\nFirst 6 rows of the Daily Index (saved to Daily_Index_CubicSplineNoise.csv):\n")
print(head(daily_output))

# Plot and save
png("Daily_Index_Plot_CubicSplineNoise.png", width = 800, height = 600)
plot(disaggregated_daily,
     main = "Disaggregated Daily Index (Cubic Spline with Noise, 2020–2024)",
     xlab = "Date", ylab = "Daily Index")
dev.off()
cat("\nPlot saved to Daily_Index_Plot_CubicSplineNoise.png\n")

# Validate
monthly_reagg <- aggregate(disaggregated_daily, as.yearmon, FUN = mean)
comparison <- merge(zoo(monthly_df$Index.Value..Exp, monthly_df$MonthDate),
                    monthly_reagg, all = TRUE)
colnames(comparison) <- c("Original", "Reaggregated")
write.csv(as.data.frame(comparison), "Monthly_Comparison_CubicSplineNoise.csv", row.names = TRUE)
cat("\nComparison of Original vs Reaggregated Monthly Index (saved to Monthly_Comparison_CubicSplineNoise.csv):\n")
print(head(comparison))