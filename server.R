library(shiny)
library(caret)

load("fitted_model.RData")

shinyServer(function(input,output){
  
  PREDICTORS <- reactive({
    as.data.frame(list(SECMEAN = input$SECMEAN, PH_LAB=input$PH_LAB, COND=input$COND, PTL=input$PTL,
                       TEMP_FIELD=input$TEMP_FIELD, DO_FIELD=input$DO_FIELD, DEPTHMAX=input$DEPTHMAX, 
                       LAKEAREA=input$LAKEAREA, SLD=input$SLD, DATE=input$DATE))
  })
  
  # Use the model to predict chl a
  CHLA <- reactive({      
    predict(modFit_RF, PREDICTORS())
  })
  
  # Generate chl a estimate as a text ouput 
  output$CHLA_text <- renderPrint({
    print("The estimated chlorophyll a concentration (ug/L) is:")
    CHLA()
  })
  
})