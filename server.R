library(shiny)
library(readr)
library(plyr)

options(shiny.maxRequestSize = 60*1024^2)

shinyServer(function(input, output, session){

  myData <- reactive({
    if(input$goButton == 0)
      return()
    
    inFile <- input$file1
    if(is.null(inFile))
      return(NULL)
    raw <- read_csv(inFile$datapath, col_names = c("date", "interval", "plant", "mw", "price", "revenue",
                                            "peakday", "bucket", "hour", "month", "year"),
             col_types = list(
               date = col_datetime(format="%m/%d/%Y"),
               interval = col_integer(),
               plant = col_character(),
               mw = col_double(),
               price = col_double(),
               revenue = col_double(),
               peakday = col_character(),
               bucket = col_character(),
               hour = col_integer(),
               month = col_integer(),
               year = col_integer()), skip = 1)
    
    # get rid of daylight savings extra hour in November
    raw <- raw[-which(raw$hour==25),]
    
    # replace empty price/revenue with 0 (if the file is set up properly, this should have no effect)
    raw[is.na(raw)] <- 0
    
    # select only period defined by the user
    raw_select <- raw[which(raw$date>=parse_datetime(input$histDates[1], "%Y-%m-%d") & 
                              raw$date <=parse_datetime(input$histDates[2], "%Y-%m-%d")),]
    
    # segmental price to be appended to hourly data
    price_by_seg <- ddply (raw_select, .(plant, month, bucket), summarize,
                           seg_price = mean(price))
    
    # 4 below is due to the raw operation data being given in 15 min increments
    plant_summary <- ddply (raw_select, .(plant, month, bucket, hour), summarize,
                            total_revenue = sum(revenue),
                            ave_price = mean(price),
                            total_mw = sum(mw))
    
    # after joining, the segment prices (ave_price) is repeated for the same hour block
    plant_summary <- join(plant_summary, price_by_seg, by=c("plant", "month", "bucket"), 
                          type = "left")
    
    if (input$level == "segment"){
      plant_summary <- ddply(plant_summary, .(plant, month, bucket), summarize,
                             total_revenue = sum(total_revenue),
                             ave_price = mean(ave_price),
                             total_mw = sum(total_mw),
                             seg_price = mean(seg_price))
    }
    # the discount factors are calculated at the month/bucket/hour level, remove levels in the statements above if needed
    plant_summary <- mutate (plant_summary,
                             discount_factor = (total_revenue/total_mw - ave_price)/ave_price)
    return(plant_summary)
    
  })
  
  output$contents <- renderTable(myData())
  
  observe({
    volumes <- c("UserFolder" = "P:/Risk/Risk - Risk Management")
    shinyFileSave(input, "save", roots=volumes, session=session)
    fileinfo <- parseSavePath(volumes, input$save)
    if(nrow(fileinfo) > 0){
      write.csv(myData(), as.character(fileinfo$datapath), row.names = FALSE)
    }
  })
})