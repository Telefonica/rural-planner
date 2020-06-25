
Sys.setlocale(locale = 'Spanish_Spain.1252')

library(shiny)
library(leaflet)
library(tidyverse)
library(stringr)
library(scales)
library(plotly)
library(shinydashboard)
library(DT)
library(shiny)
library(RColorBrewer)
library(rgeos)
library(DBI)
library(RSQLite)
library(geosphere)
library(Imap)
library(readr)


dev <- FALSE
create_data_for_prod <- FALSE

if (dev) {
  source('generateDatabaseForWWW.R', local = TRUE)
} 

sqlitePath <- "."
setwd(sqlitePath)  # But modify path if alternative path needed. 
database <- 'rpdashboard.sqlite'

db <- dbConnect(SQLite(), dbname=database)
input_tab_2 <- dbGetQuery(db, "SELECT * FROM input_tab_2")
input_tab_3 <- dbGetQuery(db, "SELECT * FROM input_tab_3")
input_tab_3_lines <- dbGetQuery(db, "SELECT * FROM input_tab_3_lines")
input_tab_4 <- dbGetQuery(db, "SELECT * FROM input_tab_4")

dbDisconnect(db)


# SERVER FUNCTION

shinyServer(function(input, output, session) {
  
  ####SEGMENTATION TAB
  
  departamento<-reactive({if (is.null(input$departamento) || input$departamento=="TODOS") unique(input_tab_2$departamento) else input$departamento})
  
  
  # Subset filtering options of the province based on the departamento selected
  
  output$municipio <- renderUI({
    selectizeInput("municipio",'Municipio',c("TODOS",unique(input_tab_2$municipio[which(input_tab_2$departamento%in%departamento())])), multiple= TRUE, selected='TODOS', options = list(maxOptions = 30, placeholder = 'Introduzca municipio'))
  })
  
  municipio<-reactive({if (is.null(input$municipio) || input$municipio=="TODOS") unique(input_tab_2$municipio) else input$municipio})
  
  
  # CONNECTED COLUMN
  
  # Create connected dataframe
  
  s_c <- reactive ({ data.frame("Segmento_Telefonica" = c("TELEFONICA SERVED","TELEFONICA UNSERVED","Total"), 
                                
                                "Poblacion" = c(sum(input_tab_2$poblacion[which(input_tab_2$municipio%in%municipio() & input_tab_2$departamento%in%departamento() & input_tab_2$segmento_telefonica=='TELEFONICA SERVED')], na.rm =TRUE), sum(input_tab_2$poblacion[which(input_tab_2$municipio%in%municipio() & input_tab_2$departamento%in%departamento() & input_tab_2$segmento_telefonica=='TELEFONICA UNSERVED')], na.rm =TRUE), sum(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_telefonica) & input_tab_2$municipio%in%municipio() & input_tab_2$departamento%in%departamento())], na.rm =TRUE)),
                                
                                "Num_CentrosPoblados" = c(length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_telefonica) & input_tab_2$segmento_telefonica=='TELEFONICA SERVED' & input_tab_2$municipio%in%municipio() & input_tab_2$departamento%in%departamento())]), length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_telefonica) & input_tab_2$segmento_telefonica=='TELEFONICA UNSERVED' & input_tab_2$municipio%in%municipio() & input_tab_2$departamento%in%departamento())]), length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_telefonica) & input_tab_2$municipio%in%municipio() & input_tab_2$departamento%in%departamento())]))
  )
  })
  
  
  # Set configuration for x axis
  
  ax <- list(
    title = "",
    zeroline = FALSE,
    showline = FALSE,
    showticklabels = FALSE,
    showgrid = FALSE
  )
  
  # Connected population plot
  
  output$poblacion_conectados <- renderPlotly(
    plot_ly(s_c()[!(s_c()$"Segmento_Telefonica"=='Total'),], x = c('TELEFONICA SERVED','TELEFONICA UNSERVED'), y = ~s_c()[!(s_c()$"Segmento_Telefonica"=='Total'),2], type = 'bar',
            marker = list(color = 'rgb(255,105,105)',
                          line = list(color = 'rgb(255,0,0)',
                                      width = 1.5))) %>%
      layout(title = ("Poblacion Conectados"),
             xaxis = ax,
             yaxis = list(title = "")) %>%
      config(displayModeBar=FALSE)
  )
  
  # Connected settlements plot
  
  output$settlements_conectados <-renderPlotly(
    plot_ly(s_c()[!(s_c()$"Segmento_Telefonica"=='Total'),], x = c('TELEFONICA SERVED','TELEFONICA UNSERVED'), y = ~s_c()[!(s_c()$"Segmento_Telefonica"=='Total'),3], type = 'bar',
            marker = list(color = 'rgb(255,105,105)',
                          line = list(color = 'rgb(255,0,0)',
                                      width = 1.5))) %>%
      layout(title = ("Num CCPP Conectados"),
             xaxis = ax,
             yaxis = list(title = "")) %>%
      config(displayModeBar=FALSE)
  )
  
  # Plot connected dataframe
  
  output$segmento_conectados <- renderTable(s_c())
  
  
  # OVERELAY COLUMN
  
  # Create overlay dataframe
  
  s_o <- reactive ({
    data.frame("Segmento_Overlay" = c("OVERLAY","Total"),
               
               "Poblacion" = c(sum(input_tab_2$poblacion[which(input_tab_2$municipio%in%municipio() & input_tab_2$departamento%in%departamento() & input_tab_2$segmento_overlay=='OVERLAY')], na.rm =TRUE), sum(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_overlay) & input_tab_2$municipio%in%municipio() & input_tab_2$departamento%in%departamento())], na.rm =TRUE)),
               
               "Num_CentrosPoblados" = c(length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_overlay) & input_tab_2$segmento_overlay=='OVERLAY' & input_tab_2$municipio%in%municipio() & input_tab_2$departamento%in%departamento())]), length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_overlay) & input_tab_2$municipio%in%municipio() & input_tab_2$departamento%in%departamento())]))
    )
  })
  
  #Overlay population plot
  
  output$poblacion_overlay <-  renderPlotly(
    plot_ly(s_o()[!(s_o()$"Segmento_Overlay"=='Total'),], x = c('OVERLAY'), y = ~s_o()[!(s_o()$"Segmento_Overlay"=='Total'),2], type = 'bar',
            marker = list(color = 'rgb(158,202,225)',
                          line = list(color = 'rgb(8,48,107)',
                                      width = 1.5))) %>%
      layout(title = ("Población Overlay"),
             xaxis = ax,
             yaxis = list(title = "")) %>%
      config(displayModeBar=FALSE)
  )
  
  
  # Overlay settlements plot
  
  output$settlements_overlay <-  renderPlotly(
    plot_ly(s_o()[!(s_o()$"Segmento_Overlay"=='Total'),], x = c('OVERLAY'), y = ~s_o()[!(s_o()$"Segmento_Overlay"=='Total'),3], type = 'bar',
            marker = list(color = 'rgb(158,202,225)',
                          line = list(color = 'rgb(8,48,107)',
                                      width = 1.5))) %>%
      layout(title = ("Num CCPP Overlay"),
             xaxis = ax,
             yaxis = list(title = "")) %>%
      config(displayModeBar=FALSE)
  )
  
  #Plot overlay dataframe
  
  output$segmento_overlay <- renderTable(s_o())
  
  
  #GREENFIELD COLUMN
  
  # Create Greenfield dataframe
  
  
  s_g <-   reactive({  data.frame("Segmento_Greenfield" = c("GREENFIELD","Total"),
                                  
                                  "Poblacion" = c(sum(input_tab_2$poblacion[which(input_tab_2$municipio%in%municipio() & input_tab_2$departamento%in%departamento() & input_tab_2$segmento_greenfield=='GREENFIELD')], na.rm =TRUE), sum(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_greenfield) & input_tab_2$municipio%in%municipio() & input_tab_2$departamento%in%departamento())], na.rm =TRUE)),
                                  
                                  "Num_CentrosPoblados" = c(length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_greenfield) & input_tab_2$segmento_greenfield=='GREENFIELD' & input_tab_2$municipio%in%municipio() & input_tab_2$departamento%in%departamento())]), length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_greenfield) & input_tab_2$municipio%in%municipio() & input_tab_2$departamento%in%departamento())]))
  )
  })
  
  
  #Greenfield population plot
  
  output$poblacion_greenfield <-   renderPlotly(
    plot_ly(s_g()[!(s_g()$"Segmento_Greenfield"=='Total'),], x = c("GREENFIELD"), y = ~s_g()[!(s_g()$"Segmento_Greenfield"=='Total'),2], type = 'bar',
            marker = list(color = 'rgb(131,219,128)',
                          line = list(color = 'rgb(61,156,57)',
                                      width = 1.5))) %>%
      layout(title = ("Población Greenfield"),
             xaxis = ax,
             yaxis = list(title = "")) %>%
      config(displayModeBar=FALSE)
  )
  
  #Greenfield settlements plot
  
  output$settlements_greenfield <-   renderPlotly(
    plot_ly(s_g()[!(s_g()$"Segmento_Greenfield"=='Total'),], x = c("GREENFIELD"), y = ~s_g()[!(s_g()$"Segmento_Greenfield"=='Total'),3], type = 'bar',
            marker = list(color = 'rgb(131,219,128)',
                          line = list(color = 'rgb(61,156,57)',
                                      width = 1.5))) %>%
      layout(title = ("Num CCPP Greenfield"),
             xaxis = ax,
             yaxis = list(title = "")) %>%
      config(displayModeBar=FALSE)
  )
  
  #Plot Greenfield dataframe
  
  
  output$segmento_greenfield <- renderTable(s_g())
  
  
  ### PRIORIZATION TAB
  
  departamento_2<-reactive({if (is.null(input$departamento_2) || input$departamento_2=="TODOS") unique(input_tab_2$departamento) else input$departamento_2})
  
  # Subset filtering options of the province based on the departamento selected
  
  output$municipio_2 <- renderUI({
    selectizeInput("municipio_2",'Municipio',c("TODOS",unique(input_tab_2$municipio[input_tab_2$departamento%in%departamento_2()])), multiple= TRUE, selected='TODOS', options = list(maxOptions = 30, placeholder = 'Introduzca municipio'))
  })
  
  municipio_2 <- reactive({if (is.null(input$municipio_2) || input$municipio_2=="TODOS") unique(input_tab_2$municipio) else input$municipio_2})
  
  segmento <- reactive({  input$segmento })
  
  
  # Subset filtering options of the Movistar coverage available based on the departamento selected
  
  output$cobertura_movistar <- renderUI({
    selectizeInput("cobertura_movistar",'Cobertura Movistar',unique(input_tab_2$cobertura_movistar[input_tab_2$departamento%in%departamento_2() & input_tab_2$municipio%in%municipio_2()]), multiple= TRUE, options = list(maxOptions = 8, placeholder = 'Introduzca cobertura Movistar'))
  })
  
  cobertura_movistar <- reactive({if (is.null(input$cobertura_movistar)) unique(input_tab_2$cobertura_movistar) else input$cobertura_movistar})
  
  # Subset filtering options of the competitors' coverage available based on the departamento selected
  
  output$cobertura_competidores <- renderUI({
    selectizeInput("cobertura_competidores",'Cobertura Competidores',unique(input_tab_2$cobertura_competidores[input_tab_2$departamento%in%departamento_2() & input_tab_2$municipio%in%municipio_2()]), multiple= TRUE, options = list(maxOptions = 8, placeholder = 'Introduzca cobertura Competidores'))
  })
  
  cobertura_competidores <- reactive({if (is.null(input$cobertura_competidores)) unique(input_tab_2$cobertura_competidores) else input$cobertura_competidores})
  
  poblacion <- reactive({input$poblacion})
  
  # Create reactive dataframe according to the inputs
  
  outputdf <- reactive({
    input_tab_2[which(input_tab_2$municipio%in%municipio_2()
                      & input_tab_2$departamento%in%departamento_2()
                      & input_tab_2$segmentacion%in%segmento()
                      & input_tab_2$cobertura_movistar%in%cobertura_movistar()
                      & input_tab_2$cobertura_competidores%in%cobertura_competidores()
                      & (input_tab_2$poblacion>=poblacion()[1] & input_tab_2$poblacion<=poblacion()[2])),]
  })
  
  output$outputdf <- DT::renderDataTable(outputdf(), extensions='Buttons', options = list(order=list(list(3,'desc')), scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 25, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)
  
  # Calculate and render the number of settlements
  
  sum_settlements <- reactive({ format(nrow(outputdf()),big.mark=".", decimal.mark=",") })
  
  output$sum_settlements <- renderText(sum_settlements())
  
  # Calculate and render the population included
  
  sum_population <- reactive ({ format(sum(outputdf()$poblacion,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_population <- renderText(sum_population())
  
  # Render an OpenStreetMap with markers on the settlements filtered
  
  pal_segmentation <- colorFactor( palette=c('green', 'orange','red', 'navy'), domain = unique(input_tab_2$segmentacion))
  pal_coverage_movistar <- colorFactor( palette="Blues", domain = unique(input_tab_2$cobertura_movistar))
  pal_coverage_competidores <- colorFactor( palette="Reds", domain = unique(input_tab_2$cobertura_competidores))
  
  
  html_legend <- "<img src='access_tower.png' style='width:15px;height:20px;'>Access tower<br/>
  <img src='tx_tower.png' style='width:15px;height:20px;'>Telefonica infrastructure (Tx)<br/>
  <img src='tx_tower_3.png' style='width:15px;height:20px;'>Competitors infrastructure (Tx)<br/>
  <img src='tx_tower_2.png' style='width:15px;height:20px;'>Azteca infrastructure (Tx)<br/>
  <img src='tx_tower_4.png' style='width:15px;height:20px;'>Anditel infrastructure (Tx)<br/>
  <img src='tx_tower_5.png' style='width:15px;height:20px;'>Partners infrastructure"
  
  
  output$output_map_segmentation <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data=outputdf(), radius=3, color= ~pal_segmentation(outputdf()$segmentacion) , fillOpacity = 0.7, label=outputdf()$centro_poblado, popup = (paste0("Codigo Divipola: ",outputdf()$codigo_divipola, "<br>", "Centro poblado: ",outputdf()$centro_poblado, "<br>", "Municipio: ",outputdf()$municipio, "<br>", "Departamento: ",outputdf()$departamento,  "<br>", "Poblacion: ",outputdf()$poblacion,  "<br>", "Segmento Telefonica: ",outputdf()$segmento_telefonica, "<br>", "Segmento Overlay: ",outputdf()$segmento_overlay, "<br>", "Segmento Greenfield: ",outputdf()$segmento_greenfield)),
                       stroke = FALSE) %>%
      addLegend("topright", pal = pal_segmentation, values = unique(input_tab_2$segmentacion),
                title = "Segmentación",
                opacity = 1
      ) %>%
      addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))
  })
  
  third_party_owners <-c("COMPETITORS","ANDITEL","INFRA_PARTNERS", "AZTECA")
  
  access_icon <- makeIcon(iconUrl = "./www/access_tower.png", iconWidth = 15, iconHeight = 20)
  tx_icon <- makeIcon(iconUrl = "./www/tx_tower.png", iconWidth = 15, iconHeight = 20)
  
  iconSet <- iconList(
    
    COMPETITORS =  makeIcon(iconUrl = "./www/tx_tower_3.png", iconWidth = 15, iconHeight = 20),
    
    ANDITEL =  makeIcon(iconUrl = "./www/tx_tower_4.png", iconWidth = 15, iconHeight = 20),
    
    AZTECA =  makeIcon(iconUrl = "./www/tx_tower_2.png", iconWidth = 15, iconHeight = 20),
    
    INFRA_PARTNERS =  makeIcon(iconUrl = "./www/tx_tower_5.png", iconWidth = 15, iconHeight = 20)
    
  )
  
  output$output_map_access_transport <- renderLeaflet({
    validate(
      need(outputdf()$latitude_torre_acceso, 'No encontradas opciones de acceso para los filtros seleccionados. Por favor, amplíe rango de búsqueda.'),
      need(outputdf()$longitude_torre_transporte[!(outputdf()$tx_owner%in%third_party_owners)], 'No encontradas opciones de transporte para los filtros seleccionados. Por favor, amplíe rango de búsqueda.'),
      need(outputdf()$latitude_torre_transporte[(outputdf()$tx_owner%in%third_party_owners)], 'No encontradas opciones de transporte para los filtros seleccionados. Por favor, amplíe rango de búsqueda.')
    )
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addLayersControl(
        overlayGroups = c("Centros Poblados", "Acceso y Transporte"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>% hideGroup(c("Acceso y Transporte")) %>%
      addCircleMarkers(data=outputdf(), radius=3, color= 'grey', fillOpacity = 1, label=outputdf()$centro_poblado, popup = (paste0("Codigo Divipola: ",outputdf()$codigo_divipola, "<br>", "Centro poblado: ",outputdf()$centro_poblado, "<br>", "Municipio: ",outputdf()$municipio, "<br>", "Departamento: ",outputdf()$departamento,  "<br>", "Poblacion: ",outputdf()$poblacion,  "<br>",  "Acceso disponible: ",outputdf()$acceso_disponible,  "<br>", "Distancia a torre acceso (km): ",outputdf()$km_dist_torre_acceso,  "<br>", "Transporte disponible: ",outputdf()$transporte_disponible,  "<br>", "Distancia a torre transporte (km): ",outputdf()$km_dist_torre_transporte )),
                       stroke = FALSE,group="Centros Poblados") %>%
      addMarkers (lat = as.numeric(outputdf()$latitude_torre_acceso), lng = as.numeric(outputdf()$longitude_torre_acceso), 
                  icon= access_icon, group = "Acceso y Transporte", label=outputdf()$torre_acceso_internal_id, 
                  popup = (paste0("Codigo unico: ",outputdf()$torre_acceso_internal_id, "<br>", 
                                  "Owner: ",outputdf()$owner_torre_acceso, "<br>", 
                                  "Tipo: ",outputdf()$tipo_torre_acceso, "<br>", 
                                  "Tecnologia: ",outputdf()$tecnologia_torre_acceso, "<br>", 
                                  "Altura: ",outputdf()$altura_torre_acceso, "<br>", 
                                  "LoS acceso - transporte: ",outputdf()$los_acceso_transporte))
      ) %>%
      addMarkers (lat = as.numeric(outputdf()$latitude_torre_transporte[!(outputdf()$tx_owner%in%third_party_owners)]), 
                  lng = as.numeric(outputdf()$longitude_torre_transporte[!(outputdf()$tx_owner%in%third_party_owners)]), 
                  icon= tx_icon, group = "Acceso y Transporte",
                  label=outputdf()$torre_transporte_internal_id[!(outputdf()$tx_owner%in%third_party_owners)], 
                  popup = (paste0("Codigo unico: ",outputdf()$torre_transporte_internal_id[!(outputdf()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Owner: ",outputdf()$owner_torre_transporte[!(outputdf()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Tipo: ",outputdf()$tx_owner[!(outputdf()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Tecnologia: ",outputdf()$tecnologia_torre_transporte[!(outputdf()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Altura: ",outputdf()$altura_torre_transporte[!(outputdf()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Banda satélite: ",outputdf()$banda_satelite_torre_transporte[!(outputdf()$tx_owner%in%third_party_owners)]))
      ) %>%
      addMarkers (lat = as.numeric(outputdf()$latitude_torre_transporte[(outputdf()$tx_owner%in%third_party_owners)]), 
                  lng = as.numeric(outputdf()$longitude_torre_transporte[(outputdf()$tx_owner%in%third_party_owners)]), 
                  icon= iconSet[outputdf()$tx_owner[(outputdf()$tx_owner%in%third_party_owners)]], group = "Acceso y Transporte",
                  label=outputdf()$torre_transporte_internal_id[(outputdf()$tx_owner%in%third_party_owners)], 
                  popup = (paste0("Codigo unico: ",outputdf()$torre_transporte_internal_id[(outputdf()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Owner: ",outputdf()$owner_torre_transporte[(outputdf()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Tipo: ",outputdf()$tx_owner[(outputdf()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Tecnologia: ",outputdf()$tecnologia_torre_transporte[(outputdf()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Altura: ",outputdf()$altura_torre_transporte[(outputdf()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Banda satélite: ", outputdf()$banda_satelite_torre_transporte[(outputdf()$tx_owner%in%third_party_owners)]))
      ) %>%
      addControl(html = html_legend, position = "bottomleft") %>%
      addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))
    
  })
  
  output$output_map_coverage <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data=outputdf(), radius=3, color= 'grey', stroke= FALSE, fillOpacity = 1, label=outputdf()$centro_poblado, popup = (paste0("Codigo Divipola: ",outputdf()$codigo_divipola, "<br>", "Centro poblado: ",outputdf()$centro_poblado, "<br>", "<br>", "Municipio: ",outputdf()$municipio, "<br>", "Departamento: ",outputdf()$departamento,  "<br>", "Poblacion: ",outputdf()$poblacion,  "<br>", "Cobertura Movistar: ",outputdf()$cobertura_movistar, "<br>", "Cobertura Competidores: ",outputdf()$cobertura_competidores )),
                       group="Centros Poblados") %>%
      addCircleMarkers( data=outputdf(),
                        radius =3,
                        color = ~pal_coverage_competidores(outputdf()$cobertura_competidores), label=outputdf()$centro_poblado, popup = (paste0("Codigo Divipola: ",outputdf()$codigo_divipola, "<br>", "Centro poblado: ",outputdf()$centro_poblado, "<br>", "Cobertura Competidores: ",outputdf()$cobertura_competidores)),
                        stroke = FALSE, fillOpacity = 1, group= "Cobertura Competidores"
      ) %>%
      addCircleMarkers( data=outputdf(),
                        radius =3,
                        color = ~pal_coverage_movistar(outputdf()$cobertura_movistar), label=outputdf()$centro_poblado, popup = (paste0("Codigo Divipola: ",outputdf()$codigo_divipola, "<br>", "Centro poblado: ",outputdf()$centro_poblado, "<br>", "Cobertura Movistar: ",outputdf()$cobertura_movistar)),
                        stroke = FALSE, fillOpacity = 1, group= "Cobertura Movistar"
      ) %>%
      addLayersControl(
        overlayGroups = c("Centros Poblados", "Cobertura Movistar", "Cobertura Competidores"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>% hideGroup(c("Centros Poblados")) %>%
      addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))
  })
  
  output$downloadData <- downloadHandler(
    filename = function() {
      paste0("priorizacion_centros_poblados_", Sys.Date(), ".csv")
    },
    content = function(file) {
      s=input$outputdf_rows_all
      write.csv2(outputdf()[s, , drop = FALSE], file, fileEncoding='UTF-8')
    } ,
    contentType= "text/csv"
  )
  
  
  observeEvent(input$outputdf_rows_selected, {
    leafletProxy("output_map_coverage") %>%
      clearPopups() %>%
      addPopups(lng=outputdf()$longitude[input$outputdf_rows_selected], lat=outputdf()$latitude[input$outputdf_rows_selected], popup=(paste0("Codigo Divipola: ",outputdf()$codigo_divipola[input$outputdf_rows_selected], "<br>", "Centro poblado: ",outputdf()$centro_poblado[input$outputdf_rows_selected], "<br>",  "Municipio: ",outputdf()$municipio[input$outputdf_rows_selected], "<br>", "Departamento: ",outputdf()$departamento[input$outputdf_rows_selected],  "<br>", "Poblacion: ",outputdf()$poblacion[input$outputdf_rows_selected],  "<br>", "Cobertura Movistar: ",outputdf()$cobertura_movistar[input$outputdf_rows_selected], "<br>", "Cobertura Competidores: ",outputdf()$cobertura_competidores[input$outputdf_rows_selected])), options = popupOptions(closeOnClick = TRUE)
      )
    leafletProxy("output_map_segmentation") %>%
      clearPopups() %>%
      addPopups(lng=outputdf()$longitude[input$outputdf_rows_selected], lat=outputdf()$latitude[input$outputdf_rows_selected], popup=(paste0("Codigo Divipola: ",outputdf()$codigo_divipola[input$outputdf_rows_selected], "<br>", "Centro poblado: ",outputdf()$centro_poblado[input$outputdf_rows_selected], "<br>", "Municipio: ",outputdf()$municipio[input$outputdf_rows_selected], "<br>", "Departamento: ",outputdf()$departamento[input$outputdf_rows_selected],  "<br>", "Poblacion: ",outputdf()$poblacion[input$outputdf_rows_selected],  "<br>", "<br>", "Segmento Telefonica: ",outputdf()$segmento_telefonica[input$outputdf_rows_selected], "<br>", "Segmento Overlay: ",outputdf()$segmento_overlay[input$outputdf_rows_selected], "<br>", "Segmento Greenfield: ",outputdf()$segmento_greenfield)[input$outputdf_rows_selected]), options = popupOptions(closeOnClick = TRUE)
      )
    leafletProxy("output_map_access_transport") %>%
      clearPopups() %>%  removeShape("line_acceso") %>% removeShape("line_transporte") %>%  removeShape("line_transporte_cp") %>%
      addPopups(lng=outputdf()$longitude[input$outputdf_rows_selected], lat=outputdf()$latitude[input$outputdf_rows_selected], popup= (paste0("Codigo Divipola: ",outputdf()$codigo_divipola[input$outputdf_rows_selected], "<br>", "Centro poblado: ",outputdf()$centro_poblado[input$outputdf_rows_selected], "<br>", "Municipio: ",outputdf()$municipio[input$outputdf_rows_selected], "<br>", "Departamento: ",outputdf()$departamento[input$outputdf_rows_selected],  "<br>", "Poblacion: ",outputdf()$poblacion[input$outputdf_rows_selected],  "<br>", "Acceso disponible: ",outputdf()$acceso_disponible[input$outputdf_rows_selected],  "<br>", "Distancia a torre acceso (km): ",outputdf()$km_dist_torre_acceso[input$outputdf_rows_selected],  "<br>", "Transporte disponible: ",outputdf()$transporte_disponible[input$outputdf_rows_selected],  "<br>", "Distancia a torre transporte (km): ",outputdf()$km_dist_torre_transporte[input$outputdf_rows_selected] )), options = popupOptions(closeOnClick = TRUE)
      )
    if (!is.na(outputdf()$line_acceso[input$outputdf_rows_selected])) {
      leafletProxy("output_map_access_transport") %>% 
        addPolylines(layerId= "line_acceso",data= readWKT(outputdf()$line_acceso[input$outputdf_rows_selected]), weight= 1.5, group = "Acceso y Transporte", color="yellow") }
    if (!is.na(outputdf()$line_transporte[input$outputdf_rows_selected])) {
      leafletProxy("output_map_access_transport") %>%  
        addPolylines(layerId = "line_transporte" ,data= readWKT(outputdf()$line_transporte[input$outputdf_rows_selected]), weight= 1.5, group = "Acceso y Transporte", color= "black") }
    else if  (!is.na(outputdf()$line_transporte_cp[input$outputdf_rows_selected])){ leafletProxy("output_map_access_transport") %>% 
        addPolylines(layerId= "line_transporte_cp", data= readWKT(outputdf()$line_transporte_cp[input$outputdf_rows_selected]), weight= 1.5, group = "Acceso y Transporte", color= "green") }
  })
  
  observeEvent(input$output_map_access_transport_click, {
    leafletProxy("output_map_access_transport") %>%
      removeShape("line_acceso") %>% removeShape("line_transporte") %>%  removeShape("line_transporte_cp")
  })
  
  
  ### LISTING TAB
  
  departamento_listing<-reactive({if (is.null(input$departamento_listing) || input$departamento_listing=="TODOS") unique(input_tab_2$departamento) else input$departamento_listing})
  
  # Subset filtering options of the province based on the departamento selected
  
  output$municipio_listing <- renderUI({
    selectizeInput("municipio_listing",'Municipio',c("TODOS",unique(input_tab_2$municipio[input_tab_2$departamento%in%departamento_listing()])), multiple= TRUE, selected='TODOS', options = list(maxOptions = 30, placeholder = 'Introduzca municipio'))
  })
  
  municipio_listing <- reactive({if (is.null(input$municipio_listing) || input$municipio_listing=="TODOS") unique(input_tab_2$municipio) else input$municipio_listing})
  
  segmento_listing <- reactive({  input$segmento_listing  })
  
  
  # Subset filtering options of the Movistar coverage available based on the departamento selected
  
  output$cobertura_movistar_listing <- renderUI({
    selectizeInput("cobertura_movistar_listing",'Cobertura Movistar',unique(input_tab_2$cobertura_movistar[input_tab_2$departamento%in%departamento_listing() & input_tab_2$municipio%in%municipio_listing()]), multiple= TRUE, options = list(maxOptions = 8, placeholder = 'Introduzca cobertura Movistar'))
  })
  
  cobertura_movistar_listing <- reactive({if (is.null(input$cobertura_movistar_listing)) unique(input_tab_2$cobertura_movistar) else input$cobertura_movistar_listing})
  
  # Subset filtering options of the competitors' coverage available based on the departamento selected
  
  output$cobertura_competidores_listing <- renderUI({
    selectizeInput("cobertura_competidores_listing",'Cobertura Competidores',unique(input_tab_2$cobertura_competidores[input_tab_2$departamento%in%departamento_listing() & input_tab_2$municipio%in%municipio_listing()]), multiple= TRUE, options = list(maxOptions = 8, placeholder = 'Introduzca cobertura Competidores'))
  })
  
  cobertura_competidores_listing <- reactive({if (is.null(input$cobertura_competidores_listing)) unique(input_tab_2$cobertura_competidores) else input$cobertura_competidores_listing})
  
  poblacion_2 <- reactive({input$poblacion_2})
  
  # Create reactive dataframe according to the inputs
  
  outputdf_listing <- reactive({
    input_tab_2[which(input_tab_2$municipio%in%municipio_listing()
                      & input_tab_2$departamento%in%departamento_listing()
                      & input_tab_2$segmentacion%in%segmento_listing()
                      & input_tab_2$cobertura_movistar%in%cobertura_movistar_listing()
                      & input_tab_2$cobertura_competidores%in%cobertura_competidores_listing()
                      & (input_tab_2$poblacion>=poblacion_2()[1] & input_tab_2$poblacion<=poblacion_2()[2])),]
  })
  
  output$outputdf_listing <- DT::renderDataTable(outputdf_listing(), extensions='Buttons', options = list(order=list(list(3,'desc')), scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 25, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)
  
  output
  # Calculate and render the number of settlements
  
  sum_settlements_listing <- reactive({ format(nrow(outputdf_listing()),big.mark=".", decimal.mark=",") })
  
  output$sum_settlements_listing <- renderText(sum_settlements_listing())
  
  # Calculate and render the population included
  
  sum_population_listing <- reactive ({ format(sum(outputdf_listing()$poblacion,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_population_listing <- renderText(sum_population_listing())
  
  output$downloadData_listing <- downloadHandler(
    filename = function() {
      paste0("priorizacion_centros_poblados_", Sys.Date(), ".csv")
    },
    content = function(file) {
      s=input$outputdf_listing_rows_all
      write.csv2(outputdf_listing()[s, , drop = FALSE], file, fileEncoding = 'latin1')
    } ,
    contentType= "text/csv"
  )
  
  
  ### CLUSTER PRIORIZATION TAB
  
  
  departamento_3<-reactive({if (is.null(input$departamento_3) || input$departamento_3=="TODOS") unique(unlist(strsplit(unique(input_tab_3$departamentos), " , ", fixed = TRUE))) else unique(unlist(strsplit(input$departamento_3, " , ", fixed = TRUE)))})
  
  # Subset filtering options of the province based on the departamento selected
  
  output$municipio_3 <- renderUI({
    selectizeInput("municipio_3",'Municipio',c("TODOS","-",unique(input_tab_2$municipio[input_tab_2$departamento%in%departamento_3()])), multiple= TRUE, selected='TODOS', options = list(maxOptions = 30, placeholder = 'Introduzca municipio/municipios'))
  })
  
  municipio_3 <- reactive({if (is.null(input$municipio_3) || input$municipio_3=="TODOS") unique(unlist(strsplit(unique(input_tab_3$municipios), " , ", fixed = TRUE))) else unique(unlist(strsplit(input$municipio_3, " , ", fixed = TRUE)))})
  
  segmento_2 <- reactive({  input$segmento_2  })
  
  
  
  # Subset filtering options of the clusters' centroid type
  
  tipo_cluster <- reactive({if (is.null(input$tipo_cluster)) unique(input_tab_3$tipo_cluster) else input$tipo_cluster})
  
  poblacion_3 <- reactive({input$poblacion_3})
  
  weight <- reactive({input$weight})
  
  
  weight_p <- reactive({as.numeric(input$weight_p)})
  
  
  # Create reactive dataframe according to the inputs
  
  outputdf_2 <- reactive({
    input_tab_3[which( grepl(paste(departamento_3(),collapse="|"),input_tab_3$departamentos)
                       & grepl(paste(municipio_3(),collapse="|"),input_tab_3$municipios)
                       & input_tab_3$tipo_cluster%in%tipo_cluster()
                       & input_tab_3$segmentacion%in%segmento_2()
                       & (input_tab_3$poblacion_total>=poblacion_3()[1] & input_tab_3$poblacion_total<=poblacion_3()[2])
                       & (input_tab_3$poblacion_no_conectada_movistar>=weight()[1] & input_tab_3$poblacion_no_conectada_movistar<=weight()[2])
                       & input_tab_3$poblacion_no_conectada_movistar>=weight_p()),]
  })
  
  output$outputdf_2 <- DT::renderDataTable(outputdf_2(), extensions='Buttons', options = list(order=list(list(6,'desc')),scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 10, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)
  
  # Calculate and render the number of clusters
  
  sum_clusters <- reactive({ format(nrow(outputdf_2()),big.mark=".", decimal.mark=",") })
  
  output$sum_clusters <- renderText(sum_clusters())  
  
  
  # Calculate and render the number of settlements
  
  sum_settlements_2 <- reactive({ format(sum(outputdf_2()$tamano_cluster,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_settlements_2 <- renderText(sum_settlements_2())
  
  # Calculate and render the population included
  
  sum_population_2 <- reactive ({ format(sum(outputdf_2()$poblacion_total,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_population_2 <- renderText(sum_population_2())
  
  # Render an OpenStreetMap with markers on the settlements filtered
  
  pal_segmentation_2 <- colorFactor( palette=c('green', 'orange', 'navy'), domain = unique(input_tab_3$segmentacion))
  
  output$output_map_segmentation_2 <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data= outputdf_2(), radius=3, color= ~pal_segmentation_2(outputdf_2()$segmentacion) , fillOpacity = 0.7, label=outputdf_2()$centroide, popup = (paste0("ID Centroide: ",outputdf_2()$centroide, "<br>", "Tipo de cluster: ",outputdf_2()$tipo_cluster, "<br>", "Centros Poblados: ",outputdf_2()$centros_poblados, "<br>", "Municipios: ",outputdf_2()$municipios, "<br>", "Departamentos: ",outputdf_2()$departamentos, "<br>", "Tamaño de cluster: ",outputdf_2()$tamano_cluster,  "<br>", "Población total: ",outputdf_2()$poblacion_total,  "<br>","Población no conectada: ",outputdf_2()$poblacion_no_conectada_movistar,  "<br>",  "Segmento: ",outputdf_2()$segmentacion)),
                       stroke = FALSE) %>%
      addLegend("topright", pal = pal_segmentation_2, values = unique(input_tab_3$segmentacion),
                title = "Segmentación",
                opacity = 1
      ) %>%
      addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))
  })
  
  
  output$output_map_access_transport_2 <- renderLeaflet({
    validate(
      need(outputdf_2()$latitude_torre_acceso, 'No encontradas opciones de acceso para los filtros seleccionados. Por favor, amplíe rango de búsqueda.'),
      need(outputdf_2()$longitude_torre_transporte[!(outputdf_2()$tx_owner%in%third_party_owners)], 'No encontradas opciones de transporte para los filtros seleccionados. Por favor, amplíe rango de búsqueda.'),
      need(outputdf_2()$latitude_torre_transporte[(outputdf_2()$tx_owner%in%third_party_owners)], 'No encontradas opciones de transporte para los filtros seleccionados. Por favor, amplíe rango de búsqueda.')
    )
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data=outputdf_2(), radius=3, color= 'grey', fillOpacity = 1, label=outputdf_2()$centroide, popup = (paste0("ID Centroide: ",outputdf_2()$centroide, "<br>", "Tipo de cluster: ",outputdf_2()$tipo_cluster,  "<br>", "Municipios: ",outputdf_2()$municipio, "<br>", "Departamentos: ",outputdf_2()$departamento,  "<br>", "Poblacion: ",outputdf_2()$poblacion,  "<br>", "Acceso disponible: ",outputdf_2()$acceso_disponible,  "<br>", "Distancia a torre acceso (km): ",outputdf_2()$km_dist_torre_acceso,  "<br>", "Transporte disponible: ",outputdf_2()$transporte_disponible,  "<br>", "Distancia a torre transporte (km): ",outputdf_2()$km_dist_torre_transporte )),
                       stroke = FALSE,group="Centroides") %>%  hideGroup(c("Acceso y Transporte"))  %>%
      addMarkers (lat = as.numeric(outputdf_2()$latitude_torre_acceso), lng = as.numeric(outputdf_2()$longitude_torre_acceso), 
                  icon= access_icon, group = "Acceso y Transporte", label=outputdf_2()$torre_acceso_internal_id, 
                  popup = (paste0("Codigo unico: ",outputdf_2()$torre_acceso_internal_id, "<br>", 
                                  "Owner: ",outputdf_2()$owner_torre_acceso, "<br>", 
                                  "Tipo: ",outputdf_2()$tipo_torre_acceso, "<br>", 
                                  "Tecnologia: ",outputdf_2()$tecnologia_torre_acceso, "<br>", 
                                  "Altura: ",outputdf_2()$altura_torre_acceso, "<br>", 
                                  "LoS acceso - transporte: ",outputdf_2()$los_acceso_transporte))) %>%
      addMarkers (lat = as.numeric(outputdf_2()$latitude_torre_transporte[(outputdf_2()$tx_owner%in%third_party_owners)]), 
                  lng = as.numeric(outputdf_2()$longitude_torre_transporte[(outputdf_2()$tx_owner%in%third_party_owners)]), 
                  icon= iconSet[outputdf_2()$tx_owner[(outputdf_2()$tx_owner%in%third_party_owners)]], group = "Acceso y Transporte", 
                  label=outputdf_2()$torre_transporte_internal_id[(outputdf_2()$tx_owner%in%third_party_owners)], 
                  popup = (paste0("Codigo unico: ",outputdf_2()$torre_transporte_internal_id[(outputdf_2()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Owner: ",outputdf_2()$owner_torre_transporte[(outputdf_2()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Tipo: ",outputdf_2()$tx_owner[(outputdf_2()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Tecnologia: ",outputdf_2()$tecnologia_torre_transporte[(outputdf_2()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Altura: ",outputdf_2()$altura_torre_transporte[(outputdf_2()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Banda satélite: ",outputdf_2()$banda_satelite_torre_transporte[(outputdf_2()$tx_owner%in%third_party_owners)]))
      ) %>%
      addMarkers (lat = as.numeric(outputdf_2()$latitude_torre_transporte[!(outputdf_2()$tx_owner%in%third_party_owners)]), 
                  lng = as.numeric(outputdf_2()$longitude_torre_transporte[!(outputdf_2()$tx_owner%in%third_party_owners)]), 
                  icon= tx_icon, group = "Acceso y Transporte", label=outputdf_2()$torre_transporte_internal_id[!(outputdf_2()$tx_owner%in%third_party_owners)], 
                  popup = (paste0("Codigo unico: ",outputdf_2()$torre_transporte_internal_id[!(outputdf_2()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Owner: ",outputdf_2()$owner_torre_transporte[!(outputdf_2()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Tipo: ",outputdf_2()$tx_owner[!(outputdf_2()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Tecnologia: ",outputdf_2()$tecnologia_torre_transporte[!(outputdf_2()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Altura: ",outputdf_2()$altura_torre_transporte[!(outputdf_2()$tx_owner%in%third_party_owners)], "<br>", 
                                  "Banda satélite: ",outputdf_2()$banda_satelite_torre_transporte[!(outputdf_2()$tx_owner%in%third_party_owners)]))
      ) %>%
      addLayersControl(
        overlayGroups = c("Centroides", "Acceso y Transporte"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>%
      addControl(html = html_legend, position = "bottomleft") %>%
      addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))
  })
  
  
  output$downloadData_2 <- downloadHandler(
    filename = function() {
      paste0("priorizacion_clusters_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv2(outputdf_2()[,c(1:41,76:87,112:114, 117:120), drop = FALSE], file, fileEncoding = 'latin1')
    } ,
    contentType= "text/csv"
  )
  
  
  observeEvent(input$outputdf_2_rows_selected, {
    
    lines_selected <- input_tab_3_lines[outputdf_2()$centroide[input$outputdf_2_rows_selected]==input_tab_3_lines$centroide,]
    
    leafletProxy("output_map_segmentation_2") %>%
      clearPopups() %>% clearGroup("lines_centroide") %>% clearGroup("nodes_centroide") %>%
      addPopups(lng=outputdf_2()$longitude[input$outputdf_2_rows_selected], lat=outputdf_2()$latitude[input$outputdf_2_rows_selected], popup = (paste0("ID Centroide: ",outputdf_2()$centroide[input$outputdf_2_rows_selected], "<br>", "Tipo de cluster: ",outputdf_2()$tipo_cluster[input$outputdf_2_rows_selected], "<br>", "Centros Poblados: ",outputdf_2()$centros_poblados[input$outputdf_2_rows_selected], "<br>", "Municipios: ",outputdf_2()$municipios[input$outputdf_2_rows_selected], "<br>", "Departamentos: ",outputdf_2()$departamentos[input$outputdf_2_rows_selected], "<br>", "Tamaño de cluster: ",outputdf_2()$tamano_cluster[input$outputdf_2_rows_selected],  "<br>", "Poblacion: ",outputdf_2()$poblacion[input$outputdf_2_rows_selected],  "<br>", "Segmento: ",outputdf_2()$segmentacion[input$outputdf_2_rows_selected])),
                options = popupOptions(closeOnClick = TRUE)
      )
    for (i in (1:nrow(lines_selected)))
    {
      if(!is.na(lines_selected$lines_centroide[i])){leafletProxy("output_map_segmentation_2") %>% addPolylines(group= "lines_centroide",data= readWKT(lines_selected$lines_centroide[i]), weight= 0.8, color="grey") %>%
          addCircleMarkers(data=readWKT(lines_selected$nodes_centroide[i]), radius=3, fillOpacity=0.7, color= "grey", stroke=FALSE, group="nodes_centroide", label=lines_selected$centros_poblados[i], popup = paste0("Centro Poblado: ",lines_selected$centros_poblados[i])) }
    }
    leafletProxy("output_map_access_transport_2") %>%
      clearPopups() %>%  removeShape("line_acceso") %>% removeShape("line_transporte") %>%  removeShape("line_transporte_cp") %>%
      addPopups(lng=outputdf_2()$longitude[input$outputdf_2_rows_selected], lat=outputdf_2()$latitude[input$outputdf_2_rows_selected], popup= (paste0("ID Centroide: ",outputdf_2()$centroide[input$outputdf_2_rows_selected], "<br>", "Tipo de cluster: ",outputdf_2()$tipo_cluster[input$outputdf_2_rows_selected],  "<br>", "Municipios: ",outputdf_2()$municipios[input$outputdf_2_rows_selected], "<br>", "Departamentos: ",outputdf_2()$departamentos[input$outputdf_2_rows_selected],  "<br>", "Población: ",outputdf_2()$poblacion[input$outputdf_2_rows_selected],   "<br>", "Acceso disponible: ",outputdf_2()$acceso_disponible[input$outputdf_2_rows_selected],  "<br>", "Distancia a torre acceso (km): ",outputdf_2()$km_dist_torre_acceso[input$outputdf_2_rows_selected],  "<br>", "Transporte disponible: ",outputdf_2()$transporte_disponible[input$outputdf_2_rows_selected],  "<br>", "Distancia a torre transporte (km): ",outputdf_2()$km_dist_torre_transporte[input$outputdf_2_rows_selected] )), options = popupOptions(closeOnClick = TRUE)
      )
    if (!is.na(outputdf_2()$line_acceso[input$outputdf_2_rows_selected])) {
      leafletProxy("output_map_access_transport_2") %>%
        addPolylines(layerId= "line_acceso",data= readWKT(outputdf_2()$line_acceso[input$outputdf_2_rows_selected]), weight= 0.8, group = "Acceso y Transporte") }
    if (!is.na(outputdf_2()$line_transporte[input$outputdf_2_rows_selected])) {
      leafletProxy("output_map_access_transport_2") %>%
        addPolylines(layerId = "line_transporte" ,data= readWKT(outputdf_2()$line_transporte[input$outputdf_2_rows_selected]), weight= 0.8, group = "Acceso y Transporte", color= "black") }
    else if (!is.na(outputdf_2()$line_transporte_cp[input$outputdf_2_rows_selected])) { leafletProxy("output_map_access_transport_2") %>%
        addPolylines(layerId= "line_transporte_cp", data= readWKT(outputdf_2()$line_transporte_cp[input$outputdf_2_rows_selected]), weight= 0.8, group = "Acceso y Transporte", color= "orange") }
    
  })
  
  
  observeEvent(input$output_map_segmentation_2_click, {
    leafletProxy("output_map_segmentation_2") %>%
      clearGroup("lines_centroide") %>% clearGroup("nodes_centroide")
    leafletProxy("output_map_access_transport_2") %>%
      removeShape("line_acceso") %>% removeShape("line_transporte") %>%  removeShape("line_transporte_cp")
  })
  
  
  ### CLUSTER LISTING TAB
  
  
  departamento_3_listing<-reactive({if (is.null(input$departamento_3_listing) || input$departamento_3_listing=="TODOS") unique(unlist(strsplit(unique(input_tab_3$departamentos), " , ", fixed = TRUE))) else unique(unlist(strsplit(input$departamento_3_listing, " , ", fixed = TRUE)))})
  
  # Subset filtering options of the province based on the departamento selected
  
  output$municipio_3_listing <- renderUI({
    selectizeInput("municipio_3_listing",'Municipio',c("TODOS","-",unique(input_tab_2$municipio[input_tab_2$departamento%in%departamento_3_listing()])), multiple= TRUE, selected='TODOS', options = list(maxOptions = 30, placeholder = 'Introduzca municipio/municipios'))
  })
  
  municipio_3_listing <- reactive({if (is.null(input$municipio_3_listing) || input$municipio_3_listing=="TODOS") unique(unlist(strsplit(unique(input_tab_3$municipios), " , ", fixed = TRUE))) else unique(unlist(strsplit(input$municipio_3_listing, " , ", fixed = TRUE)))})
  
  segmento_2_listing <- reactive({  input$segmento_2_listing  })
  
  
  
  # Subset filtering options of the clusters' centroid type
  
  tipo_cluster_listing <- reactive({if (is.null(input$tipo_cluster_listing)) unique(input_tab_3$tipo_cluster) else input$tipo_cluster_listing})
  
  
  poblacion_4 <- reactive({input$poblacion_4})
  
  
  weight_2 <- reactive({input$weight_2})
  
  weight_2_p <- reactive({as.numeric(input$weight_2_p)})

  
  # Create reactive dataframe according to the inputs
  
  outputdf_2_listing <- reactive({
    input_tab_3[which( grepl(paste(departamento_3_listing(),collapse="|"),input_tab_3$departamentos)
                       & grepl(paste(municipio_3_listing(),collapse="|"),input_tab_3$municipios)
                       & input_tab_3$tipo_cluster%in%tipo_cluster_listing()
                       & input_tab_3$segmentacion%in%segmento_2_listing()
                       & (input_tab_3$poblacion_total>=poblacion_4()[1] & input_tab_3$poblacion_total<=poblacion_4()[2])
                       & (input_tab_3$poblacion_no_conectada_movistar>=weight_2()[1] & input_tab_3$poblacion_no_conectada_movistar<=weight_2()[2])
                       & input_tab_3$poblacion_no_conectada_movistar>=weight_2_p()),]
  })
  
  output$outputdf_2_listing <- DT::renderDataTable(outputdf_2_listing(), extensions = 'Buttons', options = list(order=list(list(6,'desc')),scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 10, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)
  
  # Calculate and render the number of clusters
  
  sum_clusters_listing <- reactive({ format(nrow(outputdf_2_listing()),big.mark=".", decimal.mark=",") })
  
  output$sum_clusters_listing <- renderText(sum_clusters_listing())  
  
  
  # Calculate and render the number of settlements
  
  sum_settlements_2_listing <- reactive({ format(sum(outputdf_2_listing()$tamano_cluster,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_settlements_2_listing <- renderText(sum_settlements_2_listing())
  
  # Calculate and render the population included
  
  sum_population_2_listing <- reactive ({ format(sum(outputdf_2_listing()$poblacion_total,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_population_2_listing <- renderText(sum_population_2_listing()) 
  
  output$downloadData_2_listing <- downloadHandler(
    filename = function() {
      paste0("priorizacion_clusters_", Sys.Date(), ".csv")
    },
    content = function(file) {
      s=input$outputdf_2_listing_rows_all
      write.csv2(outputdf_2_listing()[s, , drop = FALSE], file, fileEncoding = 'latin1')
    } ,
    contentType= "text/csv"
  )
  
  ## GEOLOCATION TAB
  
  inFile <- reactive({input$file1})
  
  latitude <- reactive({as.numeric(input$latitude)})
  
  longitude <- reactive({as.numeric(input$longitude)})
  
  n_settlements <- reactive({as.numeric(input$n_settlements)})
  
  n_towers <- reactive({as.numeric(input$n_towers)})
  
  n_clusters <- reactive({as.numeric(input$n_clusters)})
  
  input_coordinates <- eventReactive(inFile(),
                      {read.csv(inFile()$datapath, sep=';', dec=',')})
  
  outputdf_3 <- reactive({
    input_tab_2_selection <- input_tab_2
      output_coordinates <- data.frame()
      for (j in (1:nrow(input_coordinates()))){
        input_tab_2_selection_aux <- input_tab_2_selection
        input_tab_2_selection_aux$input_latitude <- input_coordinates()$latitude[j]
        input_tab_2_selection_aux$input_longitude <- input_coordinates()$longitude[j]
        
          input_tab_2_selection_aux$distance <- gdist(input_tab_2_selection_aux$input_longitude,input_tab_2_selection_aux$input_latitude,input_tab_2_selection_aux$longitude,input_tab_2_selection_aux$latitude, units='m')
        
        input_tab_2_selection_aux <- input_tab_2_selection_aux[order(input_tab_2_selection_aux$distance),]
        input_tab_2_selection_aux <- input_tab_2_selection_aux[c(1:n_settlements()),]
        output_coordinates <- rbind(output_coordinates, input_tab_2_selection_aux)
        rm(input_tab_2_selection_aux)
        
      }
      
      output_coordinates
  })
  
  # outputdf_3 <- reactive({
  #   input_tab_2_selection <- input_tab_2
  # 
  #   if(is.null(inFile())) {
  #     for (i in (1:nrow(input_tab_2_selection))){
  #       input_tab_2_selection$distance[i] <- distVincentyEllipsoid(c(input_coordinates()$longitude, input_coordinates()$latitude),c(input_tab_2_selection$longitude[i],input_tab_2_selection$latitude[i]))
  #     }
  # 
  #     input_tab_2_selection <- input_tab_2_selection[order(input_tab_2_selection$distance),]
  #     input_tab_2_selection <- input_tab_2_selection[c(1:n_clusters()),]
  # 
  #     input_tab_2_selection
  #   }
  #   else {
  #     output_coordinates <- data.frame()
  #     for (j in (1:nrow(input_coordinates()))){
  #       input_tab_2_selection_aux <- input_tab_2_selection
  #       input_tab_2_selection_aux$input_latitude <- input_coordinates()$latitude[j]
  #       input_tab_2_selection_aux$input_longitude <- input_coordinates()$longitude[j]
  # 
  #       for (i in (1:nrow(input_tab_2_selection))){
  #         input_tab_2_selection_aux$distance[i] <- distVincentyEllipsoid(c(input_coordinates()$longitude[j],input_coordinates()$latitude[j]),c(input_tab_2_selection_aux$longitude[i],input_tab_2_selection_aux$latitude[i]))
  #       }
  # 
  #       input_tab_2_selection_aux <- input_tab_2_selection_aux[order(input_tab_2_selection_aux$distance),]
  #       input_tab_2_selection_aux <- input_tab_2_selection_aux[c(1:n_clusters()),]
  #       output_coordinates <- rbind(output_coordinates, input_tab_2_selection_aux)
  #       rm(input_tab_2_selection_aux)
  # 
  #     }
  # 
  #     output_coordinates
  #   }
  # 
  # })




  outputdf_4 <- reactive({
    input_tab_3_selection <- input_tab_3

      output_coordinates <- data.frame()
      for (j in (1:nrow(input_coordinates()))){
        input_tab_3_selection_aux <- input_tab_3_selection
        input_tab_3_selection_aux$input_latitude <- input_coordinates()$latitude[j]
        input_tab_3_selection_aux$input_longitude <- input_coordinates()$longitude[j]

        
        input_tab_3_selection_aux$distance <- gdist(input_tab_3_selection_aux$input_longitude,input_tab_3_selection_aux$input_latitude,input_tab_3_selection_aux$longitude,input_tab_3_selection_aux$latitude, units='m')
        

        input_tab_3_selection_aux <- input_tab_3_selection_aux[order(input_tab_3_selection_aux$distance),]
        input_tab_3_selection_aux <- input_tab_3_selection_aux[c(1:n_clusters()),]
        output_coordinates <- rbind(output_coordinates, input_tab_3_selection_aux)
        rm(input_tab_3_selection_aux)

      }

      output_coordinates

  })


  outputdf_5 <- reactive({
    input_tab_4_selection <- input_tab_4

      output_coordinates <- data.frame()
      for (j in (1:nrow(input_coordinates()))){
        input_tab_4_selection_aux <- input_tab_4_selection
        input_tab_4_selection_aux$input_latitude <- input_coordinates()$latitude[j]
        input_tab_4_selection_aux$input_longitude <- input_coordinates()$longitude[j]

        
        input_tab_4_selection_aux$distance <- gdist(input_tab_4_selection_aux$input_longitude,input_tab_4_selection_aux$input_latitude,input_tab_4_selection_aux$longitude,input_tab_4_selection_aux$latitude, units='m')

        input_tab_4_selection_aux <- input_tab_4_selection_aux[order(input_tab_4_selection_aux$distance),]
        input_tab_4_selection_aux <- input_tab_4_selection_aux[c(1:n_towers()),]
        output_coordinates <- rbind(output_coordinates, input_tab_4_selection_aux)
        rm(input_tab_4_selection_aux)

      }

      output_coordinates

  })


  output$downloadData_3 <- downloadHandler(
    filename = function() {
      paste0("centros_poblados_mas_cercanos_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv2(outputdf_3(), file, row.names = FALSE, fileEncoding = 'latin1')
    } ,
    contentType= "text/csv"
  )
  
  output$downloadData_4 <- downloadHandler(
    filename = function() {
      paste0("clusters_mas_cercanos_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv2(outputdf_4(), file, row.names = FALSE, fileEncoding = 'latin1')
    } ,
    contentType= "text/csv"
  )
  
  output$downloadData_5 <- downloadHandler(
    filename = function() {
      paste0("torres_mas_cercanas_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv2(outputdf_5(), file, row.names = FALSE, fileEncoding = 'latin1')
    } ,
    contentType= "text/csv"
  )
  
  
  

  output$output_map_coordinates <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% fitBounds(-78.9909352282, -4.29818694419, -66.8763258531, 12.4373031682) %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addLayersControl(
        overlayGroups = c("Coordenadas Input"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>% addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))

  })
  
  observeEvent(input_coordinates(),{
    leafletProxy("output_map_coordinates") %>% clearMarkers() %>%
      addCircleMarkers(lat= input_coordinates()$latitude, lng=input_coordinates()$longitude, radius=1, color= 'black', fillOpacity = 1, label="Punto seleccionado", popup= paste0("Latitud: ",input_coordinates()$latitude, "<br>", "Longitud: ",input_coordinates()$longitude))
  })
  

  
  ## INFRASTRUCTURE LISTING TAB
  
  
  
  source_listing<-reactive({if (is.null(input$source_listing) || input$source_listing=="TODOS") unique(input_tab_4$source) else input$source_listing})
  
  # Subset filtering options of the clusters' centroid type
    
    tipo_torre_listing <- reactive({if (is.null(input$tipo_torre_listing)) unique(input_tab_4$tower_type) else input$tipo_torre_listing})
    
    fiber_listing <- reactive({ if ("FO"%in%(input$tx_tech_listing)) TRUE else FALSE})

    radio_listing <- reactive({ if ("Radioenlace"%in%(input$tx_tech_listing)) TRUE else FALSE})

    satellite_listing <- reactive({ if ("Satélite"%in%(input$tx_tech_listing)) TRUE else FALSE})

    tech_2g_listing <-  reactive({ if ("2G"%in%(input$access_tech_listing)) TRUE else FALSE})

    tech_3g_listing <-  reactive({ if ("3G"%in%(input$access_tech_listing)) TRUE else FALSE})

    tech_4g_listing <-  reactive({ if ("4G"%in%(input$access_tech_listing)) TRUE else FALSE})

    
    # Create reactive dataframe according to the inputs
    
    outputdf_6_listing <- reactive({
      input_tab_4[which( input_tab_4$source%in%source_listing()
                         & input_tab_4$tower_type%in%tipo_torre_listing()
                         ),]
    })
    
    output$outputdf_6_listing <- DT::renderDataTable(outputdf_6_listing(), extensions = 'Buttons', options = list(scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 10, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)
    
    # Calculate and render the number of towers
    
    sum_towers_listing <- reactive({ format(nrow(outputdf_6_listing()),big.mark=".", decimal.mark=",") })
    
    output$sum_towers_listing <- renderText(sum_towers_listing())  
    

    
    output$downloadData_6_listing <- downloadHandler(
      filename = function() {
        paste0("listado_torres_", Sys.Date(), ".csv")
      },
      content = function(file) {
        s=input$outputdf_6_listing_rows_all
        write.csv2(outputdf_6_listing()[s, , drop = FALSE], file, fileEncoding = 'latin1')
      } ,
      contentType= "text/csv"
    )

    session$onSessionEnded(function() {
      stopApp()
      q("no")
    })
 }
)
