-- NACE V2: era union of its components (death + cohorts 17923702, 1792373, 1792372, 1792374).
-- Same result as the Circe composite; built from cohorts already in the cohort table.
select person_id, min(start_date) as start_date, max(end_date) as end_date
into #final_cohort
from (
  select person_id, start_date, end_date, sum(is_start) over (partition by person_id order by start_date, is_start desc rows unbounded preceding) group_idx
  from (
    select person_id, start_date, end_date,
      case when max(end_date) over (partition by person_id order by start_date rows between unbounded preceding and 1 preceding) >= start_date then 0 else 1 end is_start
    from (
      select subject_id as person_id, cohort_start_date as start_date, cohort_end_date as end_date
      from @target_database_schema.@target_cohort_table
      where cohort_definition_id in (17923702, 1792373, 1792372, 1792374)
      union all
      -- death component as in the Circe composite: death in an observation period, end = death + 1 day (capped)
      select d.person_id, d.death_date as start_date,
        case when DATEADD(day,1,d.death_date) > op.observation_period_end_date then op.observation_period_end_date else DATEADD(day,1,d.death_date) end as end_date
      from @cdm_database_schema.DEATH d
      join @cdm_database_schema.OBSERVATION_PERIOD op on d.person_id = op.person_id
        and op.observation_period_start_date <= d.death_date and op.observation_period_end_date >= d.death_date
    ) CR
  ) ST
) GR
group by person_id, group_idx;

DELETE FROM @target_database_schema.@target_cohort_table where cohort_definition_id = @target_cohort_id;
INSERT INTO @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
select @target_cohort_id as cohort_definition_id, person_id, start_date, end_date
FROM #final_cohort CO;

TRUNCATE TABLE #final_cohort;
DROP TABLE #final_cohort;
