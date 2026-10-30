# JACC Asia revision: post hoc analyses (Strategus sites, MAIN version only) -----------
# 1. Run StrategusCodeToRun.R on this branch first. Keep its work folder.
# 2. From the project root, fill in the settings below (same values as StrategusCodeToRun.R).
# 3. Source this file. Output: <workFolder>/revisionPostHoc/*.csv (aggregate; counts
#    below 5 shown as -5). Please send that folder.
# Database: one read-only query (P2Y12 drug records); nothing is written.
source("extras/revision/RevisionPostHoc.R")

# Site settings ---------------------------------------------------------------------------
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

# No changes needed below -----------------------------------------------------------------
spec <- ParallelLogger::loadSettingsFromJson("inst/GDE2025AniplateletAnalysisSpecification.json")
cmSpec <- Filter(function(m) m$module == "CohortMethodModule", spec$moduleSpecifications)[[1]]
cmAnalysis <- function(analysisId) {
  Filter(function(a) a$analysisId == analysisId, cmSpec$settings$cmAnalysisList)[[1]]
}

runRevisionPostHoc(
  cmFolder = file.path(workFolder, "CohortMethodModule"),
  exportFolder = exportFolder,
  databaseId = databaseId,
  primaryAnalysisId = 8, # ITT 1 year, PS stratification
  onTreatmentAnalysisId = 5, # on-treatment, PS stratification
  createStudyPopArgs = list("8" = cmAnalysis(8)$createStudyPopArgs, "5" = cmAnalysis(5)$createStudyPopArgs),
  stratifyByPsArgs = cmAnalysis(8)$stratifyByPsArgs, # subgroup calibration with negative controls
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTable = cohortTable,
  minCellCount = minCellCount
)
