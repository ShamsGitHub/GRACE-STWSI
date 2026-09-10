#########################################################################################################
# GRACE-STWSI country-level analysis
#
# R script for analysing changes in extremely dry and wet terrestrial water storage
# conditions using the Standardised Terrestrial Water Storage Index (STWSI), and
# long-term trends in GRACE terrestrial water storage using the Theil-Sen estimator.
#
# Developed for the Lancet Countdown 2026.
#
# Author: Prof Mohammad Shamsudduha
# Department of Risk and Disaster Reduction, University College London (UCL)
#
# Last updated: 09 September 2026
#########################################################################################################

# Load required packages

library(terra)
library(sf)
library(ggplot2)
library(dplyr)
library(countrycode)


#########################################################################################################
# 1. Read STWSI data
#########################################################################################################

# Monthly global STWSI raster, January 2003 to December 2025

stwsi <- rast("data/CSR_GRACE_Global_Standardised_TWSI_03_25.tif")

# Exclude the Caspian Sea from the analysis

caspian_vect <- vect("data/worldglwd1.shp")
stwsi <- mask(stwsi, caspian_vect, inverse = TRUE)

# Assign monthly dates

dates <- seq(
  as.Date("2003-01-15"),
  as.Date("2025-12-15"),
  by = "month"
)

names(stwsi) <- format(dates, "%Y-%m")
terra::time(stwsi) <- dates


#########################################################################################################
# 2. Read Lancet Countdown country list and country boundaries
#########################################################################################################

# Read the Lancet Countdown 2026 country list

lancet_countries <- read.csv(
  "data/Lancet_Countdown_2026_Country_Names.csv",
  stringsAsFactors = FALSE
)

# Read ESRI World Countries Generalized shapefile

countries <- vect("data/World_Countries_Generalized.shp")

# Convert ESRI ISO2 country codes to ISO3

countries$ISO3 <- countrycode(
  countries$ISO,
  origin = "iso2c",
  destination = "iso3c"
)

# Manual ISO3 assignments where required

countries$ISO3[countries$COUNTRY == "Namibia"] <- "NAM"
countries$ISO3[countries$COUNTRY == "Hong Kong"] <- "HKG"
countries$ISO3[countries$COUNTRY == "Macao"] <- "MAC"

# Retain countries included in the Lancet Countdown country list

countries <- countries[countries$ISO3 %in% lancet_countries$ISO3, ]

# Dissolve multiple polygons belonging to the same country

countries <- aggregate(countries, by = "ISO3", dissolve = TRUE)

# Use WGS84 coordinate reference system

countries <- project(countries, "EPSG:4326")

# Add Lancet Countdown country information

country_info <- lancet_countries[
  match(countries$ISO3, lancet_countries$ISO3),
]

countries$CountryName <- country_info$CountryName
countries$LCGrouping <- country_info$LCGrouping
countries$WHORegion <- country_info$WHORegion
countries$HDIGroup2025 <- country_info$HDIGroup2025

#########################################################################################################
# 3. Define baseline and recent periods
#########################################################################################################

# Baseline period: 2006-2015

baseline_idx <- which(format(dates, "%Y") %in% 2006:2015)

# Recent period: 2016-2025

recent_idx <- which(format(dates, "%Y") %in% 2016:2025)


#########################################################################################################
# 4. Calculate frequency of extremely dry conditions
#########################################################################################################

# Extremely dry conditions are defined as STWSI < -1.5

# Baseline period

drought_base <- stwsi[[baseline_idx]] < -1.5
drought_base <- as.numeric(drought_base)

base_sum <- app(drought_base, sum, na.rm = TRUE)
base_n <- app(!is.na(stwsi[[baseline_idx]]), sum, na.rm = TRUE)

base_freq <- base_sum / base_n


# Recent period

drought_recent <- stwsi[[recent_idx]] < -1.5
drought_recent <- as.numeric(drought_recent)

recent_sum <- app(drought_recent, sum, na.rm = TRUE)
recent_n <- app(!is.na(stwsi[[recent_idx]]), sum, na.rm = TRUE)

recent_freq <- recent_sum / recent_n


