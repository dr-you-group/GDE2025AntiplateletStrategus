# Faster SQL for 7 cohorts that are very slow on some databases; same cohorts as the Circe SQL.
# Sourced by StrategusCodeToRun.R before Strategus::execute().
#   1792365 CV mortality: heart-failure records limited to the 30 days before a death
#   MACE/NACE/Ischemic event V1/V2: built from their component cohorts
local({
  folder <- file.path("extras", "revision", "fastCohortSql")
  spec <- ParallelLogger::loadSettingsFromJson("inst/GDE2025AniplateletAnalysisSpecification.json")
  cohorts <- unlist(lapply(spec$sharedResources, function(r) r$cohortDefinitions), recursive = FALSE)
  fastIds <- sub("[.]sql$", "", list.files(folder, pattern = "[.]sql$"))
  circeSql <- c()
  fastSql <- c()
  for (cohort in cohorts) {
    if (!as.character(cohort$cohortId) %in% fastIds) next
    sql <- SqlRender::readSql(file.path(folder, paste0(cohort$cohortId, ".sql")))
    expression <- CirceR::cohortExpressionFromJson(cohort$cohortDefinition)
    for (generateStats in c(TRUE, FALSE)) {
      circeSql <- c(circeSql, CirceR::buildCohortQuery(expression, CirceR::createGenerateOptions(generateStats = generateStats)))
      fastSql <- c(fastSql, sql)
    }
  }
  if (length(fastSql) != 2 * length(fastIds)) stop("Fast cohort SQL: cohorts not found in the analysis specification")
  options(strategus.cohortSqlOptimizationFunction = function(sql) {
    i <- match(sql, circeSql)
    if (is.na(i)) sql else fastSql[i]
  })
  message("Fast SQL set for cohorts ", paste(fastIds, collapse = ", "))
})
