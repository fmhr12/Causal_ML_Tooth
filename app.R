# ==============================================================================
# app.R
# Description: Final App with Custom Defaults, Clean UI, and Specific Messaging
# ==============================================================================

library(shiny)
library(grf)
library(shinythemes)

# Ensure data file exists
if (!file.exists("csf_model_deploy.rds")) stop("csf_deploy_data.rds not found! Please ensure the file is in the working directory.")
deploy_data  <- readRDS("csf_model_deploy.rds")
model        <- deploy_data$model
saved_levels <- deploy_data$saved_levels 
cat_vars     <- deploy_data$cat_vars
cont_vars    <- deploy_data$cont_vars

# ==============================================================================
# 1. DEFAULTS
# ==============================================================================
defaults <- list(
  Age                            = 60,
  Smoking_Pack_per_Year          = 0,
  DMFS                           = 30,
  Number_Teeth_before_Extraction = 24,
  RT_Fx                          = 30,
  Duration_RT_Days               = 40,
  RT_Dose                        = 60,
  Income_1000                    = 600,
  D10cc                          = 65
)

# ==============================================================================
# 2. VARIABLE LABELS MAP
# ==============================================================================
var_label_map <- list(
  # Categorical
  Sex                          = "Sex",
  ECOG_Merged                  = "ECOG Performance Status",
  Drinking_History_Merged      = "Alcohol Consumption",
  TNM_Staging_Merged_2         = "TNM Stage",
  Primary_Treatment_Modality   = "Primary Treatment",
  Insurance_Type               = "Dental Insurance",
  Periodontal_Grading_Merged   = "Periodontal Condition",
  HPV                          = "HPV Status",
  Disease_Site_Merged_2        = "Tumor Site",
  Histological_Diagnosis       = "Histology",
  Chemotherapy                 = "Chemotherapy",
  
  # Continuous
  Age                            = "Age (years)",
  Income_1000                    = "Income (in $1,000)",
  Smoking_Pack_per_Year          = "Smoking pack-year",
  DMFS                           = "DMFS (Decayed, Missing, Filled Surfaces)",
  Number_Teeth_before_Extraction = "Number of teeth before extraction",
  Duration_RT_Days               = "Duration of RT (Days)",
  RT_Dose                        = "Prescription RT Dose (Gy)",
  RT_Fx                          = "Number of RT fractions",
  D10cc                          = "D10cc (Gy)"
)

# ==============================================================================
# 3. DROPDOWN OPTIONS & DEFAULTS
# ==============================================================================
ui_config <- list(
  Sex = list(choices = c("Male" = "0", "Female" = "1"), selected = "0"),
  ECOG_Merged = list(choices = c("0" = "0", "1 (Scores 1-4)" = "1"), selected = "1"),
  Drinking_History_Merged = list(choices = c("Never (Non-drinker)" = "0", "Previous (Ex-drinker)" = "1", "Current" = "2"), selected = "0"),
  TNM_Staging_Merged_2 = list(choices = c("I-II" = "1", "III-IV" = "2"), selected = "2"),
  Primary_Treatment_Modality = list(choices = c("Surgery" = "0", "Radiotherapy" = "1"), selected = "1"),
  Insurance_Type = list(choices = c("Self-Pay" = "0", "Private" = "1", "Public" = "2"), selected = "2"),
  Periodontal_Grading_Merged = list(choices = c("Grade 0" = "0", "Grade I-II" = "1", "Grade III-IV" = "2"), selected = "2"),
  HPV = list(choices = c("Negative" = "0", "Not tested" = "1", "Positive" = "2"), selected = "0"),
  Disease_Site_Merged_2 = list(choices = c("Others" = "0", "Oropharynx" = "1", "Oral Cavity" = "2"), selected = "2"),
  Histological_Diagnosis = list(choices = c("Non-SCC" = "0", "SCC" = "1"), selected = "1"),
  Chemotherapy = list(choices = c("No" = "0", "Yes" = "1"), selected = "0")
)

# ==============================================================================
# UI
# ==============================================================================
ui <- fluidPage(
  theme = shinytheme("flatly"),
  titlePanel("Personalized Treatment Effect Tool"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Patient Profile"),
      tabsetPanel(
        tabPanel("Categorical", br(),
                 lapply(cat_vars, function(v) {
                   my_label <- if(!is.null(var_label_map[[v]])) var_label_map[[v]] else v
                   config <- ui_config[[v]]
                   choices <- if (!is.null(config)) config$choices else saved_levels[[v]]
                   sel      <- if (!is.null(config)) config$selected else NULL
                   selectInput(inputId = v, label = my_label, choices = choices, selected = sel)
                 })
        ),
        tabPanel("Continuous", br(),
                 lapply(cont_vars, function(v) {
                   my_label <- if(!is.null(var_label_map[[v]])) var_label_map[[v]] else v
                   val <- if(!is.null(defaults[[v]])) defaults[[v]] else 0
                   numericInput(v, my_label, val)
                 })
        )
      ),
      br(), 
      actionButton("btn_predict", "Calculate Treatment Effect", class = "btn-success btn-lg", width = "100%")
    ),
    
    mainPanel(
      h3("Pre-radiotherapy Extraction Effect on Osteoradionecrosis Risk"), 
      uiOutput("result_panel")
    )
  )
)

# ==============================================================================
# Server
# ==============================================================================
server <- function(input, output) {
  
  prediction_data <- eventReactive(input$btn_predict, {
    input_list <- list()
    
    # 1. Process Categorical
    for (v in cat_vars) {
      val_code <- as.character(input[[v]])
      level_idx <- match(val_code, saved_levels[[v]])
      if (is.na(level_idx)) stop(paste0("Error: Code '", val_code, "' not found."))
      input_list[[v]] <- as.integer(level_idx)
    }
    
    # 2. Process Continuous
    for (v in cont_vars) input_list[[v]] <- as.numeric(input[[v]])
    
    as.matrix(as.data.frame(input_list)[, c(cat_vars, cont_vars)])
  })
  
  output$result_panel <- renderUI({
    req(prediction_data())
    
    # Predict and Round to 2 decimals
    val <- round(predict(model, newdata = prediction_data())$predictions, 2)
    
    # Conditional Messaging
    if(val > 0) {
      # Benefit
      msg_color <- "#27ae60" # Green
      msg_text  <- HTML(paste0("<b>Benefit:</b> Extraction is estimated to extend ORN-free survival by <b>", val, " months</b>."))
    } else if(val < 0) {
      # Harm
      msg_color <- "#c0392b" # Red
      msg_text  <- HTML(paste0("<b>Harm:</b> Extraction is estimated to reduce ORN-free survival by <b>", abs(val), " months</b>."))
    } else {
      # Neutral
      msg_color <- "grey"
      msg_text  <- "Neutral: No significant difference in RMST detected."
    }
    
    # UPDATED RESULT DISPLAY
    div(style="border:2px solid #2c3e50; padding:20px; border-radius:10px; text-align:center;",
        h4("Conditional Average Treatment Effect (CATE):"),
        h5("Difference in RMST (Horizon: 60 Months)", style="color: #7f8c8d; margin-top: -5px;"),
        h1(paste(val, "months"), style=paste0("color:", msg_color, "; font-weight:bold;")),
        hr(), 
        h4(msg_text)
    )
  })
}

shinyApp(ui, server)
