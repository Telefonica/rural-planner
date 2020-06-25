
library(shiny)
library(leaflet)
library(stringr)
library(scales)
library(plotly)
library(shinydashboard)
library(DT)
library(RColorBrewer)

shinyUI( dashboardPage(
  
  #Title layout (Title text, IpT logo and TEF logo)
  title="Rural Planner", 
  
  dashboardHeader( 
    
    title= div("INTERNET PARA TODOS",style='font-family:"Trebuchet MS", Helvetica, sans-serif; font-weight: bold;'),
    titleWidth = 250,
    tags$li(class="dropdown", div(h4(strong("Rural Planner")), style="padding-top:5px; padding-right:20px; color:#00334d;")),
    tags$li(class="dropdown",div(img(height = 33, width = 48, src= "colombia_logo.png", align="right"),style="padding-top:10px; padding-right:10px"))
  ),
  
  # Sidebar menu: 5 tabs: segmentacion, listado ccpp, priorizacion ccpp, listado clusters, priorizacion clusters and priorizacion transporte. When one of them is clicked on, the filters for the given tab appear.
  
  dashboardSidebar(
    width=250,
    sidebarMenu( id= 'sidebarmenu',
                 menuItem("Segmentación", tabName = "segmentation", icon = icon("bar-chart-o")),
                 # FILTERS: departamento and municipio
                 conditionalPanel("input.sidebarmenu === 'segmentation'",
                                  
                                  selectizeInput("departamento",'Departamento',c("TODOS",unique(input_tab_2$departamento)), multiple= TRUE, 
                                                 selected='TODOS', options = list(maxOptions = 25, placeholder = 'Introduzca departamento'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'segmentation'",
                                  (uiOutput("municipio"))),
                 
                 menuItem("Priorización CCPP", tabName = "priorization", icon = icon("th")),
                 
                 # FILTERS: departamento, province, Overlay segment, Greenfield segment, Movistar coverage, Competitors coverage and number of secondary schools
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  selectizeInput("departamento_2",'Departamento',c("TODOS",unique(input_tab_2$departamento)), multiple= TRUE, 
                                                 selected='CUNDINAMARCA', options = list(maxOptions = 25, placeholder = 'Introduzca departamento'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (uiOutput("municipio_2"))),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (checkboxGroupInput("segmento",'Segmento',unique(input_tab_2$segmentacion[!is.na(input_tab_2$segmentacion)]), selected= unique(input_tab_2$segmentacion[!is.na(input_tab_2$segmentacion)]) ))),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (uiOutput("cobertura_movistar"))),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (uiOutput("cobertura_competidores"))),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (sliderInput("poblacion",'Numero de habitantes CCPP',0,10000000,c(0,1000)))),
                 
                 menuItem("Listado CCPP", tabName = "listing", icon = icon("align-justify")),
                 
                 # FILTERS: departamento, province, Overlay segment, Greenfield segment, Movistar coverage, Competitors coverage and number of secondary schools
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  selectizeInput("departamento_listing",'Departamento',c("TODOS",unique(input_tab_2$departamento)), multiple= TRUE, 
                                                 selected='CUNDINAMARCA', options = list(maxOptions = 25, placeholder = 'Introduzca departamento'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (uiOutput("municipio_listing"))),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (checkboxGroupInput("segmento_listing",'Segmento',unique(input_tab_2$segmentacion[!is.na(input_tab_2$segmentacion)]), selected= unique(input_tab_2$segmentacion[!is.na(input_tab_2$segmentacion)]) ))),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (uiOutput("cobertura_movistar_listing"))),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (uiOutput("cobertura_competidores_listing"))),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (sliderInput("poblacion_2",'Numero de habitantes CCPP',0,10000000,c(0,1000)))),
                 
                 menuItem("Priorización Clusters", tabName = "priorization_clusters", icon = icon("th-large")),
                 
                 # FILTERS: departamento, province, Overlay segment, Greenfield segment, Movistar coverage, Competitors coverage and number of secondary schools
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  selectizeInput("departamento_3",'Departamento',c("TODOS","-",unique(input_tab_2$departamento)), multiple= TRUE, 
                                                 selected='CUNDINAMARCA', options = list(maxOptions = 25, placeholder = 'Introduzca departamento/departamentos'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  (uiOutput("municipio_3"))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  (checkboxGroupInput("segmento_2",'Segmento',unique(input_tab_3$segmentacion[!is.na(input_tab_3$segmentacion)]), selected= unique(input_tab_3$segmentacion[!is.na(input_tab_3$segmentacion)]) ))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  (selectizeInput("tipo_cluster",'Tipo de cluster',unique(input_tab_3$tipo_cluster),multiple= TRUE,
                                                  options = list(maxOptions = 8, placeholder = 'Introduzca tipo/tipos')))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  (sliderInput("poblacion_3",'Numero de habitantes cluster',0,8200000,c(0,2000)))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  (sliderInput("weight",'Poblacion no conectada Mov. cluster',0,25000,c(0,25000)))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  (checkboxInput("weight_p",'Poblacion no conectada Mov. cluster > 0'))),
                 
                 
                 menuItem("Listado Clusters", tabName = "listing_clusters", icon = icon("bars")),
                 
                 # FILTERS: departamento, province, Overlay segment, Greenfield segment, Movistar coverage, Competitors coverage and number of secondary schools
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  selectizeInput("departamento_3_listing",'Departamento',c("TODOS","-",unique(input_tab_2$departamento)), multiple= TRUE, 
                                                 selected='CUNDINAMARCA', options = list(maxOptions = 25, placeholder = 'Introduzca departamento/departamentos'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  (uiOutput("municipio_3_listing"))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  (checkboxGroupInput("segmento_2_listing",'Segmento',unique(input_tab_3$segmentacion[!is.na(input_tab_3$segmentacion)]), selected= unique(input_tab_3$segmentacion[!is.na(input_tab_3$segmentacion)])))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  (selectizeInput("tipo_cluster_listing",'Tipo de cluster',unique(input_tab_3$tipo_cluster),multiple= TRUE,
                                                  options = list(maxOptions = 8, placeholder = 'Introduzca tipo/tipos')))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  (sliderInput("poblacion_4",'Numero de habitantes cluster',0,8200000,c(0,2000)))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  (sliderInput("weight_2",'Poblacion no conectada Mov. cluster',0,25000,c(0,25000)))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  (checkboxInput("weight_2_p",'Poblacion no conectada Mov. cluster > 0'))),
                 
                 menuItem("Localización por coordenadas", tabName = "geolocation", icon = icon("compass")),
                 # FILTERS: file, latitude, longitude, selection of outputs (n closest clusters, n closest towers, n closest settlements)
                 conditionalPanel("input.sidebarmenu === 'geolocation'",
                                  
                                  fileInput("file1", "Suba archivo CSV de lat/long.", accept = c( "text/csv", "text/comma-separated-values,text/plain", ".csv") )
                 ),
                 conditionalPanel("input.sidebarmenu === 'geolocation'",
                                  (sliderInput("n_clusters", 'Número clusters', 0,20, 3))),
                 conditionalPanel("input.sidebarmenu === 'geolocation'",
                                  (sliderInput("n_towers", 'Número torres', 0,20,3 ))),
                 conditionalPanel("input.sidebarmenu === 'geolocation'",
                                  (sliderInput("n_settlements", 'Número centros poblados', 0,20, 3))),
                 
                 menuItem("Listado Infraestructura", tabName = "listing_towers", icon = icon("bars")),
                 
                 # FILTERS: departamento, province, Overlay segment, Greenfield segment, Movistar coverage, Competitors coverage and number of secondary schools
                 conditionalPanel("input.sidebarmenu === 'listing_towers'",
                                  selectizeInput("source_listing",'Propietario',c("TODOS",unique(input_tab_4$source)), multiple= TRUE, 
                                                 selected='SITES_TEF', options = list(maxOptions = 10, placeholder = 'Introduzca propietario/propietarios'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'listing_towers'",
                                  (selectizeInput("tipo_torre_listing",'Tipo de torre',unique(input_tab_4$tower_type),multiple= TRUE,
                                                  options = list(maxOptions = 4, placeholder = 'Introduzca tipo/tipos'))))
     ) ),
  
  
  dashboardBody(
    
    tabItems(
      
      # First tab content
      
      tabItem(
        tabName = "segmentation",
        
        # Tab Header
        
        fluidRow(
          column(3, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
          column(6, div(h2(strong("Segmentación Oportunidad Telefónica Colombia")),style="padding-top:15px; text-align: center; color:#00334d;")),
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
                column(6, div(h2(strong("Priorización Centros Poblados Telefónica Colombia")),style="padding-top:15px; text-align: center; color:#00334d;")),
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
                        
                        fluidRow(downloadButton("downloadData", "Descargar CSV"), 
                                 box(("Info: para priorizar la ordenacion de columnas del resultado de la busqueda, hacer Shift + click en las columnas por orden de prioridad."), width=10))),
                
                column( 6,
                        tabBox( side= "right", width = 12, height = "820px",
                                tabPanel("Mapa Coberturas", leafletOutput("output_map_coverage", height = "800px")),
                                tabPanel("Mapa Acceso y Transporte", leafletOutput("output_map_access_transport", height = "800px")),
                                tabPanel("Mapa Detalle CCPP", leafletOutput("output_map_segmentation", height = "800px")))
                        
                )
              )),
      
      tabItem(tabName = "listing",
              
              # Tab Header
              fluidRow(
                column(3, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(6, div(h2(strong("Listado Centros Poblados Telefónica Colombia")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(3, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              
              # Tab body
              
              fluidRow(
                # Text output:
                fluidRow(div (box(title= "Número de centros poblados", status= "primary", solidHeader = TRUE, height= "110px", width= 5, h3(textOutput("sum_settlements_listing"))) , 
                              box(title= "Población incluida", status= "primary", solidHeader = TRUE,  height= "110px", width= 5, h3(textOutput("sum_population_listing"))),style="padding-left:150px;padding-right:150px;")) ,
                
                
                fluidRow(div(downloadButton("downloadData_listing", "Descargar CSV"), 
                             box(("Info: para priorizar la ordenacion de columnas del resultado de la busqueda, hacer Shift + click en las columnas por orden de prioridad."),
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
                column(8, div(h2(strong("Priorización Clusters Telefónica Colombia")),style="padding-top:15px; text-align: center; color:#00334d;")),
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
                        
                        fluidRow(downloadButton("downloadData_2", "Descargar CSV"), 
                                 box(("Info: para priorizar la ordenación de columnas del resultado de la búsqueda, hacer Shift + click en las columnas por orden de prioridad."), width=10))),
                
                column( 6,
                        tabBox( side= "right", width = 12, height = "820px",
                                tabPanel("Mapa Detalle Clusters", leafletOutput("output_map_segmentation_2", height = "800px")),
                                tabPanel("Mapa Acceso y Transporte", leafletOutput("output_map_access_transport_2", height = "800px")))
                        
                )
              ))
      ,
      
      #6th tab content
      tabItem(tabName = "listing_clusters",
              
              
              # Tab Header
              fluidRow(
                column(2, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(8, div(h2(strong("Listado Clusters Telefónica Colombia")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(2, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              # Tab body
              
              fluidRow(
                # Text output:
                fluidRow (div(box(title= "Número de clusters", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_clusters_listing"))) ,
                              box(title= "Número de centros poblados", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_settlements_2_listing"))) ,
                              box(title= "Población incluida", status= "primary", solidHeader = TRUE,  height= "110px", width= 4, h3(textOutput("sum_population_2_listing")))),style="padding-left:40px;padding-right:40px;") ,
                
                fluidRow(div(downloadButton("downloadData_2_listing", "Descargar CSV"), 
                             box(("Info: para priorizar la ordenación de columnas del resultado de la búsqueda, hacer Shift + click en las columnas por orden de prioridad."),
                                 width=10)),style="padding-left:40px;"),
                
                # Dataframe output
                div(box(
                  dataTableOutput("outputdf_2_listing"), width = "80%", height= "700px"
                ) ,style="padding-left:40px;padding-right:40px;")
                
              ))
      ,
      # 7th tab content
      
      tabItem(tabName = "geolocation",
              
              # Tab Header
              fluidRow(
                column(3, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(6, div(h2(strong("Localización por coordenadas")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(3, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              br(),
              br(),
              
              # Tab body
              column( 12, align="center",  fluidRow(downloadButton("downloadData_3", "Descargar CSV centros poblados"),
                                                    downloadButton("downloadData_4", "Descargar CSV clusters"),
                                                    downloadButton("downloadData_5", "Descargar CSV torres")),
                      br(),
                      box("Info: Para consulta masiva de coordenadas, subir archivo .csv con una columna para las longitudes, con el nombre 'longitude'; y otra para las latitudes, con el nombre 'latitude',
                     separador ';' y separador decimal ','. No introducir archivos mayores de 100 muestras cada vez ya que el tiempo de computación es demasiado largo y se desconecta del servidor.", width=20),
                      leafletOutput("output_map_coordinates", height = "500px")
              )
      ),
      # # 8th tab content
      # 
      tabItem(tabName = "listing_towers",
              
              # Tab Header
              fluidRow(
                column(2, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(8, div(h2(strong("Listado Infraestructura Telefónica Colombia")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(2, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              # Tab body
              
              fluidRow(
                # Text output:
                fluidRow(div(box(title= "Número de torres", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_towers_listing"))), style="padding-top:35px; padding-left:40px")),
                
                fluidRow(div(downloadButton("downloadData_6_listing", "Descargar CSV"), 
                             box(("Info: para priorizar la ordenación de columnas del resultado de la búsqueda, hacer Shift + click en las columnas por orden de prioridad."),
                                 width=10)),style="padding-left:40px;"),
                
                # Dataframe output
                div(box(
                  dataTableOutput("outputdf_6_listing"), width = "80%", height= "700px"
                ) ,style="padding-left:40px;padding-right:40px;")
                
              )
      )
    )))
)