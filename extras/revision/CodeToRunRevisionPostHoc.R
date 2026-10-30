# JACC Asia revision: post hoc analyses. Run after StrategusCodeToRun.R.
# Fill in the settings and source this file. Send the <workFolder>/revisionPostHoc folder.
source("extras/revision/RevisionPostHoc.R")

# Settings: same as StrategusCodeToRun.R ------------------------------------------------
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "",
  server = "",
  user = "",
  password = "",
  port = "",
  pathToDriver = ""
)
cdmDatabaseSchema <- ""
cohortDatabaseSchema <- "" # workDatabaseSchema
cohortTable <- ""
workFolder <- ""
databaseId <- "" # "HealthVerity", "CCAE" or "MDCR"

# No changes needed below -----------------------------------------------------------------
exportFolder <- file.path(workFolder, "revisionPostHoc")
minCellCount <- 5
spec <- ParallelLogger::loadSettingsFromJson("inst/GDE2025AniplateletAnalysisSpecification.json")
cmSpec <- Filter(function(m) m$module == "CohortMethodModule", spec$moduleSpecifications)[[1]]
cmAnalysis <- function(analysisId) {
  Filter(function(a) a$analysisId == analysisId, cmSpec$settings$cmAnalysisList)[[1]]
}

runRevisionPostHoc(
  cmFolder = file.path(workFolder, "CohortMethodModule"),
  exportFolder = exportFolder,
  databaseId = databaseId,
  primaryAnalysisId = 8,
  onTreatmentAnalysisId = 5,
  createStudyPopArgs = list("8" = cmAnalysis(8)$createStudyPopArgs, "5" = cmAnalysis(5)$createStudyPopArgs),
  stratifyByPsArgs = cmAnalysis(8)$stratifyByPsArgs,
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTable = cohortTable,
  minCellCount = minCellCount
)