#########################################################################################################
# 5. Calculate change between the two periods
#########################################################################################################

# Percentage-point change in frequency of extremely dry months

drought_change <- (recent_freq - base_freq) * 100

#########################################################################################################
# 5a. Calculate frequency and change in extremely wet conditions
#########################################################################################################

# Extremely wet conditions are defined as STWSI > 1.5

# Baseline period

wet_base <- stwsi[[baseline_idx]] > 1.5
wet_base <- as.numeric(wet_base)

base_sum_wet <- app(wet_base, sum, na.rm = TRUE)
base_n_wet <- app(!is.na(stwsi[[baseline_idx]]), sum, na.rm = TRUE)

base_freq_wet <- base_sum_wet / base_n_wet

# Recent period

wet_recent <- stwsi[[recent_idx]] > 1.5
wet_recent <- as.numeric(wet_recent)

recent_sum_wet <- app(wet_recent, sum, na.rm = TRUE)
recent_n_wet <- app(!is.na(stwsi[[recent_idx]]), sum, na.rm = TRUE)

recent_freq_wet <- recent_sum_wet / recent_n_wet

# Percentage-point change in frequency of extremely wet months

wet_change <- (recent_freq_wet - base_freq_wet) * 100

#########################################################################################################
# 6. Calculate country-level mean change
#########################################################################################################

country_change <- extract(
  drought_change,
  countries,
  fun = mean,
  weights = TRUE,
  na.rm = TRUE
)

countries$drought_change <- country_change[, 2]

# Calculate country-level mean change in extremely wet conditions

country_wet_change <- extract(
  wet_change,
  countries,
  fun = mean,
  weights = TRUE,
  na.rm = TRUE
)

countries$wet_change <- country_wet_change[, 2]

#########################################################################################################
# 6a. Extract country-level Theil-Sen trends in terrestrial water storage
#########################################################################################################

# Global Theil-Sen trend in GRACE terrestrial water storage, 2003-2025

ts_trend <- rast("data/CSR_GRACE_TWS_Global_TSens_trends_03_25.tif")

# Exclude the Caspian Sea to avoid its strong water-storage trend influencing
# estimates for neighbouring countries

ts_trend <- mask(ts_trend, caspian_vect, inverse = TRUE)

# Calculate area-weighted mean TWS trend for each country

country_trend <- extract(
  ts_trend,
  countries,
  fun = mean,
  weights = TRUE,
  na.rm = TRUE
)

countries$tws_sen_trend <- country_trend[, 2]

#########################################################################################################
# 7. Map country-level changes
#########################################################################################################

countries_sf <- st_as_sf(countries)

dry_change_map <- ggplot(countries_sf) +
  geom_sf(
    aes(fill = drought_change),
    colour = "black",
    size = 0.1
  ) +
  scale_fill_gradient2(
    name = "Change (%)",
    na.value = "grey60",
    low = "blue2",
    mid = "gray90",
    high = "red2",
    midpoint = 0,
    limits = c(-20, 20),
    breaks = c(-20, -10, 0, 10, 20),
    labels = c("<-20", "-10", "0", "10", ">20"),
    oob = scales::squish
  ) +
  labs(
    title = "Change in dry conditions (2016-2025 relative to 2006-2015)"
  ) +
  theme_minimal()

print(dry_change_map)


#########################################################################################################
# 8. Export results
#########################################################################################################

# Create output directory if it does not already exist

dir.create("outputs", showWarnings = FALSE)

# Export map

ggsave(
  "outputs/STWSI_country_dry_change_2006_2015_vs_2016_2025.png",
  dry_change_map,
  width = 10,
  height = 5.5,
  dpi = 300
)

# Export country-level results

# Select key country-level indicators for export

country_results <- countries_sf |>
  st_drop_geometry() |>
  select(
    ISO3,
    CountryName,
    LCGrouping,
    WHORegion,
    HDIGroup2025,
    drought_change,
    wet_change,
    tws_sen_trend
  )

write.csv(
  country_results,
  "outputs/GRACE_STWSI_country_indicators_2003_2025.csv",
  row.names = FALSE
)

#########################################################################################################
# End of script
#########################################################################################################
