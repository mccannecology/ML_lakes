library(shiny)
library(ggplot2)

shinyUI(pageWithSidebar(
  
  # Title
  headerPanel("Chlorophyll a Prediction"),
  
  sidebarPanel(
    
    numericInput("SECMEAN", 
                 label = "Secchi depth (m)", 
                 min = 0, 
                 max = 100,
                 value = 1.5),

    numericInput("PH_LAB", 
                 label = "pH", 
                 min = 1, 
                 max = 12,
                 value = 7.5),
    
    numericInput("COND", 
                 label = "Conductivity", 
                 min = 0, 
                 max = 20000,
                 value = 100),
    
    numericInput("PTL", 
                 label = "Total phosphorus (ug/L)", 
                 min = 0, 
                 max = 5000,
                 value = 100),
    
    numericInput("TEMP_FIELD", 
                 label = "Temperature (C)", 
                 min = 0, 
                 max = 40,
                 value = 25),
    
    numericInput("DO_FIELD", 
                 label = "Dissolved oxygen (mg/L)", 
                 min = 0, 
                 max = 25,
                 value = 7.5),
    
    numericInput("DEPTHMAX", 
                 label = "Depth, maximum (m)", 
                 min = 0, 
                 max = 100,
                 value = 5),
    
    numericInput("LAKEAREA", 
                 label = "Lake size (sq. km)", 
                 min = 0, 
                 max = 10000,
                 value = 0.01),
    
    numericInput("SLD", 
                 label = "Shoreline development index", 
                 min = 1, 
                 max = 10,
                 value = 1.5),

    numericInput("DATE", 
                 label = "Julian day of the year", 
                 min = 0, 
                 max = 365,
                 value = 200),
    
    hr(),
    helpText("")
  ),
  
  
  mainPanel(
    verbatimTextOutput("CHLA_text")
  )
  
  
  
))