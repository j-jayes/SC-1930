library(shiny)
library(tidyverse)
library(leaflet)
library(sf)


df_to_join <- read_rds("df_to_join.rds")
st_map <- read_rds("st_map.rds")
exclusion_zone <- read_rds("exclusion_zone.rds")
parish_buffer_matrix_long <- read_rds("parish_buffer_matrix_long.rds")
el_paishes_1930 <- read_rds("el_paishes_1930.rds")
grid_1926 <- read_rds("1926_grid.rds") %>% st_transform(crs = 4326)

st_map_with_el_parished <- st_map %>%
  mutate(parish_code = as.numeric(str_sub(ref_code.x, 4, 12))) %>%
  left_join(df_to_join)

st_map_with_el_parished_1930 <- st_map_with_el_parished %>%
  filter(iline == 1)

union_of_el_parishes <- st_map_with_el_parished %>%
  filter(iline == 1) %>%
  st_union() %>%
  st_transform(crs = 4326)

union_exclusion_zone <- st_map %>%
  inner_join(exclusion_zone) %>%
  st_union() %>%
  st_transform(crs = 4326)

st_map_only_el_parished_1930 <- st_map_with_el_parished %>%
  inner_join(el_paishes_1930) %>%
  st_transform(crs = 4326)

st_map_only_el_parished <- st_map_with_el_parished %>%
  inner_join(el_paishes_1930) %>%
  st_transform(crs = 4326)

to_exclude_from_buffer_map_1930 <- st_map %>%
  filter(!geom_id %in% st_map_only_el_parished$geom_id) %>%
  inner_join(exclusion_zone) %>%
  st_transform(crs = 4326)

ui <- fluidPage(
  titlePanel("Choosing control groups"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      sliderInput("buffer_inp",
        "Control parish threshold:",
        min = 50,
        max = 250,
        step = 50,
        value = 100
      )
    ),

    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(
        id = "tab_being_displayed",
        type = "tabs",
        tabPanel(
          "Theory",
          leafletOutput("leaflet_map", height = 800)
        ),
        tabPanel(
          "1930 data",
          leafletOutput("leaflet_map_1930", height = 800)
        )
      )
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    union_parishes_in_buffer <- reactive({
      st_map %>%
        inner_join(parish_buffer_matrix_long %>%
          filter(
            type == "all_parishes",
            buffer == input$buffer_inp,
            is.na(exclusion_zone_indicator),
            is.na(electricity_parish)
          ), by = "geom_id") %>%
        st_union() %>%
        st_transform(crs = 4326)
    })

     output$leaflet_map <- renderLeaflet({
       leaflet() %>%
         setView(
           lng = 12,
           lat = 60,
           zoom = 5
         ) %>%
         addProviderTiles("CartoDB.Positron")
     })

     observe({
       leafletProxy("leaflet_map") %>%
         clearShapes() %>%
         addPolylines(data = grid_1926, color = "#7f7f7f") %>%
         addPolygons(data = union_of_el_parishes, color = "blue") %>%
         addPolygons(data = union_exclusion_zone, color = "red") %>%
         addPolygons(data = union_parishes_in_buffer(), color = "green")
       })

     # next map

     parishes_in_buffer_1930 <- reactive({
       st_map %>%
         inner_join(parish_buffer_matrix_long %>%
           filter(
             type == "parishes_1930",
             buffer == input$buffer_inp,
             is.na(exclusion_zone_indicator),
             is.na(electricity_parish)
           ), by = "geom_id") %>%
         st_transform(crs = 4326)
     })

     output$leaflet_map_1930 <- renderLeaflet({
       leaflet() %>%
         setView(
           lng = 12,
           lat = 60,
           zoom = 5
         ) %>%
         addProviderTiles("CartoDB.Positron")
     })

     observe({
       req(input$tab_being_displayed == "1930 data")

       leafletProxy("leaflet_map_1930") %>%
         clearShapes() %>%
         addPolylines(data = grid_1926, color = "#7f7f7f") %>%
         addPolygons(data = st_map_only_el_parished_1930, color = "blue") %>%
         addPolygons(data = to_exclude_from_buffer_map_1930, color = "red") %>%
         addPolygons(data = parishes_in_buffer_1930(), color = "green")
     })


}

# Run the application
shinyApp(ui = ui, server = server)
