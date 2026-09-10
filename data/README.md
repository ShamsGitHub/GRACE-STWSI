# Data

This directory contains supporting datasets used in the GRACE-STWSI analysis
developed for **Indicator 1.2.2: Drought** in *The 2026 Report of the Lancet
Countdown on Health and Climate Change*.

## Standardised Terrestrial Water Storage Index (STWSI)

The analysis requires the monthly global STWSI raster:

`CSR_GRACE_Global_Standardised_TWSI_03_25.tif`

The **Standardised Terrestrial Water Storage Index (STWSI)** was derived from
monthly terrestrial water storage (TWS) observations from the **CSR
GRACE/GRACE-FO RL06.3 Mascon Solution**.

Missing monthly observations were filled using linear interpolation for short
data gaps. For the extended observational gaps during 2017–2018, missing
monthly values were replaced using the corresponding monthly climatological
means calculated over the six-year period from January 2015 to December 2020.
The resulting continuous monthly TWS time series was then standardised relative
to the long-term monthly climatology to produce the STWSI.

The STWSI dataset covers **January 2003 to December 2025**.

For the Lancet Countdown 2026 analysis:

- extremely dry terrestrial water storage conditions are defined as `STWSI < -1.5`;
- extremely wet terrestrial water storage conditions are defined as `STWSI > 1.5`; and
- changes in their frequency are assessed by comparing **2006–2015** with
  **2016–2025**.

### STWSI data availability

The STWSI GeoTIFF is not stored directly in this GitHub repository because of
its file size. It has been deposited in the **UCL Research Data Repository
(Figshare)** and is publicly available.

The STWSI dataset is available here: https://doi.org/10.5522/04/33528709

To reproduce the analysis, download:

`CSR_GRACE_Global_Standardised_TWSI_03_25.tif`

and place it in this `data/` directory before running the R script.

## GRACE terrestrial water storage trend

The following derived raster is included in this directory:

`CSR_GRACE_TWS_Global_TSens_trends_03_25.tif`

This raster contains the **Theil-Sen trend in GRACE terrestrial water storage
for 2003–2025** and is used to calculate country-level mean TWS trends.

## Lancet Countdown country information

The following file is included:

`Lancet_Countdown_2026_Country_Names.csv`

It contains the country list and geographical classifications used in the
Lancet Countdown 2026 analysis, including ISO3 country codes, country names,
Lancet Countdown geographical groupings, WHO regions and 2025 Human Development
Index (HDI) groupings.

## Country boundaries

Country boundaries used for spatial aggregation are provided by the **ESRI
World Countries Generalized** dataset.

The following shapefile components are included:

`World_Countries_Generalized.shp`  
`World_Countries_Generalized.shx`  
`World_Countries_Generalized.dbf`  
`World_Countries_Generalized.prj`  
`World_Countries_Generalized.cpg`

The country polygons are used to aggregate the GRACE-derived indicators to
country level.

## Caspian Sea mask

The `worldglwd1` shapefile is used to mask the Caspian Sea from the analysis.
This prevents large water-storage variations in the Caspian Sea from
influencing terrestrial water storage estimates for neighbouring countries.

The associated shapefile components required by the R script are provided in
this directory.

## Data licences and attribution

The MIT License in the root of this repository applies to the R code. Third-party
and derived datasets remain subject to the licences and terms of use of their
respective data providers.
