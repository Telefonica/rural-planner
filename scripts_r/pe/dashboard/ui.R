
library(shiny)
library(leaflet)
library(stringr)
library(scales)
library(plotly)
library(shinydashboard)
library(DT)
library(RColorBrewer)

shinyUI(dashboardPage(
  
  title="Rural Planner", 
  #Title layout (Title text, IpT logo and TEF logo)
  
  dashboardHeader( 
    
    title= div("INTERNET PARA TODOS",style='font-family:"Trebuchet MS", Helvetica, sans-serif; font-weight: bold;'),
    titleWidth = 250,
    tags$li(class="dropdown", div(h4(strong("Rural Planner")), style="padding-top:5px; padding-right:20px; color:#00334d;")),
    tags$li(class="dropdown",div(img(height = 33, width = 48, src= "peru_logo_2.png", align="right"),style="padding-top:10px; padding-right:10px"))
  ),
  
  # Sidebar menu: 5 tabs: segmentacion, listado ccpp, priorizacion ccpp, listado clusters, priorizacion clusters and priorizacion transporte. When one of them is clicked on, the filters for the given tab appear.
  
  dashboardSidebar(
    width=250,
    sidebarMenu( id= 'sidebarmenu',
                 menuItem("Segmentación", tabName = "segmentation", icon = icon("bar-chart-o")),
                 # FILTERS: Region and province
                 conditionalPanel("input.sidebarmenu === 'segmentation'",
                                  
                                  selectizeInput("region",'Región',c("TODAS",unique(input_tab_2$region)), multiple= TRUE, 
                                                 selected='SAN MARTIN', options = list(maxOptions = 25, placeholder = 'Introduzca región'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'segmentation'",
                                  (uiOutput("provincia"))),
                 
                 menuItem("Priorización CCPP", tabName = "priorization", icon = icon("th")),
                 
                 # FILTERS: Region, province, Overlay segment, Greenfield segment, Movistar coverage, Competitors coverage and number of secondary schools
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  selectizeInput("region_2",'Region',c("TODAS",unique(input_tab_2$region)), multiple= TRUE, 
                                                 selected='SAN MARTIN', options = list(maxOptions = 25, placeholder = 'Introduzca region'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (uiOutput("provincia_2"))),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (checkboxGroupInput("segmento",'Segmento',unique(input_tab_2$segmentacion[!is.na(input_tab_2$segmentacion)]), selected= unique(input_tab_2$segmentacion[!is.na(input_tab_2$segmentacion)]) ))),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (uiOutput("cobertura_movistar"))),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (uiOutput("cobertura_competidores"))),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (sliderInput("poblacion",'Numero de habitantes CCPP',0,1000000,c(0,1000)))),
                 
                 menuItem("Listado CCPP", tabName = "listing", icon = icon("align-justify")),
                 
                 # FILTERS: Region, province, Overlay segment, Greenfield segment, Movistar coverage, Competitors coverage and number of secondary schools
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  selectizeInput("region_listing",'Region',c("TODAS",unique(input_tab_2$region)), multiple= TRUE, 
                                                 selected='TODAS', options = list(maxOptions = 25, placeholder = 'Introduzca region'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (uiOutput("provincia_listing"))),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (checkboxGroupInput("segmento_listing",'Segmento',unique(input_tab_2$segmentacion[!is.na(input_tab_2$segmentacion)]), selected= unique(input_tab_2$segmentacion[!is.na(input_tab_2$segmentacion)]) ))),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (uiOutput("cobertura_movistar_listing"))),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (uiOutput("cobertura_competidores_listing"))),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (sliderInput("poblacion_2",'Numero de habitantes CCPP',0,1000000,c(0,1000)))),
                 
                 menuItem("Priorización Clusters", tabName = "priorization_clusters", icon = icon("th-large")),
                 
                 # FILTERS: Region, province, Overlay segment, Greenfield segment, Movistar coverage, Competitors coverage and number of secondary schools
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  selectizeInput("region_3",'Region',c("TODAS",unique(input_tab_2$region)), multiple= TRUE, 
                                                 selected='SAN MARTIN', options = list(maxOptions = 25, placeholder = 'Introduzca region/regiones'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  (uiOutput("provincia_3"))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  (checkboxGroupInput("segmento_2",'Segmento',unique(input_tab_3$segmentacion[!is.na(input_tab_3$segmentacion)]), selected= unique(input_tab_3$segmentacion[!is.na(input_tab_3$segmentacion)]) ))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  (selectizeInput("tipo_cluster",'Tipo de cluster',unique(input_tab_3$tipo_cluster),multiple= TRUE,
                                                  options = list(maxOptions = 8, placeholder = 'Introduzca tipo/tipos')))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  (sliderInput("poblacion_3",'Numero de habitantes cluster',0,22000,c(0,1200)))),
                 
                 
                 menuItem("Listado Clusters", tabName = "listing_clusters", icon = icon("bars")),
                 
                 # FILTERS: Region, province, Overlay segment, Greenfield segment, Movistar coverage, Competitors coverage and number of secondary schools
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  selectizeInput("region_3_listing",'Region',c("TODAS",unique(input_tab_2$region)), multiple= TRUE, 
                                                 selected='TODAS', options = list(maxOptions = 25, placeholder = 'Introduzca region/regiones'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  (uiOutput("provincia_3_listing"))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  (checkboxGroupInput("segmento_2_listing",'Segmento',unique(input_tab_3$segmentacion[!is.na(input_tab_3$segmentacion)]), selected= unique(input_tab_3$segmentacion[!is.na(input_tab_3$segmentacion)])))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  (selectizeInput("tipo_cluster_listing",'Tipo de cluster',unique(input_tab_3$tipo_cluster),multiple= TRUE,
                                                  options = list(maxOptions = 8, placeholder = 'Introduzca tipo/tipos')))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  (sliderInput("poblacion_4",'Numero de habitantes cluster',0,22000,c(0,1200)))),
                 
                 menuItem("Priorización Transporte", tabName = "priorization_transport", icon = icon("align-left")),
                 
                 # FILTERS: 
                 
                 conditionalPanel("input.sidebarmenu === 'priorization_transport'",
                                  (checkboxGroupInput("medio_tx",'Medio de transporte',unique(input_tab_6$medio_transporte), selected= unique(input_tab_6$medio_transporte)))),
                 conditionalPanel("input.sidebarmenu === 'priorization_transport'",
                                  (selectizeInput("segmento_pf",'Segmento',c("TODOS",unique(input_tab_6$segmento)),multiple= TRUE,
                                                  options = list(maxOptions = 8, placeholder = 'Introduzca tipo/tipos')))),
                 conditionalPanel("input.sidebarmenu === 'priorization_transport'",
                                  (checkboxGroupInput("proveedor_fibra",'Proveedor de FO',unique(input_tab_6$proveedor_fibra), selected= unique(input_tab_6$proveedor_fibra)))),
                 conditionalPanel("input.sidebarmenu === 'priorization_transport'",
                                  (sliderInput("fiber_length",'Longitud fibra (km)',0,370,c(0,370)))),
                 conditionalPanel("input.sidebarmenu === 'priorization_transport'",
                                  (sliderInput("mw_hops",'Saltos intermedios',1,5,c(1,5)))),
                 conditionalPanel("input.sidebarmenu === 'priorization_transport'",
                                  (selectizeInput("fiber_node",'Nodo Fibra',c("TODOS",unique(input_tab_6$nodo_fibra)),multiple= TRUE,
                                                  options = list(maxOptions = 8, placeholder = 'Introduzca código único')))),
                 conditionalPanel("input.sidebarmenu === 'priorization_transport'",
                                  (selectizeInput("deployment_id",'ID Despliegue',c("TODOS",unique(input_tab_6$id_despliegue)),multiple= TRUE,
                                                  options = list(maxOptions = 8, placeholder = 'Introduzca identificador')))),
                 
                 menuItem("Visualización Transporte", tabName = "visualization_transport", icon = icon("columns")),
                 
                 # FILTERS: 
                 
                 conditionalPanel("input.sidebarmenu === 'visualization_transport'",
                                  (selectizeInput("deployment_id_2",'Despliegue',unique(input_tab_6$id_despliegue), multiple= TRUE,
                                                  options = list(maxOptions = 15, placeholder = 'Introduzca ID de despliegue')))),
                 conditionalPanel("input.sidebarmenu === 'visualization_transport'",
                                  (actionButton("show_3",'Mostrar transporte'))),
                 conditionalPanel("input.sidebarmenu === 'visualization_transport'",
                                  (actionButton("hide_3",'Limpiar mapa')))
    )
  ),
  
  
  dashboardBody(
    
    tabItems(
      
      # First tab content
      
      tabItem(
        tabName = "segmentation",
        
        # Tab Header
        
        fluidRow(
          column(3, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
          column(6, div(h2(strong("Segmentación Oportunidad Telefónica del Perú")),style="padding-top:15px; text-align: center; color:#00334d;")),
          column(3, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
        br(),
        
        # Tab body
        
        fluidRow(
          
          # Connected segment information
          
          box( title= "Conectados", status= "primary", solidHeader = TRUE,  width = 4, height= "640px",
               splitLayout(plotlyOutput("poblacion_conectados"), plotlyOutput("settlements_conectados")),
               br(),
               tableOutput("segmento_conectados"),
               tags$style(type="text/css", "#segmento_conectados tr:last-child {font-weight:bold;}")
          ),
          # Overlay segment information
          
          box( title= "Overlay 2G Telefónica", status= "primary", solidHeader = TRUE,  width = 4, height= "640px",
               splitLayout(plotlyOutput("poblacion_overlay"), plotlyOutput("settlements_overlay")),
               br(),
               tableOutput("segmento_overlay"),
               tags$style(type="text/css", "#segmento_overlay tr:last-child {font-weight:bold;}")
          ),
          # Greenfield segment information
          
          box( title= "Greenfield Telefónica", status= "primary", solidHeader = TRUE, width = 4, height= "640px",
               splitLayout(plotlyOutput("poblacion_greenfield"), plotlyOutput("settlements_greenfield")),
               br(),
               tableOutput("segmento_greenfield"),
               tags$style(type="text/css", "#segmento_greenfield tr:last-child {font-weight:bold;}")
          ))),
      
      
      tabItem(tabName = "priorization",
              
              # Tab Header
              fluidRow(
                column(3, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(6, div(h2(strong("Priorizacion Centros Poblados Telefonica del Perú")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(3, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              
              # Tab body
              
              fluidRow(
                
                column( 6, 
                        
                        # Text output:
                        fluidRow (box(title= "Número de centros poblados", status= "primary", solidHeader = TRUE, height= "110px", width= 6, h3(textOutput("sum_settlements"))) , 
                                  box(title= "Población incluida", status= "primary", solidHeader = TRUE,  height= "110px", width= 6, h3(textOutput("sum_population")))) ,
                        
                        # Dataframe output
                        box(
                          dataTableOutput("outputdf"), width = "100%", height= "700px"
                        ) ,
                        
                        fluidRow(downloadButton("downloadData", "Descargar CSV"), box(("Info: para priorizar la ordenacion de columnas del resultado de la busqueda, hacer Shift + click en las columnas por orden de prioridad."), width=10))),
                
                column( 6,
                        tabBox( side= "right", width = 12, height = "820px",
                                tabPanel("Mapa Coberturas", leafletOutput("output_map_coverage", height = "800px")),
                                tabPanel("Mapa Acceso y Transporte", leafletOutput("output_map_access_transport", height = "800px")),
                                tabPanel("Mapa Detalle CCPP", leafletOutput("output_map_segmentation", height = "800px"))),
                        fluidRow(br()),
                        fluidRow(br()),
                        fluidRow(br())
                        
                )
              )),
      
      tabItem(tabName = "listing",
              
              # Tab Header
              fluidRow(
                column(3, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(6, div(h2(strong("Listado Centros Poblados Telefonica del Perú")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(3, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              
              # Tab body
              
              fluidRow(
                # Text output:
                fluidRow(div (box(title= "Número de centros poblados", status= "primary", solidHeader = TRUE, height= "110px", width= 5, h3(textOutput("sum_settlements_listing"))) , 
                              box(title= "Población incluida", status= "primary", solidHeader = TRUE,  height= "110px", width= 5, h3(textOutput("sum_population_listing"))),style="padding-left:150px;padding-right:150px;")) ,
                
                
                fluidRow(div(downloadButton("downloadData_listing", "Descargar CSV"), box(("Info: para priorizar la ordenacion de columnas del resultado de la busqueda, hacer Shift + click en las columnas por orden de prioridad."),
                                                                                          width=10)), style="padding-left:40px;padding-right:40px;"),
                
                # Dataframe output
                div(box(
                  dataTableOutput("outputdf_listing"), width = "80%", height= "700px"
                ),  style="padding-left:40px;padding-right:40px;" )
                
                
              )),
      
      
      #5th tab content
      tabItem(tabName = "priorization_clusters",
              
              
              # Tab Header
              fluidRow(
                column(2, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(8, div(h2(strong("Priorización Clusters Telefónica del Perú")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(2, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              # Tab body
              
              fluidRow(
                
                column( 6, 
                        
                        # Text output:
                        fluidRow (box(title= "Número de clusters", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_clusters"))) , 
                                  box(title= "Número de centros poblados", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_settlements_2"))) , 
                                  box(title= "Población incluida", status= "primary", solidHeader = TRUE,  height= "110px", width= 4, h3(textOutput("sum_population_2")))) ,
                        
                        # Dataframe output
                        box(
                          dataTableOutput("outputdf_2"), width = "100%", height= "700px"
                        ) ,
                        
                        fluidRow(downloadButton("downloadData_2", "Descargar CSV"), box(("Info: para priorizar la ordenación de columnas del resultado de la búsqueda, hacer Shift + click en las columnas por orden de prioridad."), width=10))),
                
                column( 6,
                        tabBox( side= "right", width = 12, height = "820px",
                                tabPanel("Mapa Acceso y Transporte", leafletOutput("output_map_access_transport_2", height = "800px")),
                                tabPanel("Mapa Detalle Clusters", leafletOutput("output_map_segmentation_2", height = "800px"))),
                        fluidRow(br()),
                        fluidRow(br()),
                        fluidRow(br())
                        
                )
              )
      ),
      
      #6th tab content
      tabItem(tabName = "listing_clusters",
              
              
              # Tab Header
              fluidRow(
                column(2, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(8, div(h2(strong("Listado Clusters Telefónica del Perú")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(2, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              # Tab body
              
              fluidRow(
                # Text output:
                fluidRow (div(box(title= "Número de clusters", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_clusters_listing"))) , 
                              box(title= "Número de centros poblados", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_settlements_2_listing"))) , 
                              box(title= "Población incluida", status= "primary", solidHeader = TRUE,  height= "110px", width= 4, h3(textOutput("sum_population_2_listing")))),style="padding-left:40px;padding-right:40px;") ,
                
                fluidRow(div(downloadButton("downloadData_2_listing", "Descargar CSV"), box(("Info: para priorizar la ordenación de columnas del resultado de la búsqueda, hacer Shift + click en las columnas por orden de prioridad."),
                                                                                            width=10)),style="padding-left:40px;"),
                
                # Dataframe output
                div(box(
                  dataTableOutput("outputdf_2_listing"), width = "80%", height= "700px"
                ) ,style="padding-left:40px;padding-right:40px;")        
                
              )
      ),
      # 11th tab item
      
      tabItem(tabName = "priorization_transport",
              
              
              # Tab Header
              fluidRow(
                column(2, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(8, div(h2(strong("Priorización Transporte Telefónica del Perú")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(2, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              # Tab body
              
              fluidRow(
                fluidRow(div(downloadButton("downloadData_5_listing", "Descargar CSV"), box(("Info: para priorizar la ordenación de columnas del resultado de la búsqueda, hacer Shift + click en las columnas por orden de prioridad."),
                                                                                            width=10)),style="padding-left:40px;"),
                
                div(box(
                  dataTableOutput("outputdf_5_listing"), width = "80%", height= "700px"
                ) ,style="padding-left:40px;padding-right:40px;") 
              )
      ),
      #6th tab content
      
      tabItem(tabName = "visualization_transport",
              
              # Tab Header
              fluidRow(
                column(2, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(8, div(h2(strong("Visualización Transporte Telefónica del Perú")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(2, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              # Tab body
              
              # Text output:
              fluidRow (div(box(title= "Número de sites conectados", status= "primary", solidHeader = TRUE, height= "110px", width= 6, h3(textOutput("sum_clusters_deployment"))) ,
                            box(title= "Población no conectada cubierta", status= "primary", solidHeader = TRUE,  height= "110px", width= 6, h3(textOutput("sum_population_deployment")))),style="padding-left:40px;padding-right:40px;") ,
              
              # Dataframe output
              box( leafletOutput("output_map_transport", height = "700px"),  width = "80%", style="padding-left:40px;padding-right:40px;") 
              
      )
    )))
)