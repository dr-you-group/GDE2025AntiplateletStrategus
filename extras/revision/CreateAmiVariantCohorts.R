# JACC Asia revision: builds the AMI-variant outcome cohorts. Sites do NOT run this;
# its outputs (inst/cohorts, inst/sql/sql_server, inst/Cohorts.csv) are in the package.
#   V1: AMI recorded on the start date of an inpatient/ER visit (new admission)
#   V2: inpatient/ER AMI with no PCI 1-6 days before it (AMI from day 7 after index PCI)
# Applied to AMI, MACE, NACE and the ischemic composite; other components unchanged.
library(jsonlite)

parents <- data.frame(
  parentId = c(1792370, 1792367, 1792366, 1792369),
  label = c("AMI", "MACE", "NACE", "Ischemic event")
)
amiConceptSetName <- "[GDE2025_Antiplatelet] AMI (from LEGEND)"
visitConceptSetName <- "[GDE2025_Antiplatelet] InpatientER visit"
pciConceptSetName <- "[GDE2025_Antiplatelet] PCI"

readCohort <- function(id) {
  fromJSON(file.path("inst", "cohorts", paste0(id, ".json")), simplifyVector = FALSE)
}

conceptSetId <- function(cohort, name) {
  ids <- Filter(Negate(is.null), lapply(cohort$ConceptSets, function(cs) if (cs$name == name) cs$id))
  if (length(ids) != 1) stop("Concept set not found: ", name)
  ids[[1]]
}

# Inpatient/ER visit around the AMI record (original rule)
visitSpanningEvent <- function(visitCodesetId) {
  list(
    Criteria = list(VisitOccurrence = list(CodesetId = visitCodesetId, VisitTypeExclude = FALSE)),
    StartWindow = list(Start = list(Coeff = -1), End = list(Days = 0, Coeff = 1),
                       UseIndexEnd = FALSE, UseEventEnd = FALSE),
    EndWindow = list(Start = list(Days = 0, Coeff = -1), End = list(Coeff = 1),
                     UseIndexEnd = FALSE, UseEventEnd = TRUE),
    RestrictVisit = FALSE, IgnoreObservationPeriod = FALSE,
    Occurrence = list(Type = 2, Count = 1, IsDistinct = FALSE)
  )
}

# V1: inpatient/ER visit starting on the AMI date
visitStartingOnEvent <- function(visitCodesetId) {
  list(
    Criteria = list(VisitOccurrence = list(CodesetId = visitCodesetId, VisitTypeExclude = FALSE)),
    StartWindow = list(Start = list(Days = 0, Coeff = -1), End = list(Days = 0, Coeff = 1),
                       UseIndexEnd = FALSE, UseEventEnd = FALSE),
    RestrictVisit = FALSE, IgnoreObservationPeriod = FALSE,
    Occurrence = list(Type = 2, Count = 1, IsDistinct = FALSE)
  )
}

# V2: no PCI in the 1-6 days before the AMI date
noPciInPriorSixDays <- function(pciCodesetId) {
  list(
    Criteria = list(ProcedureOccurrence = list(CodesetId = pciCodesetId)),
    StartWindow = list(Start = list(Days = 6, Coeff = -1), End = list(Days = 1, Coeff = -1),
                       UseIndexEnd = FALSE, UseEventEnd = FALSE),
    RestrictVisit = FALSE, IgnoreObservationPeriod = FALSE,
    Occurrence = list(Type = 0, Count = 0, IsDistinct = FALSE)
  )
}

group <- function(criteriaList) {
  list(Type = "ALL", CriteriaList = criteriaList, DemographicCriteriaList = list(), Groups = list())
}

addPciConceptSet <- function(cohort) {
  pciSet <- Filter(function(cs) cs$name == pciConceptSetName, readCohort(1792797)$ConceptSets)[[1]]
  pciSet$id <- max(sapply(cohort$ConceptSets, function(cs) cs$id)) + 1
  cohort$ConceptSets <- c(cohort$ConceptSets, list(pciSet))
  cohort
}

