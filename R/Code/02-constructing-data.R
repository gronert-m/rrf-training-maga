# Reproducible Research Fundamentals 
# 02. Data construction
# RRF - 2024 - Construction

# Preliminary - Load Data ----
# Load household-level data (HH)
hh_data <- read_dta(file.path(data_path, "Intermediate/TZA_CCT_HH.dta"))

# Load HH-member data
mem_data <- read_dta(file.path(data_path, "Intermediate/TZA_CCT_HH_mem.dta"))

# Load secondary data
secondary_data <- read_dta(file.path(data_path, "Intermediate/TZA_amenity_tidy.dta"))

# Exercise 1: Plan construction outputs ----
# Plan the following outputs:
# 1. Area in acres. 
#       --> HHs: Need ar_farm, ar_unit where 2 is acre, 3 is Hectare
# 2. Household consumption (food and nonfood) in USD.
#       --> HHs:sum of food, non food at HH
# 3. Any HH member sick.
#       --> IND - binary/max at HHs
# 4. Any HH member can read or write.
#       --> IND - binary/max at HH
# 5. Average sick days.
#       --> IND - avg at HH
# 6. Total treatment cost in USD.
#       --> IND
# 7. Total medical facilities.
#       --> Sec, sum hospital and clinic

# Define conversion factors
acres_in_hectare <- 2.47
usd <- 0.00037

# Area in acres
hh_data <- hh_data |> 
    mutate(area_acre = case_when(
        ar_unit == 1 ~ ar_farm,
        ar_unit == 2 ~ ar_farm * acres_in_hectare
    )) |> 
    mutate(area_acre = replace_na(area_acre, 0)) |> 
    set_variable_labels(area_acre = "Area farmed in acres")

# Consumption in USD
hh_data <- hh_data |> 
    mutate(across(c(food_cons, nonfood_cons),
                  ~.x * usd,
                  .names = "{.col}_usd"))

    
    
# Exercise 2: Standardize conversion values ----
# Define standardized conversion values:
# 1. Conversion factor for acres.
# 2. USD conversion factor.

# Data construction: Household (HH) ----
# Instructions:
# 1. Convert farming area to acres where necessary.
# 2. Convert household consumption for food and nonfood into USD.

# Exercise 3: Handle outliers ----
# you can use custom Winsorization function to handle outliers.
winsor_function <- function(dataset, var, min = 0.00, max = 0.95) {
    var_sym <- sym(var)
    
    percentiles <- quantile(
        dataset %>% pull(!!var_sym), probs = c(min, max), na.rm = TRUE
    )
    
    min_percentile <- percentiles[1]
    max_percentile <- percentiles[2]
    
    dataset %>%
        mutate(
            !!paste0(var, "_w") := case_when(
                is.na(!!var_sym) ~ NA_real_,
                !!var_sym <= min_percentile ~ percentiles[1],
                !!var_sym >= max_percentile ~ percentiles[2],
                TRUE ~ !!var_sym
            )
        )
}

# winsorize vars
win_vars <- c("area_acre", "food_cons_usd", "nonfood_cons_usd")

# apply
for (var in win_vars) {
    hh_data <- winsor_function(hh_data, var)
}

hh_data <- hh_data |> 
    mutate(across(ends_with("_w"),
                  ~ labelled(.x, label = paste0(attr(.x, "label"), 
                                                " (winsorized 5%)"))))


# Tips: Apply the Winsorization function to the relevant variables.
# Create a list of variables that require Winsorization and apply the function to each.

# Exercise 4.1: Create indicators at household level ----
# Instructions:
# Collapse HH-member level data to HH level.
# Plan to create the following indicators:
# 1. Any member was sick.
# 2. Any member can read/write.
# 3. Average sick days.
# 4. Total treatment cost in USD.

# Collapse HH member data to HH level\
hh_mem_collapsed <- mem_data |> 
    # Convert treatment cost into USD
    mutate(treat_cost_usd = treat_cost * usd) 
    
# Winsorize
hh_mem_collapsed <- winsor_function(hh_mem_collapsed, "treat_cost_usd", min = 0.01, max = 0.99)

# Collapse proper
hh_mem_collapsed <-
    hh_mem_collapsed |> 
    group_by(hhid) |> 
    summarise(
        sick = max(sick, na.rm = T), # At least one member was sick
        read = max(read, na.rm = T), # At least one member is literate
        # If all values of days sick NA, return NA
        days_sick = ifelse(all(is.na(days_sick)), NA_real_, mean(days_sick, na.rm = T)),
        treat_cost_usd_w = ifelse(all(is.na(treat_cost_usd_w)), NA_real_, sum(treat_cost_usd_w, na.rm = T))
    ) |> 
    ungroup() |> 
    # REplace missing treat cost if missing with average
    mutate(treat_cost_usd_w = if_else(is.na(treat_cost_usd_w), mean(treat_cost_usd_w, na.rm = T), treat_cost_usd_w)) |> 
    # Apply labels to the variables
    set_variable_labels(
        read = "Any member can read/write",
        sick = "Any member was sich in the last 4 weeks",
        days_sick = "Avg sick daus", 
        treat_cost_usd_w = "Winsorized total cost of treatment (USD)"
    )


# Exercise 4.2: Data construction: Secondary data ----
# Instructions:
# Calculate the total number of medical facilities by summing relevant columns.
# Apply appropriate labels to the new variables created.


secondary_data <- secondary_data |>
    (\(.) mutate(., n_medical = rowSums(select(., n_clinic, n_hospital), na.rm = TRUE)))()
    
    # secondary_data |> 
    # # Below not workign for reasons I do not comprehend
    # #mutate(n_medical = rowSums(select(\(.) ., n_clinic, n_hospital), na.rm = T))
    # mutate(n_medical = rowSums(\(.) .[c(2,4)]))


# Exercise 5: Merge HH and HH-member data ----
# Instructions:
# Merge the household-level data with the HH-member level indicators.
# After merging, ensure the treatment status is included in the final dataset.

# Merge HH and HH-member datasets
final_hh_data <- hh_data %>%
    left_join(hh_mem_collapsed, by = "hhid")

# Load treatment status and merge
treat_status <- read_dta(file.path(data_path, "Raw/treat_status.dta"))

final_hh_data <- final_hh_data %>%
    left_join(treat_status, by = "vid") 

# Exercise 6: Save final dataset ----
# Instructions:
# Only keep the variables you will use for analysis.
# Save the final dataset for further analysis.
# Save both the HH dataset and the secondary data.

# Tip: Ensure all variables are correctly labeled 

# Save the final merged data for analysis
write_dta(final_hh_data, file.path(data_path, "Final/TZA_CCT_analysis.dta"))

# Save the final secondary data for analysis
write_dta(secondary_data, file.path(data_path, "Final/TZA_amenity_analysis.dta"))
