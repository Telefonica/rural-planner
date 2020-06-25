

#install.packages("RColorBrewer")
library(shiny)
library(leaflet)
library(tidyverse)
library(stringr)
library(scales)
library(readxl)
library(xlsx)
library(plotly)
library(shinydashboard)
library(DT)
library(shiny)
library(RColorBrewer)
library(rgeos)
library(DBI)
library(RSQLite)


dev <- FALSE

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
input_tab_5 <- dbGetQuery(db, "SELECT * FROM input_tab_5")
input_tab_6 <- dbGetQuery(db, "SELECT * FROM input_tab_6")

dbDisconnect(db)


shinyServer(function(input, output, session) {
  
  ####SEGMENTATION TAB
  
  region<-reactive({if (is.null(input$region) || input$region=="TODAS") unique(input_tab_2$region) else input$region})
  
  
  # Subset filtering options of the province based on the region selected
  
  output$provincia <- renderUI({
    selectizeInput("provincia",'Provincia',c("TODAS",unique(input_tab_2$provincia[which(input_tab_2$region%in%region())])), multiple= TRUE, selected='TODAS', options = list(maxOptions = 30, placeholder = 'Introduzca provincia'))
  })
  
  provincia<-reactive({if (is.null(input$provincia) || input$provincia=="TODAS") unique(input_tab_2$provincia) else input$provincia})
  
  
  # CONNECTED COLUMN
  
  # Create connected dataframe
  
  s_c <- reactive ({ data.frame("Segmento_Telefonica" = c("TELEFONICA SERVED","TELEFONICA UNSERVED","Total"), 
                                
                                "Poblacion" = c(sum(input_tab_2$poblacion[which(input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region() & input_tab_2$segmento_telefonica=='TELEFONICA SERVED')], na.rm =TRUE), sum(input_tab_2$poblacion[which(input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region() & input_tab_2$segmento_telefonica=='TELEFONICA UNSERVED')], na.rm =TRUE), sum(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_telefonica) & input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region())], na.rm =TRUE)),
                                
                                "Num_CCPP" = c(length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_telefonica) & input_tab_2$segmento_telefonica=='TELEFONICA SERVED' & input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region())]), length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_telefonica) & input_tab_2$segmento_telefonica=='TELEFONICA UNSERVED' & input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region())]), length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_telefonica) & input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region())]))
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
    data.frame("Segmento_Overlay" = c("OVERLAY MACRO","OVERLAY FEMTO","Total"),
               
               "Poblacion" = c(sum(input_tab_2$poblacion[which(input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region() & input_tab_2$segmento_overlay=='OVERLAY MACRO')], na.rm =TRUE), sum(input_tab_2$poblacion[which(input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region() & input_tab_2$segmento_overlay=='OVERLAY FEMTO')], na.rm =TRUE), sum(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_overlay) & input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region())], na.rm =TRUE)),
               
               "Num_CCPP" = c(length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_overlay) & input_tab_2$segmento_overlay=='OVERLAY MACRO' & input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region())]), length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_overlay) & input_tab_2$segmento_overlay=='OVERLAY FEMTO' & input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region())]),  length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_overlay) & input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region())]))
    )
  })
  
  #Overlay population plot
  
  output$poblacion_overlay <-  renderPlotly(
    plot_ly(s_o()[!(s_o()$"Segmento_Overlay"=='Total'),], x = c('OVERLAY MACRO','OVERLAY FEMTO'), y = ~s_o()[!(s_o()$"Segmento_Overlay"=='Total'),2], type = 'bar',
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
    plot_ly(s_o()[!(s_o()$"Segmento_Overlay"=='Total'),], x = c('OVERLAY MACRO','OVERLAY FEMTO'), y = ~s_o()[!(s_o()$"Segmento_Overlay"=='Total'),3], type = 'bar',
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
                                  
                                  "Poblacion" = c(sum(input_tab_2$poblacion[which(input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region() & input_tab_2$segmento_greenfield=='GREENFIELD')], na.rm =TRUE), sum(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_greenfield) & input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region())], na.rm =TRUE)),
                                  
                                  "Num_CCPP" = c(length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_greenfield) & input_tab_2$segmento_greenfield=='GREENFIELD' & input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region())]), length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_greenfield) & input_tab_2$provincia%in%provincia() & input_tab_2$region%in%region())]))
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
  
  region_2<-reactive({if (is.null(input$region_2) || input$region_2=="TODAS") unique(input_tab_2$region) else input$region_2})
  
  # Subset filtering options of the province based on the region selected
  
  output$provincia_2 <- renderUI({
    selectizeInput("provincia_2",'Provincia',c("TODAS",unique(input_tab_2$provincia[input_tab_2$region%in%region_2()])), multiple= TRUE, selected='TODAS', options = list(maxOptions = 30, placeholder = 'Introduzca provincia'))
  })
  
  provincia_2 <- reactive({if (is.null(input$provincia_2) || input$provincia_2=="TODAS") unique(input_tab_2$provincia) else input$provincia_2})
  
  segmento <- reactive({  input$segmento })

  
  # Subset filtering options of the Movistar coverage available based on the region selected
  
  output$cobertura_movistar <- renderUI({
    selectizeInput("cobertura_movistar",'Cobertura Movistar',unique(input_tab_2$cobertura_movistar[input_tab_2$region%in%region_2() & input_tab_2$provincia%in%provincia_2()]), multiple= TRUE, options = list(maxOptions = 8, placeholder = 'Introduzca cobertura Movistar'))
  })
  
  cobertura_movistar <- reactive({if (is.null(input$cobertura_movistar)) unique(input_tab_2$cobertura_movistar) else input$cobertura_movistar})
  
  # Subset filtering options of the competitors' coverage available based on the region selected
  
  output$cobertura_competidores <- renderUI({
    selectizeInput("cobertura_competidores",'Cobertura Competidores',unique(input_tab_2$cobertura_competidores[input_tab_2$region%in%region_2() & input_tab_2$provincia%in%provincia_2()]), multiple= TRUE, options = list(maxOptions = 8, placeholder = 'Introduzca cobertura Competidores'))
  })
  
  cobertura_competidores <- reactive({if (is.null(input$cobertura_competidores)) unique(input_tab_2$cobertura_competidores) else input$cobertura_competidores})

  poblacion <- reactive({c(input$poblacion[1]:input$poblacion[2])})
  
  # Create reactive dataframe according to the inputs
  
  outputdf <- reactive({
    input_tab_2[which(input_tab_2$provincia%in%provincia_2()
                      & input_tab_2$region%in%region_2()
                      & input_tab_2$segmentacion%in%segmento()
                      & input_tab_2$cobertura_movistar%in%cobertura_movistar()
                      & input_tab_2$cobertura_competidores%in%cobertura_competidores()
                      & input_tab_2$poblacion%in%poblacion()),]
  })
  
  output$outputdf <- DT::renderDataTable(outputdf(), extensions='Buttons', options = list(order=list(list(4,'desc')), scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 25, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)
  
  # Calculate and render the number of settlements
  
  sum_settlements <- reactive({ format(nrow(outputdf()),big.mark=".") })
  
  output$sum_settlements <- renderText(sum_settlements())
  
  # Calculate and render the population included
  
  sum_population <- reactive ({ format(sum(outputdf()$poblacion,na.rm=TRUE),big.mark=".") })
  
  output$sum_population <- renderText(sum_population())
  
  # Render an OpenStreetMap with markers on the settlements filtered
  
  pal_segmentation <- colorFactor( palette=c('green', 'orange','red', 'navy'), domain = unique(input_tab_2$segmentacion))
  pal_coverage_movistar <- colorFactor( palette=c('#ffffff','#c2d4dd','#d0d1e6','#a6bddb','#74a9cf','#3690c0','#0570b0','#034e7b'), levels = c("-","2G","3G","3G+2G","4G","4G+2G","4G+3G", "4G+3G+2G"), na.color = "#808080E6")
  pal_coverage_bitel <- colorFactor( palette='Greens', domain = unique(input_tab_2$coverage_bitel))
  pal_coverage_entel <- colorFactor( palette='Oranges', domain = unique(input_tab_2$coverage_entel))
  pal_coverage_claro <- colorFactor( palette='Reds', domain = unique(input_tab_2$coverage_claro))
  
  
  html_legend <- "<img src='access_tower.png' style='width:15px;height:20px;'>Telefonica access<br/>
  <img src='tx_tower.png' style='width:15px;height:20px;'>Telefonica transport<br/>
  <img src='tx_tower_3.png' style='width:15px;height:20px;'>Ehas transport<br/>
  <img src='tx_tower_2.png' style='width:15px;height:20px;'>Gilat transport<br/>
  <img src='tx_tower_4.png' style='width:15px;height:20px;'>Azteca transport<br/>
  <img src='tx_tower_5.png' style='width:15px;height:20px;'>Regional transport"
  

  output$output_map_segmentation <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data=outputdf(), radius=3, color= ~pal_segmentation(outputdf()$segmentacion) , fillOpacity = 0.7, label=outputdf()$centro_poblado, popup = (paste0("Ubigeo: ",outputdf()$ubigeo, "<br>", "Centro poblado: ",outputdf()$centro_poblado, "<br>", "Distrito: ",outputdf()$distrito, "<br>", "Provincia: ",outputdf()$provincia, "<br>", "Region: ",outputdf()$region,  "<br>", "Poblacion: ",outputdf()$poblacion,  "<br>", "Escuelas educacion secundaria: ",outputdf()$num_escuelas_edu_secundaria, "<br>", "Segmento Telefonica: ",outputdf()$segmento_telefonica, "<br>", "Segmento Overlay: ",outputdf()$segmento_overlay, "<br>", "Segmento Greenfield: ",outputdf()$segmento_greenfield)),
                       stroke = FALSE) %>%
      addLegend("topright", pal = pal_segmentation, values = unique(input_tab_2$segmentacion),
                title = "Segmentación",
                opacity = 1
      ) %>%
      addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))
    })
  
  third_party_owners <-c("EHAS","GILAT","AZTECA","LAMBAYEQUE")
  
  access_icon <- makeIcon(iconUrl = "./www/access_tower.png", iconWidth = 15, iconHeight = 20)
  tx_icon <- makeIcon(iconUrl = "./www/tx_tower.png", iconWidth = 15, iconHeight = 20)
  
  iconSet <- iconList(

    EHAS =  makeIcon(iconUrl = "./www/tx_tower_3.png", iconWidth = 15, iconHeight = 20),

    GILAT =  makeIcon(iconUrl = "./www/tx_tower_2.png", iconWidth = 15, iconHeight = 20),

    AZTECA =  makeIcon(iconUrl = "./www/tx_tower_4.png", iconWidth = 15, iconHeight = 20),

    LAMBAYEQUE =  makeIcon(iconUrl = "./www/tx_tower_5.png", iconWidth = 15, iconHeight = 20)

  )
  
  output$output_map_access_transport <- renderLeaflet({
    # validate(
    #   need(outputdf()$latitude_torre_acceso, 'No encontradas opciones de acceso para los filtros seleccionados. Por favor, amplíe rango de búsqueda.'),
    #   need(outputdf()$longitude_torre_transporte[!(outputdf()$tx_owner%in%third_party_owners)], 'No encontradas opciones de transporte para los filtros seleccionados. Por favor, amplíe rango de búsqueda.'),
    #   need(outputdf()$latitude_torre_transporte[(outputdf()$tx_owner%in%third_party_owners)], 'No encontradas opciones de transporte para los filtros seleccionados. Por favor, amplíe rango de búsqueda.')
    # )
  leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data=outputdf(), radius=3, color= 'grey', fillOpacity = 1, label=outputdf()$centro_poblado, popup = (paste0("Ubigeo: ",outputdf()$ubigeo, "<br>", "Centro poblado: ",outputdf()$centro_poblado, "<br>", "Distrito: ",outputdf()$distrito, "<br>", "Provincia: ",outputdf()$provincia, "<br>", "Region: ",outputdf()$region,  "<br>", "Poblacion: ",outputdf()$poblacion,  "<br>", "Escuelas educacion secundaria: ",outputdf()$num_escuelas_edu_secundaria,  "<br>", "Acceso disponible: ",outputdf()$acceso_disponible,  "<br>", "Distancia a torre acceso (km): ",outputdf()$km_dist_torre_acceso,  "<br>", "Transporte disponible: ",outputdf()$transporte_disponible,  "<br>", "Distancia a torre transporte (km): ",outputdf()$km_dist_torre_transporte )),
                       stroke = FALSE,group="Centros Poblados") %>%
      addMarkers (lat = as.numeric(outputdf()$latitude_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf()$latitude_torre_transporte)]), lng = as.numeric(outputdf()$longitude_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners)  & !is.na(outputdf()$longitude_torre_transporte)]), icon= iconSet[outputdf()$tipo_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners)  & !is.na(outputdf()$latitude_torre_transporte)]], group = "Acceso y Transporte",
                  label=outputdf()$torre_transporte_internal_id[(outputdf()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf()$latitude_torre_transporte)], popup = (paste0("Codigo unico: ",outputdf()$torre_transporte_internal_id[(outputdf()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf()$latitude_torre_transporte)], "<br>", "Owner: ",outputdf()$tipo_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf()$latitude_torre_transporte)], "<br>", "Tipo: ",outputdf()$tipo_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf()$latitude_torre_transporte)], "<br>", "Tecnologia: ",outputdf()$tecnologia_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf()$latitude_torre_transporte)], "<br>", "Altura: ",outputdf()$altura_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners)& !is.na(outputdf()$latitude_torre_transporte)], "<br>", "Banda satélite: ", outputdf()$banda_satelite_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf()$latitude_torre_transporte)]))
      ) %>%
      addMarkers (lat = as.numeric(outputdf()$latitude_torre_transporte[!(outputdf()$tipo_torre_transporte%in%third_party_owners)  & !is.na(outputdf()$latitude_torre_transporte)]), lng = as.numeric(outputdf()$longitude_torre_transporte[!(outputdf()$tipo_torre_transporte%in%third_party_owners)  & !is.na(outputdf()$longitude_torre_transporte)]), icon= tx_icon, group = "Acceso y Transporte",
                  label=outputdf()$torre_transporte_internal_id[!(outputdf()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf()$latitude_torre_transporte)], popup = (paste0("Codigo unico: ",outputdf()$torre_transporte_internal_id[!(outputdf()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf()$latitude_torre_transporte)], "<br>", "Owner: ",outputdf()$tipo_torre_transporte[!(outputdf()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf()$latitude_torre_transporte)], "<br>", "Tipo: ",outputdf()$tipo_torre_transporte[!(outputdf()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf()$latitude_torre_transporte)], "<br>", "Tecnologia: ",outputdf()$tecnologia_torre_transporte[!(outputdf()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf()$latitude_torre_transporte)], "<br>", "Altura: ",outputdf()$altura_torre_transporte[!(outputdf()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf()$latitude_torre_transporte)], "<br>", "Banda satélite: ",outputdf()$banda_satelite_torre_transporte[!(outputdf()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf()$latitude_torre_transporte)]))
      ) %>%
      addMarkers (lat = as.numeric(outputdf()$latitude_torre_acceso[ !is.na(outputdf()$latitude_torre_acceso)]), lng = as.numeric(outputdf()$longitude_torre_acceso[ !is.na(outputdf()$longitude_torre_acceso)]), icon= access_icon, group = "Acceso y Transporte",
                  label=outputdf()$torre_acceso_internal_id[ !is.na(outputdf()$latitude_torre_acceso)], popup = (paste0("Codigo unico: ",outputdf()$torre_acceso_internal_id[ !is.na(outputdf()$latitude_torre_acceso)], "<br>", "Owner: ",outputdf()$owner_torre_acceso[ !is.na(outputdf()$latitude_torre_acceso)], "<br>", "Tipo: ",outputdf()$tipo_torre_acceso[ !is.na(outputdf()$latitude_torre_acceso)], "<br>", "Tecnologia: ",outputdf()$tecnologia_torre_acceso[ !is.na(outputdf()$latitude_torre_acceso)], "<br>", "Altura: ",outputdf()$altura_torre_acceso[ !is.na(outputdf()$latitude_torre_acceso)], "<br>", "LoS acceso - transporte: ",outputdf()$los_acceso_transporte[ !is.na(outputdf()$latitude_torre_acceso)]))
      ) %>%
      addLayersControl(
        overlayGroups = c("Centros Poblados", "Acceso y Transporte"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>% hideGroup(c("Acceso y Transporte")) %>%
      addControl(html = html_legend, position = "bottomleft") %>%
      addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))
    
  })
      
      output$output_map_coverage <- renderLeaflet({
        leaflet() %>%
          addProviderTiles(providers$OpenStreetMap.Mapnik,
                           options = providerTileOptions(noWrap = FALSE)
          ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
          addCircleMarkers(data=outputdf(), radius=3, color= 'grey', stroke= FALSE, fillOpacity = 1, label=outputdf()$centro_poblado, popup = (paste0("Ubigeo: ",outputdf()$ubigeo, "<br>", "Centro poblado: ",outputdf()$centro_poblado, "<br>", "Distrito: ",outputdf()$distrito, "<br>", "Provincia: ",outputdf()$provincia, "<br>", "Region: ",outputdf()$region,  "<br>", "Poblacion: ",outputdf()$poblacion,  "<br>", "Cobertura Movistar: ",outputdf()$cobertura_movistar, "<br>", "Cobertura Competidores: ",outputdf()$cobertura_competidores )),
                           group="Centros Poblados") %>%
          addCircleMarkers( data=outputdf(),
                            radius =3,
                            color = ~pal_coverage_claro(outputdf()$cobertura_claro), label=outputdf()$centro_poblado, popup = (paste0("Ubigeo: ",outputdf()$ubigeo, "<br>", "Centro poblado: ",outputdf()$centro_poblado, "<br>", "Cobertura Claro: ",outputdf()$cobertura_claro)),
                            stroke = FALSE, fillOpacity = 1, group= "Cobertura Claro"
          ) %>%
          addCircleMarkers( data=outputdf(),
                            radius =3,
                            color = ~pal_coverage_bitel(outputdf()$cobertura_bitel), label=outputdf()$centro_poblado, popup = (paste0("Ubigeo: ",outputdf()$ubigeo, "<br>", "Centro poblado: ",outputdf()$centro_poblado, "<br>", "Cobertura Bitel: ",outputdf()$cobertura_bitel)),
                            stroke = FALSE, fillOpacity = 1, group= "Cobertura Bitel"
          ) %>%
          addCircleMarkers( data=outputdf(),
                            radius =3,
                            color = ~pal_coverage_entel(outputdf()$cobertura_entel), label=outputdf()$centro_poblado, popup = (paste0("Ubigeo: ",outputdf()$ubigeo, "<br>", "Centro poblado: ",outputdf()$centro_poblado, "<br>", "Cobertura Entel: ",outputdf()$cobertura_entel)),
                            stroke = FALSE, fillOpacity = 1, group= "Cobertura Entel"
          ) %>%
          addCircleMarkers( data=outputdf(),
                            radius =3,
                            color = ~pal_coverage_movistar(outputdf()$cobertura_movistar), label=outputdf()$centro_poblado, popup = (paste0("Ubigeo: ",outputdf()$ubigeo, "<br>", "Centro poblado: ",outputdf()$centro_poblado, "<br>", "Cobertura Movistar: ",outputdf()$cobertura_movistar)),
                            stroke = FALSE, fillOpacity = 1, group= "Cobertura Movistar"
          ) %>%
          addLayersControl(
            overlayGroups = c("Centros Poblados", "Cobertura Movistar", "Cobertura Bitel", "Cobertura Entel", "Cobertura Claro"),
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
      write.csv2(outputdf()[s, , drop = FALSE], file, row.names = FALSE)
    } ,
    contentType= "text/csv"
  )
  

  observeEvent(input$outputdf_rows_selected, {
    leafletProxy("output_map_coverage") %>%
      clearPopups() %>%
     addPopups(lng=outputdf()$longitude[input$outputdf_rows_selected], lat=outputdf()$latitude[input$outputdf_rows_selected], popup=(paste0("Ubigeo: ",outputdf()$ubigeo[input$outputdf_rows_selected], "<br>", "Centro poblado: ",outputdf()$centro_poblado[input$outputdf_rows_selected], "<br>", "Distrito: ",outputdf()$distrito[input$outputdf_rows_selected], "<br>", "Provincia: ",outputdf()$provincia[input$outputdf_rows_selected], "<br>", "Region: ",outputdf()$region[input$outputdf_rows_selected],  "<br>", "Poblacion: ",outputdf()$poblacion[input$outputdf_rows_selected],  "<br>", "Cobertura Movistar: ",outputdf()$cobertura_movistar[input$outputdf_rows_selected], "<br>", "Cobertura Competidores: ",outputdf()$cobertura_competidores[input$outputdf_rows_selected])), options = popupOptions(closeOnClick = TRUE)
     )
    leafletProxy("output_map_segmentation") %>%
      clearPopups() %>%
      addPopups(lng=outputdf()$longitude[input$outputdf_rows_selected], lat=outputdf()$latitude[input$outputdf_rows_selected], popup=(paste0("Ubigeo: ",outputdf()$ubigeo[input$outputdf_rows_selected], "<br>", "Centro poblado: ",outputdf()$centro_poblado[input$outputdf_rows_selected], "<br>", "Distrito: ",outputdf()$distrito[input$outputdf_rows_selected], "<br>", "Provincia: ",outputdf()$provincia[input$outputdf_rows_selected], "<br>", "Region: ",outputdf()$region[input$outputdf_rows_selected],  "<br>", "Poblacion: ",outputdf()$poblacion[input$outputdf_rows_selected],  "<br>", "Escuelas educacion secundaria: ",outputdf()$num_escuelas_edu_secundaria[input$outputdf_rows_selected], "<br>", "Segmento Telefonica: ",outputdf()$segmento_telefonica[input$outputdf_rows_selected], "<br>", "Segmento Overlay: ",outputdf()$segmento_overlay[input$outputdf_rows_selected], "<br>", "Segmento Greenfield: ",outputdf()$segmento_greenfield)[input$outputdf_rows_selected]), options = popupOptions(closeOnClick = TRUE)
      )
     leafletProxy("output_map_access_transport") %>%
       clearPopups() %>%  removeShape("line_acceso") %>% removeShape("line_transporte") %>%  removeShape("line_transporte_cp") %>%
      addPopups(lng=outputdf()$longitude[input$outputdf_rows_selected], lat=outputdf()$latitude[input$outputdf_rows_selected], popup= (paste0("Ubigeo: ",outputdf()$ubigeo[input$outputdf_rows_selected], "<br>", "Centro poblado: ",outputdf()$centro_poblado[input$outputdf_rows_selected], "<br>", "Distrito: ",outputdf()$distrito[input$outputdf_rows_selected], "<br>", "Provincia: ",outputdf()$provincia[input$outputdf_rows_selected], "<br>", "Region: ",outputdf()$region[input$outputdf_rows_selected],  "<br>", "Poblacion: ",outputdf()$poblacion[input$outputdf_rows_selected],  "<br>", "Escuelas educacion secundaria: ",outputdf()$num_escuelas_edu_secundaria[input$outputdf_rows_selected],  "<br>", "Acceso disponible: ",outputdf()$acceso_disponible[input$outputdf_rows_selected],  "<br>", "Distancia a torre acceso (km): ",outputdf()$km_dist_torre_acceso[input$outputdf_rows_selected],  "<br>", "Transporte disponible: ",outputdf()$transporte_disponible[input$outputdf_rows_selected],  "<br>", "Distancia a torre transporte (km): ",outputdf()$km_dist_torre_transporte[input$outputdf_rows_selected] )), options = popupOptions(closeOnClick = TRUE)
      )
      if (!is.na(outputdf()$line_acceso[input$outputdf_rows_selected])) {
        leafletProxy("output_map_access_transport") %>% 
          addPolylines(layerId= "line_acceso",data= readWKT(outputdf()$line_acceso[input$outputdf_rows_selected]), weight= 1.5, group = "Acceso y Transporte", color="yellow") }
      if (!is.na(outputdf()$line_transporte[input$outputdf_rows_selected])) {
        leafletProxy("output_map_access_transport") %>%  
          addPolylines(layerId = "line_transporte" ,data= readWKT(outputdf()$line_transporte[input$outputdf_rows_selected]), weight= 1.5, group = "Acceso y Transporte", color= "black") }
      else { leafletProxy("output_map_access_transport") %>% 
          addPolylines(layerId= "line_transporte_cp", data= readWKT(outputdf()$line_transporte_cp[input$outputdf_rows_selected]), weight= 1.5, group = "Acceso y Transporte", color= "green") }
    })
  
  observeEvent(input$output_map_access_transport_click, {
    leafletProxy("output_map_access_transport") %>%
      removeShape("line_acceso") %>% removeShape("line_transporte") %>%  removeShape("line_transporte_cp")
  })
  
  
  ### LISTING TAB
  
  region_listing<-reactive({if (is.null(input$region_listing) || input$region_listing=="TODAS") unique(input_tab_2$region) else input$region_listing})
  
  # Subset filtering options of the province based on the region selected
  
  output$provincia_listing <- renderUI({
    selectizeInput("provincia_listing",'Provincia',c("TODAS",unique(input_tab_2$provincia[input_tab_2$region%in%region_listing()])), multiple= TRUE, selected='TODAS', options = list(maxOptions = 30, placeholder = 'Introduzca provincia'))
  })
  
  provincia_listing <- reactive({if (is.null(input$provincia_listing) || input$provincia_listing=="TODAS") unique(input_tab_2$provincia) else input$provincia_listing})
  
  segmento_listing <- reactive({  input$segmento_listing  })
  
  
  # Subset filtering options of the Movistar coverage available based on the region selected
  
  output$cobertura_movistar_listing <- renderUI({
    selectizeInput("cobertura_movistar_listing",'Cobertura Movistar',unique(input_tab_2$cobertura_movistar[input_tab_2$region%in%region_listing() & input_tab_2$provincia%in%provincia_listing()]), multiple= TRUE, options = list(maxOptions = 8, placeholder = 'Introduzca cobertura Movistar'))
  })
  
  cobertura_movistar_listing <- reactive({if (is.null(input$cobertura_movistar_listing)) unique(input_tab_2$cobertura_movistar) else input$cobertura_movistar_listing})
  
  # Subset filtering options of the competitors' coverage available based on the region selected
  
  output$cobertura_competidores_listing <- renderUI({
    selectizeInput("cobertura_competidores_listing",'Cobertura Competidores',unique(input_tab_2$cobertura_competidores[input_tab_2$region%in%region_listing() & input_tab_2$provincia%in%provincia_listing()]), multiple= TRUE, options = list(maxOptions = 8, placeholder = 'Introduzca cobertura Competidores'))
  })
  
  cobertura_competidores_listing <- reactive({if (is.null(input$cobertura_competidores_listing)) unique(input_tab_2$cobertura_competidores) else input$cobertura_competidores_listing})
  
  poblacion_2 <- reactive({c(input$poblacion_2[1]:input$poblacion_2[2])})
  
  # Create reactive dataframe according to the inputs
  
  outputdf_listing <- reactive({
    input_tab_2[which(input_tab_2$provincia%in%provincia_listing()
                      & input_tab_2$region%in%region_listing()
                      & input_tab_2$segmentacion%in%segmento_listing()
                      & input_tab_2$cobertura_movistar%in%cobertura_movistar_listing()
                      & input_tab_2$cobertura_competidores%in%cobertura_competidores_listing()
                      & input_tab_2$poblacion%in%poblacion_2()),]
  })
  
  output$outputdf_listing <- DT::renderDataTable(outputdf_listing(), extensions='Buttons', options = list(order=list(list(4,'desc')), scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 25, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)
  
  # Calculate and render the number of settlements
  
  sum_settlements_listing <- reactive({ format(nrow(outputdf_listing()),big.mark=".") })
  
  output$sum_settlements_listing <- renderText(sum_settlements_listing())
  
  # Calculate and render the population included
  
  sum_population_listing <- reactive ({ format(sum(outputdf_listing()$poblacion,na.rm=TRUE),big.mark=".") })
  
  output$sum_population_listing <- renderText(sum_population_listing())
  
  output$downloadData_listing <- downloadHandler(
    filename = function() {
      paste0("priorizacion_centros_poblados_", Sys.Date(), ".csv")
    },
    content = function(file) {
      s=input$outputdf_listing_rows_all
      write.csv2(outputdf_listing()[s, , drop = FALSE], file, row.names = FALSE)
    } ,
    contentType= "text/csv"
  )
  
  
  ### CLUSTER PRIORIZATION TAB
  
  
  region_3<-reactive({if (is.null(input$region_3) || input$region_3=="TODAS") unique(unlist(strsplit(unique(input_tab_3$regiones), " , ", fixed = TRUE))) else unique(unlist(strsplit(input$region_3, " , ", fixed = TRUE)))})
  
  # Subset filtering options of the province based on the region selected
  
  output$provincia_3 <- renderUI({
    selectizeInput("provincia_3",'Provincia',c("TODAS",unique(input_tab_2$provincia[input_tab_2$region%in%region_3()])), multiple= TRUE, selected='TODAS', options = list(maxOptions = 30, placeholder = 'Introduzca provincia/provincias'))
  })
  
  provincia_3 <- reactive({if (is.null(input$provincia_3) || input$provincia_3=="TODAS") unique(unlist(strsplit(unique(input_tab_3$provincias), " , ", fixed = TRUE))) else unique(unlist(strsplit(input$provincia_3, " , ", fixed = TRUE)))})
  
  segmento_2 <- reactive({  input$segmento_2  })
  
  
  
  # Subset filtering options of the clusters' centroid type
  
  tipo_cluster <- reactive({if (is.null(input$tipo_cluster)) unique(input_tab_3$tipo_cluster) else input$tipo_cluster})
  
  poblacion_3 <- reactive({c(input$poblacion_3[1]:input$poblacion_3[2])})

  
  # Create reactive dataframe according to the inputs
  
  outputdf_2 <- reactive({
    input_tab_3[which( grepl(paste(region_3(),collapse="|"),input_tab_3$regiones)
                      & grepl(paste(provincia_3(),collapse="|"),input_tab_3$provincias)
                      & input_tab_3$tipo_cluster%in%tipo_cluster()
                      & input_tab_3$segmentacion%in%segmento_2()
                      & input_tab_3$poblacion%in%poblacion_3()),]
  })
  
  output$outputdf_2 <- DT::renderDataTable(outputdf_2(), extensions='Buttons', options = list(order=list(list(7,'desc')),scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 10, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)

  # Calculate and render the number of clusters
  
  sum_clusters <- reactive({ format(nrow(outputdf_2()),big.mark=".") })
  
  output$sum_clusters <- renderText(sum_clusters())  

  
  # Calculate and render the number of settlements
  
  sum_settlements_2 <- reactive({ format(sum(outputdf_2()$tamano_cluster,na.rm=TRUE),big.mark=".") })
  
  output$sum_settlements_2 <- renderText(sum_settlements_2())
  
  # Calculate and render the population included
  
  sum_population_2 <- reactive ({ format(sum(outputdf_2()$poblacion,na.rm=TRUE),big.mark=".") })
  
  output$sum_population_2 <- renderText(sum_population_2())
  
  # Render an OpenStreetMap with markers on the settlements filtered

  pal_segmentation_2 <- colorFactor( palette=c('green', 'orange','blue', 'navy'), domain = unique(input_tab_3$segmentacion))

  output$output_map_segmentation_2 <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data= outputdf_2(), radius=3, color= ~pal_segmentation_2(outputdf_2()$segmentacion) , fillOpacity = 0.7, label=outputdf_2()$centroide, popup = (paste0("ID Centroide: ",outputdf_2()$centroide, "<br>", "Tipo de cluster: ",outputdf_2()$tipo_cluster, "<br>", "Centros Poblados: ",outputdf_2()$centros_poblados, "<br>", "Distritos: ",outputdf_2()$distritos, "<br>", "Provincias: ",outputdf_2()$provincias, "<br>", "Regiones: ",outputdf_2()$regiones, "<br>", "Tamaño de cluster: ",outputdf_2()$tamano_cluster,  "<br>", "Poblacion: ",outputdf_2()$poblacion,  "<br>", "Escuelas educacion secundaria: ",outputdf_2()$num_escuelas_edu_secundaria, "<br>", "Segmento: ",outputdf()$segmentacion)),
                       stroke = FALSE) %>%
      addLegend("topright", pal = pal_segmentation_2, values = unique(input_tab_3$segmentacion),
                title = "Segmentación",
                opacity = 1
      ) %>%
      addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))
  })


  output$output_map_access_transport_2 <- renderLeaflet({
     leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data=outputdf_2(), radius=3, color= 'grey', fillOpacity = 1, label=outputdf_2()$centroide, popup = (paste0("ID Centroide: ",outputdf_2()$centroide, "<br>", "Tipo de cluster: ",outputdf_2()$tipo_cluster, "<br>", "Distritos: ",outputdf_2()$distrito, "<br>", "Provincias: ",outputdf_2()$provincia, "<br>", "Regiones: ",outputdf_2()$region,  "<br>", "Poblacion: ",outputdf_2()$poblacion,  "<br>", "Escuelas educacion secundaria: ",outputdf_2()$num_escuelas_edu_secundaria,  "<br>", "Acceso disponible: ",outputdf_2()$acceso_disponible,  "<br>", "Distancia a torre acceso (km): ",outputdf_2()$km_dist_torre_acceso,  "<br>", "Transporte disponible: ",outputdf_2()$transporte_disponible,  "<br>", "Distancia a torre transporte (km): ",outputdf_2()$km_dist_torre_transporte )),
                       stroke = FALSE,group="Centroides") %>%
      addMarkers (lat = as.numeric(outputdf_2()$latitude_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf_2()$latitude_torre_transporte)]), lng = as.numeric(outputdf_2()$longitude_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners)  & !is.na(outputdf_2()$longitude_torre_transporte)]), icon= iconSet[outputdf_2()$tipo_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners)  & !is.na(outputdf_2()$latitude_torre_transporte)]], group = "Acceso y Transporte",
                  label=outputdf_2()$torre_transporte_internal_id[(outputdf_2()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf_2()$latitude_torre_transporte)], popup = (paste0("Codigo unico: ",outputdf_2()$torre_transporte_internal_id[(outputdf_2()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf_2()$latitude_torre_transporte)], "<br>", "Owner: ",outputdf_2()$tipo_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf_2()$latitude_torre_transporte)], "<br>", "Tipo: ",outputdf_2()$tipo_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf_2()$latitude_torre_transporte)], "<br>", "Tecnologia: ",outputdf_2()$tecnologia_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf_2()$latitude_torre_transporte)], "<br>", "Altura: ",outputdf_2()$altura_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners)& !is.na(outputdf_2()$latitude_torre_transporte)], "<br>", "Banda satélite: ", outputdf_2()$banda_satelite_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf_2()$latitude_torre_transporte)]))
      ) %>%
      addMarkers (lat = as.numeric(outputdf_2()$latitude_torre_transporte[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners)  & !is.na(outputdf_2()$latitude_torre_transporte)]), lng = as.numeric(outputdf_2()$longitude_torre_transporte[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners)  & !is.na(outputdf_2()$longitude_torre_transporte)]), icon= tx_icon, group = "Acceso y Transporte",
                  label=outputdf_2()$torre_transporte_internal_id[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf_2()$latitude_torre_transporte)], popup = (paste0("Codigo unico: ",outputdf_2()$torre_transporte_internal_id[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf_2()$latitude_torre_transporte)], "<br>", "Owner: ",outputdf_2()$tipo_torre_transporte[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf_2()$latitude_torre_transporte)], "<br>", "Tipo: ",outputdf_2()$tipo_torre_transporte[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf_2()$latitude_torre_transporte)], "<br>", "Tecnologia: ",outputdf_2()$tecnologia_torre_transporte[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf_2()$latitude_torre_transporte)], "<br>", "Altura: ",outputdf_2()$altura_torre_transporte[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf_2()$latitude_torre_transporte)], "<br>", "Banda satélite: ",outputdf_2()$banda_satelite_torre_transporte[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners) & !is.na(outputdf_2()$latitude_torre_transporte)]))
      ) %>%
      addMarkers (lat = as.numeric(outputdf_2()$latitude_torre_acceso[ !is.na(outputdf_2()$latitude_torre_acceso)]), lng = as.numeric(outputdf_2()$longitude_torre_acceso[ !is.na(outputdf_2()$longitude_torre_acceso)]), icon= access_icon, group = "Acceso y Transporte",
                  label=outputdf_2()$torre_acceso_internal_id[ !is.na(outputdf_2()$latitude_torre_acceso)], popup = (paste0("Codigo unico: ",outputdf_2()$torre_acceso_internal_id[ !is.na(outputdf_2()$latitude_torre_acceso)], "<br>", "Owner: ",outputdf_2()$owner_torre_acceso[ !is.na(outputdf_2()$latitude_torre_acceso)], "<br>", "Tipo: ",outputdf_2()$tipo_torre_acceso[ !is.na(outputdf_2()$latitude_torre_acceso)], "<br>", "Tecnologia: ",outputdf_2()$tecnologia_torre_acceso[ !is.na(outputdf_2()$latitude_torre_acceso)], "<br>", "Altura: ",outputdf_2()$altura_torre_acceso[ !is.na(outputdf_2()$latitude_torre_acceso)], "<br>", "LoS acceso - transporte: ",outputdf_2()$los_acceso_transporte[ !is.na(outputdf_2()$latitude_torre_acceso)]))
      ) %>%
      addLayersControl(
        overlayGroups = c("Centroides", "Acceso y Transporte"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>% hideGroup(c("Acceso y Transporte"))  %>%
      addControl(html = html_legend, position = "bottomleft") %>%
      addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))


  })
  

  output$downloadData_2 <- downloadHandler(
    filename = function() {
      paste0("priorizacion_clusters_", Sys.Date(), ".csv")
    },
    content = function(file) {
      s=input$outputdf_2_rows_all
      write.csv2(outputdf_2()[s, , drop = FALSE], file, row.names = FALSE)
    } ,
    contentType= "text/csv"
  )


  observeEvent(input$outputdf_2_rows_selected, {
    
    lines_selected <- input_tab_3_lines[outputdf_2()$centroide[input$outputdf_2_rows_selected]==input_tab_3_lines$centroide,]
    
    leafletProxy("output_map_segmentation_2") %>%
      clearPopups() %>% clearGroup("lines_centroide") %>% clearGroup("nodes_centroide") %>%
      addPopups(lng=outputdf_2()$longitude[input$outputdf_2_rows_selected], lat=outputdf_2()$latitude[input$outputdf_2_rows_selected], popup = (paste0("ID Centroide: ",outputdf_2()$centroide[input$outputdf_2_rows_selected], "<br>", "Tipo de cluster: ",outputdf_2()$tipo_cluster[input$outputdf_2_rows_selected], "<br>", "Centros Poblados: ",outputdf_2()$centros_poblados[input$outputdf_2_rows_selected], "<br>", "Distritos: ",outputdf_2()$distritos[input$outputdf_2_rows_selected], "<br>", "Provincias: ",outputdf_2()$provincias[input$outputdf_2_rows_selected], "<br>", "Regiones: ",outputdf_2()$regiones[input$outputdf_2_rows_selected], "<br>", "Tamaño de cluster: ",outputdf_2()$tamano_cluster[input$outputdf_2_rows_selected],  "<br>", "Poblacion: ",outputdf_2()$poblacion[input$outputdf_2_rows_selected],  "<br>", "Escuelas educacion secundaria: ",outputdf_2()$num_escuelas_edu_secundaria[input$outputdf_2_rows_selected], "<br>", "Segmento: ",outputdf_2()$segmentacion[input$outputdf_2_rows_selected])),
                options = popupOptions(closeOnClick = TRUE)
      )
    for (i in (1:nrow(lines_selected)))
    {
        if(!is.na(lines_selected$lines_centroide[i])){leafletProxy("output_map_segmentation_2") %>% addPolylines(group= "lines_centroide",data= readWKT(lines_selected$lines_centroide[i]), weight= 0.8, color="grey") %>%
        addCircleMarkers(data=readWKT(lines_selected$nodes_centroide[i]), radius=3, fillOpacity=0.7, color= "grey", stroke=FALSE, group="nodes_centroide", label=lines_selected$centros_poblados[i], popup = paste0("Centro Poblado: ",lines_selected$centros_poblados[i])) }
    }
    leafletProxy("output_map_access_transport_2") %>%
      clearPopups() %>%  removeShape("line_acceso") %>% removeShape("line_transporte") %>%  removeShape("line_transporte_cp") %>%
      addPopups(lng=outputdf_2()$longitude[input$outputdf_2_rows_selected], lat=outputdf_2()$latitude[input$outputdf_2_rows_selected], popup= (paste0("ID Centroide: ",outputdf_2()$centroide[input$outputdf_2_rows_selected], "<br>", "Tipo de cluster: ",outputdf_2()$tipo_cluster[input$outputdf_2_rows_selected], "<br>", "Distritos: ",outputdf_2()$distritos[input$outputdf_2_rows_selected], "<br>", "Provincias: ",outputdf_2()$provincias[input$outputdf_2_rows_selected], "<br>", "Regiones: ",outputdf_2()$regiones[input$outputdf_2_rows_selected],  "<br>", "Poblacion: ",outputdf_2()$poblacion[input$outputdf_2_rows_selected],  "<br>", "Escuelas educacion secundaria: ",outputdf_2()$num_escuelas_edu_secundaria[input$outputdf_2_rows_selected],  "<br>", "Acceso disponible: ",outputdf_2()$acceso_disponible[input$outputdf_2_rows_selected],  "<br>", "Distancia a torre acceso (km): ",outputdf_2()$km_dist_torre_acceso[input$outputdf_2_rows_selected],  "<br>", "Transporte disponible: ",outputdf_2()$transporte_disponible[input$outputdf_2_rows_selected],  "<br>", "Distancia a torre transporte (km): ",outputdf_2()$km_dist_torre_transporte[input$outputdf_2_rows_selected] )), options = popupOptions(closeOnClick = TRUE)
      )
    if (!is.na(outputdf_2()$line_acceso[input$outputdf_2_rows_selected])) {
      leafletProxy("output_map_access_transport_2") %>%
        addPolylines(layerId= "line_acceso",data= readWKT(outputdf_2()$line_acceso[input$outputdf_2_rows_selected]), weight= 0.8, group = "Acceso y Transporte") }
    if (!is.na(outputdf_2()$line_transporte[input$outputdf_2_rows_selected])) {
      leafletProxy("output_map_access_transport_2") %>%
        addPolylines(layerId = "line_transporte" ,data= readWKT(outputdf_2()$line_transporte[input$outputdf_2_rows_selected]), weight= 0.8, group = "Acceso y Transporte", color= "black") }
    else { leafletProxy("output_map_access_transport_2") %>%
        addPolylines(layerId= "line_transporte_cp", data= readWKT(outputdf_2()$line_transporte_cp[input$outputdf_2_rows_selected]), weight= 0.8, group = "Acceso y Transporte", color= "orange") }

  })
  
    
    observeEvent(input$output_map_segmentation_2_click, {
      leafletProxy("output_map_segmentation_2") %>%
        clearGroup("lines_centroide") %>% clearGroup("nodes_centroide")
      leafletProxy("output_map_access_transport_2") %>%
        removeShape("line_acceso") %>% removeShape("line_transporte") %>%  removeShape("line_transporte_cp")
    })
    
    
    ### CLUSTER LISTING TAB
    
    
    region_3_listing<-reactive({if (is.null(input$region_3_listing) || input$region_3_listing=="TODAS") unique(unlist(strsplit(unique(input_tab_3$regiones), " , ", fixed = TRUE))) else unique(unlist(strsplit(input$region_3_listing, " , ", fixed = TRUE)))})
    
    # Subset filtering options of the province based on the region selected
    
    output$provincia_3_listing <- renderUI({
      selectizeInput("provincia_3_listing",'Provincia',c("TODAS",unique(input_tab_2$provincia[input_tab_2$region%in%region_3_listing()])), multiple= TRUE, selected='TODAS', options = list(maxOptions = 30, placeholder = 'Introduzca provincia/provincias'))
    })
    
    provincia_3_listing <- reactive({if (is.null(input$provincia_3_listing) || input$provincia_3_listing=="TODAS") unique(unlist(strsplit(unique(input_tab_3$provincias), " , ", fixed = TRUE))) else unique(unlist(strsplit(input$provincia_3_listing, " , ", fixed = TRUE)))})
    
    segmento_2_listing <- reactive({  input$segmento_2_listing  })
    
    
    
    # Subset filtering options of the clusters' centroid type
    
    tipo_cluster_listing <- reactive({if (is.null(input$tipo_cluster_listing)) unique(input_tab_3$tipo_cluster) else input$tipo_cluster_listing})
    
    
    poblacion_4 <- reactive({c(input$poblacion_4[1]:input$poblacion_4[2])})
    
    # Create reactive dataframe according to the inputs
    
    outputdf_2_listing <- reactive({
      input_tab_3[which( grepl(paste(region_3_listing(),collapse="|"),input_tab_3$regiones)
                         & grepl(paste(provincia_3_listing(),collapse="|"),input_tab_3$provincias)
                         & input_tab_3$tipo_cluster%in%tipo_cluster_listing()
                         & input_tab_3$segmentacion%in%segmento_2_listing()
                         & input_tab_3$poblacion%in%poblacion_4()),]
    })
    
    output$outputdf_2_listing <- DT::renderDataTable(outputdf_2_listing(), extensions = 'Buttons', options = list(order=list(list(7,'desc')),scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 10, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)
    
    # Calculate and render the number of clusters
    
    sum_clusters_listing <- reactive({ format(nrow(outputdf_2_listing()),big.mark=".") })
    
    output$sum_clusters_listing <- renderText(sum_clusters_listing())  
    
    
    # Calculate and render the number of settlements
    
    sum_settlements_2_listing <- reactive({ format(sum(outputdf_2_listing()$tamano_cluster,na.rm=TRUE),big.mark=".") })
    
    output$sum_settlements_2_listing <- renderText(sum_settlements_2_listing())
    
    # Calculate and render the population included
    
    sum_population_2_listing <- reactive ({ format(sum(outputdf_2_listing()$poblacion,na.rm=TRUE),big.mark=".") })
    
    output$sum_population_2_listing <- renderText(sum_population_2_listing()) 
    
    output$downloadData_2_listing <- downloadHandler(
      filename = function() {
        paste0("priorizacion_clusters_", Sys.Date(), ".csv")
      },
      content = function(file) {
        s=input$outputdf_2_listing_rows_all
        write.csv2(outputdf_2_listing()[s, , drop = FALSE], file, row.names = FALSE)
      } ,
      contentType= "text/csv"
    )
    # COMBINED TRANSPORT PRIORIZATION TAB
    
    # Subset filtering options of the different deployment options
    
    medio_tx <- reactive({  input$medio_tx  })
    
    segmento_pf <- reactive({ if (is.null(input$segmento_pf) || input$segmento_pf=="TODOS") unique(input_tab_6$segmento) else input$segmento_pf  })
    
    proveedor_fibra <- reactive({  input$proveedor_fibra  })
    
    fiber_length <- reactive({c(input$fiber_length[1],input$fiber_length[2])})
    
    mw_hops <- reactive({c(input$mw_hops[1]:input$mw_hops[2])})
    
    deployment_id <- reactive({ if (is.null(input$deployment_id)) unique(input_tab_6$id_despliegue) else input$deployment_id  })
    
    fiber_node <- reactive({ if (is.null(input$fiber_node)) unique(input_tab_6$nodo_fibra) else input$fiber_node  })
    
    
    # Create reactive dataframe according to the inputs
    
    outputdf_5_listing <- reactive({
      input_tab_6[which( input_tab_6$medio_transporte%in%medio_tx()
                         & input_tab_6$segmento%in%segmento_pf()
                         & input_tab_6$proveedor_fibra%in%proveedor_fibra()
                         & (input_tab_6$longitud_fibra_km>fiber_length()[1] & input_tab_6$longitud_fibra_km<fiber_length()[2] | input_tab_6$longitud_fibra_km==0 | is.na(input_tab_6$longitud_fibra_km))
                         & (input_tab_6$saltos_radioenlace%in%mw_hops() | is.na(input_tab_6$saltos_radioenlace))
                         & input_tab_6$id_despliegue%in%deployment_id()
                         & input_tab_6$nodo_fibra%in%fiber_node()
      ),]
    })
    
    output$outputdf_5_listing <- DT::renderDataTable(outputdf_5_listing(), extensions='Buttons', options = list(scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 25, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)
    
    
    output$downloadData_5_listing <- downloadHandler(
      filename = function() {
        paste0("priorizacion_transporte_", Sys.Date(), ".csv")
      },
      content = function(file) {
        s=input$outputdf_5_listing_rows_all
        write.csv2(outputdf_5_listing()[s, , drop = FALSE], file, row.names = FALSE)
      } ,
      contentType= "text/csv"
    )
    
    ## Combined tx visualization TAB
    
    # Calculate and render the number of sites
    
    sum_clusters_deployment <- reactive({ format(length(outputdf_5()$id_sitio),big.mark=".") })
    
    output$sum_clusters_deployment <- renderText(sum_clusters_deployment())
    
    # Calculate and render the population included
    
    sum_population_deployment <- reactive ({ format(sum(outputdf_5()$poblacion_directa,na.rm=TRUE),big.mark=".") })
    
    output$sum_population_deployment <- renderText(sum_population_deployment()) 
    
    deployment_id_2 <- reactive({ if (is.null(input$deployment_id_2)) unique(input_tab_6$id_despliegue) else input$deployment_id_2})
    
    outputdf_5 <- reactive ({
      input_tab_6[input_tab_6$id_despliegue%in%deployment_id_2(),]
    })
    
    
    pal_tx_segment <- colorFactor( palette='Set3', domain = unique(input_tab_6$segmento))
    
    tx_fiber_icon <- makeIcon(iconUrl = "./www/tx_tower.png", iconWidth = 15, iconHeight = 20)
    
    
    output$output_map_transport <- renderLeaflet({
      leaflet() %>% clearBounds() %>% 
        addProviderTiles(providers$OpenStreetMap.Mapnik,
                         options = providerTileOptions(noWrap = FALSE)
        ) %>% fitBounds(-82.0, -18.4, -68.7,0.0) %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
        addLayersControl(
          overlayGroups = c("Centroides","Nodos Fibra", "Despliegues Fibra","Saltos Radioenlace"),
          options = layersControlOptions(collapsed = FALSE)
        ) %>%
        addCircleMarkers(lat=input_tab_6$latitud_sitio, lng=input_tab_6$longitud_sitio, radius=1, color= 'grey', fillOpacity = 1, label=input_tab_6$id_sitio, popup = (paste0("Sitio: ",input_tab_6$sitio, "<br>", "Medio Transporte: ",input_tab_6$medio_transporte,  "<br>", "Segmento: ",input_tab_6$segmento,  "<br>", "ID Despliegue: ",input_tab_6$id_despliegue,  "<br>", "Nodo fibra: ",input_tab_6$nodo_fibra,  "<br>", "Proveedor fibra: ",input_tab_6$proveedor_fibra,  "<br>", "Longitud despliegue fibra (km): ",input_tab_6$longitud_fibra_km,  "<br>", "Saltos radioenlace: ",input_tab_6$saltos_radioenlace)),
                         stroke = FALSE,group="Centroides") %>%
        addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))
    })
    
    observeEvent(input$show_3,{
      
      # Clear previous data
      leafletProxy("output_map_transport") %>% clearGroup("Nodos Fibra") %>% clearGroup("Despliegues Fibra") %>% clearGroup("Saltos Radioenlace") %>% clearGroup("Spot")
      
      
      leafletProxy("output_map_transport") %>%
        setView(mean(outputdf_5()$longitud_sitio),mean(outputdf_5()$latitud_sitio),zoom=10)%>%
        addCircleMarkers(lat=outputdf_5()$latitud_sitio, lng=outputdf_5()$longitud_sitio, radius=3, color= pal_tx_segment(outputdf_5()$segmento), fillOpacity = 1, 
                         label=outputdf_5()$id_sitio, popup = (paste0("Sitio: ",outputdf_5()$sitio, "<br>", "Medio Transporte: ",outputdf_5()$medio_transporte,  "<br>", 
                                                                         "Segmento: ",outputdf_5()$segmento,  "<br>", "ID Despliegue: ",outputdf_5()$id_despliegue,  "<br>", 
                                                                         "Nodo fibra: ",outputdf_5()$nodo_fibra,  "<br>", "Proveedor fibra: ",outputdf_5()$proveedor_fibra,  "<br>", 
                                                                         "Longitud despliegue fibra (km): ",outputdf_5()$longitud_fibra_km,  "<br>", 
                                                                         "Saltos radioenlace: ",outputdf_5()$saltos_radioenlace)),
                         stroke = FALSE, group="Spot")
      
      for (i in (1:nrow(outputdf_5()))){

        if (!is.na(outputdf_5()$fiber_node[i])) {
          leafletProxy("output_map_transport") %>% 
            addMarkers(data=readWKT(outputdf_5()$fiber_node[i]), icon= tx_fiber_icon, group="Nodos Fibra", label=outputdf_5()$nodo_fibra[i], popup = (paste0("Nodo fibra: ",outputdf_5()$nodo_fibra[i], "<br>", "Fiber provider: ",outputdf_5()$proveedor_fibra[i]))) }
        
        if (!is.na(outputdf_5()$fiber_paths[i])) {
          leafletProxy("output_map_transport") %>%
            addPolylines(layerId= "fiber_paths",data= readWKT(outputdf_5()$fiber_paths[i]), weight= 2, group = "Despliegues Fibra", color="green") }
        
        if (!is.na(outputdf_5()$radio_paths[i])) {
          leafletProxy("output_map_transport") %>%
            addPolylines(layerId= "radio_paths",data= readWKT(outputdf_5()$radio_paths[i]), weight= 2, group = "Saltos Radioenlace", color="red") }
      }
    }
    )
    
    observeEvent(input$hide_3,{
      leafletProxy("output_map_transport") %>% clearGroup("Nodos Fibra") %>% clearGroup("Despliegues Fibra") %>% clearGroup("Saltos Radioenlace") %>% clearGroup("Spot")
    }
    )

 }
)