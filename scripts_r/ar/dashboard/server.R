
library(shiny)
library(leaflet)
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
library(stringi)


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
input_tab_3_access <- dbGetQuery(db, "SELECT * FROM input_tab_3_access")
input_tab_4 <- dbGetQuery(db, "SELECT * FROM input_tab_4")
input_tab_4_lines <- dbGetQuery(db, "SELECT * FROM input_tab_4_lines")

dbDisconnect(db)


# SERVER FUNCTION


shinyServer(function(input, output, session) {
  
  ####SEGMENTATION TAB
  
  provincia<-reactive({if (is.null(input$provincia) || input$provincia=="TODAS") unique(input_tab_2$provincia) else input$provincia})
  
  
  # Subset filtering options of the province based on the region selected
  
  output$departamento <- renderUI({
    selectizeInput("departamento",'Departamento',c("TODOS",unique(input_tab_2$departamento[which(input_tab_2$provincia%in%provincia())])), multiple= TRUE, selected='TODOS', options = list(maxOptions = 30, placeholder = 'Introduzca departamento'))
  })
  
  departamento<-reactive({if (is.null(input$departamento) || input$departamento=="TODOS") unique(input_tab_2$departamento) else input$departamento})
  
  
  # CONNECTED COLUMN
  
  # Create connected dataframe
  
  s_c <- reactive ({ data.frame("Segmento_Telefonica" = c("TELEFONICA SERVED","TELEFONICA UNSERVED","Total"), 
                                
                                "Poblacion" = c(sum(input_tab_2$poblacion[which(input_tab_2$provincia%in%provincia() & input_tab_2$departamento%in%departamento() & input_tab_2$segmento_telefonica=='TELEFONICA SERVED')], na.rm =TRUE), sum(input_tab_2$poblacion[which(input_tab_2$provincia%in%provincia() & input_tab_2$departamento%in%departamento() & input_tab_2$segmento_telefonica=='TELEFONICA UNSERVED')], na.rm =TRUE), sum(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_telefonica) & input_tab_2$provincia%in%provincia() & input_tab_2$departamento%in%departamento())], na.rm =TRUE)),
                                
                                "Num_CCPP" = c(length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_telefonica) & input_tab_2$segmento_telefonica=='TELEFONICA SERVED' & input_tab_2$provincia%in%provincia() & input_tab_2$departamento%in%departamento())]), length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_telefonica) & input_tab_2$segmento_telefonica=='TELEFONICA UNSERVED' & input_tab_2$provincia%in%provincia() & input_tab_2$departamento%in%departamento())]), length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_telefonica) & input_tab_2$provincia%in%provincia() & input_tab_2$departamento%in%departamento())]))
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
    data.frame("Segmento_Overlay" = c("OVERLAY 2G","Total"),
               
               "Poblacion" = c(sum(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_overlay) & input_tab_2$provincia%in%provincia() & input_tab_2$departamento%in%departamento())], na.rm =TRUE), sum(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_overlay) & input_tab_2$provincia%in%provincia() & input_tab_2$departamento%in%departamento())], na.rm =TRUE)),
               
               "Num_CCPP" = c(length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_overlay) & input_tab_2$provincia%in%provincia() & input_tab_2$departamento%in%departamento())]), length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_overlay) & input_tab_2$provincia%in%provincia() & input_tab_2$departamento%in%departamento())]))
    )
  })

  
  #Overlay population plot
  # 
  output$poblacion_overlay <-  renderPlotly(
    plot_ly(s_o()[!(s_o()$"Segmento_Overlay"=='Total'),], x = c('OVERLAY 2G'), y = ~s_o()[!(s_o()$"Segmento_Overlay"=='Total'),2], type = 'bar',
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
    plot_ly(s_o()[!(s_o()$"Segmento_Overlay"=='Total'),], x = c('OVERLAY 2G'), y = ~s_o()[!(s_o()$"Segmento_Overlay"=='Total'),3], type = 'bar',
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
                                  
                                  "Poblacion" = c(sum(input_tab_2$poblacion[which(input_tab_2$provincia%in%provincia() & input_tab_2$departamento%in%departamento() & input_tab_2$segmento_greenfield=='GREENFIELD')], na.rm =TRUE), sum(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_greenfield) & input_tab_2$provincia%in%provincia() & input_tab_2$departamento%in%departamento())], na.rm =TRUE)),
                                  
                                  "Num_CCPP" = c(length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_greenfield) & input_tab_2$segmento_greenfield=='GREENFIELD' & input_tab_2$provincia%in%provincia() & input_tab_2$departamento%in%departamento())]), length(input_tab_2$poblacion[which(!is.na(input_tab_2$segmento_greenfield) & input_tab_2$provincia%in%provincia() & input_tab_2$departamento%in%departamento())]))
  )
  })
  
  # s_g <- reactive ({
  #   rbind(
  #     input_tab_2[which(input_tab_2$departamento%in%departamento()
  #                       & input_tab_2$provincia%in%provincia()
  #                       & grepl("GREENFIELD",input_tab_2$segmentacion)),]
  #     %>% group_by("segmentacion") %>% summarise("Poblacion"= sum(poblacion), "Num_CCPP"= n()),
  #     input_tab_2[which(input_tab_2$departamento%in%departamento()
  #                       & input_tab_2$provincia%in%provincia()
  #                       & grepl("GREENFIELD",input_tab_2$segmentacion)),] %>% summarise(segmentacion = "Total", "Poblacion"= sum(poblacion), "Num_CCPP"= n())
  #   )
  # })
  
  
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
  
  provincia_2 <- reactive({if (is.null(input$provincia_2) || input$provincia_2=="TODAS") unique(input_tab_2$provincia) else input$provincia_2})
  
  # Subset filtering options of the department based on the province selected
  
  output$departamento_2 <- renderUI({
    selectizeInput("departamento_2",'Departamento',c("TODOS",unique(input_tab_2$departamento[input_tab_2$provincia%in%provincia_2()])), multiple= TRUE, selected='TODOS', options = list(maxOptions = 30, placeholder = 'Introduzca departamento'))
  })
  
  departamento_2 <- reactive({if (is.null(input$departamento_2) || input$departamento_2=="TODOS") unique(input_tab_2$departamento) else input$departamento_2})
  
  segmento <- reactive({  input$segmento })
  
  etapa <- reactive({  input$etapa })
  
  plan_2019 <- reactive({  input$plan_2019 })
  
  # Subset filtering options of the Movistar coverage available based on the region selected
  
  output$cobertura_movistar <- renderUI({
    selectizeInput("cobertura_movistar",'Cobertura Movistar',unique(input_tab_2$cobertura_movistar[input_tab_2$departamento%in%departamento_2() & input_tab_2$provincia%in%provincia_2()]), multiple= TRUE, options = list(maxOptions = 8, placeholder = 'Introduzca cobertura Movistar'))
  })
  
  cobertura_movistar <- reactive({if (is.null(input$cobertura_movistar)) unique(input_tab_2$cobertura_movistar) else input$cobertura_movistar})
  
  # Subset filtering options of the competitors' coverage available based on the region selected
  
  output$cobertura_competidores <- renderUI({
    selectizeInput("cobertura_competidores",'Cobertura Competidores',unique(input_tab_2$cobertura_competidores[input_tab_2$departamento%in%departamento_2() & input_tab_2$provincia%in%provincia_2()]), multiple= TRUE, options = list(maxOptions = 8, placeholder = 'Introduzca cobertura Competidores'))
  })
  
  cobertura_competidores <- reactive({if (is.null(input$cobertura_competidores)) unique(input_tab_2$cobertura_competidores) else input$cobertura_competidores})
  
  poblacion <- reactive({ input$poblacion })
  
  transport <- reactive({ 
    switch(input$transport,
           "N/A" = { input_tab_2$id_localidad },
           TODOS = { input_tab_2$tipo_torre_transporte },
           TASA = { input_tab_2$torre_transporte_movistar_optima },
           ARSAT = { input_tab_2$torre_transporte_arsat_optima },
           SILICA = { input_tab_2$torre_transporte_silica_optima },
           GIGARED = { input_tab_2$torre_transporte_gigared_optima },
           FIBER_POINTS = { input_tab_2$torre_transporte_points_optima },
           OTROS = { input_tab_2$torre_transporte_otros_optima })
  })
  
  # Create reactive dataframe according to the inputs
  
  outputdf <- reactive({
    input_tab_2[which(input_tab_2$departamento%in%departamento_2()
                      & input_tab_2$provincia%in%provincia_2()
                      & input_tab_2$segmentacion%in%segmento()
                      & input_tab_2$etapa_enacom%in%etapa()
                      & input_tab_2$plan_2019%in%plan_2019()
                      & input_tab_2$cobertura_movistar%in%cobertura_movistar()
                      & input_tab_2$cobertura_competidores%in%cobertura_competidores()
                      & (input_tab_2$poblacion>=poblacion()[1] & input_tab_2$poblacion<=poblacion()[2])
                      & !is.na(transport())),]
    
  })
  
  output$outputdf <- DT::renderDataTable(outputdf(), extensions='Buttons', options = list(order=list(list(4,'desc')), scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 25, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)
  
  # Calculate and render the number of settlements
  
  sum_settlements <- reactive({ format(nrow(outputdf()),big.mark=".") })
  
  output$sum_settlements <- renderText(sum_settlements())
  
  # Calculate and render the population included
  
  sum_population <- reactive ({ format(sum(outputdf()$poblacion,na.rm=TRUE),big.mark=".") })
  
  output$sum_population <- renderText(sum_population())
  
  # Render an OpenStreetMap with markers on the settlements filtered
  
  pal_segmentation <- colorFactor( palette=c('purple', 'blue','orange', 'green','red', 'navy'), domain = unique(input_tab_2$segmentacion))
  pal_coverage_movistar <- colorFactor( palette=c('#c2d4dd','#d0d1e6','#a6bddb','#74a9cf','#3690c0','#0570b0','#034e7b'), domain = c("2G","3G","3G+2G","4G","4G+2G","4G+3G", "4G+3G+2G"))
  pal_coverage_personal <- colorFactor( palette="Greens", domain = c("2G"))
  #pal_coverage_nextel <- colorFactor( palette=c('#fdd0a2','#fdae6b','#fd8d3c','#e6550d','#a63603'), domain = c("2G","3G+2G","4G","4G+2G","4G+3G+2G"))
  pal_coverage_claro <- colorFactor( palette="Reds", domain = c("2G","3G","3G+2G","4G+3G","4G+3G+2G"))
  
  
  html_legend <- "<img src='access_tower.png' style='width:15px;height:20px;'>Telefonica access<br/>
  <img src='tx_tower.png' style='width:15px;height:20px;'>Telefonica transport<br/>
  <img src='tx_tower_3.png' style='width:15px;height:20px;'>Gigared transport<br/>
  <img src='tx_tower_6.png' style='width:15px;height:20px;'>Fiber points transport<br/>
  <img src='tx_tower_2.png' style='width:15px;height:20px;'>Arsat transport<br/>
  <img src='tx_tower_4.png' style='width:15px;height:20px;'>Silica transport<br/>
  <img src='tx_tower_5.png' style='width:15px;height:20px;'>Others transport"
  
  
  output$output_map_segmentation <- renderLeaflet({
    validate(
      need(outputdf()$latitude_torre_acceso, 'No encontradas opciones de acceso para los filtros seleccionados. Por favor, amplíe rango de búsqueda.'),
      need(outputdf()$longitude_torre_transporte, 'No encontradas opciones de transporte para los filtros seleccionados. Por favor, amplíe rango de búsqueda.')
    )
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data=outputdf(), radius=3, color= ~pal_segmentation(outputdf()$segmentacion) , fillOpacity = 0.7, label=outputdf()$localidad, popup = (paste0("ID Localidad: ",outputdf()$id_localidad, "<br>", "Localidad: ",outputdf()$localidad, "<br>", "Departamento: ",outputdf()$departamento, "<br>", "Provincia: ",outputdf()$provincia,  "<br>", "Poblacion: ",outputdf()$poblacion,  "<br>", "<br>", "Segmento Telefonica: ",outputdf()$segmento_telefonica, "<br>", "Segmento Overlay: ",outputdf()$segmento_overlay, "<br>", "Segmento Greenfield: ",outputdf()$segmento_greenfield)),
                       stroke = FALSE) %>%
      addLegend("topright", pal = pal_segmentation, values = unique(input_tab_2$segmentacion),
                title = "Segmentación",
                opacity = 1
      ) %>%
      addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))
  })
  
  third_party_owners <-c("GIGARED","EPEC_POINTS", "FIBRA_PROV_SAN_LUIS_POINTS", "HG_PISADA_SION_POINTS", "SION_USHUAIA_POINTS", "TELMEX_POINTS", "ARSAT", "SILICA", "OTROS")
  
  access_icon <- makeIcon(iconUrl = "./www/access_tower.png", iconWidth = 15, iconHeight = 20)
  tx_icon <- makeIcon(iconUrl = "./www/tx_tower.png", iconWidth = 15, iconHeight = 20)
  
  iconSet <- iconList(
    
    GIGARED =  makeIcon(iconUrl = "./www/tx_tower_3.png", iconWidth = 15, iconHeight = 20),
    
    FIBRA_PROV_SAN_LUIS_POINTS =  makeIcon(iconUrl = "./www/tx_tower_6.png", iconWidth = 15, iconHeight = 20),
    
    ARSAT =  makeIcon(iconUrl = "./www/tx_tower_2.png", iconWidth = 15, iconHeight = 20),
    
    SILICA =  makeIcon(iconUrl = "./www/tx_tower_4.png", iconWidth = 15, iconHeight = 20),
    
    OTROS =  makeIcon(iconUrl = "./www/tx_tower_5.png", iconWidth = 15, iconHeight = 20)
    
    
  )
  
  output$output_map_access_transport <- renderLeaflet({
    validate(
      need(outputdf()$latitude_torre_acceso, 'No encontradas opciones de acceso para los filtros seleccionados. Por favor, amplíe rango de búsqueda.'),
      need(outputdf()$longitude_torre_transporte, 'No encontradas opciones de transporte para los filtros seleccionados. Por favor, amplíe rango de búsqueda.')
    )
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data=outputdf(), radius=3, color= 'grey', fillOpacity = 1, label=outputdf()$localidad, popup = (paste0("ID Localidad: ",outputdf()$id_localidad, "<br>", "Localidad: ",outputdf()$localidad, "<br>", "Departamento: ",outputdf()$departamento, "<br>", "Provincia: ",outputdf()$provincia,  "<br>", "Poblacion: ",outputdf()$poblacion, "<br>", "Acceso disponible: ",outputdf()$acceso_disponible,  "<br>", "Distancia a torre acceso (km): ",outputdf()$km_dist_torre_acceso,  "<br>", "Transporte disponible: ",outputdf()$transporte_disponible,  "<br>", "Distancia a torre transporte (km): ",outputdf()$km_dist_torre_transporte )),
                       stroke = FALSE,group="Centros Poblados") %>%
      addMarkers (lat = as.numeric(outputdf()$latitude_torre_acceso), lng = as.numeric(outputdf()$longitude_torre_acceso), icon= access_icon, group = "Acceso y Transporte",
                  label=outputdf()$torre_acceso_internal_id, popup = (paste0("Codigo unico: ",outputdf()$torre_acceso_internal_id, "<br>", "Owner: ",outputdf()$owner_torre_acceso, "<br>", "Tipo: ",outputdf()$tipo_torre_acceso, "<br>", "Tecnologia: ",outputdf()$tecnologia_torre_acceso, "<br>", "Altura: ",outputdf()$altura_torre_acceso, "<br>", "LoS acceso - transporte: ",outputdf()$los_acceso_transporte))
      ) %>%
      addMarkers (lat = as.numeric(outputdf()$latitude_torre_transporte[!(outputdf()$tipo_torre_transporte%in%third_party_owners)]), lng = as.numeric(outputdf()$longitude_torre_transporte[!(outputdf()$tipo_torre_transporte%in%third_party_owners)]), icon= tx_icon, group = "Acceso y Transporte",
                  label=outputdf()$torre_transporte_internal_id[!(outputdf()$tipo_torre_transporte%in%third_party_owners)], popup = (paste0("Codigo unico: ",outputdf()$torre_transporte_internal_id[!(outputdf()$tipo_torre_transporte%in%third_party_owners)], "<br>", "Owner: ",outputdf()$tipo_torre_transporte[!(outputdf()$tipo_torre_transporte%in%third_party_owners)], "<br>", "Tipo: ",outputdf()$tipo_torre_transporte[!(outputdf()$tipo_torre_transporte%in%third_party_owners)], "<br>", "Tecnologia: ",outputdf()$tecnologia_torre_transporte[!(outputdf()$tipo_torre_transporte%in%third_party_owners)], "<br>", "Altura: ",outputdf()$altura_torre_transporte[!(outputdf()$tipo_torre_transporte%in%third_party_owners)], "<br>", "Banda satélite: ",outputdf()$banda_satelite_torre_transporte[!(outputdf()$tipo_torre_transporte%in%third_party_owners)]))
      ) %>%
      addMarkers (lat = as.numeric(outputdf()$latitude_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners)]), lng = as.numeric(outputdf()$longitude_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners)]), icon= iconSet[outputdf()$tipo_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners)]], group = "Acceso y Transporte",
                  label=outputdf()$torre_transporte_internal_id[(outputdf()$tipo_torre_transporte%in%third_party_owners)], popup = (paste0("Codigo unico: ",outputdf()$torre_transporte_internal_id[(outputdf()$tipo_torre_transporte%in%third_party_owners)], "<br>", "Owner: ",outputdf()$tipo_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners)], "<br>", "Tipo: ",outputdf()$tipo_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners)], "<br>", "Tecnologia: ",outputdf()$tecnologia_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners)],
                                                                                                                                           "<br>", "Altura: ",outputdf()$altura_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners)], "<br>", "Banda satélite: ",
                                                                                                                                           outputdf()$banda_satelite_torre_transporte[(outputdf()$tipo_torre_transporte%in%third_party_owners)]))
      ) %>%
      addLayersControl(
        overlayGroups = c("Centros Poblados", "Acceso y Transporte"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>% hideGroup(c("Acceso y Transporte")) %>%
      addControl(html = html_legend, position = "bottomleft") %>%
      addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))
    
  })
  
  output$output_map_coverage <- renderLeaflet({
    validate(
      need(outputdf()$latitude_torre_acceso, 'No encontradas opciones de acceso para los filtros seleccionados. Por favor, amplíe rango de búsqueda.'),
      need(outputdf()$longitude_torre_transporte, 'No encontradas opciones de transporte para los filtros seleccionados. Por favor, amplíe rango de búsqueda.')
    )
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data=outputdf(), radius=3, color= 'grey', stroke= FALSE, fillOpacity = 1, label=outputdf()$localidad, popup = (paste0("ID Localidad: ",outputdf()$id_localidad, "<br>", "Localidad: ",outputdf()$localidad, "<br>", "Departamento: ",outputdf()$departamento, "<br>", "Provincia: ",outputdf()$provincia,  "<br>", "Poblacion: ",outputdf()$poblacion,  "<br>", "Cobertura Movistar: ",outputdf()$cobertura_movistar, "<br>", "Cobertura Competidores: ",outputdf()$cobertura_competidores )),
                       group="Centros Poblados") %>%
      addCircleMarkers( data=outputdf(),
                        radius =3,
                        color = ~pal_coverage_claro(outputdf()$cobertura_claro), label=outputdf()$localidad, popup = (paste0("ID Localidad: ",outputdf()$id_localidad, "<br>", "Localidad: ",outputdf()$localidad, "<br>", "Cobertura Claro: ",outputdf()$cobertura_claro)),
                        stroke = FALSE, fillOpacity = 1, group= "Cobertura Claro"
      ) %>%
      addCircleMarkers( data=outputdf(),
                        radius =3,
                        color = ~pal_coverage_personal(outputdf()$cobertura_personal), label=outputdf()$localidad, popup = (paste0("ID Localidad: ",outputdf()$id_localidad, "<br>", "Localidad: ",outputdf()$localidad, "<br>", "Cobertura Personal: ",outputdf()$cobertura_personal)),
                        stroke = FALSE, fillOpacity = 1, group= "Cobertura Personal"
      ) %>%
      # addCircleMarkers( data=outputdf(),
      #                   radius =3,
      #                   color = ~pal_coverage_nextel(outputdf()$cobertura_nextel), label=outputdf()$localidad, popup = (paste0("ID Localidad: ",outputdf()$id_localidad, "<br>", "Localidad: ",outputdf()$localidad, "<br>", "Cobertura Nextel: ",outputdf()$cobertura_nextel)),
      #                   stroke = FALSE, fillOpacity = 1, group= "Cobertura Nextel"
      # ) %>%
      addCircleMarkers( data=outputdf(),
                        radius =3,
                        color = ~pal_coverage_movistar(outputdf()$cobertura_movistar), label=outputdf()$localidad, popup = (paste0("ID Localidad: ",outputdf()$id_localidad, "<br>", "Localidad: ",outputdf()$localidad, "<br>", "Cobertura Movistar: ",outputdf()$cobertura_movistar)),
                        stroke = FALSE, fillOpacity = 1, group= "Cobertura Movistar"
      ) %>%
      addLayersControl(
        overlayGroups = c("Centros Poblados", "Cobertura Movistar", "Cobertura Nextel", "Cobertura Personal", "Cobertura Claro"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>% hideGroup(c("Centros Poblados")) %>%
      addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))
  })
  
  output$downloadData <- downloadHandler(
    filename = function() {
      paste0("priorizacion_localidades_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      s=input$outputdf_rows_all
      #DASHA: write.csv2(outputdf()[s, , drop = FALSE], file, row.names = FALSE)
      #BEA:
      df_aux <- outputdf()[s, , drop = FALSE]
      #Para csv: df_aux[,'localidad'] <- stri_unescape_unicode(gsub("<U\\+(....)>", "\\\\u\\1", df_aux[,'localidad']))
      write.xlsx(df_aux, file, row.names = FALSE)
      
    } ,
    contentType= "text/csv"
  )
  
  
  observeEvent(input$outputdf_rows_selected, {
    leafletProxy("output_map_coverage") %>%
      clearPopups() %>%
      addPopups(lng=outputdf()$longitude[input$outputdf_rows_selected], lat=outputdf()$latitude[input$outputdf_rows_selected], popup=(paste0("ID Localidad: ",outputdf()$id_localidad[input$outputdf_rows_selected], "<br>", "Localidad: ",outputdf()$localidad[input$outputdf_rows_selected], "<br>", "Departamento: ",outputdf()$departamento[input$outputdf_rows_selected], "<br>", "Provincia: ",outputdf()$provincia[input$outputdf_rows_selected],  "<br>", "Poblacion: ",outputdf()$poblacion[input$outputdf_rows_selected],  "<br>", "Cobertura Movistar: ",outputdf()$cobertura_movistar[input$outputdf_rows_selected], "<br>", "Cobertura Competidores: ",outputdf()$cobertura_competidores[input$outputdf_rows_selected])), options = popupOptions(closeOnClick = TRUE)
      )
    leafletProxy("output_map_segmentation") %>%
      clearPopups() %>%
      addPopups(lng=outputdf()$longitude[input$outputdf_rows_selected], lat=outputdf()$latitude[input$outputdf_rows_selected], popup=(paste0("ID Localidad: ",outputdf()$id_localidad[input$outputdf_rows_selected], "<br>", "Localidad: ",outputdf()$localidad[input$outputdf_rows_selected], "<br>", "Departamento: ",outputdf()$departamento[input$outputdf_rows_selected], "<br>", "Provincia: ",outputdf()$provincia[input$outputdf_rows_selected],  "<br>", "Poblacion: ",outputdf()$poblacion[input$outputdf_rows_selected], "<br>", "Segmento Telefonica: ",outputdf()$segmento_telefonica[input$outputdf_rows_selected], "<br>", "Segmento Overlay: ",outputdf()$segmento_overlay[input$outputdf_rows_selected], "<br>", "Segmento Greenfield: ",outputdf()$segmento_greenfield)[input$outputdf_rows_selected]), options = popupOptions(closeOnClick = TRUE)
      )
    leafletProxy("output_map_access_transport") %>%
      clearPopups() %>%  removeShape("line_acceso") %>% removeShape("line_transporte") %>%  removeShape("line_transporte_cp") %>%
      addPopups(lng=outputdf()$longitude[input$outputdf_rows_selected], lat=outputdf()$latitude[input$outputdf_rows_selected], popup= (paste0("ID Localidad: ",outputdf()$id_localidad[input$outputdf_rows_selected], "<br>", "Localidad: ",outputdf()$localidad[input$outputdf_rows_selected], "<br>", "Departamento: ",outputdf()$departamento[input$outputdf_rows_selected], "<br>", "Provincia: ",outputdf()$provincia[input$outputdf_rows_selected],  "<br>", "Poblacion: ",outputdf()$poblacion[input$outputdf_rows_selected], "<br>", "Acceso disponible: ",outputdf()$acceso_disponible[input$outputdf_rows_selected],  "<br>", "Distancia a torre acceso (km): ",outputdf()$km_dist_torre_acceso[input$outputdf_rows_selected],  "<br>", "Transporte disponible: ",outputdf()$transporte_disponible[input$outputdf_rows_selected],  "<br>", "Distancia a torre transporte (km): ",outputdf()$km_dist_torre_transporte[input$outputdf_rows_selected] )), options = popupOptions(closeOnClick = TRUE)
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
  
  provincia_listing<-reactive({if (is.null(input$provincia_listing) || input$provincia_listing=="TODAS") unique(input_tab_2$provincia) else input$provincia_listing})
  
  # Subset filtering options of the province based on the region selected
  
  output$departamento_listing <- renderUI({
    selectizeInput("departamento_listing",'Departamento',c("TODOS",unique(input_tab_2$departamento[input_tab_2$provincia%in%provincia_listing()])), multiple= TRUE, selected='TODOS', options = list(maxOptions = 30, placeholder = 'Introduzca departamento'))
  })
  
  departamento_listing <- reactive({if (is.null(input$departamento_listing) || input$departamento_listing=="TODOS") unique(input_tab_2$departamento) else input$departamento_listing})
  
  segmento_listing <- reactive({  input$segmento_listing  })
  
  etapa_listing <- reactive({  input$etapa_listing })
  
  plan_2019_listing <- reactive({  input$plan_2019_listing })
  
  
  # Subset filtering options of the Movistar coverage available based on the region selected
  
  output$cobertura_movistar_listing <- renderUI({
    selectizeInput("cobertura_movistar_listing",'Cobertura Movistar',unique(input_tab_2$cobertura_movistar[input_tab_2$provincia%in%provincia_listing() & input_tab_2$departamento%in%departamento_listing()]), multiple= TRUE, options = list(maxOptions = 8, placeholder = 'Introduzca cobertura Movistar'))
  })
  
  cobertura_movistar_listing <- reactive({if (is.null(input$cobertura_movistar_listing)) unique(input_tab_2$cobertura_movistar) else input$cobertura_movistar_listing})
  
  # Subset filtering options of the competitors' coverage available based on the region selected
  
  output$cobertura_competidores_listing <- renderUI({
    selectizeInput("cobertura_competidores_listing",'Cobertura Competidores',unique(input_tab_2$cobertura_competidores[input_tab_2$provincia%in%provincia_listing() & input_tab_2$departamento%in%departamento_listing()]), multiple= TRUE, options = list(maxOptions = 8, placeholder = 'Introduzca cobertura Competidores'))
  })
  
  cobertura_competidores_listing <- reactive({if (is.null(input$cobertura_competidores_listing)) unique(input_tab_2$cobertura_competidores) else input$cobertura_competidores_listing})
  
  poblacion_2 <- reactive({ input$poblacion_2 })
  
  
  transport_2 <- reactive({ 
    switch(input$transport_2,
           "N/A" = { input_tab_2$id_localidad },
           TODOS = { input_tab_2$tipo_torre_transporte },
           TASA = { input_tab_2$torre_transporte_movistar_optima },
           ARSAT = { input_tab_2$torre_transporte_arsat_optima },
           SILICA = { input_tab_2$torre_transporte_silica_optima },
           GIGARED = { input_tab_2$torre_transporte_gigared_optima },
           FIBER_POINTS = { input_tab_2$torre_transporte_points_optima },
           OTROS = { input_tab_2$torre_transporte_otros_optima })
  })
  
  
  # Create reactive dataframe according to the inputs
  
  outputdf_listing <- reactive({
    input_tab_2[which(input_tab_2$provincia%in%provincia_listing()
                      & input_tab_2$departamento%in%departamento_listing()
                      & input_tab_2$segmentacion%in%segmento_listing()
                      & input_tab_2$etapa_enacom%in%etapa_listing()
                      & input_tab_2$plan_2019%in%plan_2019_listing()
                      & input_tab_2$cobertura_movistar%in%cobertura_movistar_listing()
                      & input_tab_2$cobertura_competidores%in%cobertura_competidores_listing()
                      & (input_tab_2$poblacion>=poblacion_2()[1] & input_tab_2$poblacion<=poblacion_2()[2])
                      & !is.na(transport_2())),]
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
      paste0("priorizacion_localidades_", Sys.Date(), ".csv")
    },
    content = function(file) {
      s=input$outputdf_listing_rows_all
      #Dasha: write.csv2(outputdf_listing()[s, , drop = FALSE], file, row.names = FALSE)
      df_aux_listing <- outputdf_listing()[s, , drop = FALSE]
      
      write.csv(df_aux_listing, file, row.names = FALSE)
      
    } ,
    contentType= "text/csv"
  )
  
  
  
  
  ### CLUSTER PRIORIZATION TAB
  
  
  provincia_3 <-reactive({if (is.null(input$provincia_3) || input$provincia_3=="TODAS") unique(unlist(strsplit(unique(input_tab_3$provincias), " , ", fixed = TRUE))) else unique(unlist(strsplit(input$provincia_3, " , ", fixed = TRUE)))})
  
  # Subset filtering options of the province based on the departamento selected
  
  output$departamento_3 <- renderUI({
    selectizeInput("departamento_3",'Departamento',c("TODOS","-",unique(input_tab_2$departamento[input_tab_2$provincia%in%provincia_3()])), multiple= TRUE, selected='TODOS', options = list(maxOptions = 30, placeholder = 'Introduzca departamento/departamentos'))
  })
  
  departamento_3 <- reactive({if (is.null(input$departamento_3) || input$departamento_3=="TODOS") unique(unlist(strsplit(unique(input_tab_3$departamentos), " , ", fixed = TRUE))) else unique(unlist(strsplit(input$departamento_3, " , ", fixed = TRUE)))})
  
  segmento_2 <- reactive({  input$segmento_2  })
  
  
  
  # Subset filtering options of the clusters' centroid type
  
  tipo_cluster <- reactive({if (is.null(input$tipo_cluster)) unique(input_tab_3$tipo_cluster) else input$tipo_cluster})
  
  poblacion_3 <- reactive({input$poblacion_3})
  
  
  transport_3 <- reactive({ 
    switch(input$transport_3,
           "N/A" = { input_tab_3$centroide },
           TODOS = { input_tab_3$tipo_torre_transporte },
           TASA = { input_tab_3$torre_transporte_movistar_optima },
           ARSAT = { input_tab_3$torre_transporte_arsat_optima },
           SILICA = { input_tab_3$torre_transporte_silica_optima },
           GIGARED = { input_tab_3$torre_transporte_gigared_optima },
           FIBER_POINTS = { input_tab_3$torre_transporte_points_optima },
           OTROS = { input_tab_3$torre_transporte_otros_optima })
  })
  
  
  
  
  # Create reactive dataframe according to the inputs
  
  outputdf_2 <- reactive({
    input_tab_3[which( grepl(paste(departamento_3(),collapse="|"),input_tab_3$departamentos)
                       & grepl(paste(provincia_3(),collapse="|"),input_tab_3$provincias)
                       & input_tab_3$tipo_cluster%in%tipo_cluster()
                       & input_tab_3$segmentacion%in%segmento_2()
                       & (input_tab_3$poblacion_unserved>=poblacion_3()[1] & input_tab_3$poblacion_unserved<=poblacion_3()[2])
                       & !is.na(transport_3())),]
  })
  
  output$outputdf_2 <- DT::renderDataTable(outputdf_2(), extensions='Buttons', options = list(order=list(list(6,'desc')),scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 10, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)
  
  # Calculate and render the number of clusters
  
  sum_clusters <- reactive({ format(nrow(outputdf_2()),big.mark=".", decimal.mark=",") })
  
  output$sum_clusters <- renderText(sum_clusters())  
  
  
  # Calculate and render the number of settlements
  
  sum_settlements_2 <- reactive({ format(sum(outputdf_2()$tamano_cluster,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_settlements_2 <- renderText(sum_settlements_2())
  
  # Calculate and render the population included
  
  sum_population_2 <- reactive ({ format(sum(outputdf_2()$poblacion_unserved,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_population_2 <- renderText(sum_population_2())
  
  # Render an OpenStreetMap with markers on the settlements filtered
  
  pal_segmentation_2 <- colorFactor( palette=c('green', 'navy', 'blue', 'orange'), domain = unique(input_tab_3$segmentacion))
  
  output$output_map_segmentation_2 <- renderLeaflet({
    validate(
      need(outputdf_2()$latitude_torre_acceso, 'No encontradas opciones de acceso para los filtros seleccionados. Por favor, amplíe rango de búsqueda.'),
      need(outputdf_2()$longitude_torre_transporte, 'No encontradas opciones de transporte para los filtros seleccionados. Por favor, amplíe rango de búsqueda.')
    )
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data= outputdf_2(), radius=3, color= ~pal_segmentation_2(outputdf_2()$segmentacion) , fillOpacity = 0.7, label=outputdf_2()$centroide, popup = (paste0("ID Centroide: ",outputdf_2()$centroide, "<br>", "Tipo de cluster: ",outputdf_2()$tipo_cluster, "<br>", "Centros Poblados: ",outputdf_2()$localidades, "<br>", "Provincias: ",outputdf_2()$provincias, "<br>", "Departamentos: ",outputdf_2()$departamentos, "<br>", "Tamaño de cluster: ",outputdf_2()$tamano_cluster,  "<br>", "Población total: ",outputdf_2()$poblacion_total,  "<br>","Población no conectada: ",outputdf_2()$poblacion_unserved,  "<br>",  "Segmento: ",outputdf_2()$segmentacion)),
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
      need(outputdf_2()$longitude_torre_transporte, 'No encontradas opciones de transporte para los filtros seleccionados. Por favor, amplíe rango de búsqueda.')
    )
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data=outputdf_2(), radius=3, color= 'grey', fillOpacity = 1, label=outputdf_2()$centroide, popup = (paste0("ID Centroide: ",outputdf_2()$centroide, "<br>", "Tipo de cluster: ",outputdf_2()$tipo_cluster,  "<br>", "Provincias: ",outputdf_2()$provincias, "<br>", "Departamentos: ",outputdf_2()$departamentos,  "<br>", "Poblacion total: ",outputdf_2()$poblacion_total,  "<br>", "Poblacion unserved: ",outputdf_2()$poblacion_unserved,  "<br>", "Acceso disponible: ",outputdf_2()$acceso_disponible,  "<br>", "Distancia a torre acceso (km): ",outputdf_2()$km_dist_torre_acceso,  "<br>", "Transporte disponible: ",outputdf_2()$transporte_disponible,  "<br>", "Distancia a torre transporte (km): ",outputdf_2()$km_dist_torre_transporte )),
                       stroke = FALSE,group="Centroides") %>%  hideGroup(c("Acceso y Transporte"))  %>%
      addMarkers (lat = as.numeric(outputdf_2()$latitude_torre_acceso), lng = as.numeric(outputdf_2()$longitude_torre_acceso), 
                  icon= access_icon, group = "Acceso y Transporte", label=outputdf_2()$torre_acceso_internal_id, 
                  popup = (paste0("Codigo unico: ",outputdf_2()$torre_acceso_internal_id, "<br>", 
                                  "Owner: ",outputdf_2()$owner_torre_acceso, "<br>", 
                                  "Tipo: ",outputdf_2()$tipo_torre_acceso, "<br>", 
                                  "Tecnologia: ",outputdf_2()$tecnologia_torre_acceso, "<br>", 
                                  "Altura: ",outputdf_2()$altura_torre_acceso, "<br>", 
                                  "LoS acceso - transporte: ",outputdf_2()$los_acceso_transporte))) %>%
      addMarkers (lat = as.numeric(outputdf_2()$latitude_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners)]), 
                  lng = as.numeric(outputdf_2()$longitude_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners)]), 
                  icon= iconSet[outputdf_2()$tipo_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners)]], group = "Acceso y Transporte", 
                  label=outputdf_2()$torre_transporte_internal_id[(outputdf_2()$tipo_torre_transporte%in%third_party_owners)], 
                  popup = (paste0("Codigo unico: ",outputdf_2()$torre_transporte_internal_id[(outputdf_2()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Owner: ",outputdf_2()$owner_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Tipo: ",outputdf_2()$tipo_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Tecnologia: ",outputdf_2()$tecnologia_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Altura: ",outputdf_2()$altura_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Banda satélite: ",outputdf_2()$banda_satelite_torre_transporte[(outputdf_2()$tipo_torre_transporte%in%third_party_owners)]))
      ) %>%
      addMarkers (lat = as.numeric(outputdf_2()$latitude_torre_transporte[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners)]), 
                  lng = as.numeric(outputdf_2()$longitude_torre_transporte[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners)]), 
                  icon= tx_icon, group = "Acceso y Transporte", label=outputdf_2()$torre_transporte_internal_id[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners)], 
                  popup = (paste0("Codigo unico: ",outputdf_2()$torre_transporte_internal_id[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Owner: ",outputdf_2()$owner_torre_transporte[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Tipo: ",outputdf_2()$tipo_torre_transporte[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Tecnologia: ",outputdf_2()$tecnologia_torre_transporte[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Altura: ",outputdf_2()$altura_torre_transporte[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Banda satélite: ",outputdf_2()$banda_satelite_torre_transporte[!(outputdf_2()$tipo_torre_transporte%in%third_party_owners)]))
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
      paste0("priorizacion_clusters_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      s=input$outputdf_2_rows_all
      
      #write.csv2(outputdf_2()[s, , drop = FALSE], file, row.names = FALSE, fileEncoding = "latin1")
      write.xlxs(outputdf_2()[s, , drop = FALSE], file, row.names = FALSE)
    } ,
    contentType= "text/csv"
  )
  
  
  observeEvent(input$outputdf_2_rows_selected, {
    
    lines_selected <- input_tab_3_lines[outputdf_2()$centroide[input$outputdf_2_rows_selected]==input_tab_3_lines$centroide,]
    
    leafletProxy("output_map_segmentation_2") %>%
      clearPopups() %>% clearGroup("lines_centroide") %>% clearGroup("nodes_centroide") %>%
      addPopups(lng=outputdf_2()$longitude[input$outputdf_2_rows_selected], lat=outputdf_2()$latitude[input$outputdf_2_rows_selected], popup = (paste0("ID Centroide: ",outputdf_2()$centroide[input$outputdf_2_rows_selected], "<br>", "Tipo de cluster: ",outputdf_2()$tipo_cluster[input$outputdf_2_rows_selected], "<br>", "Centros Poblados: ",outputdf_2()$localidades[input$outputdf_2_rows_selected], "<br>", "Provincias: ",outputdf_2()$provincias[input$outputdf_2_rows_selected], "<br>", "Departamentos: ",outputdf_2()$departamentos[input$outputdf_2_rows_selected], "<br>", "Tamaño de cluster: ",outputdf_2()$tamano_cluster[input$outputdf_2_rows_selected],  "<br>", "Población total: ",outputdf_2()$poblacion_total[input$outputdf_2_rows_selected],  "<br>","Población no conectada: ",outputdf_2()$unserved[input$outputdf_2_rows_selected],  "<br>", "Segmento: ",outputdf_2()$segmentacion[input$outputdf_2_rows_selected])),
                options = popupOptions(closeOnClick = TRUE)
      )
    for (i in (1:nrow(lines_selected)))
    {
      if(!is.na(lines_selected$lines_centroide[i])){leafletProxy("output_map_segmentation_2") %>% addPolylines(group= "lines_centroide",data= readWKT(lines_selected$lines_centroide[i]), weight= 0.8, color="grey") %>%
          addCircleMarkers(data=readWKT(lines_selected$nodes_centroide[i]), radius=3, fillOpacity=0.7, color= "grey", stroke=FALSE, group="nodes_centroide", label=lines_selected$localidades[i], popup = paste0("Centro Poblado: ",lines_selected$localidades[i])) }
    }
    leafletProxy("output_map_access_transport_2") %>%
      clearPopups() %>%  removeShape("line_acceso") %>% removeShape("line_transporte") %>%  removeShape("line_transporte_cp") %>%
      addPopups(lng=outputdf_2()$longitude[input$outputdf_2_rows_selected], lat=outputdf_2()$latitude[input$outputdf_2_rows_selected], popup= (paste0("ID Centroide: ",outputdf_2()$centroide[input$outputdf_2_rows_selected], "<br>", "Tipo de cluster: ",outputdf_2()$tipo_cluster[input$outputdf_2_rows_selected],  "<br>", "Provincias: ",outputdf_2()$provincias[input$outputdf_2_rows_selected], "<br>", "Departamentos: ",outputdf_2()$departamentos[input$outputdf_2_rows_selected],  "<br>", "Población total: ",outputdf_2()$poblacion_total[input$outputdf_2_rows_selected], "Población no conectada: ",outputdf_2()$poblacion_unserved[input$outputdf_2_rows_selected],   "<br>", "Acceso disponible: ",outputdf_2()$acceso_disponible[input$outputdf_2_rows_selected],  "<br>", "Distancia a torre acceso (km): ",outputdf_2()$km_dist_torre_acceso[input$outputdf_2_rows_selected],  "<br>", "Transporte disponible: ",outputdf_2()$transporte_disponible[input$outputdf_2_rows_selected],  "<br>", "Distancia a torre transporte (km): ",outputdf_2()$km_dist_torre_transporte[input$outputdf_2_rows_selected] )), options = popupOptions(closeOnClick = TRUE)
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
  
  provincia_2_listing<-reactive({if (is.null(input$provincia_2_listing) || input$provincia_2_listing=="TODAS") unique(input_tab_2$provincia) else input$provincia_2_listing})
  
  # Subset filtering options of the province based on the region selected
  
  output$departamento_2_listing <- renderUI({
    selectizeInput("departamento_listing",'Departamento',c("TODOS",unique(input_tab_2$departamento[input_tab_2$provincia%in%provincia_2_listing()])), multiple= TRUE, selected='TODOS', options = list(maxOptions = 30, placeholder = 'Introduzca departamento'))
  })
  
  departamento_2_listing <- reactive({if (is.null(input$departamento_2_listing) || input$departamento_2_listing=="TODOS") unique(input_tab_2$departamento) else input$departamento_2_listing})
  
  segmento_2_listing <- reactive({  input$segmento_2_listing  })
  
  
  
  # Subset filtering options of the clusters' centroid type
  
  tipo_cluster_listing <- reactive({if (is.null(input$tipo_cluster_listing)) unique(input_tab_3$tipo_cluster) else input$tipo_cluster_listing})
  
  
  poblacion_4 <- reactive({input$poblacion_4})
  
  
  transport_4 <- reactive({ 
    switch(input$transport_4,
           "N/A" = { input_tab_3$centroide },
           TODOS = { input_tab_3$tipo_torre_transporte },
           TASA = { input_tab_3$torre_transporte_movistar_optima },
           ARSAT = { input_tab_3$torre_transporte_arsat_optima },
           SILICA = { input_tab_3$torre_transporte_silica_optima },
           GIGARED = { input_tab_3$torre_transporte_gigared_optima },
           FIBER_POINTS = { input_tab_3$torre_transporte_points_optima },
           OTROS = { input_tab_3$torre_transporte_otros_optima })
  })
  
  
  
  # Create reactive dataframe according to the inputs
  
  outputdf_2_listing <- reactive({
    input_tab_3[which( grepl(paste(departamento_2_listing(),collapse="|"),input_tab_3$departamentos)
                       & grepl(paste(provincia_2_listing(),collapse="|"),input_tab_3$provincias)
                       & input_tab_3$tipo_cluster%in%tipo_cluster_listing()
                       & input_tab_3$segmentacion%in%segmento_2_listing()
                       & (input_tab_3$poblacion_unserved>=poblacion_4()[1] & input_tab_3$poblacion_unserved<=poblacion_4()[2])
                       & !is.na(transport_4())),]
  })
  
  output$outputdf_2_listing <- DT::renderDataTable(outputdf_2_listing(), extensions = 'Buttons', options = list(order=list(list(6,'desc')),scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 10, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)
  
  # Calculate and render the number of clusters
  
  sum_clusters_listing <- reactive({ format(nrow(outputdf_2_listing()),big.mark=".", decimal.mark=",") })
  
  output$sum_clusters_listing <- renderText(sum_clusters_listing())  
  
  
  # Calculate and render the number of settlements
  
  sum_settlements_2_listing <- reactive({ format(sum(outputdf_2_listing()$tamano_cluster,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_settlements_2_listing <- renderText(sum_settlements_2_listing())
  
  # Calculate and render the population included
  
  sum_population_2_listing <- reactive ({ format(sum(outputdf_2_listing()$poblacion_unserved,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_population_2_listing <- renderText(sum_population_2_listing()) 
  
  output$downloadData_2_listing <- downloadHandler(
    filename = function() {
      paste0("priorizacion_clusters_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      s=input$outputdf_2_listing_rows_all
      #write.csv2(outputdf_2_listing()[s, , drop = FALSE], file, row.names = FALSE)
      write.xlsx(outputdf_2_listing()[s, , drop = FALSE], file, row.names = FALSE)
    } ,
    contentType= "text/csv"
  )
  
  ## new start
  ### CLUSTER PRIORIZATION TAB IPT
  
  
  provincia_7 <-reactive({if (is.null(input$provincia_7) || input$provincia_7=="TODAS") unique(unlist(strsplit(unique(input_tab_4$provincias), " , ", fixed = TRUE))) else unique(unlist(strsplit(input$provincia_7, " , ", fixed = TRUE)))})
  
  # Subset filtering options of the province based on the departamento selected
  
  output$departamento_7 <- renderUI({
    selectizeInput("departamento_7",'Departamento',c("TODOS","-",unique(input_tab_2$departamento[input_tab_2$provincia%in%provincia_7()])), multiple= TRUE, selected='TODOS', options = list(maxOptions = 30, placeholder = 'Introduzca departamento/departamentos'))
  })
  
  departamento_7 <- reactive({if (is.null(input$departamento_7) || input$departamento_7=="TODOS") unique(unlist(strsplit(unique(input_tab_4$departamentos), " , ", fixed = TRUE))) else unique(unlist(strsplit(input$departamento_7, " , ", fixed = TRUE)))})
  
  segmento_7 <- reactive({  input$segmento_7  })
  
  
  
  # Subset filtering options of the clusters' centroid type
  
  tipo_cluster_7 <- reactive({if (is.null(input$tipo_cluster_7)) unique(input_tab_4$tipo_cluster) else input$tipo_cluster_7})
  
  poblacion_7 <- reactive({input$poblacion_7})
  
  
  transport_7 <- reactive({ 
    switch(input$transport_7,
           "N/A" = { input_tab_4$centroide },
           TODOS = { input_tab_4$tipo_torre_transporte },
           TASA = { input_tab_4$torre_transporte_movistar_optima },
           ARSAT = { input_tab_4$torre_transporte_arsat_optima },
           SILICA = { input_tab_4$torre_transporte_silica_optima },
           GIGARED = { input_tab_4$torre_transporte_gigared_optima },
           FIBER_POINTS = { input_tab_4$torre_transporte_points_optima },
           OTROS = { input_tab_4$torre_transporte_otros_optima })
  })
  
  
  
  
  # Create reactive dataframe according to the inputs
  
  outputdf_7 <- reactive({
    input_tab_4[which( grepl(paste(departamento_7(),collapse="|"),input_tab_4$departamentos)
                       & grepl(paste(provincia_7(),collapse="|"),input_tab_4$provincias)
                       & input_tab_4$tipo_cluster%in%tipo_cluster_7()
                       & input_tab_4$segmentacion%in%segmento_7()
                       & (input_tab_4$poblacion_unserved>=poblacion_7()[1] & input_tab_4$poblacion_unserved<=poblacion_7()[2])
                       & !is.na(transport_7())),]
  })
  
  output$outputdf_7 <- DT::renderDataTable(outputdf_7(), extensions='Buttons', options = list(order=list(list(6,'desc')),scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 10, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)
  
  # Calculate and render the number of clusters
  
  sum_clusters_7 <- reactive({ format(nrow(outputdf_7()),big.mark=".", decimal.mark=",") })
  
  output$sum_clusters_7 <- renderText(sum_clusters_7())  
  
  
  # Calculate and render the number of settlements
  
  sum_settlements_7 <- reactive({ format(sum(outputdf_7()$tamano_cluster,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_settlements_7 <- renderText(sum_settlements_7())
  
  # Calculate and render the population included
  
  sum_population_7 <- reactive ({ format(sum(outputdf_7()$poblacion_unserved,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_population_7 <- renderText(sum_population_7())
  
  # Render an OpenStreetMap with markers on the settlements filtered
  
  pal_segmentation_7 <- colorFactor( palette=c('green', 'blue', 'navy', 'orange'), domain = unique(input_tab_4$segmentacion))
  
  output$output_map_segmentation_7 <- renderLeaflet({
    validate(
      need(outputdf_7()$latitude_torre_acceso, 'No encontradas opciones de acceso para los filtros seleccionados. Por favor, amplíe rango de búsqueda.'),
      need(outputdf_7()$longitude_torre_transporte, 'No encontradas opciones de transporte para los filtros seleccionados. Por favor, amplíe rango de búsqueda.')
    )
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data= outputdf_7(), radius=3, color= ~pal_segmentation_7(outputdf_7()$segmentacion) , fillOpacity = 0.7, label=outputdf_7()$centroide, popup = (paste0("ID Centroide: ",outputdf_7()$centroide, "<br>", "Tipo de cluster: ",outputdf_7()$tipo_cluster, "<br>", "Centros Poblados: ",outputdf_7()$localidades, "<br>", "Provincias: ",outputdf_7()$provincias, "<br>", "Departamentos: ",outputdf_7()$departamentos, "<br>", "Tamaño de cluster: ",outputdf_7()$tamano_cluster,  "<br>", "Población total: ",outputdf_7()$poblacion_total,  "<br>","Población no conectada: ",outputdf_7()$poblacion_unserved,  "<br>",  "Segmento: ",outputdf_7()$segmentacion)),
                       stroke = FALSE) %>%
      addLegend("topright", pal = pal_segmentation_7, values = unique(input_tab_4$segmentacion),
                title = "Segmentación",
                opacity = 1
      ) %>%
      addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))
  })
  
  
  output$output_map_access_transport_7 <- renderLeaflet({
    validate(
      need(outputdf_7()$latitude_torre_acceso, 'No encontradas opciones de acceso para los filtros seleccionados. Por favor, amplíe rango de búsqueda.'),
      need(outputdf_7()$longitude_torre_transporte, 'No encontradas opciones de transporte para los filtros seleccionados. Por favor, amplíe rango de búsqueda.')
    )
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data=outputdf_7(), radius=3, color= 'grey', fillOpacity = 1, label=outputdf_7()$centroide, popup = (paste0("ID Centroide: ",outputdf_7()$centroide, "<br>", "Tipo de cluster: ",outputdf_7()$tipo_cluster,  "<br>", "Provincias: ",outputdf_7()$provincia, "<br>", "Departamentos: ",outputdf_7()$departamento,  "<br>", "Poblacion total: ",outputdf_7()$poblacion_total,  "<br>", "Poblacion no conectada Movistar: ",outputdf_7()$poblacion_unserved,  "<br>", "Acceso disponible: ",outputdf_7()$acceso_disponible,  "<br>", "Distancia a torre acceso (km): ",outputdf_7()$km_dist_torre_acceso,  "<br>", "Transporte disponible: ",outputdf_7()$transporte_disponible,  "<br>", "Distancia a torre transporte (km): ",outputdf_7()$km_dist_torre_transporte )),
                       stroke = FALSE,group="Centroides") %>%  hideGroup(c("Acceso y Transporte"))  %>%
      addMarkers (lat = as.numeric(outputdf_7()$latitude_torre_acceso), lng = as.numeric(outputdf_7()$longitude_torre_acceso), 
                  icon= access_icon, group = "Acceso y Transporte", label=outputdf_7()$torre_acceso_internal_id, 
                  popup = (paste0("Codigo unico: ",outputdf_7()$torre_acceso_internal_id, "<br>", 
                                  "Owner: ",outputdf_7()$owner_torre_acceso, "<br>", 
                                  "Tipo: ",outputdf_7()$tipo_torre_acceso, "<br>", 
                                  "Tecnologia: ",outputdf_7()$tecnologia_torre_acceso, "<br>", 
                                  "Altura: ",outputdf_7()$altura_torre_acceso, "<br>", 
                                  "LoS acceso - transporte: ",outputdf_7()$los_acceso_transporte))) %>%
      addMarkers (lat = as.numeric(outputdf_7()$latitude_torre_transporte[(outputdf_7()$tipo_torre_transporte%in%third_party_owners)]), 
                  lng = as.numeric(outputdf_7()$longitude_torre_transporte[(outputdf_7()$tipo_torre_transporte%in%third_party_owners)]), 
                  icon= iconSet[outputdf_7()$tipo_torre_transporte[(outputdf_7()$tipo_torre_transporte%in%third_party_owners)]], group = "Acceso y Transporte", 
                  label=outputdf_7()$torre_transporte_internal_id[(outputdf_7()$tipo_torre_transporte%in%third_party_owners)], 
                  popup = (paste0("Codigo unico: ",outputdf_7()$torre_transporte_internal_id[(outputdf_7()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Owner: ",outputdf_7()$owner_torre_transporte[(outputdf_7()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Tipo: ",outputdf_7()$tipo_torre_transporte[(outputdf_7()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Tecnologia: ",outputdf_7()$tecnologia_torre_transporte[(outputdf_7()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Altura: ",outputdf_7()$altura_torre_transporte[(outputdf_7()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Banda satélite: ",outputdf_7()$banda_satelite_torre_transporte[(outputdf_7()$tipo_torre_transporte%in%third_party_owners)]))
      ) %>%
      addMarkers (lat = as.numeric(outputdf_7()$latitude_torre_transporte[!(outputdf_7()$tipo_torre_transporte%in%third_party_owners)]), 
                  lng = as.numeric(outputdf_7()$longitude_torre_transporte[!(outputdf_7()$tipo_torre_transporte%in%third_party_owners)]), 
                  icon= tx_icon, group = "Acceso y Transporte", label=outputdf_7()$torre_transporte_internal_id[!(outputdf_7()$tipo_torre_transporte%in%third_party_owners)], 
                  popup = (paste0("Codigo unico: ",outputdf_7()$torre_transporte_internal_id[!(outputdf_7()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Owner: ",outputdf_7()$owner_torre_transporte[!(outputdf_7()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Tipo: ",outputdf_7()$tipo_torre_transporte[!(outputdf_7()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Tecnologia: ",outputdf_7()$tecnologia_torre_transporte[!(outputdf_7()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Altura: ",outputdf_7()$altura_torre_transporte[!(outputdf_7()$tipo_torre_transporte%in%third_party_owners)], "<br>", 
                                  "Banda satélite: ",outputdf_7()$banda_satelite_torre_transporte[!(outputdf_7()$tipo_torre_transporte%in%third_party_owners)]))
      ) %>%
      addLayersControl(
        overlayGroups = c("Centroides", "Acceso y Transporte"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>%
      addControl(html = html_legend, position = "bottomleft") %>%
      addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))
  })
  
  
  output$downloadData_7 <- downloadHandler(
    filename = function() {
      paste0("priorizacion_clusters_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      s=input$outputdf_7_rows_all
      #write.csv2(outputdf_7()[s, , drop = FALSE], file, row.names = FALSE, fileEncoding = "latin1")
      
      write.xlsx(outputdf_7()[s, , drop = FALSE], file, row.names = FALSE)
    } ,
    contentType= "text/csv"
  )
  
  
  observeEvent(input$outputdf_7_rows_selected, {
    
    lines_selected <- input_tab_4_lines[outputdf_7()$centroide[input$outputdf_7_rows_selected]==input_tab_4_lines$centroide,]
    
    leafletProxy("output_map_segmentation_7") %>%
      clearPopups() %>% clearGroup("lines_centroide") %>% clearGroup("nodes_centroide") %>%
      addPopups(lng=outputdf_7()$longitude[input$outputdf_7_rows_selected], lat=outputdf_7()$latitude[input$outputdf_7_rows_selected], popup = (paste0("ID Centroide: ",outputdf_7()$centroide[input$outputdf_7_rows_selected], "<br>", "Tipo de cluster: ",outputdf_7()$tipo_cluster[input$outputdf_7_rows_selected], "<br>", "Centros Poblados: ",outputdf_7()$localidades[input$outputdf_7_rows_selected], "<br>", "Provincias: ",outputdf_7()$provincias[input$outputdf_7_rows_selected], "<br>", "Departamentos: ",outputdf_7()$departamentos[input$outputdf_7_rows_selected], "<br>", "Tamaño de cluster: ",outputdf_7()$tamano_cluster[input$outputdf_7_rows_selected],  "<br>", "Poblacion total: ",outputdf_7()$poblacion_total[input$outputdf_7_rows_selected], "<br>", "Poblacion no conectada: ",outputdf_7()$poblacion_unserved[input$outputdf_7_rows_selected],   "<br>", "Segmento: ",outputdf_7()$segmentacion[input$outputdf_7_rows_selected])),
                options = popupOptions(closeOnClick = TRUE)
      )
    for (i in (1:nrow(lines_selected)))
    {
      if(!is.na(lines_selected$lines_centroide[i])){leafletProxy("output_map_segmentation_7") %>% addPolylines(group= "lines_centroide",data= readWKT(lines_selected$lines_centroide[i]), weight= 0.8, color="grey") %>%
          addCircleMarkers(data=readWKT(lines_selected$nodes_centroide[i]), radius=3, fillOpacity=0.7, color= "grey", stroke=FALSE, group="nodes_centroide", label=lines_selected$localidades[i], popup = paste0("Centro Poblado: ",lines_selected$localidades[i])) }
    }
    leafletProxy("output_map_access_transport_7") %>%
      clearPopups() %>%  removeShape("line_acceso") %>% removeShape("line_transporte") %>%  removeShape("line_transporte_cp") %>%
      addPopups(lng=outputdf_7()$longitude[input$outputdf_7_rows_selected], lat=outputdf_7()$latitude[input$outputdf_7_rows_selected], popup= (paste0("ID Centroide: ",outputdf_7()$centroide[input$outputdf_7_rows_selected], "<br>", "Tipo de cluster: ",outputdf_7()$tipo_cluster[input$outputdf_7_rows_selected],  "<br>", "Provincias: ",outputdf_7()$provincias[input$outputdf_7_rows_selected], "<br>", "Departamentos: ",outputdf_7()$departamentos[input$outputdf_7_rows_selected],  "<br>", "Población total: ",outputdf_7()$poblacion_total[input$outputdf_7_rows_selected],   "<br>",  "Población no conectada: ",outputdf_7()$poblacion_unserved[input$outputdf_7_rows_selected], "<br>", "Acceso disponible: ",outputdf_7()$acceso_disponible[input$outputdf_7_rows_selected],  "<br>", "Distancia a torre acceso (km): ",outputdf_7()$km_dist_torre_acceso[input$outputdf_7_rows_selected],  "<br>", "Transporte disponible: ",outputdf_7()$transporte_disponible[input$outputdf_7_rows_selected],  "<br>", "Distancia a torre transporte (km): ",outputdf_7()$km_dist_torre_transporte[input$outputdf_7_rows_selected] )), options = popupOptions(closeOnClick = TRUE)
      )
    if (!is.na(outputdf_7()$line_acceso[input$outputdf_7_rows_selected])) {
      leafletProxy("output_map_access_transport_7") %>%
        addPolylines(layerId= "line_acceso",data= readWKT(outputdf_7()$line_acceso[input$outputdf_7_rows_selected]), weight= 0.8, group = "Acceso y Transporte") }
    if (!is.na(outputdf_7()$line_transporte[input$outputdf_7_rows_selected])) {
      leafletProxy("output_map_access_transport_7") %>%
        addPolylines(layerId = "line_transporte" ,data= readWKT(outputdf_7()$line_transporte[input$outputdf_7_rows_selected]), weight= 0.8, group = "Acceso y Transporte", color= "black") }
    else if (!is.na(outputdf_7()$line_transporte_cp[input$outputdf_7_rows_selected])) { leafletProxy("output_map_access_transport_7") %>%
        addPolylines(layerId= "line_transporte_cp", data= readWKT(outputdf_7()$line_transporte_cp[input$outputdf_7_rows_selected]), weight= 0.8, group = "Acceso y Transporte", color= "orange") }
    
  })
  
  
  observeEvent(input$output_map_segmentation_7_click, {
    leafletProxy("output_map_segmentation_7") %>%
      clearGroup("lines_centroide") %>% clearGroup("nodes_centroide")
    leafletProxy("output_map_access_transport_7") %>%
      removeShape("line_acceso") %>% removeShape("line_transporte") %>%  removeShape("line_transporte_cp")
  })
  
  
  ### CLUSTER LISTING TAB
  
  provincia_8_listing<-reactive({if (is.null(input$provincia_8_listing) || input$provincia_8_listing=="TODAS") unique(input_tab_4$provincia) else input$provincia_8_listing})
  
  # Subset filtering options of the province based on the region selected
  
  output$departamento_8_listing <- renderUI({
    selectizeInput("departamento_8_listing",'Departamento',c("TODOS",unique(input_tab_4$departamento[input_tab_4$provincia%in%provincia_8_listing()])), multiple= TRUE, selected='TODOS', options = list(maxOptions = 30, placeholder = 'Introduzca departamento'))
  })
  
  departamento_8_listing <- reactive({if (is.null(input$departamento_8_listing) || input$departamento_8_listing=="TODOS") unique(input_tab_4$departamento) else input$departamento_8_listing})
  
  segmento_8_listing <- reactive({  input$segmento_8_listing  })
  
  
  
  # Subset filtering options of the clusters' centroid type
  
  tipo_cluster_8_listing <- reactive({if (is.null(input$tipo_cluster_8_listing)) unique(input_tab_4$tipo_cluster) else input$tipo_cluster_8_listing})
  
  
  poblacion_8 <- reactive({input$poblacion_8})
  
  
  transport_8 <- reactive({ 
    switch(input$transport_8,
           "N/A" = { input_tab_4$centroide },
           TODOS = { input_tab_4$tipo_torre_transporte },
           TASA = { input_tab_4$torre_transporte_movistar_optima },
           ARSAT = { input_tab_4$torre_transporte_arsat_optima },
           SILICA = { input_tab_4$torre_transporte_silica_optima },
           GIGARED = { input_tab_4$torre_transporte_gigared_optima },
           FIBER_POINTS = { input_tab_4$torre_transporte_points_optima },
           OTROS = { input_tab_3$torre_transporte_otros_optima })
  })
  
  
  
  # Create reactive dataframe according to the inputs
  
  outputdf_8_listing <- reactive({
    input_tab_4[which( grepl(paste(departamento_8_listing(),collapse="|"),input_tab_4$departamentos)
                       & grepl(paste(provincia_8_listing(),collapse="|"),input_tab_4$provincias)
                       & input_tab_4$tipo_cluster%in%tipo_cluster_8_listing()
                       & input_tab_4$segmentacion%in%segmento_8_listing()
                       & (input_tab_4$poblacion_unserved>=poblacion_8()[1] & input_tab_4$poblacion_unserved<=poblacion_8()[2])
                       & !is.na(transport_8())),]
  })
  
  output$outputdf_8_listing <- DT::renderDataTable(outputdf_8_listing(), extensions = 'Buttons', options = list(order=list(list(6,'desc')),scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 10, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)
  
  # Calculate and render the number of clusters
  
  sum_clusters_listing_8 <- reactive({ format(nrow(outputdf_8_listing()),big.mark=".", decimal.mark=",") })
  
  output$sum_clusters_listing_8 <- renderText(sum_clusters_listing_8())  
  
  
  # Calculate and render the number of settlements
  
  sum_settlements_8_listing <- reactive({ format(sum(outputdf_8_listing()$tamano_cluster,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_settlements_8_listing <- renderText(sum_settlements_8_listing())
  
  # Calculate and render the population included
  
  sum_population_8_listing <- reactive ({ format(sum(outputdf_8_listing()$poblacion_unserved,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_population_8_listing <- renderText(sum_population_8_listing()) 
  
  output$downloadData_8_listing <- downloadHandler(
    filename = function() {
      #paste0("priorizacion_clusters_", Sys.Date(), ".csv")
      paste0("priorizacion_clusters_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      s=input$outputdf_8_listing_rows_all
      #write.csv2(outputdf_8_listing()[s, , drop = FALSE], file, row.names = FALSE)
      #write.csv2(outputdf_8_listing()[s, , drop = FALSE], file, row.names = FALSE, fileEncoding = "cp1252")
      write.xlsx(x = outputdf_8_listing()[s, , drop = FALSE],file, row.names = FALSE)
    } ,
    contentType= "text/csv"
  )
  
  ### new end
  
  
  ### PARTNER PRIORIZATION TAB
  
  nivel_partners <-reactive({ input$nivel_partners })
  
  partner <- reactive({if ("TODOS"%in%input$partner) unique(input_tab_3$tipo_torre_transporte[!is.na(input_tab_3$tipo_torre_transporte)]) else input$partner })
  
  provincia_4 <- reactive({if (nivel_partners()%in%c("Nacional","Departamental")) unique(input_tab_2$provincia) else input$provincia_4})
  
  departamento_4 <- reactive({if (nivel_partners()=="Nacional") unique(input_tab_2$departamento) else if (nivel_partners()=="Provincial") unique(input_tab_2$departamento[input_tab_2$provincia%in%provincia_4()]) else input$departamento_4})
  
  
  # Create reactive dataframe according to the inputs
  
  outputdf_3 <- reactive({
    input_tab_3_access %>%
      filter(tipo_torre_transporte %in% partner()) %>%
      filter(!is.na(tipo_torre_transporte)) %>%
      filter(grepl(paste(departamento_4(),collapse="|"),departamentos))  %>%
      filter(grepl(paste(provincia_4(),collapse="|"),provincias))
  })
  
  # Calculate and render the number of clusters
  
  sum_sites_4 <- reactive({ format(length(unique(outputdf_3()$cluster_id)),big.mark=".", decimal.mark=",") })
  
  output$sum_sites_4 <- renderText(sum_sites_4())  
  
  
  # Calculate and render the number of settlements
  
  sum_settlements_4 <- reactive({ format(sum(outputdf_3()$tamano_cluster[!duplicated(outputdf_3()$cluster_id)],na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_settlements_4 <- renderText(sum_settlements_4())
  
  # Calculate and render the population included
  
  sum_population_4 <- reactive ({ format(sum(outputdf_3()$poblacion_unserved[!duplicated(outputdf_3()$cluster_id)],na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_population_4 <- renderText(sum_population_4())
  
  ### Plots
  # 
  
  output$partners_plot <- renderPlotly({
    ggplotly(ggplot(data = outputdf_3()[!is.na(outputdf_3()$tipo_torre_acceso),], aes(x = tipo_torre_transporte,
                                                                                      fill = tipo_torre_acceso)) +
               geom_bar() + labs( y = "Número sites", x = "Owner transporte") + scale_fill_discrete(name = "Owner acceso")
             + theme(legend.position="none")+ coord_flip()) 
  })
  
  ### PARTNER VISUALIZATION TAB
  
  # nivel_partners_2 <-reactive({ input$nivel_partners_2 })
  
  partner_2 <- reactive({if (is.null(input$partner_2) || "TODOS"%in%input$partner_2) unique(input_tab_3$tipo_torre_transporte[!is.na(input_tab_3$tipo_torre_transporte)]) else input$partner_2 })
  # 
  # provincia_5 <- reactive({if (nivel_partners()=="Nacional") unique(input_tab_2$provincia) else input$provincia_5})
  # 
  # 
  
  # Create reactive dataframe according to the inputs
  
  outputdf_4 <- reactive({
    input_tab_3[which( #grepl(paste(provincia_5(),collapse="|"),input_tab_3$provincias) &
      input_tab_3$tipo_torre_transporte %in% c(partner_2())
      & !is.na(input_tab_3$tipo_torre_transporte)),]
  })
  
  # Calculate and render the number of clusters
  
  sum_sites_5 <- reactive({ format(nrow(outputdf_4()),big.mark=".", decimal.mark=",") })
  
  output$sum_sites_5 <- renderText(sum_sites_5())  
  
  
  # Calculate and render the number of settlements
  
  sum_settlements_5 <- reactive({ format(sum(outputdf_4()$tamano_cluster,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_settlements_5 <- renderText(sum_settlements_5())
  
  # Calculate and render the population included
  
  sum_population_5 <- reactive ({ format(sum(outputdf_4()$poblacion_unserved,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_population_5 <- renderText(sum_population_5())
  
  
  access_icon <- makeIcon(iconUrl = "./www/access_tower.png", iconWidth = 15, iconHeight = 20)
  
  iconSet_2 <- iconList(
    
    OTROS = makeIcon(iconUrl = "./www/tx_tower_5.png", iconWidth = 15, iconHeight = 20),
    
    TASA = makeIcon(iconUrl = "./www/tx_tower.png", iconWidth = 15, iconHeight = 20),
    
    GIGARED =  makeIcon(iconUrl = "./www/tx_tower_3.png", iconWidth = 15, iconHeight = 20),
    
    FIBER_POINTS =  makeIcon(iconUrl = "./www/tx_tower_6.png", iconWidth = 15, iconHeight = 20),
    
    ARSAT =  makeIcon(iconUrl = "./www/tx_tower_2.png", iconWidth = 15, iconHeight = 20),
    
    SILICA =  makeIcon(iconUrl = "./www/tx_tower_4.png", iconWidth = 15, iconHeight = 20)
    
  )
  
  html_legend <- "<img src='access_tower.png' style='width:15px;height:20px;'>Telefonica access<br/>
  <img src='tx_tower.png' style='width:15px;height:20px;'>Telefonica transport<br/>
  <img src='tx_tower_3.png' style='width:15px;height:20px;'>Gigared transport<br/>
  <img src='tx_tower_6.png' style='width:15px;height:20px;'>Fiber points transport<br/>
  <img src='tx_tower_2.png' style='width:15px;height:20px;'>Arsat transport<br/>
  <img src='tx_tower_4.png' style='width:15px;height:20px;'>Silica transport<br/>
  <img src='tx_tower_5.png' style='width:15px;height:20px;'>Otros transport"
  
  
  
  
  output$partners_map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = FALSE)
      ) %>% clearBounds() %>% addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="sqmeters") %>%
      addCircleMarkers(data=outputdf_4(), radius=3, color= 'grey', fillOpacity = 1, label=outputdf_4()$centroide, popup = (paste0("ID Centroide: ",outputdf_4()$centroide, "<br>", "Tipo de cluster: ",outputdf_4()$tipo_cluster,  "<br>", "Provincias: ",outputdf_4()$provincia, "<br>", "Departamentos: ",outputdf_4()$departamento,  "<br>", "Poblacion: ",outputdf_4()$poblacion,  "<br>", "Acceso disponible: ",outputdf_4()$acceso_disponible,  "<br>", "Distancia a torre acceso (km): ",outputdf_4()$km_dist_torre_acceso,  "<br>", "Transporte disponible: ",outputdf_4()$transporte_disponible,  "<br>", "Distancia a torre transporte (km): ",outputdf_4()$km_dist_torre_transporte )),
                       stroke = FALSE,group="Centroides") %>%
      addMarkers (lat = as.numeric(outputdf_4()$latitude_torre_transporte),
                  lng = as.numeric(outputdf_4()$longitude_torre_transporte),
                  icon= iconSet_2[outputdf_4()$tipo_torre_transporte], group = "Acceso y Transporte",
                  label=outputdf_4()$torre_transporte_internal_id,
                  popup = (paste0("Codigo unico: ",outputdf_4()$torre_transporte_internal_id, "<br>",
                                  "Owner: ",outputdf_4()$tipo_torre_transporte, "<br>",
                                  "Tecnologia: ",outputdf_4()$tecnologia_torre_transporte, "<br>",
                                  "Altura: ",outputdf_4()$altura_torre_transporte, "<br>",
                                  "Banda satélite: ",outputdf_4()$banda_satelite_torre_transporte))
      ) %>%
      addLayersControl(
        overlayGroups = c("Centroides", "Acceso y Transporte"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>%
      addControl(html = html_legend, position = "bottomleft") %>%
      addScaleBar(position="bottomright",options=scaleBarOptions(maxWidth = 200, metric = TRUE, imperial = FALSE))
  })
  
  
  #### LISTING PARTNERS TAB
  
  
  provincia_6 <- reactive({if (is.null(input$provincia_6) || input$provincia_6=="TODAS") unique(input_tab_2$provincia) else input$provincia_6})
  
  # Subset filtering options of the department based on the province selected
  
  output$departamento_6 <- renderUI({
    selectizeInput("departamento_6",'Departamento',c("TODOS",unique(input_tab_2$departamento[input_tab_2$provincia%in%provincia_6()])), multiple= TRUE, selected='TODOS', options = list(maxOptions = 30, placeholder = 'Introduzca departamento'))
  })
  
  departamento_6 <- reactive({if (is.null(input$departamento_6) || input$departamento_6=="TODOS") unique(input_tab_2$departamento) else input$departamento_6})
  
  segmento_3 <- reactive({  input$segmento_3 })
  
  
  # Subset filtering options of the Movistar coverage available based on the region selected
  
  output$cobertura_movistar_3 <- renderUI({
    selectizeInput("cobertura_movistar_3",'Cobertura Movistar',unique(input_tab_2$cobertura_movistar[input_tab_2$departamento%in%departamento_6() & input_tab_2$provincia%in%provincia_6()]), multiple= TRUE, options = list(maxOptions = 8, placeholder = 'Introduzca cobertura Movistar'))
  })
  
  cobertura_movistar_3 <- reactive({if (is.null(input$cobertura_movistar_3)) unique(input_tab_2$cobertura_movistar) else input$cobertura_movistar_3})
  
  # Subset filtering options of the competitors' coverage available based on the region selected
  
  output$cobertura_competidores_3 <- renderUI({
    selectizeInput("cobertura_competidores_3",'Cobertura Competidores',unique(input_tab_2$cobertura_competidores[input_tab_2$departamento%in%departamento_6() & input_tab_2$provincia%in%provincia_6()]), multiple= TRUE, options = list(maxOptions = 8, placeholder = 'Introduzca cobertura Competidores'))
  })
  
  cobertura_competidores_3 <- reactive({if (is.null(input$cobertura_competidores_3)) unique(input_tab_2$cobertura_competidores) else input$cobertura_competidores_3})
  
  poblacion_5 <- reactive({ input$poblacion_5 })
  
  # transport_5 <- reactive({ if (input$transport_5=="TODOS") c("TASA","GIGARED","ARSAT","SILICA") else input$transport_5 })
  transport_5 <- reactive({ input$transport_5 })
  
  # Create reactive dataframe according to the inputs
  
  outputdf_6 <- reactive({
    switch(transport_5(),
           "N/A" = { input_tab_2 },
           TODOS = { rbind(cbind(third_party_owners = "TASA",input_tab_2[which(input_tab_2$departamento%in%departamento_6()
                                                                               & input_tab_2$provincia%in%provincia_6()
                                                                               & input_tab_2$segmentacion%in%segmento_3()
                                                                               & input_tab_2$cobertura_movistar%in%cobertura_movistar_3()
                                                                               & input_tab_2$cobertura_competidores%in%cobertura_competidores_3()
                                                                               & (input_tab_2$poblacion>=poblacion_5()[1] & input_tab_2$poblacion<=poblacion_5()[2])
                                                                               & !is.na(input_tab_2$torre_transporte_movistar_optima)),c(1:5,42:59)]),
                           cbind(third_party_owners = "GIGARED",input_tab_2[which(input_tab_2$departamento%in%departamento_6()
                                                                                  & input_tab_2$provincia%in%provincia_6()
                                                                                  & input_tab_2$segmentacion%in%segmento_3()
                                                                                  & input_tab_2$cobertura_movistar%in%cobertura_movistar_3()
                                                                                  & input_tab_2$cobertura_competidores%in%cobertura_competidores_3()
                                                                                  & (input_tab_2$poblacion>=poblacion_5()[1] & input_tab_2$poblacion<=poblacion_5()[2])
                                                                                  & !is.na(input_tab_2$torre_transporte_gigared_optima)),c(1:5,42:59)]),
                           cbind(third_party_owners = "FIBER_POINTS",input_tab_2[which(input_tab_2$departamento%in%departamento_6()
                                                                                       & input_tab_2$provincia%in%provincia_6()
                                                                                       & input_tab_2$segmentacion%in%segmento_3()
                                                                                       & input_tab_2$cobertura_movistar%in%cobertura_movistar_3()
                                                                                       & input_tab_2$cobertura_competidores%in%cobertura_competidores_3()
                                                                                       & (input_tab_2$poblacion>=poblacion_5()[1] & input_tab_2$poblacion<=poblacion_5()[2])
                                                                                       & !is.na(input_tab_2$torre_transporte_points_optima)),c(1:5,42:59)]),
                           cbind(third_party_owners = "ARSAT",input_tab_2[which(input_tab_2$departamento%in%departamento_6()
                                                                                & input_tab_2$provincia%in%provincia_6()
                                                                                & input_tab_2$segmentacion%in%segmento_3()
                                                                                & input_tab_2$cobertura_movistar%in%cobertura_movistar_3()
                                                                                & input_tab_2$cobertura_competidores%in%cobertura_competidores_3()
                                                                                & (input_tab_2$poblacion>=poblacion_5()[1] & input_tab_2$poblacion<=poblacion_5()[2])
                                                                                & !is.na(input_tab_2$torre_transporte_arsat_optima)),c(1:5,42:59)]),
                           cbind(third_party_owners = "SILICA",input_tab_2[which(input_tab_2$departamento%in%departamento_6()
                                                                                 & input_tab_2$provincia%in%provincia_6()
                                                                                 & input_tab_2$segmentacion%in%segmento_3()
                                                                                 & input_tab_2$cobertura_movistar%in%cobertura_movistar_3()
                                                                                 & input_tab_2$cobertura_competidores%in%cobertura_competidores_3()
                                                                                 & (input_tab_2$poblacion>=poblacion_5()[1] & input_tab_2$poblacion<=poblacion_5()[2])
                                                                                 & !is.na(input_tab_2$torre_transporte_silica_optima)),c(1:5,42:59)]),
                           cbind(third_party_owners = "OTROS",input_tab_2[which(input_tab_2$departamento%in%departamento_6()
                                                                                & input_tab_2$provincia%in%provincia_6()
                                                                                & input_tab_2$segmentacion%in%segmento_3()
                                                                                & input_tab_2$cobertura_movistar%in%cobertura_movistar_3()
                                                                                & input_tab_2$cobertura_competidores%in%cobertura_competidores_3()
                                                                                & (input_tab_2$poblacion>=poblacion_5()[1] & input_tab_2$poblacion<=poblacion_5()[2])
                                                                                & !is.na(input_tab_2$torre_transporte_otros_optima)),c(1:5,42:59)]),make.row.names=F)},
           TASA = { cbind(third_party_owners = "TASA",input_tab_2[which(input_tab_2$departamento%in%departamento_6()
                                                                        & input_tab_2$provincia%in%provincia_6()
                                                                        & input_tab_2$segmentacion%in%segmento_3()
                                                                        & input_tab_2$cobertura_movistar%in%cobertura_movistar_3()
                                                                        & input_tab_2$cobertura_competidores%in%cobertura_competidores_3()
                                                                        & (input_tab_2$poblacion>=poblacion_5()[1] & input_tab_2$poblacion<=poblacion_5()[2])
                                                                        & !is.na(input_tab_2$torre_transporte_movistar_optima)),c(1:5,42:59)]) },
           ARSAT = { cbind(third_party_owners = "ARSAT",input_tab_2[which(input_tab_2$departamento%in%departamento_6()
                                                                          & input_tab_2$provincia%in%provincia_6()
                                                                          & input_tab_2$segmentacion%in%segmento_3()
                                                                          & input_tab_2$cobertura_movistar%in%cobertura_movistar_3()
                                                                          & input_tab_2$cobertura_competidores%in%cobertura_competidores_3()
                                                                          & (input_tab_2$poblacion>=poblacion_5()[1] & input_tab_2$poblacion<=poblacion_5()[2])
                                                                          & !is.na(input_tab_2$torre_transporte_arsat_optima)),c(1:5,42:59)]) },
           SILICA = { cbind(third_party_owners = "SILICA",input_tab_2[which(input_tab_2$departamento%in%departamento_6()
                                                                            & input_tab_2$provincia%in%provincia_6()
                                                                            & input_tab_2$segmentacion%in%segmento_3()
                                                                            & input_tab_2$cobertura_movistar%in%cobertura_movistar_3()
                                                                            & input_tab_2$cobertura_competidores%in%cobertura_competidores_3()
                                                                            & (input_tab_2$poblacion>=poblacion_5()[1] & input_tab_2$poblacion<=poblacion_5()[2])
                                                                            & !is.na(input_tab_2$torre_transporte_silica_optima)),c(1:5,42:59)]) },
           GIGARED = { cbind(third_party_owners = "GIGARED",input_tab_2[which(input_tab_2$departamento%in%departamento_6()
                                                                              & input_tab_2$provincia%in%provincia_6()
                                                                              & input_tab_2$segmentacion%in%segmento_3()
                                                                              & input_tab_2$cobertura_movistar%in%cobertura_movistar_3()
                                                                              & input_tab_2$cobertura_competidores%in%cobertura_competidores_3()
                                                                              & (input_tab_2$poblacion>=poblacion_5()[1] & input_tab_2$poblacion<=poblacion_5()[2])
                                                                              & !is.na(input_tab_2$torre_transporte_gigared_optima)),c(1:5,42:59)]) },
           FIBER_POINTS = { cbind(third_party_owners = "FIBER_POINTS",input_tab_2[which(input_tab_2$departamento%in%departamento_6()
                                                                                        & input_tab_2$provincia%in%provincia_6()
                                                                                        & input_tab_2$segmentacion%in%segmento_3()
                                                                                        & input_tab_2$cobertura_movistar%in%cobertura_movistar_3()
                                                                                        & input_tab_2$cobertura_competidores%in%cobertura_competidores_3()
                                                                                        & (input_tab_2$poblacion>=poblacion_5()[1] & input_tab_2$poblacion<=poblacion_5()[2])
                                                                                        & !is.na(input_tab_2$torre_transporte_points_optima)),c(1:5,42:59)]) },
           OTROS = { cbind(third_party_owners = "OTROS",input_tab_2[which(input_tab_2$departamento%in%departamento_6()
                                                                          & input_tab_2$provincia%in%provincia_6()
                                                                          & input_tab_2$segmentacion%in%segmento_3()
                                                                          & input_tab_2$cobertura_movistar%in%cobertura_movistar_3()
                                                                          & input_tab_2$cobertura_competidores%in%cobertura_competidores_3()
                                                                          & (input_tab_2$poblacion>=poblacion_5()[1] & input_tab_2$poblacion<=poblacion_5()[2])
                                                                          & !is.na(input_tab_2$torre_transporte_otros_optima)),c(1:5,42:59)]) })
  })
  
  
  # Calculate and render the number of settlements
  
  sum_settlements_6 <- reactive({ format(length(unique(outputdf_6()$id_localidad)),big.mark=".", decimal.mark=",") })
  
  output$sum_settlements_6 <- renderText(sum_settlements_6())
  
  # Calculate and render the population included
  
  sum_population_6 <- reactive ({ format(sum(distinct(outputdf_6(),id_localidad,.keep_all=T)$poblacion,na.rm=TRUE),big.mark=".", decimal.mark=",") })
  
  output$sum_population_6 <- renderText(sum_population_6())
  
  output$outputdf_6 <- DT::renderDataTable(outputdf_6(), extensions='Buttons', options = list( scrollX = TRUE, scrollY= "540px", paging= TRUE, searching= TRUE, pageLength = 25, dom = 'Bfrtip', buttons = I('colvis')),  selection = 'single', rownames=FALSE)
  
  
})
