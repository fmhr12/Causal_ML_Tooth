# Personalized Treatment Effect Tool (Causal Survival Forest)

A Shiny application that estimates the conditional average treatment effect (CATE) of pre-radiotherapy dental extractions on Osteoradionecrosis (ORN) free survival.

This tool uses a Causal Survival Forest (GRF) model to predict the difference in Restricted Mean Survival Time (RMST) over a 60-month horizon based on specific patient characteristics.

## Features

* **Personalized CATE Estimation:** Calculates the specific benefit or harm of dental extractions for an individual patient profile.
* **RMST Difference:** Outputs the result in "Months gained or lost" over a 5-year (60-month) period.
* **Clear Interpretation:** Automatically flags results as "Benefit" (Green) or "Harm" (Red).
* **Comprehensive Inputs:** Accounts for tumor site, D10cc dose, periodontal status, smoking history, and more.

## Prerequisites

To run this application, you need **R** installed along with the following packages:

```r
install.packages(c("shiny", "grf", "shinythemes"))
