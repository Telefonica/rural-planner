
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
    tags$li(class="dropdown",div(img(height = 33, width = 48, src= "arg_logo.png", align="right"),style="padding-top:10px; padding-right:10px"))
  ),
  
  # Sidebar menu: 5 tabs: segmentacion, listado ccpp, priorizacion ccpp, listado clusters, priorizacion clusters and priorizacion transporte. When one of them is clicked on, the filters for the given tab appear.
  
  dashboardSidebar(
    width=250,
    sidebarMenu( id= 'sidebarmenu',
                 menuItem("Segmentación", tabName = "segmentation", icon = icon("bar-chart-o")),
                 # FILTERS: Province and department
                 conditionalPanel("input.sidebarmenu === 'segmentation'",
                                  
                                  selectizeInput("provincia",'Provincia',c("TODAS",unique(input_tab_2$provincia)), multiple= TRUE, 
                                                 selected='CHACO', options = list(maxOptions = 25, placeholder = 'Introduzca provincia'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'segmentation'",
                                  (uiOutput("departamento"))),
                 
                 menuItem("Priorización Localidades", tabName = "priorization", icon = icon("th")),
                 
                 # FILTERS:  Province and department, Overlay segment, Greenfield segment, Movistar coverage, Competitors coverage and number of secondary schools
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  selectizeInput("provincia_2",'Provincia',c("TODAS",unique(input_tab_2$provincia)), multiple= TRUE,
                                                 selected='CHACO', options = list(maxOptions = 25, placeholder = 'Introduzca provincia'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (uiOutput("departamento_2"))),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (checkboxGroupInput("segmento",'Segmento',unique(input_tab_2$segmentacion[!is.na(input_tab_2$segmentacion)]), selected= unique(input_tab_2$segmentacion[!is.na(input_tab_2$segmentacion)]) ))),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (checkboxGroupInput("etapa",'Etapa Enacom',unique(input_tab_2$etapa_enacom), selected= unique(input_tab_2$etapa_enacom) ))),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (checkboxGroupInput("plan_2019",'Plan 2019',unique(input_tab_2$plan_2019[!is.na(input_tab_2$plan_2019)]), selected= unique(input_tab_2$plan_2019[!is.na(input_tab_2$plan_2019)]) ))),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (uiOutput("cobertura_movistar"))),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (uiOutput("cobertura_competidores"))),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  (sliderInput("poblacion",'Numero de habitantes localidad',0,3000000,c(0,1000)))),
                 conditionalPanel("input.sidebarmenu === 'priorization'",
                                  selectInput("transport",'Owner transporte',c("N/A","TODOS","ARSAT","GIGARED","FIBER_POINTS","SILICA","TASA", "OTROS"), multiple= FALSE,
                                              selected='N/A')),
                 
                 
                 menuItem("Listado Localidades", tabName = "listing", icon = icon("align-justify")),
                 
                 # FILTERS: Region, province, Overlay segment, Greenfield segment, Movistar coverage, Competitors coverage and number of secondary schools
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  selectizeInput("provincia_listing",'Provincia',c("TODAS",unique(input_tab_2$provincia)), multiple= TRUE,
                                                 selected='TODAS', options = list(maxOptions = 25, placeholder = 'Introduzca provincia'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (uiOutput("departamento_listing"))),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (checkboxGroupInput("segmento_listing",'Segmento',unique(input_tab_2$segmentacion[!is.na(input_tab_2$segmentacion)]), selected= unique(input_tab_2$segmentacion[!is.na(input_tab_2$segmentacion)]) ))),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (checkboxGroupInput("etapa_listing",'Etapa Enacom',unique(input_tab_2$etapa_enacom), selected= unique(input_tab_2$etapa_enacom) ))),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (checkboxGroupInput("plan_2019_listing",'Plan 2019',unique(input_tab_2$plan_2019[!is.na(input_tab_2$plan_2019)]), selected= unique(input_tab_2$plan_2019[!is.na(input_tab_2$plan_2019)]) ))),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (uiOutput("cobertura_movistar_listing"))),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (uiOutput("cobertura_competidores_listing"))),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  (sliderInput("poblacion_2",'Numero de habitantes localidad',0,3000000,c(0,1000)))),
                 conditionalPanel("input.sidebarmenu === 'listing'",
                                  selectInput("transport_2",'Owner transporte',c("N/A","TODOS","ARSAT","GIGARED","FIBER_POINTS","SILICA","TASA", "OTROS"), multiple= FALSE,
                                              selected='N/A')),
                 
                 menuItem("Priorización Clusters", tabName = "priorization_clusters", icon = icon("th")),
                 
                 # FILTERS:  Province and department, Overlay segment, Greenfield segment, Movistar coverage, Competitors coverage and number of secondary schools
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  selectizeInput("provincia_3",'Provincia',c("TODAS",unique(input_tab_2$provincia)), multiple= TRUE,
                                                 selected='CHACO', options = list(maxOptions = 25, placeholder = 'Introduzca provincia'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  (uiOutput("departamento_3"))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  (checkboxGroupInput("segmento_2",'Segmento',unique(input_tab_3$segmentacion[!is.na(input_tab_3$segmentacion)]), selected= unique(input_tab_3$segmentacion[!is.na(input_tab_3$segmentacion)]) ))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  (selectizeInput("tipo_cluster",'Tipo de cluster',unique(input_tab_3$tipo_cluster),multiple= TRUE,
                                                  options = list(maxOptions = 8, placeholder = 'Introduzca tipo/tipos')))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  (sliderInput("poblacion_3",'Numero de habitantes no conectados cluster',0,20000,c(0,1000)))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters'",
                                  selectInput("transport_3",'Owner transporte optimo',c("N/A","TODOS","ARSAT","GIGARED","FIBER_POINTS","SILICA","TASA", "OTROS"), multiple= FALSE,
                                              selected='N/A')),
                 
                 menuItem("Listado Clusters", tabName = "listing_clusters", icon = icon("align-justify")),
                 
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  selectizeInput("provincia_2_listing",'Provincia',c("TODAS",unique(input_tab_2$provincia)), multiple= TRUE,
                                                 selected='CHACO', options = list(maxOptions = 25, placeholder = 'Introduzca provincia'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  (uiOutput("departamento_2_listing"))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  (checkboxGroupInput("segmento_2_listing",'Segmento',unique(input_tab_3$segmentacion[!is.na(input_tab_3$segmentacion)]), selected= unique(input_tab_3$segmentacion[!is.na(input_tab_3$segmentacion)]) ))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  (selectizeInput("tipo_cluster_listing",'Tipo de cluster',unique(input_tab_3$tipo_cluster),multiple= TRUE,
                                                  options = list(maxOptions = 8, placeholder = 'Introduzca tipo/tipos')))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  (sliderInput("poblacion_4",'Numero de habitantes no conectados cluster',0,20000,c(0,1000)))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters'",
                                  selectInput("transport_4",'Owner transporte optimo',c("N/A","TODOS","ARSAT","GIGARED","FIBER_POINTS","SILICA","TASA"), multiple= FALSE,
                                              selected='N/A')),
                 
                 menuItem("Priorización Clusters IpT", tabName = "priorization_clusters_ipt", icon = icon("th")),
                 
                 # FILTERS:  Province and department, Overlay segment, Greenfield segment, Movistar coverage, Competitors coverage and number of secondary schools
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters_ipt'",
                                  selectizeInput("provincia_7",'Provincia',c("TODAS",unique(input_tab_2$provincia)), multiple= TRUE,
                                                 selected='CHACO', options = list(maxOptions = 25, placeholder = 'Introduzca provincia'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters_ipt'",
                                  (uiOutput("departamento_7"))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters_ipt'",
                                  (checkboxGroupInput("segmento_7",'Segmento',unique(input_tab_4$segmentacion[!is.na(input_tab_4$segmentacion)]), selected= unique(input_tab_4$segmentacion[!is.na(input_tab_4$segmentacion)]) ))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters_ipt'",
                                  (selectizeInput("tipo_cluster_7",'Tipo de cluster',unique(input_tab_4$tipo_cluster),multiple= TRUE,
                                                  options = list(maxOptions = 8, placeholder = 'Introduzca tipo/tipos')))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters_ipt'",
                                  (sliderInput("poblacion_7",'Numero de habitantes no conectados cluster',0,22000,c(0,1000)))),
                 conditionalPanel("input.sidebarmenu === 'priorization_clusters_ipt'",
                                  selectInput("transport_7",'Owner transporte optimo',c("N/A","TODOS","ARSAT","GIGARED","FIBER_POINTS","SILICA","TASA", "OTROS"), multiple= FALSE,
                                              selected='N/A')),
                 
                 menuItem("Listado Clusters IpT", tabName = "listing_clusters_ipt", icon = icon("align-justify")),
                 
                 conditionalPanel("input.sidebarmenu === 'listing_clusters_ipt'",
                                  selectizeInput("provincia_8_listing",'Provincia',c("TODAS",unique(input_tab_2$provincia)), multiple= TRUE,
                                                 selected='CHACO', options = list(maxOptions = 25, placeholder = 'Introduzca provincia'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters_ipt'",
                                  (uiOutput("departamento_8_listing"))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters_ipt'",
                                  (checkboxGroupInput("segmento_8_listing",'Segmento',unique(input_tab_4$segmentacion[!is.na(input_tab_4$segmentacion)]), selected= unique(input_tab_4$segmentacion[!is.na(input_tab_4$segmentacion)]) ))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters_ipt'",
                                  (selectizeInput("tipo_cluster_8_listing",'Tipo de cluster',unique(input_tab_4$tipo_cluster),multiple= TRUE,
                                                  options = list(maxOptions = 8, placeholder = 'Introduzca tipo/tipos')))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters_ipt'",
                                  (sliderInput("poblacion_8",'Numero de habitantes no conectados cluster',0,22000,c(0,1000)))),
                 conditionalPanel("input.sidebarmenu === 'listing_clusters_ipt'",
                                  selectInput("transport_8",'Owner transporte optimo',c("N/A","TODOS","ARSAT","GIGARED","FIBER_POINTS","SILICA","TASA", "OTROS"), multiple= FALSE,
                                              selected='N/A')),
                 
                 menuItem("Priorización Partners", tabName = "priorization_partners", icon = icon("th")),
                 
                 # FILTERS:  Province and department, Overlay segment, Greenfield segment, Movistar coverage, Competitors coverage and number of secondary schools
                 conditionalPanel("input.sidebarmenu === 'priorization_partners'",
                                  selectInput("nivel_partners",'Nivel de agregación',c("Nacional","Provincial","Departamental"),
                                              selected='Nacional')
                 ),
                 conditionalPanel("input.sidebarmenu === 'priorization_partners' && input.nivel_partners === 'Provincial'",
                                  selectizeInput("provincia_4",'Provincia',c("TODAS",unique(input_tab_2$provincia)), multiple= TRUE,
                                                 selected='CHACO', options = list(maxOptions = 25, placeholder = 'Introduzca provincia'))
                 ), 
                 conditionalPanel("input.sidebarmenu === 'priorization_partners' && input.nivel_partners === 'Departamental'",
                                  selectizeInput("departamento_4",'Departamento',unique(input_tab_2$departamento), multiple= TRUE, selected='TODOS', options = list(maxOptions = 30, placeholder = 'Introduzca departamento'))
                 ), 
                 conditionalPanel("input.sidebarmenu === 'priorization_partners'",
                                  (selectizeInput("partner",'Partner',c("TODOS",unique(input_tab_3$tipo_torre_transporte[!is.na(input_tab_3$tipo_torre_transporte)])),multiple= TRUE,selected="TODOS",
                                                  options = list(maxOptions = 8, placeholder = 'Introduzca partner/partners')))
                 ),
                 
                 menuItem("Visualización Partners", tabName = "visualization_partners", icon = icon("align-justify")),
                 
                 conditionalPanel("input.sidebarmenu === 'visualization_partners'",
                                  (selectizeInput("partner_2",'Partner',c("TODOS",unique(input_tab_3$tipo_torre_transporte[!is.na(input_tab_3$tipo_torre_transporte)])),multiple= TRUE, selected="GIGARED",
                                                  options = list(maxOptions = 8, placeholder = 'Introduzca partner/partners')))
                 ),
                 
                 menuItem("Listado Partners", tabName = "listing_partners", icon = icon("align-justify")),
                 
                 conditionalPanel("input.sidebarmenu === 'listing_partners'",
                                  selectizeInput("provincia_6",'Provincia',c("TODAS",unique(input_tab_2$provincia)), multiple= TRUE,
                                                 selected='TODAS', options = list(maxOptions = 25, placeholder = 'Introduzca provincia'))
                 ),
                 conditionalPanel("input.sidebarmenu === 'listing_partners'",
                                  (uiOutput("departamento_6"))),
                 conditionalPanel("input.sidebarmenu === 'listing_partners'",
                                  (checkboxGroupInput("segmento_3",'Segmento',unique(input_tab_2$segmentacion[!is.na(input_tab_2$segmentacion)]), selected= unique(input_tab_2$segmentacion[!is.na(input_tab_2$segmentacion)]) ))),
                 conditionalPanel("input.sidebarmenu === 'listing_partners'",
                                  (uiOutput("cobertura_movistar_3"))),
                 conditionalPanel("input.sidebarmenu === 'listing_partners'",
                                  (uiOutput("cobertura_competidores_3"))),
                 conditionalPanel("input.sidebarmenu === 'listing_partners'",
                                  (sliderInput("poblacion_5",'Numero de habitantes localidad',0,3000000,c(0,3000000)))),
                 conditionalPanel("input.sidebarmenu === 'listing_partners'",
                                  selectInput("transport_5",'Owner transporte',c("TODOS","ARSAT","GIGARED","FIBER_POINTS","SILICA","TASA","OTROS"), multiple= FALSE,
                                              selected='TODOS'))
                 
    )),
  
  
  dashboardBody(
    
    tabItems(
      
      # First tab content
      
      tabItem(
        tabName = "segmentation",
        
        # Tab Header
        
        fluidRow(
          column(3, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
          column(6, div(h2(strong("Segmentación Oportunidad Telefónica Argentina")),style="padding-top:15px; text-align: center; color:#00334d;")),
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
                column(6, div(h2(strong("Priorizacion Localidades Telefonica Argentina")),style="padding-top:15px; text-align: center; color:#00334d;")),
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
                                tabPanel("Mapa Detalle CCPP", leafletOutput("output_map_segmentation", height = "800px")))
                        
                )
              )),
      
      tabItem(tabName = "listing",
              
              # Tab Header
              fluidRow(
                column(3, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(6, div(h2(strong("Listado Localidades Telefonica Argentina")),style="padding-top:15px; text-align: center; color:#00334d;")),
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
                ),  style="padding-left:40px;padding-right:40px;" ))),
      
      
      tabItem(tabName = "priorization_clusters",
              
              # Tab Header
              fluidRow(
                column(3, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(6, div(h2(strong("Priorizacion Clusters Telefonica Argentina")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(3, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              
              # Tab body
              
              fluidRow(
                
                column( 6,
                        
                        # Text output:
                        fluidRow (box(title= "Número de clusters", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_clusters"))),
                                  box(title= "Número de centros poblados", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_settlements_2"))) ,
                                  box(title= "Población incluida", status= "primary", solidHeader = TRUE,  height= "110px", width= 4, h3(textOutput("sum_population_2")))) ,
                        
                        # Dataframe output
                        box(
                          dataTableOutput("outputdf_2"), width = "100%", height= "700px"
                        ) ,
                        
                        fluidRow(downloadButton("downloadData_2", "Descargar CSV"), box(("Info: para priorizar la ordenacion de columnas del resultado de la busqueda, hacer Shift + click en las columnas por orden de prioridad."), width=10))),
                
                column( 6,
                        tabBox( side= "right", width = 12, height = "820px",
                                tabPanel("Mapa Acceso y Transporte", leafletOutput("output_map_access_transport_2", height = "800px")),
                                tabPanel("Mapa Detalle CCPP", leafletOutput("output_map_segmentation_2", height = "800px")))
                        
                )
              )),
      
      tabItem(tabName = "listing_clusters",
              
              # Tab Header
              fluidRow(
                column(3, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(6, div(h2(strong("Listado Clusters Telefonica Argentina")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(3, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              
              # Tab body
              
              fluidRow(
                # Text output:
                fluidRow(div (box(title= "Número de clusters", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_clusters_listing"))),
                              box(title= "Número de centros poblados", status= "primary", solidHeader = TRUE, height= "110px", width= 5, h3(textOutput("sum_settlements_2_listing"))) ,
                              box(title= "Población incluida", status= "primary", solidHeader = TRUE,  height= "110px", width= 5, h3(textOutput("sum_population_2_listing"))),style="padding-left:150px;padding-right:150px;")) ,
                
                
                fluidRow(div(downloadButton("downloadData_2_listing", "Descargar CSV"), box(("Info: para priorizar la ordenacion de columnas del resultado de la busqueda, hacer Shift + click en las columnas por orden de prioridad."),
                                                                                            width=10)), style="padding-left:40px;padding-right:40px;"),
                
                # Dataframe output
                div(box(
                  dataTableOutput("outputdf_2_listing"), width = "80%", height= "700px"
                ),  style="padding-left:40px;padding-right:40px;" )
                
                
              )),
      tabItem(tabName = "priorization_clusters_ipt",
              
              # Tab Header
              fluidRow(
                column(3, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(6, div(h2(strong("Priorización Clusters Perímetro IpT Telefónica Argentina")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(3, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              
              # Tab body
              
              fluidRow(
                
                column( 6,
                        
                        # Text output:
                        fluidRow (box(title= "Número de clusters", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_clusters_7"))),
                                  box(title= "Número de centros poblados", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_settlements_7"))) ,
                                  box(title= "Población incluida", status= "primary", solidHeader = TRUE,  height= "110px", width= 4, h3(textOutput("sum_population_7")))) ,
                        
                        # Dataframe output
                        box(
                          dataTableOutput("outputdf_7"), width = "100%", height= "700px"
                        ) ,
                        
                        fluidRow(downloadButton("downloadData_7", "Descargar CSV"), box(("Info: para priorizar la ordenacion de columnas del resultado de la busqueda, hacer Shift + click en las columnas por orden de prioridad."), width=10))),
                
                column( 6,
                        tabBox( side= "right", width = 12, height = "820px",
                                tabPanel("Mapa Acceso y Transporte", leafletOutput("output_map_access_transport_7", height = "800px")),
                                tabPanel("Mapa Detalle CCPP", leafletOutput("output_map_segmentation_7", height = "800px")))
                        
                )
              )),
      
      tabItem(tabName = "listing_clusters_ipt",
              
              # Tab Header
              fluidRow(
                column(3, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(6, div(h2(strong("Listado Clusters Perímetro IpT Telefónica Argentina")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(3, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              
              # Tab body
              
              fluidRow(
                # Text output:
                fluidRow(div (box(title= "Número de clusters", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_clusters_listing_8"))),
                              box(title= "Número de centros poblados", status= "primary", solidHeader = TRUE, height= "110px", width= 5, h3(textOutput("sum_settlements_8_listing"))) ,
                              box(title= "Población incluida", status= "primary", solidHeader = TRUE,  height= "110px", width= 5, h3(textOutput("sum_population_8_listing"))),style="padding-left:150px;padding-right:150px;")) ,
                
                
                fluidRow(div(downloadButton("downloadData_8_listing", "Descargar CSV"), box(("Info: para priorizar la ordenacion de columnas del resultado de la busqueda, hacer Shift + click en las columnas por orden de prioridad."),
                                                                                            width=10)), style="padding-left:40px;padding-right:40px;"),
                
                # Dataframe output
                div(box(
                  dataTableOutput("outputdf_8_listing"), width = "80%", height= "700px"
                ),  style="padding-left:40px;padding-right:40px;" )
                
                
              )),
      tabItem(tabName = "priorization_partners",
              
              # Tab Header
              fluidRow(
                column(3, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(6, div(h2(strong("Priorización Partners Telefonica Argentina")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(3, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              
              # Tab body
              
              fluidRow(
                # Text output:
                fluidRow ( div(box(title= "Número de sites", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_sites_4"))) ,
                               box(title= "Número de centros poblados", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_settlements_4"))) ,
                               box(title= "Población incluida", status= "primary", solidHeader = TRUE,  height= "110px", width= 4, h3(textOutput("sum_population_4")))),style="padding-left:150px;padding-right:150px;") ,
                
                # Dataframe output
                box(
                  plotlyOutput("partners_plot"), width = "100%", height= "1200px"
                )
              )),
      tabItem(tabName = "visualization_partners",
              
              # Tab Header
              fluidRow(
                column(3, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(6, div(h2(strong("Visualización Partners Telefonica Argentina")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(3, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              
              # Tab body
              
              fluidRow(
                # Text output:
                fluidRow ( div(box(title= "Número de sites", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_sites_5"))) ,
                               box(title= "Número de centros poblados", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_settlements_5"))) ,
                               box(title= "Población incluida", status= "primary", solidHeader = TRUE,  height= "110px", width= 4, h3(textOutput("sum_population_5")))),style="padding-left:150px;padding-right:150px;") ,
                
                # Dataframe output
                box(
                  leafletOutput("partners_map", height = "800px"), width = "100%", height= "800px"
                )
              )),
      tabItem(tabName = "listing_partners",
              # Tab Header
              fluidRow(
                column(3, div(img(height = 40, width = 136, src= "tef_logo.png"),style="padding-top:35px; padding-left:25px")),
                column(6, div(h2(strong("Listado Partners Telefonica Argentina")),style="padding-top:15px; text-align: center; color:#00334d;")),
                column(3, div(img(height = 120, width = 150, src= "ipt_logo.png", align="right")))),
              br(),
              
              
              # Tab body
              
              fluidRow(
                # Text output:
                fluidRow(div (#box(title= "Número de sites", status= "primary", solidHeader = TRUE, height= "110px", width= 4, h3(textOutput("sum_sites_6"))),
                  box(title= "Número de centros poblados", status= "primary", solidHeader = TRUE, height= "110px", width= 5, h3(textOutput("sum_settlements_6"))) ,
                  box(title= "Población incluida", status= "primary", solidHeader = TRUE,  height= "110px", width= 5, h3(textOutput("sum_population_6"))),style="padding-left:150px;padding-right:150px;")) ,
                
                
                fluidRow(div(downloadButton("downloadData_5", "Descargar CSV"), box(("Info: para priorizar la ordenacion de columnas del resultado de la busqueda, hacer Shift + click en las columnas por orden de prioridad."),
                                                                                    width=10)), style="padding-left:40px;padding-right:40px;"),
                
                # Dataframe output
                div(box(
                  dataTableOutput("outputdf_6"), width = "80%", height= "700px"
                ),  style="padding-left:40px;padding-right:40px;" ) 
              ))
    )))
)