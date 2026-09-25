**Authors and affiliations**

<div style="font-size: larger;">
Adriana Chroma<sup>1</sup>, Vojtech Petr<sup>1,&#42;</sup>, Filip Tichanek<sup>2</sup>, Michal Schmalz<sup>1</sup>, Katarina Jakubov<sup>1</sup>, Marta D'Angelo<sup>1,3</sup>, Ondrej Viklicky<sup>1</sup>, Ivan Zahradka<sup>1</sup>
</div>

<br>

<sup>1</sup> Department of Nephrology, Transplant Center, Institute for Clinical and Experimental Medicine, Prague, Czech Republic<br>
<sup>2</sup> Department of Data Science, Institute for Clinical and Experimental Medicine, Prague, Czech Republic<br>
<sup>3</sup> Nephrology Unit, University Hospital of Parma, Parma, Italy<br>
<sup>&#42;</sup> Correspondence: Vojtech Petr, vojtech.petr@ikem.cz

---

This repository contains the R/Quarto code and statistical report accompanying the manuscript ***Short versus prolonged antibiotic therapy for complicated urinary tract infection in kidney transplant recipients: a target trial emulation***.

When using this code or data, please cite the manuscript:

> Chroma A., Petr V., Tichanek F., Schmalz M., Jakubov K., D'Angelo M., Viklicky O., Zahradka I. Short versus prolonged antibiotic therapy for complicated urinary tract infection in kidney transplant recipients: a target trial emulation. Publication details and DOI: TO BE ADDED.

---

Statistical **report**: TO BE ADDED

Original **GitHub repository**: TO BE ADDED

**Zenodo data and code archive**: TO BE ADDED

The repository is organized as follows:

- `quarto/`: Quarto analysis script and report source
- `r/initiation.R`: Initialization script for loading packages, functions and preparing the analysis dataset
- `r/functions/`: Supporting R functions
- `data/data_analysis.rds`: Analysis dataset with R variable classes preserved
- `data/data_analysis.csv`: CSV export of the analysis dataset

---

# Introduction

This single-centre retrospective study includes 544 adult kidney transplant recipients hospitalized for a first qualifying complicated urinary tract infection at the Institute for Clinical and Experimental Medicine, Prague, between January 2008 and April 2026. It compares sensitivity ATB therapy stopped by day 13 (short strategy) with therapy continued to day 14 or beyond (prolonged strategy).

## Main questions

1/ Is the short strategy non-inferior to the prolonged strategy for recurrence within 30 days after therapy completion?

2/ Are findings consistent for recurrence within 90 days, relapse with the same pathogen, and patients treated from 2017 onward?

3/ Which patient and infection characteristics are associated with recurrence?

## Statistical methods

The primary comparison uses 1:1 propensity score matching within calendar periods. Recurrence-free survival is described using Kaplan–Meier curves, with pair-stratified log-rank tests and Cox models with variance clustered by matched pair. Hazard ratios are estimated separately over 30 and 90 days after therapy completion. Recurrence proportions at these time points are compared using exact McNemar tests with Holm adjustment.

Unadjusted and multivariable logistic regression assess associations with recurrence. Additional analyses include relapse among patients with an identified initial pathogen and a two-period approximation to clone–censor–weight (CCW) analysis. The CCW stopping model includes baseline covariates and six indicators of the clinical course during days 1–13. Weighted recurrence risks, risk differences and risk ratios are reported with percentile confidence intervals from 500 patient-level bootstrap replicates.

Analyses are presented for all eligible patients and for patients treated from 2017 onward. For matched comparisons, the contemporary cohort is selected from the original matched sample, preserving matched pairs. The non-inferiority margin is 1.5 for the primary recurrence HR; the additional CCW comparison uses an RR margin of 1.5.

## Analysis data

`data_analysis` contains one row per patient and the variables used in the analyses. `ID` is an artificial identifier generated from row order, retained for matching, CCW and patient-level resampling. The RDS format preserves dates, factors and other R variable classes; the CSV provides the same data in a portable format.

