rm(list = ls())

suppressWarnings(suppressMessages({
  library(rstudioapi)
  library(RJDBC)
  library(openxlsx)
  library(tidyverse)
  library(lubridate)
  library(stringi)
  library(janitor)
  library(gtsummary)
  library(flextable)
  library(kableExtra)
  library(sjPlot)
  library(ggpubr)
  library(cowplot)
  library(ggdist)
  library(glmmTMB)
  library(rms)
  library(rmsb)
  library(brms)
  library(emmeans)
  library(car)
  library(arm)
  library(pROC)
  library(mgcv)
  library(MatchIt)
  library(survival)
  library(survminer)
}))

select <- dplyr::select
rename <- dplyr::rename
mutate <- dplyr::mutate
recode <- dplyr::recode
summarise <- dplyr::summarise
count <- dplyr::count

path <- "~/1_ticf_sec/722_PETV_emul_trial_analysis"
setwd(path)

folders <- c(
  "data", "gitignore", "gitignore/run", "gitignore/figures",
  "gitignore/data", "gitignore/html_reports"
)

invisible(lapply(folders, function(x) {
  if (!dir.exists(x)) dir.create(x, recursive = TRUE)
}))

invisible(lapply(
  list.files("r/functions", pattern = "\\.R$", full.names = TRUE),
  source
))

seeding <- 2025
set.seed(seeding)

analysis_settings <- list(
  short_max_days = 13,
  month_days = 30
)

