library(shiny)
library(shinyFiles)

shinyUI(pageWithSidebar(
    headerPanel("Discount factor calculator"),
    sidebarPanel(
      fileInput("file1", "Choose CSV file that contains the historical data",
                accept = c(
                  "test/csv",
                  "test/comma-separated-values,text/plain",
                  ".csv")
                ),
    # radioButtons("intervalType", "Choose the record time interval",
    #              c("fifteen minutes" = "fifteen",
    #                "one hour" = "onehour")
    #              ),
    dateRangeInput("histDates", "Choose historical window",
                   start = '2010-01-01',
                   end = as.character(Sys.Date() - 10)),
    helpText("Select whether the discount factors should be calculated at the peak day type + hour level,
             or price segment level. Both will be by plant, by month."),
    selectInput("level", "Choose level of aggregation",
                c("peak day type + hour", "segment")),
    actionButton("goButton", "Go!"),
    shinySaveButton("save", "Save file", "save file as ...", 
                    filetype = list(csv = "csv"))
    ),
    mainPanel(
        tabsetPanel(
          tabPanel("summary", tableOutput("contents"))
          # tabPanel("plots", plotOutput("plots"))
      )
    )
  )
)