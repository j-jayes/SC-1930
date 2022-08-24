library(shiny)
library(tidyverse)
library(glue)
library(leaflet)
library(sf)
library(shinyWidgets)
library(shinydashboard)
library(ggiraph)
library(bslib)
library(metathis)
library(sf)
library(htmltools)

setwd(here::here("Sweden-electrification-explorer"))
# df <- read_rds("folk_1930_short.rds")
birth_place_counts <- read_rds("birth_place_counts.rds")

birth_place_counts <- birth_place_counts %>%
  rename(parish = scbkod)

df_census_changes <- read_rds("df_census_changes_and_fin.rds")
st_map <- read_rds("st_map.rds")

st_map <- st_map %>%
  rename(parish = ref_code_char) %>%
  st_transform(crs = 4326)

parish_birth_stats <- read_rds("parish_birth_stats.rds")



parish_names <- st_map %>%
  select(parish, name) %>%
  as_tibble() %>%
  select(-geometry) %>%
  mutate(
    name = str_remove(name, "församling"),
    name = str_squish(name)
  ) %>%
  rename(parish_name = name)


# thematic_shiny(font = "auto")
theme_set(theme_light())
theme_update(text = element_text(size = 17))


ui <- fluidPage(
  theme = bslib::bs_theme(bootswatch = "minty", font_scale = 1.3),

  # Application title
  titlePanel("Sweden's electrification data explorer"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectizeInput("census_change_series_input",
        "Series:",
        choices = unique(df_census_changes$census_change_series),
        selected = "Population change 1880:1930 (pct)",
        multiple = FALSE
      ),
      sliderTextInput("year_input_grid",
        "Choose grid year:",
        choices = c(1900, 1911, 1926),
        selected = 1900,
        animate = TRUE
      ),
      sliderTextInput("year_input_power",
                      "Choose power generation year:",
                      choices = c(1885, 1900),
                      selected = 1885,
                      animate = TRUE
      )
    ),
    mainPanel(
      tabsetPanel(
        id = "tab_being_displayed", # will set input$tab_being_displayed
        type = "tabs",
        tabPanel(
          "Population",
          leafletOutput("leaflet_map", height = 800)
        ),
        tabPanel(
          "Table",
          # tableOutput("comp_table")
          valueBoxOutput("vbox_1"),
          leafletOutput("leaflet_map_elec", height = 800)
        ),
        tabPanel(
          "Formula",
          em("The production function is:"),
          # uiOutput("formula"),
          # tableOutput("explanation"),
          em("And plugging in the values we get:"),
          # uiOutput("formula_inputs"))
        )
      ),
      selected = "Population"
    )
  )
)