if (!file.exists("data/data_analysis.rds")) {
  data_all <- readxl::read_excel(
    "gitignore/data/mastertable final 28_6 (5).xlsx"
  ) |>
    dplyr::select(
      BID,
      TXDate:`dvojkombo/jednokombo`,
      -c(
        `Čas od Tx do infekce`, `Time - end to recurence`,
        `Time overall - end`, `Time hospital - end`,
        `Time citlivost - end`, `Time per os - end`
      )
    ) |>
    dplyr::rename_with(
      ~"favourable_early_response",
      starts_with("Favourable early response")
    ) |>
    dplyr::rename(
      days_to_2ndUTI_6MFU = `Time to second UTI within 6mo`,
      treating_physician = `zodpovedny lekar`,
      planned_ATB_duration = `Předpokladana delka ATB lecby vstupne`,
      planned_ATB_duration_reason = `pozn k predpokladane`,
      Infection_to90D_day = `Realna infekce? do 90 dnů`,
      StartDate_ATB_peroral = `per os START`,
      StartDate_inHospital = `In Hospital Start`,
      StartDate_overall = `Overall Start`,
      StartDate_sensitivity = `Citlivost Start`,
      EndDate_therapy = `End Therapy`,
      profylaxis = `profylaxe`,
      profylaxis_details = `profylaxe co`,
      stent_in_situ = `JJ stent in situ po propusteni`,
      foreign_material = `RF cizorody material, nefrostomie, ZVD, bircker`,
      renofunctional_obstruction = `RF obstrukce`,
      past_urol_instrumentation =
        `RF urologicke operace a instrumentace v minulosti`,
      bph_pca_subvesical_obstruction = `BHP/ca prostaty/subvezikalni obstrukce`,
      urethral_stricture = `Striktura uretry`,
      ureteral_stricture_anastomosis =
        `Stenoza/striktura ureteru, problemy na anastomoze`,
      leak = `Leak`,
      urology_acute = `urologie_akutní`,
      possible_adpkd_cyst_infection = `Mozna infekce cysty ADPKD`,
      urology_acute_details = `urologie_akutni_co`,
      urology_anamnestic = `urologie_anamnesticky`,
      urology_anamnestic_details = `urologie_anamnesticky_co`,
      diabetes_severe = `diabetes insulin nebo multiorganovy`,
      congenital_defect = `vrozena_vada_MC`,
      polycystosis = `polycystoza`,
      exclusion_candidate = `adept na vyřazení`,
      notes = `pozn`,
      exclude_immediately = `vyřadit hned`,
      fever_signs = `zvýšená teplota, zimnice, třesavky`,
      severe_aki = `závažné AKI`,
      dysuria_UroInfSigns = `dysurie a další příznaky infekce MM`,
      asymptomatic_inflammatory_markers = `asymptomatická elevace ZP`,
      CRP_entry = `entry CRP`,
      CRP_max = `maximum CRP`,
      hemoculture_positive = `poz hemokultura`,
      InfAgent_1 = `agens 1`,
      InfAgent_2 = `agens 2`,
      hemoculture_agreed = `souhlasna kultivace`,
      clostridium = `clostridie`,
      ClostridiumDate = `clostridie datum`,
      mra_status = `Multirezistentni agens ano/ne`,
      mra_type = `Typ MRA`,
      readmission_90d_uti = `Readmision do 90 dnů pro IMC`,
      readmission_90d_other =
        `Readmission do 90 dnů pro jiný než IMC neplánovaný důvod`,
      early_worsening_after_deescalation = `Časné zhoršení po deeskalaci`,
      bad_response_early_worsening = `Bad response nebo casne zhorseni`,
      fever_before_planned_ATB_stop =
        `teplota pred predpokladanym vysazenim ATB`,
      clinical_worsening_before_planned_ATB_stop =
        `zhorseni stavu pred predpokladanym vysazenim`,
      urine_findings_worsening_before_planned_ATB_stop =
        `zhorsení mocového nalezu pred predpokladanym vysazením`,
      ATB_extension_CRP_dynamics = `dynamika crp`,
      ATB_extension_other_reason = `jiny duvod`,
      ATB_extension_urologic_procedure =
        `urologicky vykon vedouci k prodlouzeni`,
      ATB_extension_no_reason_identified = `neidentifikuji duvod prodlouzeni`,
      depletion_induction_or_rejection_treatment_6M =
        `IS indukcni deplece nebo lecba rejekce v 6m`,
      maintenance_immunosuppression = `udrzovaci IS chronicky`,
      standard_triple_immunosuppression = `standard trojkombo`,
      any_triple_immunosuppression = `any trojkombo`,
      dual_or_single_immunosuppression = `dvojkombo/jednokombo`
    )

  date_cols <- c(
    "TXDate", "Infection_to90D_day",
    "StartDate_ATB_peroral", "StartDate_inHospital",
    "StartDate_overall", "StartDate_sensitivity", "EndDate_therapy",
    "ClostridiumDate"
  )

  binary_cols <- c(
    "profylaxis", "stent_in_situ", "foreign_material",
    "renofunctional_obstruction", "past_urol_instrumentation",
    "bph_pca_subvesical_obstruction", "urethral_stricture",
    "ureteral_stricture_anastomosis", "leak", "urology_acute",
    "possible_adpkd_cyst_infection", "urology_anamnestic", "diabetes",
    "diabetes_severe", "congenital_defect", "polycystosis",
    "exclusion_candidate", "exclude_immediately", "fever_signs",
    "severe_aki", "dysuria_UroInfSigns",
    "asymptomatic_inflammatory_markers", "hemoculture_positive",
    "hemoculture_agreed", "clostridium", "mra_status",
    "favourable_early_response", "early_worsening_after_deescalation",
    "bad_response_early_worsening", "fever_before_planned_ATB_stop",
    "clinical_worsening_before_planned_ATB_stop",
    "urine_findings_worsening_before_planned_ATB_stop",
    "ATB_extension_CRP_dynamics", "ATB_extension_no_reason_identified",
    "depletion_induction_or_rejection_treatment_6M",
    "standard_triple_immunosuppression", "any_triple_immunosuppression",
    "dual_or_single_immunosuppression"
  )

  data_all <- data_all |>
    dplyr::mutate(
      dplyr::across(
        where(is.character),
        ~ na_if(str_squish(str_replace_all(.x, "\u00a0", " ")), "")
      ),
      readmission_90d_uti_raw = as.character(readmission_90d_uti),
      readmission_90d_other_raw = as.character(readmission_90d_other),
      ReadmissionDate_uti = readmission_90d_uti_raw,
      ReadmissionDate_other = readmission_90d_other_raw,
      ATB_extension_other_reason_details =
        as.character(ATB_extension_other_reason),
      ATB_extension_urologic_procedure_details =
        as.character(ATB_extension_urologic_procedure)
    ) |>
    data.frame()

  date_cols <- c(date_cols, "ReadmissionDate_uti", "ReadmissionDate_other")
  data_all <- data_all |>
    dplyr::mutate(
      dplyr::across(
        all_of(date_cols),
        ~ coalesce(
          ymd(str_extract(as.character(.x), "\\d{4}-\\d{1,2}-\\d{1,2}"),
            quiet = TRUE
          ),
          dmy(str_extract(
            as.character(.x), "\\d{1,2}\\.\\s*\\d{1,2}\\.\\s*\\d{4}"
          ), quiet = TRUE),
          mdy(str_extract(
            as.character(.x), "\\d{1,2}/\\d{1,2}/\\d{4}"
          ), quiet = TRUE),
          as.Date(
            floor(as.numeric(str_replace(str_extract(
              as.character(.x), "^\\d{5}(?:[.,]\\d+)?$"
            ), ",", "."))),
            origin = "1899-12-30"
          )
        )
      ),
      dplyr::across(
        all_of(binary_cols),
        ~ str_to_lower(as.character(.x))
      ),
      dplyr::across(
        all_of(binary_cols),
        ~ dplyr::case_when(
          is.na(.x) ~ 0L,
          .x %in% c("", "<br>", "<br/>", "<br />") ~ 0L,
          .x %in% c("0", "0.0", "0.00", "ne", "no", "false") ~ 0L,
          .x %in% c("1", "1.0", "1.00", "ano", "yes", "true") ~ 1L,
          str_detect(.x, "^(ano|yes|1)\\s*[-:]") ~ 1L,
          str_detect(.x, "^(ne|no|0)\\s*[-:]") ~ 0L,
          str_detect(.x, "\\s+1$") ~ 1L,
          str_detect(.x, "\\s+0$") ~ 0L,
          TRUE ~ NA_integer_
        )
      ),
      readmission_90d_uti = dplyr::case_when(
        is.na(readmission_90d_uti_raw) ~ 0L,
        str_to_lower(readmission_90d_uti_raw) %in%
          c("0", "0.0", "0.00", "ne", "no", "false", "<br>", "<br/>") ~ 0L,
        str_detect(
          str_to_lower(readmission_90d_uti_raw),
          "^(ne|no|0)\\s*[-:]"
        ) ~ 0L,
        str_to_lower(readmission_90d_uti_raw) %in%
          c("1", "1.0", "1.00", "ano", "yes", "true") ~ 1L,
        str_detect(
          str_to_lower(readmission_90d_uti_raw),
          "^(ano|yes|1)\\s*[-:]"
        ) ~ 1L,
        !is.na(ReadmissionDate_uti) ~ 1L,
        TRUE ~ NA_integer_
      ),
      readmission_90d_other = dplyr::case_when(
        is.na(readmission_90d_other_raw) ~ 0L,
        str_to_lower(readmission_90d_other_raw) %in%
          c("0", "0.0", "0.00", "ne", "no", "false", "<br>", "<br/>") ~ 0L,
        str_detect(
          str_to_lower(readmission_90d_other_raw),
          "^(ne|no|0)\\s*[-:]"
        ) ~ 0L,
        str_to_lower(readmission_90d_other_raw) %in%
          c("1", "1.0", "1.00", "ano", "yes", "true") ~ 1L,
        str_detect(
          str_to_lower(readmission_90d_other_raw),
          "^(ano|yes|1)\\s*[-:]"
        ) ~ 1L,
        !is.na(ReadmissionDate_other) ~ 1L,
        TRUE ~ NA_integer_
      ),
      dplyr::across(
        c(ATB_extension_other_reason, ATB_extension_urologic_procedure),
        ~ dplyr::case_when(
          is.na(.x) ~ 0L,
          str_to_lower(as.character(.x)) %in%
            c("", "0", "0.0", "ne", "no", "false", "<br>") ~ 0L,
          str_detect(
            str_to_lower(as.character(.x)),
            "^(ne|no|0)\\s*[-:]"
          ) ~ 0L,
          TRUE ~ 1L
        )
      ),
      dplyr::across(
        c(CRP_entry, CRP_max),
        ~ dplyr::if_else(
          is.na(.x),
          0,
          suppressWarnings(as.numeric(str_replace(
            as.character(.x), ",", "."
          )))
        )
      ),
      days_to_2ndUTI_6MFU = suppressWarnings(as.numeric(str_replace(
        as.character(days_to_2ndUTI_6MFU), ",", "."
      ))),
      planned_ATB_duration = factor(
        str_to_lower(planned_ATB_duration),
        levels = c("short", "medium", "long")
      ),
      treating_physician = factor(recode(
        str_to_lower(treating_physician),
        "jns." = "jnsl"
      )),
      across(c(InfAgent_1, InfAgent_2), str_to_upper),
      maintenance_immunosuppression = str_replace_all(
        str_to_lower(maintenance_immunosuppression), "\\s*,\\s*", ","
      ),
      StartDate_ATB_peroral = if_else(
        StartDate_ATB_peroral < StartDate_overall,
        StartDate_overall, StartDate_ATB_peroral
      ),
      TX_to_infection_months = as.numeric(
        StartDate_overall - TXDate
      ) / 30.4,
      ATB_duration_overall = as.numeric(
        EndDate_therapy - StartDate_overall
      ),
      ATB_hospital_duration = as.numeric(
        EndDate_therapy - StartDate_inHospital
      ),
      ATB_sensitivity_duration = as.numeric(
        EndDate_therapy - StartDate_sensitivity
      ),
      ATB_peroral_duration = if_else(
        is.na(StartDate_ATB_peroral), 0,
        as.numeric(EndDate_therapy - StartDate_ATB_peroral)
      ),
      ATB_IV_duration = ATB_duration_overall - ATB_peroral_duration,
      peroral_ATB = as.integer(ATB_peroral_duration > 0),
      days_to_90D_inf = as.numeric(Infection_to90D_day - EndDate_therapy),
      recurence_till_1M = as.integer(
        !is.na(days_to_90D_inf) & days_to_90D_inf >= 0 &
          days_to_90D_inf <= analysis_settings$month_days
      ),
      recurence_till_90D = as.integer(
        !is.na(days_to_90D_inf) & days_to_90D_inf >= 0 &
          days_to_90D_inf <= 90
      ),
      mra_positive = mra_status,
      high_risk_pathogen = as.integer(grepl(
        paste0(
          "pseud|psaer|pseaer|entfae|enterok|enteroc|faecal|encofaca|",
          "proteus|promir|protmira|provul|morgan|mormor|sermar|seratia|",
          "citfre|citkos|citrobacter|entclo|entaer|enterobacter"
        ),
        paste(InfAgent_1, InfAgent_2, sep = " "),
        ignore.case = TRUE
      ))
    ) |>
    data.frame()

  data_all <- data_all |>
    dplyr::mutate(
      mra_positive = dplyr::if_else(
        is.na(mra_positive), 0L, mra_positive
      ),
      hemoculture_agreed = dplyr::if_else(
        is.na(hemoculture_agreed), 0L, hemoculture_agreed
      )
    ) |>
    filter(TX_to_infection_months > 0) |>
    distinct() |>
    data.frame()

  bids <- data_all |>
    distinct(BID) |>
    filter(!is.na(BID)) |>
    mutate(BID = paste0("'", str_replace_all(BID, "'", "''"), "'")) |>
    pull(BID) |>
    paste0(collapse = ",")

  ticf_dig24c(
    "patient_info4",
    "
  SELECT
    Patient -> BID AS BID,
    Patient -> DateOfBirth AS DateOfBirth,
    Patient -> Sex AS Sex
  FROM
    IKEM_Patients.Data
  WHERE
    Patient -> BID in ({bids})
  "
  )

  patient_info <- read.csv(
    "gitignore/patient_info4.csv",
    sep = ";",
    colClasses = "character"
  ) |>
    select(BID, DateOfBirth, Sex) |>
    mutate(
      BID = na_if(str_squish(as.character(BID)), ""),
      DateOfBirth = ymd(DateOfBirth, quiet = TRUE),
      Sex = factor(str_to_upper(str_squish(Sex)), levels = c("F", "M"))
    ) |>
    group_by(BID) |>
    slice_head(n = 1) |>
    ungroup()

  data_all <- data_all |>
    mutate(BID = na_if(str_squish(as.character(BID)), "")) |>
    left_join(patient_info, by = "BID") |>
    group_by(BID) |>
    slice_head(n = 1) |>
    ungroup()

  data_all <- data_all |>
    select(-any_of(c("BID", "Patient"))) |>
    mutate(ID = as.character(row_number()), .before = 1) |>
    mutate(
      T0 = StartDate_sensitivity,
      calendar_year = year(T0),
      calendar_year_factor = factor(calendar_year),
      calendar_period = calendar_year_factor,
      age = as.numeric(StartDate_overall - DateOfBirth) / 365.25,
      years_from2019 = as.numeric(
        StartDate_overall - median(StartDate_overall, na.rm = TRUE)
      ) / 365.25,
      sex_female = case_when(
        Sex == "F" ~ 1L,
        Sex == "M" ~ 0L,
        TRUE ~ NA_integer_
      ),
      ATB_peroral_proportion = if_else(
        ATB_duration_overall > 0,
        ATB_peroral_duration / ATB_duration_overall, NA_real_
      ),
      treatment_under14D = if_else(
        ATB_sensitivity_duration >= 0,
        as.integer(ATB_sensitivity_duration <=
          analysis_settings$short_max_days),
        NA_integer_
      ),
      treatment_group = factor(
        case_when(
          treatment_under14D == 1 ~ "<=13 days",
          treatment_under14D == 0 ~ ">13 days",
          TRUE ~ NA_character_
        ),
        levels = c("<=13 days", ">13 days")
      ),
      days_to_confirmed_infection_from_T0 = as.numeric(
        Infection_to90D_day - T0
      ),
      days_to_readmission_uti_from_T0 = as.numeric(ReadmissionDate_uti - T0),
      days_to_readmission_other_from_T0 = as.numeric(
        ReadmissionDate_other - T0
      ),
      any_triple_immunosuppression = if_else(
        standard_triple_immunosuppression %in% 1L,
        1L, any_triple_immunosuppression
      ),
      immunosuppression_flags_conflict =
        (standard_triple_immunosuppression == 1 &
          any_triple_immunosuppression == 0) |
          ((standard_triple_immunosuppression == 1 |
            any_triple_immunosuppression == 1) &
            dual_or_single_immunosuppression == 1) |
          (standard_triple_immunosuppression == 0 &
            any_triple_immunosuppression == 0 &
            dual_or_single_immunosuppression == 0),
      immunosuppression_regimen = factor(
        case_when(
          immunosuppression_flags_conflict %in% TRUE ~ NA_character_,
          standard_triple_immunosuppression == 1 ~ "standard triple",
          standard_triple_immunosuppression == 0 &
            any_triple_immunosuppression == 1 ~ "other triple",
          dual_or_single_immunosuppression == 1 ~ "dual or single",
          TRUE ~ NA_character_
        ),
        levels = c("standard triple", "other triple", "dual or single")
      )
    )

  data_all <- data_all |>
    dplyr::mutate(
      age_by30y = age / 30,
      CRP_entry_by100 = CRP_entry / 100,
      CRP_max_by100 = CRP_max / 100,
      log2_CRP_entry = log2(if_else(
        CRP_entry > 0, CRP_entry, NA_real_
      )),
      log2_CRP_max = log2(if_else(
        CRP_max > 0, CRP_max, NA_real_
      )),
      log2_TX_to_infection = log2(TX_to_infection_months),
      log2_ATB_duration_overall = log2(ATB_duration_overall),
      log2_ATB_hospital_duration = log2(ATB_hospital_duration),
      log2_ATB_peroral_duration = log2(ATB_peroral_duration + 1),
      log2_ATB_IV_duration = log2(ATB_IV_duration),
      log2_ATB_sensitivity_duration = log2(ATB_sensitivity_duration)
    ) |>
    data.frame()

  bm_br_vars <- c(
    "fever_before_planned_ATB_stop",
    "clinical_worsening_before_planned_ATB_stop",
    "urine_findings_worsening_before_planned_ATB_stop",
    "ATB_extension_CRP_dynamics",
    "ATB_extension_other_reason",
    "ATB_extension_urologic_procedure"
  )

  data_all <- data_all |>
    dplyr::mutate(
      any_problem_D1_13 = dplyr::case_when(
        if_any(all_of(bm_br_vars), ~ .x == 1) ~ 1L,
        if_all(all_of(bm_br_vars), ~ .x == 0) ~ 0L,
        TRUE ~ NA_integer_
      ),
      uro_intervention_any = dplyr::case_when(
        renofunctional_obstruction == 1 | foreign_material == 1 |
          past_urol_instrumentation == 1 | urology_acute == 1 ~ 1L,
        renofunctional_obstruction == 0 & foreign_material == 0 &
          past_urol_instrumentation == 0 & urology_acute == 0 ~ 0L,
        TRUE ~ NA_integer_
      ),
      urology_chronic_broad = dplyr::case_when(
        stent_in_situ == 1 | bph_pca_subvesical_obstruction == 1 |
          urethral_stricture == 1 ~ 1L,
        stent_in_situ == 0 & bph_pca_subvesical_obstruction == 0 &
          urethral_stricture == 0 ~ 0L,
        TRUE ~ NA_integer_
      )
    ) |>
    dplyr::select(-any_of("SecondUTIDgDate")) |>
    data.frame()

  coding_issues <- data_all |>
    dplyr::select(all_of(c(
      binary_cols, "readmission_90d_uti", "readmission_90d_other"
    ))) |>
    summarise(across(everything(), ~ sum(is.na(.x)))) |>
    pivot_longer(everything(), names_to = "variable", values_to = "n") |>
    dplyr::filter(n > 0) |>
    data.frame()

  rm(patient_info, bids)

  outcome_summary <- data_all |>
    summarise(across(
      c(recurence_till_1M, recurence_till_90D),
      list(
        events = ~ sum(.x == 1, na.rm = TRUE),
        nonevents = ~ sum(.x == 0, na.rm = TRUE),
        unknown = ~ sum(is.na(.x))
      )
    ))


  zero_coding_check <- data_all |>
    dplyr::select(
      mra_positive,
      readmission_90d_uti,
      readmission_90d_other,
      high_risk_pathogen,
      past_urol_instrumentation,
      foreign_material,
      renofunctional_obstruction,
      hemoculture_agreed,
      CRP_entry,
      CRP_max,
      CRP_entry_by100,
      CRP_max_by100
    ) |>
    tidyr::pivot_longer(
      dplyr::everything(),
      names_to = "variable",
      values_to = "value"
    ) |>
    dplyr::group_by(variable) |>
    dplyr::summarise(
      zero = sum(value == 0, na.rm = TRUE),
      remaining_NA = sum(is.na(value)),
      .groups = "drop"
    ) |>
    data.frame()

  zero_coding_check
  coding_issues
  outcome_summary

  data_all |> count(treatment_group, name = "n")
  data_all |> count(immunosuppression_regimen, name = "n")

  data_all |>
    filter(immunosuppression_flags_conflict %in% TRUE) |>
    select(
      ID, maintenance_immunosuppression,
      standard_triple_immunosuppression, any_triple_immunosuppression,
      dual_or_single_immunosuppression
    )

  data_all |> filter(ATB_sensitivity_duration < 1)
  data_all |> filter(ATB_duration_overall < 6)
  data_all |> filter(days_to_90D_inf < 0)

  summary(data_all)
  str(data_all)


  data_all <- data_all |>
    dplyr::select(
      ID,
      T0,
      StartDate_overall,
      EndDate_therapy,
      Infection_to90D_day,
      recurence_till_1M,
      recurence_till_90D,
      ATB_sensitivity_duration,
      ATB_duration_overall,
      ATB_IV_duration,
      log2_ATB_sensitivity_duration,
      log2_ATB_duration_overall,
      sex_female,
      age,
      age_by30y,
      TX_to_infection_months,
      log2_TX_to_infection,
      years_from2019,
      urology_acute,
      stent_in_situ,
      bph_pca_subvesical_obstruction,
      urethral_stricture,
      renofunctional_obstruction,
      diabetes_severe,
      diabetes,
      mra_positive,
      bad_response_early_worsening,
      hemoculture_positive,
      fever_signs,
      dysuria_UroInfSigns,
      InfAgent_1,
      hemoculture_agreed,
      profylaxis,
      severe_aki,
      CRP_entry,
      CRP_max,
      CRP_entry_by100,
      CRP_max_by100,
      past_urol_instrumentation,
      immunosuppression_regimen,
      depletion_induction_or_rejection_treatment_6M,
      calendar_period,
      any_problem_D1_13,
      fever_before_planned_ATB_stop,
      clinical_worsening_before_planned_ATB_stop,
      urine_findings_worsening_before_planned_ATB_stop,
      ATB_extension_CRP_dynamics,
      ATB_extension_other_reason,
      ATB_extension_urologic_procedure,
      clostridium
    ) |>
    data.frame()

  data_analysis <- data_all |>
    dplyr::filter(!is.na(CRP_entry)) |>
    dplyr::mutate(
      ID = as.character(ID),
      days_after_therapy = as.numeric(Infection_to90D_day - EndDate_therapy),
      recurence_till_1M = as.integer(
        !is.na(days_after_therapy) &
          days_after_therapy >= 0 & days_after_therapy <= 30
      ),
      recurence_till_90D = as.integer(
        !is.na(days_after_therapy) &
          days_after_therapy >= 0 & days_after_therapy <= 90
      ),
      ATB_sensitivity_per7 = ATB_sensitivity_duration / 7,
      ATB_overall_per7 = ATB_duration_overall / 7,
      treatment_under14D = as.integer(ATB_sensitivity_duration <= 13),
      treatment_group = factor(
        treatment_under14D,
        levels = c(1, 0),
        labels = c("<=13 days", ">13 days")
      ),
      calendar_year = lubridate::year(T0),
      calendar_period = factor(
        dplyr::case_when(
          calendar_year <= 2016 ~ "<=2016",
          calendar_year <= 2021 ~ "2017-2021",
          calendar_year >= 2022 ~ ">=2022"
        ),
        levels = c("<=2016", "2017-2021", ">=2022")
      )
    ) |>
    data.frame()


  write.csv(data_analysis, "data/data_analysis.csv", row.names = FALSE)
  saveRDS(data_analysis, "data/data_analysis.rds")
}

data_analysis <- readRDS("data/data_analysis.rds")

