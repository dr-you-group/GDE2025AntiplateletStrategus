# JACC Asia revision: post hoc analyses for Strategus sites ---------------------------
# Run AFTER StrategusCodeToRun.R has completed with the revision specification, in the
# same R environment and from the project root. Main version only (not the expanded run).
#
# Reads the saved CohortMethod files in the Strategus work folder and runs:
#   subgroups (MACE, MACE-V1, MACE-V2), balance of ACS type / severity markers / age groups,
#   zero time-at-risk exclusion reasons, study period, and P2Y12 switching/discontinuation.
# The switching profile needs one READ-ONLY query (drug_exposure joined to the cohort
# table); nothing is written to the database. Outputs are aggregate CSVs with counts
# below minCellCount censored. Please send the whole exportFolder.
source("extras/revision/RevisionPostHoc.R")

# Site settings (same values as in StrategusCodeToRun.R) ---------------------------------
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "",
  server = "",
  user = "",
  password = "",
  port = "",
  pathToDriver = ""
)
cdmDatabaseSchema <- ""
cohortDatabaseSchema <- "" # workDatabaseSchema used by Strategus
cohortTable <- "" # cohort table name used by Strategus (cohortTableNames$cohortTable)
workFolder <- "" # Strategus workFolder of the revision run
databaseId <- "" # e.g. "HealthVerity", "CCAE", "MDCR"
exportFolder <- file.path(workFolder, "revisionPostHoc")
minCellCount <- 5

# Study-population settings of the analyses, taken from the package specification ------
spec <- ParallelLogger::loadSettingsFromJson("inst/GDE2025AniplateletAnalysisSpecification.json")
cmSpec <- Filter(function(m) m$module == "CohortMethodModule", spec$moduleSpecifications)[[1]]
studyPopArgs <- function(analysisId) {
  analysis <- Filter(function(a) a$analysisId == analysisId, cmSpec$settings$cmAnalysisList)[[1]]
  analysis$createStudyPopArgs
}

runRevisionPostHoc(
  cmFolder = file.path(workFolder, "CohortMethodModule"),
  exportFolder = exportFolder,
  databaseId = databaseId,
  primaryAnalysisId = 8, # ITT 1 year, PS stratification
  onTreatmentAnalysisId = 5, # on-treatment, PS stratification
  createStudyPopArgs = list("8" = studyPopArgs(8), "5" = studyPopArgs(5)),
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTable = cohortTable,
  minCellCount = minCellCount
)