# Define server logic required to draw a histogram
server <- function(input, output) {

  # map number 1
  ## df
  df_map <- reactive({
    df_census_changes %>%
      filter(
        census_change_series == input$census_change_series_input,
      ) %>%
      filter(!is.na(value)) %>%
      mutate(
        value_table = str_c(format(round(value, 0), big.mark = " ")),
        parish_table = parish,
      ) %>%
      inner_join(parish_names) %>%
      gather(
        key, vt,
        parish_table, value_table, parish_name
      ) %>%
      mutate(
        key = case_when(
          key == "parish_table" ~ "Parish Number",
          key == "parish_name" ~ "Parish Name",
          TRUE ~ input$census_change_series_input
        ),
        key = str_to_title(str_replace_all(key, "_", " ")),
        key = paste0("<b>", key, "</b>")
      ) %>%
      replace_na(list(vt = "Unknown")) %>%
      nest(data = c(key, vt)) %>%
      mutate(html = map(data,
        knitr::kable,
        format = "html",
        escape = FALSE,
        col.names = c("", "")
      )) %>%
      inner_join(st_map) %>%
      st_sf()
  })
  ## palette
  colorpal <- reactive({
    colorNumeric(
      palette = "Spectral",
      domain = df_map()$value
    )
  })
  ## output
  output$leaflet_map <- renderLeaflet({
    leaflet() %>%
      setView(
        lng = 12,
        lat = 63,
        zoom = 5
      ) %>%
      addProviderTiles("CartoDB.Positron")
  })
  ## observe
  observe({
    pal <- colorpal()

    leafletProxy("leaflet_map", data = df_map()) %>%
      clearShapes() %>%
      addPolygons(
        color = ~ pal(value),
        fillOpacity = .3,
        popup = ~html,
        layerId = ~parish
      ) %>%
      clearControls() %>%
      addLegend(
        position = "bottomright",
        pal = pal,
        values = ~value,
        title = glue(input$census_change_series_input),
        labFormat = labelFormat(
          # prefix = glue(legend_prefix()),
          # suffix = glue(legend_suffix())
        )
      )
  })

  # map number 2
  ## df grid
  df_elec_map_grid <- reactive({
    elec_map_grid %>%
      filter(year == input$year_input_grid)
  })
  df_elec_map_power <- reactive({
    elec_map_power %>%
      filter(year == input$year_input_power)
  })
  ## palette
  colorpal_power <- reactive({
    pal <- colorFactor("Set1", elec_map_power_filtered$type)
  })
  ## output
  output$leaflet_map_elec <- renderLeaflet({
    leaflet() %>%
      setView(
        lng = 12,
        lat = 63,
        zoom = 5
      ) %>%
      addProviderTiles("CartoDB.Positron")
  })
  ## observe for the power
  observe({
    req(input$tab_being_displayed == "Table") # Only display if tab is 'Map Tab'

    pal <- colorpal_power()

    labels <- sprintf(
      "<strong>%s</strong><br/>%.0f kW generation capacity",
      df_elec_map_power()$type, df_elec_map_power()$power
    ) %>% lapply(htmltools::HTML)

    leafletProxy("leaflet_map_elec", data = df_elec_map_power()) %>%
      clearShapes() %>%
      addPolylines(data = df_elec_map_grid()) %>%
      clearMarkers() %>%
      addCircleMarkers(
        weight = 1,
        radius = ~ sqrt(power),
        color = ~ pal(type),
        popup = labels
      ) %>%
      clearControls() %>%
      addLegend("bottomright", pal = pal, values = ~type, title = "Power source")
  })

  # ## observe
  # observe({
  #   pal <- colorpal_power()
  #
  #   labels <- sprintf(
  #     "<strong>%s</strong><br/>%.0f kW generation capacity",
  #     df_elec_map_power()$type, df_elec_map_power()$power
  #   ) %>% lapply(htmltools::HTML)
  #
  #   leafletProxy("leaflet_map_elec", data = df_elec_map_power()) %>%
  #     clearShapes() %>%
  #     addCircleMarkers(
  #       weight = 1,
  #       radius = ~ sqrt(power),
  #       color = ~ pal(type),
  #       popup = labels
  #     ) %>%
  #     addPolylines(data = df_elec_map_grid()) %>%
  #     clearControls() %>%
  #     addLegend("bottomright", pal = pal, values = ~type, title = "Power source")
  # })



  # observe({
  #   pal <- colorpal()
  #
  #   leafletProxy("leaflet_map", data = df_map()) %>%
  #     clearControls() %>%
  #     addLegend(
  #       position = "bottomright",
  #       pal = pal,
  #       values = ~value,
  #       title = glue(input$census_change_series_input),
  #       labFormat = labelFormat(
  #         # prefix = glue(legend_prefix()),
  #         # suffix = glue(legend_suffix())
  #       )
  #     )
  # })

  # # next map
  # df_map_birthplaces <- reactive({
  #   birth_place_counts %>%
  #     filter(
  #       parish == input$leaflet_map_births_shape_click$id,
  #     ) %>%
  #   mutate(
  #     value_table = str_c(format(round(n, 0), big.mark = " ")),
  #     parish_table = parish,
  #   ) %>%
  #     gather(
  #       key, vt,
  #       parish_table, value_table
  #     ) %>%
  #     mutate(
  #       key = case_when(
  #         key == "parish_table" ~ "Parish",
  #         TRUE ~ input$leaflet_map_births_shape_click$id
  #       ),
  #       key = paste0("<b>", key, "</b>")
  #     ) %>%
  #     replace_na(list(vt = "Unknown")) %>%
  #     nest(data = c(key, vt)) %>%
  #     mutate(html = map(data,
  #                       knitr::kable,
  #                       format = "html",
  #                       escape = FALSE,
  #                       col.names = c("", "")
  #     )) %>%
  #     inner_join(st_map, by = c("fscbkod" = "parish")) %>%
  #     st_sf()
  # })
  #
  #
  # output$leaflet_map_births <- renderLeaflet({
  #   req(input$leaflet_map_births_shape_click$id)
  #   leaflet() %>%
  #     setView(
  #       lng = 12,
  #       lat = 56,
  #       zoom = 4
  #     ) %>%
  #     addProviderTiles("CartoDB.Positron")
  # })
  #
  # observe({
  #   pal <- colorpal()
  #
  #   leafletProxy("leaflet_map_births", data = df_map_birthplaces()) %>%
  #     clearShapes() %>%
  #     addPolygons(
  #       color = ~ pal(n),
  #       fillOpacity = .3,
  #       popup = ~html,
  #       layerId = ~parish
  #     )
  # })
  #
  # observe({
  #   pal <- colorpal()
  #
  #   leafletProxy("leaflet_map_births", data = df_map_birthplaces()) %>%
  #     clearControls() %>%
  #     addLegend(
  #       position = "bottomright",
  #       pal = pal,
  #       values = ~value,
  #       # title = glue(input$census_change_series_input), come back to this
  #       labFormat = labelFormat(
  #         # prefix = glue(legend_prefix()),
  #         # suffix = glue(legend_suffix())
  #       )
  #     )
  # })


  vb <- shinydashboard::valueBox(
    # background = "navy",
    value = "1,345",
    subtitle = "Lines of code written",
    icon = icon("calendar", lib = "font-awesome"),
    width = 4,
    href = NULL
  )

  output$vbox_1 <- renderValueBox(vb)

  # output$click_test <- renderPrint({reactiveValuesToList(input)})

  # output$stacked_fill <- renderggiraph({
  #   req(input$leaflet_map_shape_click$id)
  #
  #   g <- df %>%
  #     filter(
  #       series %in% c(
  #         "Agric. share of employment",
  #         "Industry share of employment",
  #         "Services share of employment"
  #       ),
  #       region == input$leaflet_map_shape_click$id
  #     ) %>%
  #     mutate(series = str_remove(series, "share of employment")) %>%
  #     ggplot(aes(year, value, fill = series, tooltip = series)) +
  #     geom_area_interactive(position = "fill") +
  #     scale_y_continuous(labels = scales::percent_format()) +
  #     scale_fill_brewer(palette = "Spectral") +
  #     theme(legend.position = "bottom") +
  #     labs(
  #       x = NULL,
  #       y = NULL,
  #       fill = NULL,
  #       title = "Employment composition"
  #     )
  #
  #
  #   ggiraph(ggobj = g)
  # })
  #
  # output$facet_line <- renderggiraph({
  #   req(input$leaflet_map_shape_click$id)
  #
  #   country_name <- df %>%
  #     filter(region == input$leaflet_map_shape_click$id) %>%
  #     distinct(country_current_borders) %>%
  #     pull()
  #
  #   f <- df %>%
  #     filter(
  #       series %in% c("Population", "Regional GDP (2011 $m)"),
  #       region == input$leaflet_map_shape_click$id
  #     ) %>%
  #     inner_join(df_country, by = c("country_current_borders", "year", "series")) %>%
  #     pivot_longer(c(value, country_avg), names_to = "stat") %>%
  #     mutate(stat = case_when(
  #       stat == "country_avg" ~ str_c("Avg. for regions in ", country_name),
  #       TRUE ~ input$leaflet_map_shape_click$id
  #     )) %>%
  #     mutate(
  #       value_disp = format(round(value), big.mark = " "),
  #       tooltip = str_c(stat, " ", value_disp)
  #     ) %>%
  #     ggplot(aes(year, value, colour = stat, tooltip = tooltip)) +
  #     geom_line(aes(year, value, colour = stat, group = stat), cex = 2, alpha = .8) +
  #     geom_point_interactive(cex = 3, alpha = .8) +
  #     facet_wrap(~series, scales = "free_y", nrow = 2) +
  #     scale_y_continuous(labels = scales::number_format()) +
  #     scale_colour_manual(values = c("#D53E4F", "#66C2A5")) +
  #     theme(legend.position = "bottom") +
  #     labs(
  #       x = NULL,
  #       y = NULL,
  #       colour = NULL,
  #       title = "Population and GDP"
  #     )
  #
  #
  #   ggiraph(ggobj = f)
  # })
}

# Run the application
shinyApp(ui = ui, server = server)