# Visit requirements kept as a cohort-wide inclusion rule (1792370, 1792369) are moved
# onto each primary criterion, so the AMI-specific rule does not touch other events.
moveVisitRuleToCriteria <- function(cohort, visitCodesetId) {
  if (length(cohort$InclusionRules) == 0) return(cohort)
  if (length(cohort$InclusionRules) != 1 || cohort$InclusionRules[[1]]$name != "Inpatient") {
    stop("Unexpected inclusion rules")
  }
  cohort$PrimaryCriteria$CriteriaList <- lapply(cohort$PrimaryCriteria$CriteriaList, function(crit) {
    crit[[1]]$CorrelatedCriteria <- group(list(visitSpanningEvent(visitCodesetId)))
    crit
  })
  cohort$InclusionRules <- list()
  cohort
}

makeVariant <- function(parentId, variant) {
  cohort <- readCohort(parentId)
  amiId <- conceptSetId(cohort, amiConceptSetName)
  visitId <- conceptSetId(cohort, visitConceptSetName)
  cohort <- moveVisitRuleToCriteria(cohort, visitId)
  if (variant == "V2") {
    cohort <- addPciConceptSet(cohort)
    pciId <- conceptSetId(cohort, pciConceptSetName)
  }
  nAmi <- 0
  cohort$PrimaryCriteria$CriteriaList <- lapply(cohort$PrimaryCriteria$CriteriaList, function(crit) {
    if (names(crit) != "ConditionOccurrence" || crit[[1]]$CodesetId != amiId) return(crit)
    nAmi <<- nAmi + 1
    rules <- if (variant == "V1") {
      list(visitStartingOnEvent(visitId))
    } else {
      list(visitSpanningEvent(visitId), noPciInPriorSixDays(pciId))
    }
    crit[[1]]$CorrelatedCriteria <- group(rules)
    crit
  })
  if (nAmi != 1) stop("Expected exactly one AMI criterion in cohort ", parentId)
  cohort
}

variantText <- c(
  V1 = "V1, AMI on inpatient/ER admission date",
  V2 = "V2, AMI from day 7: no PCI in prior 1-6 days"
)
variantLogic <- c(
  V1 = "AMI component requires the AMI record on the start date of an inpatient or ER visit (proxy for admission for AMI). Other components unchanged.",
  V2 = "AMI component requires an inpatient/ER AMI record with no PCI 1-6 days before it (7-day blanking after the index PCI). Other components unchanged."
)

csvLines <- readLines("inst/Cohorts.csv", warn = FALSE)
for (i in seq_len(nrow(parents))) {
  for (variant in c("V1", "V2")) {
    newId <- parents$parentId[i] * 10 + ifelse(variant == "V1", 1, 2)
    cohort <- makeVariant(parents$parentId[i], variant)
    json <- toJSON(cohort, auto_unbox = TRUE, pretty = TRUE, null = "null", digits = NA)
    writeLines(json, file.path("inst", "cohorts", paste0(newId, ".json")))
    sql <- CirceR::buildCohortQuery(
      CirceR::cohortExpressionFromJson(as.character(json)),
      CirceR::createGenerateOptions(generateStats = TRUE)
    )
    writeLines(sql, file.path("inst", "sql", "sql_server", paste0(newId, ".sql")))
    csvLines <- csvLines[!startsWith(csvLines, paste0(newId, ","))]
    csvLines <- c(csvLines, sprintf(
      '%d,%d,"[GDE2025_Antiplatelet] Revision outcome - %s (%s)","%s",TRUE',
      newId, newId, parents$label[i], variantText[[variant]], variantLogic[[variant]]
    ))
  }
}
writeLines(csvLines, "inst/Cohorts.csv")
