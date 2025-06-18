################################################################################
# INSTRUCTIONS: This script assumes you have cohorts you would like to use in an
# ATLAS instance. Please note you will need to update the baseUrl to match
# the settings for your enviroment. You will also want to change the 
# CohortGenerator::saveCohortDefinitionSet() function call arguments to identify
# a folder to store your cohorts. This code will store the cohorts in 
# "inst/sampleStudy" as part of the template for reference. You should store
# your settings in the root of the "inst" folder and consider removing the 
# "inst/sampleStudy" resources when you are ready to release your study.
# 
# See the Download cohorts section
# of the UsingThisTemplate.md for more details.
# ##############################################################################

library(dplyr)
baseUrl <- "https://atlas-demo.ohdsi.org/WebAPI"
# Use this if your WebAPI instance has security enables
# ROhdsiWebApi::authorizeWebApi(
#   baseUrl = baseUrl,
#   authMethod = "windows"
# )
cohortDefinitionSet <- ROhdsiWebApi::exportCohortDefinitionSet(
  baseUrl = baseUrl,
  cohortIds = c(
    1792797, # [GDE2025_Antiplatelet] Ticagrelor cohort - Revised
    1793457, # [GDE2025_Antiplatelet] Prasugrel cohort - Revised
    1792367, # [GDE2025_Antiplatelet] Primary outcome - MACE
    1792366, # [GDE2025_Antiplatelet] Secondary outcome - NACE
    1792364, # [GDE2025_Antiplatelet] Secondary outcome - All cause mortality
    1792365, # [GDE2025_Antiplatelet] Secondary outcome - Cardiovascular mortality
    1792369, # [GDE2025_Antiplatelet] Secondary outcome - Ischemic event
    1792368, # [GDE2025_Antiplatelet] Secondary outcome - Hemorrhagic event
    1792370, # [GDE2025_Antiplatelet] Secondary outcome - AMI
    1792372, # [GDE2025_Antiplatelet] Secondary outcome - Stroke(hemorrhagic)
    1792373, # [GDE2025_Antiplatelet] Secondary outcome - Stroke(ischemic)
    1792371, # [GDE2025_Antiplatelet] Secondary Outcome - Stroke(both)
    1792374 # [GDE2025_Antiplatelet] Secondary outcome - GI bleeding
  ),
  generateStats = TRUE
)

############################################

# Rename cohorts
# cohortDefinitionSet[cohortDefinitionSet$cohortId == 1778211,]$cohortName <- "celecoxib"
# cohortDefinitionSet[cohortDefinitionSet$cohortId == 1790989,]$cohortName <- "diclofenac"
# cohortDefinitionSet[cohortDefinitionSet$cohortId == 1780946,]$cohortName <- "GI Bleed"

# Re-number cohorts
# cohortDefinitionSet[cohortDefinitionSet$cohortId == 1778211,]$cohortId <- 1
# cohortDefinitionSet[cohortDefinitionSet$cohortId == 1790989,]$cohortId <- 2
# cohortDefinitionSet[cohortDefinitionSet$cohortId == 1780946,]$cohortId <- 3

# Save the cohort definition set
# NOTE: Update settingsFileName, jsonFolder and sqlFolder
# for your study.
CohortGenerator::saveCohortDefinitionSet(
  cohortDefinitionSet = cohortDefinitionSet,
  settingsFileName = "inst/Cohorts.csv",
  jsonFolder = "inst/cohorts",
  sqlFolder = "inst/sql/sql_server",
)


# Download and save the negative control outcomes
negativeControlOutcomeCohortSet <- ROhdsiWebApi::getConceptSetDefinition(
  conceptSetId = 1886472,
  baseUrl = baseUrl
) %>%
  ROhdsiWebApi::resolveConceptSet(
    baseUrl = baseUrl
  ) %>%
  ROhdsiWebApi::getConcepts(
    baseUrl = baseUrl
  ) %>%
  rename(outcomeConceptId = "conceptId",
         cohortName = "conceptName") %>%
  mutate(cohortId = row_number() + 100) %>%
  select(cohortId, cohortName, outcomeConceptId)

# NOTE: Update file location for your study.
CohortGenerator::writeCsv(
  x = negativeControlOutcomeCohortSet,
  file = "inst/negativeControlOutcomes.csv",
  warnOnFileNameCaseMismatch = F
)

