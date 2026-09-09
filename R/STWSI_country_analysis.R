#########################################################################################################
# GRACE-STWSI country-level analysis
#
# R script for analysing changes in extremely dry terrestrial water storage conditions
# using the Standardised Terrestrial Water Storage Index (STWSI).
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

# Assign monthly dates

dates <- seq(
  as.Date("2003-01-15"),
  as.Date("2025-12-15"),
  by = "month"
)

names(stwsi) <- format(dates, "%Y-%m")
terra::time(stwsi) <- dates


#########################################################################################################
# 2. Read country boundaries
#########################################################################################################

# ESRI World Countries Generalized shapefile

countries <- vect("data/World_Countries_Generalized.shp")

# Convert ISO2 country codes to ISO3

countries$ISO3 <- countrycode(
  countries$ISO,
  origin = "iso2c",
  destination = "iso3c"
)

# Namibia requires manual assignment

countries$ISO3[countries$COUNTRY == "Namibia"] <- "NAM"

# Dissolve multiple polygons belonging to the same country

countries <- aggregate(countries, by = "ISO3", dissolve = TRUE)

# Use WGS84 coordinate reference system

countries <- project(countries, "EPSG:4326")


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

country_results <- st_drop_geometry(countries_sf)

write.csv(
  country_results,
  "outputs/STWSI_country_dry_change.csv",
  row.names = FALSE
)

#########################################################################################################
# End of script
#########################################################################################################