The primary endpoint is recurrence within 30 days after therapy completion; recurrence within 90 days is secondary. An empty recurrence date indicates that no recurrence was recorded within the specified follow-up window. Relapse requires a recorded recurrence with concordant pathogens in the initial and recurrent infections. Sensitivity ATB duration determines the treatment strategy, and its initiation defines time zero for the CCW framework.

### `data_analysis.rds` data dictionary

One row represents one patient. Recurrence is assessed after therapy completion. ATB: antibiotic; UTI: urinary tract infection; CRP: C-reactive protein; BPH: benign prostatic hyperplasia.

| Variable | Type | Description | Values / Units |
| :--- | :--- | :--- | :--- |
| `ID` | Character | Artificial patient identifier | Patient ID |
| `T0` | Date | Initiation of sensitivity ATB therapy (CCW time zero) | YYYY-MM-DD |
| `TXDate` | Date | Kidney transplantation date | YYYY-MM-DD |
| `StartDate_overall` | Date | Start of overall ATB therapy | YYYY-MM-DD |
| `StartDate_sensitivity` | Date | Start of sensitivity ATB therapy | YYYY-MM-DD |
| `StartDate_ATB_peroral` | Date | Start of peroral ATB therapy | YYYY-MM-DD |
| `EndDate_therapy` | Date | Completion of ATB therapy | YYYY-MM-DD |
| `Infection_to90D_day` | Date | Date of recurrent UTI | YYYY-MM-DD; missing: no recorded recurrence within 90 days |
| `ATB_sensitivity_duration` | Numeric | Sensitivity ATB duration | Days |
| `ATB_duration_overall` | Numeric | Overall ATB duration | Days |
| `ATB_peroral_duration` | Numeric | Peroral ATB duration | Days; 0: no peroral therapy |
| `ATB_IV_duration` | Numeric | IV ATB duration | Days |
| `ATB_sensitivity_per7` | Numeric | Sensitivity ATB duration per additional seven days | One unit = 7 days |
| `ATB_overall_per7` | Numeric | Overall ATB duration per additional seven days | One unit = 7 days |
| `log2_ATB_sensitivity_duration` | Numeric | Sensitivity ATB duration per doubling | One unit = doubling of days |
| `log2_ATB_duration_overall` | Numeric | Overall ATB duration per doubling | One unit = doubling of days |
| `treatment_under14D` | Numeric (binary) | Short-treatment indicator | 1 = <=13 days |
| `treatment_group` | Factor | Treatment group for descriptive tables | Levels: `<=13 days`, `>13 days` |
| `days_after_therapy` | Numeric | Days from therapy completion to recorded recurrence | Days |
| `recurence_till_1M` | Numeric (binary) | Recurrence within 30 days after therapy completion | 0: No, 1: Yes |
| `recurence_till_90D` | Numeric (binary) | Recurrence within 90 days after therapy completion | 0: No, 1: Yes |
| `InfAgent_1` | Character | Pathogen recorded for the initial UTI | Organism name or abbreviation |
| `hemoculture_agreed` | Binary | Concordant pathogens in the initial and recurrent UTI | 0: No, 1: Yes |
| `hemoculture_positive` | Binary | Positive blood culture | 0: No, 1: Yes |
| `mra_positive` | Binary | Multidrug-resistant pathogen | 0: No, 1: Yes |
| `clostridium` | Binary | Recorded Clostridioides difficile infection | 0: No, 1: Yes |
| `sex_female` | Binary | Female sex | 0: Male, 1: Female |
| `age` | Numeric | Age at the index episode | Years |
| `age_by30y` | Numeric | Age per 30 years | One unit = 30 years |
| `TX_to_infection_months` | Numeric | Time from transplantation to index infection | Months |
| `log2_TX_to_infection` | Numeric | Log2-transformed time from transplantation to infection | One unit: doubling |
| `diabetes` | Binary | Diabetes mellitus | 0: No, 1: Yes |
| `diabetes_severe` | Binary | Complicated diabetes mellitus | 0: No, 1: Yes |
| `fever_signs` | Binary | Fever, chills or rigors | 0: No, 1: Yes |
| `dysuria_UroInfSigns` | Binary | Dysuria or other lower UTI symptoms | 0: No, 1: Yes |
| `severe_aki` | Binary | Stage 2–3 acute kidney injury | 0: No, 1: Yes |
| `bad_response_early_worsening` | Binary | Unfavourable early clinical response or early deterioration | 0: No, 1: Yes |
| `profylaxis` | Binary | Antibiotic prophylaxis | 0: No, 1: Yes |
| `urology_acute` | Binary | Acute urological complication or intervention | 0: No, 1: Yes |
| `stent_in_situ` | Binary | JJ ureteral stent in situ after discharge | 0: No, 1: Yes |
| `bph_pca_subvesical_obstruction` | Binary | BPH, prostate cancer or subvesical obstruction | 0: No, 1: Yes |
| `urethral_stricture` | Binary | Urethral stricture | 0: No, 1: Yes |
| `renofunctional_obstruction` | Binary | Obstruction | 0: No, 1: Yes |
| `past_urol_instrumentation` | Binary | History of urological surgery or instrumentation | 0: No, 1: Yes |
| `CRP_entry` | Numeric | Entry C-reactive protein | mg/L |
| `CRP_max` | Numeric | Maximum C-reactive protein during the index episode | mg/L |
| `CRP_entry_by100` | Numeric | Entry C-reactive protein, scaled | One unit: 100 mg/L |
| `CRP_max_by100` | Numeric | Maximum C-reactive protein, scaled | One unit: 100 mg/L |
| `calendar_year` | Numeric | Calendar year at sensitivity ATB initiation | Year |
| `calendar_period` | Factor | Calendar period at sensitivity ATB initiation | <=2016; 2017–2021; >=2022 |
| `years_from2019` | Numeric | Centred calendar time | Years |
| `maintenance_immunosuppression` | Character | Maintenance immunosuppressive regimen | Drug combination |
| `standard_triple_immunosuppression` | Binary | Standard tacrolimus, mycophenolate and corticosteroid triple therapy | 0: No, 1: Yes |
| `any_triple_immunosuppression` | Binary | Any triple immunosuppression | 0: No, 1: Yes |
| `dual_or_single_immunosuppression` | Binary | Dual or single maintenance immunosuppression | 0: No, 1: Yes |
| `immunosuppression_regimen` | Factor | Maintenance immunosuppression category | standard triple; other triple; dual or single |
| `depletion_induction_or_rejection_treatment_6M` | Binary | Depleting induction or rejection treatment in the preceding six months | 0: No, 1: Yes |
| `fever_before_planned_ATB_stop` | Binary | Fever during days 1–13 | 0: No, 1: Yes |
| `clinical_worsening_before_planned_ATB_stop` | Binary | Clinical worsening during days 1–13 | 0: No, 1: Yes |
| `urine_findings_worsening_before_planned_ATB_stop` | Binary | Worsening urinary findings during days 1–13 | 0: No, 1: Yes |
| `ATB_extension_CRP_dynamics` | Binary | CRP dynamics prompting treatment extension during days 1–13 | 0: No, 1: Yes |
| `ATB_extension_other_reason` | Binary | Other recorded reason for extending treatment during days 1–13 | 0: No, 1: Yes |
| `ATB_extension_urologic_procedure` | Binary | Urological procedure leading to treatment extension during days 1–13 | 0: No, 1: Yes |
| `any_problem_D1_13` | Binary | Any of the six recorded clinical-course problems during days 1–13 | 0: No, 1: Yes |

## Reproducibility

The Quarto report contains the analysis code, results and package versions from `sessionInfo()`. Computationally intensive results are cached using `run2()`. Existing cache files and PDF figures are retained until manually deleted; displayed figures are generated from the current analysis.
