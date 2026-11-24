# Fix for CohortGenerator 0.11.2: saving the cohort definition set fails for cohort IDs above
# 2,147,483 ("Assertion on 'targetOutputPair' failed"), because it adds a temporary subset with
# ID cohortId * 1000 + 1. The fixed version adds the same three columns directly; the saved
# file is otherwise identical. Sourced by FastCohortSql.R.
if (as.character(utils::packageVersion("CohortGenerator")) == "0.11.2") {
  local({
    exportCohortDefinitionSet <- function(outputFolder, cohortDefinitionSet = NULL) {
      cohortDefinitions <- createEmptyResult("cg_cohort_definition")
      cohortSubsets <- createEmptyResult("cg_cohort_subset_definition")
      if (!is.null(cohortDefinitionSet)) {
        cdsCohortSubsets <- getSubsetDefinitions(cohortDefinitionSet)
        if (length(cdsCohortSubsets) > 0) {
          for (i in seq_along(cdsCohortSubsets)) {
            cohortSubsets <- rbind(cohortSubsets, data.frame(
              subsetDefinitionId = cdsCohortSubsets[[i]]$definitionId,
              json = as.character(cdsCohortSubsets[[i]]$toJSON())
            ))
          }
        } else {
          cohortDefinitionSet$subsetParent <- cohortDefinitionSet$cohortId
          cohortDefinitionSet$isSubset <- FALSE
          cohortDefinitionSet$subsetDefinitionId <- NA
        }
        colsToRename <- c("cohortId", "cohortName", "sql", "json")
        colInd <- which(names(cohortDefinitionSet) %in% colsToRename)
        names(cohortDefinitionSet)[colInd] <- c("cohortDefinitionId", "cohortName", "sqlCommand", "json")
        if (!"description" %in% names(cohortDefinitionSet)) {
          cohortDefinitionSet$description <- ""
        }
        cohortDefinitions <- cohortDefinitionSet[, intersect(names(cohortDefinitions), names(cohortDefinitionSet))]
      }
      writeCsv(x = cohortDefinitions, file = file.path(outputFolder, "cg_cohort_definition.csv"))
      writeCsv(x = cohortSubsets, file = file.path(outputFolder, "cg_cohort_subset_definition.csv"))
    }
    environment(exportCohortDefinitionSet) <- asNamespace("CohortGenerator")
    utils::assignInNamespace("exportCohortDefinitionSet", exportCohortDefinitionSet, ns = "CohortGenerator")
    message("CohortGenerator 0.11.2: cohort definition export fixed for large cohort IDs")
  })
}
