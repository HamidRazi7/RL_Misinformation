

#This loads raw data and processes it for behavioral analysis


library(ggplot2)
library(cowplot)
library(dplyr)
library(ggeffects)
library(tidyverse)
library(here)
library(data.table)


for (study in 1:2) {

Data <-
  read.csv(here("Data", "Raw", sprintf("RAWS%d.csv", study)))

catch_to_exclude <- Data %>%
  filter(Catch.Trial != "", !is.na(TrialType)) %>%
  mutate(Correct = (TrialType & Catch.Trial == "Accurate") |
                   (!TrialType & Catch.Trial == "Inaccurate")) %>%
  group_by(subn) %>%
  summarise(Wrong = sum(!Correct)) %>%
  filter(Wrong > 1) %>%
  pull(subn)

Data <- Data %>%
  filter(!subn %in% catch_to_exclude)


# Filter to include only trials with valid reaction times between 250 and 4000 ms
Data <- Data %>%
  filter(Reaction >= 250 & Reaction <= 4000)

# Add choice indicators (C1 and C2) based on the `Choice` column
# C1 = 1 if Choice is 1, otherwise 0; C2 = 1 if Choice is 2, otherwise 0
Data <- Data %>%
  mutate(
    C1 = ifelse(Choice == 1, 1, 0),
    C2 = ifelse(Choice == 2, 1, 0)
  )

# Convert `Condition` and `subn` to factors for analysis
Data$Condition <- as.factor(Data$Condition)
Data$subn <- as.factor(Data$subn)

# Sort data by Condition for further processing
Data_sorted <- Data[order(Data$Condition), ]

# Create trial number within each Condition and subject
Data_sorted <- Data_sorted %>%
  group_by(Condition, subn) %>%
  mutate(Trial = row_number())

# Calculate the mean choice for Option 1 per condition and subject
mean_choice_df <- Data_sorted %>%
  group_by(Condition, subn) %>%
  summarise(MeanOption1 = mean(C1))

# Reshape data to a long format for analysis
mean_choice_long <- melt(setDT(mean_choice_df),
                         id.vars = c("Condition", "subn"),
                         value.name = "MeanChoice"
)

# Filter and group conditions to calculate mean points for "Solvable" and "Unsolvable" groups
mean_conditions <- mean_choice_long %>%
  filter(Condition %in% c(1, 3) | Condition %in% c(2, 4)) %>%
  group_by(subn, Condition = if_else(Condition %in% c(1, 3), "Solvable", "Unsolvable")) %>%
  summarize(MeanPoints = mean(MeanChoice, na.rm = TRUE)) %>%
  ungroup()

# Split data by solvable and unsolvable groups for participant exclusion
solvable_group <- mean_conditions %>% filter(Condition == "Solvable")
unsolvable_group <- mean_conditions %>% filter(Condition == "Unsolvable")

# Identify participants to exclude if their mean points for "Solvable" group are <= 0.55
subj_to_exclude <- solvable_group %>%
  filter(MeanPoints <= 0.55) %>%
  pull(subn)

# Filter out excluded participants from the main dataset
Data_filtered <- Data %>%
  filter(!subn %in% subj_to_exclude)

# Final filtered dataset for analysis
Data <- Data_filtered

#Remove unnecessary columns for further analysis

Data <- Data %>%
  select(-Block, 
         -Reward1,
         -Reward2,
         -Left.Image.Src, 
         -Left.Image.Type, 
         -Right.Image.Src, 
         -Right.Image.Type, 
         -Actual.Outcomes, 
         -Key.Type, 
         -Catch.Trial, 
         -Trial.Fixation.Time, 
         -Q,
         -any_of(c("Subject.Id", "Study.Id", "Session.Id")))

#Write to CSV

fwrite(Data, file = here("Data", "Processed", sprintf("Study%d.csv", study)))

}
