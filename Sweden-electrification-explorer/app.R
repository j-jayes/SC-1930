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
library(ggiraph)

# setwd(here::here("Sweden-electrification-explorer"))
birth_place_counts <- read_rds("birth_place_counts.rds")

birth_place_counts <- birth_place_counts %>%
  rename(parish = scbkod)

df_census_changes <- read_rds("df_census_changes_and_fin.rds")
st_map <- read_rds("st_map.rds")

st_map <- st_map %>%
  rename(parish = ref_code_char) %>%
  st_transform(crs = 4326)

st_map_new <- read_rds("st_map_new.rds")

parish_birth_stats <- read_rds("parish_birth_stats.rds")

elec_map_grid <- read_rds("elec_map_grid.rds")
elec_map_power <- read_rds("elec_map_power.rds")
electricity_parishes <- read_rds("electricity_parishes.rds")

parish_names <- read_rds("parish_names.rds")
title_counts  <- read_rds("title_counts_map.rds")
outcomes_avg <- read_rds("outcomes_avg.rds")

type_title_counts <- read_rds("type_title_counts.rds")
df_census_changes_names <- read_rds("df_census_changes_names.rds")


# thematic_shiny(font = "auto")
theme_set(theme_light())
theme_update(text = element_text(size = 17))

ui <- fluidPage(
  theme = bslib::bs_theme(bootswatch = "minty", font_scale = 1.3),

  # Application title
  titlePanel("Sweden's electrification data explorer"),
  tabsetPanel(
    id = "tab_being_displayed", # will set input$tab_being_displayed
    type = "tabs",
    tabPanel(
      "Electricity",
      sidebarLayout(
        sidebarPanel(
          width = 3,
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
          leafletOutput("leaflet_map_elec", height = 800),
          p("Source:",  em("The Economic Geography of Electricity: An Outline"),  "Hjulström, Enequist, Lagerstedt (1942)"),
          a(href="https://books.google.se/books/about/The_Economic_Geography_of_Electricity.html?id=stP3xgEACAAJ&redir_esc=y", "Link"),
          p("Source: Junkka, Johan.", em("histmaps data package")),
          a(href="https://github.com/junkka/histmaps/blob/master/LICENSE", "Link to github")
        )
      )),
    tabPanel(
      "Outcomes",
      sidebarLayout(
        sidebarPanel(
          width = 3,
          selectizeInput("census_change_series_input",
                         "Series:",
                         choices = unique(df_census_changes$census_change_series),
                         selected = "Population change 1880:1930 (pct)",
                         multiple = FALSE
          ),
          ggiraphOutput("comparison_col")
        ),
        mainPanel(
          leafletOutput("leaflet_map", height = 800),
          p("Source: ", em("Minnesota Population Center. Integrated Public Use Microdata Series, International: Version 7.3 [dataset]. Minneapolis, MN: IPUMS, 2020.")),
          a(href="https://doi.org/10.18128/D020.V7.3", "Link"),
          p("Source: ", em("Riksarkivet. 1930 Census")),
          p("Source: Junkka, Johan.", em("histmaps data package")),
          a(href="https://github.com/junkka/histmaps/blob/master/LICENSE", "Link to github")
        ))
    ),
    tabPanel(
      "Titles",
      sidebarLayout(
        sidebarPanel(
          width = 3,
          h4("Most common job titles by parish type"),
          ggiraphOutput("comparison_title"),
          p("Risinge parish has 558 Metallarbetare")
        ),
        mainPanel(
          leafletOutput("leaflet_map_titles", height = 800),
          p("Source: ", em("Riksarkivet. 1930 Census")),
          p("Source: Junkka, Johan.", em("histmaps data package")),
          a(href="https://github.com/junkka/histmaps/blob/master/LICENSE", "Link to github")
        ))
    ),
    tabPanel(
      "Descriptives",
      fluidRow(
        column(5,
               h4("Wealth and income ginis in 1930"),
               h6("By parish and parish type"),
               ggiraphOutput("gini_scatter")),
        column(5, offset = 1,
               h4("Population and mean income in 1930"),
               h6("By parish and parish type"),
               ggiraphOutput("agglomorations_scatter"))
      )
      ),
    tabPanel(
      "What's next?",
      h4("Wealth and income difference by origin in electricity parishes"),
      h4("Migration maps"),
      h4("Digitize 1925 power stations")),
    selected = "Electricity"
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
        parish_table, value_table, parish_name, county_name
      ) %>%
      mutate(
        key = case_when(
          key == "parish_table" ~ "Parish Number",
          key == "parish_name" ~ "Parish Name",
          key == "county_name" ~ "County Name",
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
    req(input$tab_being_displayed == "Outcomes")

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
        title = glue(input$census_change_series_input)
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
    pal <- colorFactor("Set1", df_elec_map_power()$type)
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
    pal <- colorpal_power()

    labels <- sprintf(
      "<strong>%s</strong><br/>%.0f kW generation capacity",
      df_elec_map_power()$type, df_elec_map_power()$power
    ) %>% lapply(htmltools::HTML)

    leafletProxy("leaflet_map_elec", data = df_elec_map_power()) %>%
      clearShapes() %>%
      addPolygons(
        data = st_map_new %>% filter(type == "Electricity parish"),
        color = "#444444", weight = 1, smoothFactor = 1,
        opacity = 1.0, fillOpacity = 0.5, popup = ~ parish_name
      ) %>%
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

  # map number 3
  ## output
  output$leaflet_map_titles <- renderLeaflet({
    req(input$tab_being_displayed == "Titles")


    leaflet(title_counts) %>%
      setView(
        lng = 12,
        lat = 63,
        zoom = 5
      ) %>%
      addProviderTiles("CartoDB.Positron") %>%
      addPolygons(
        popup = ~html,
        layerId = ~scbkod,
        color = "#191970", weight = 1, smoothFactor = 1,
        opacity = 1.0, fillOpacity = 0.5

      )

  })

  # comparison chart

  output$comparison_col <- renderggiraph({

    f <- outcomes_avg %>%
      filter(name == input$census_change_series_input) %>%
      mutate(mean_value = round(mean_value, 2)) %>%
      ggplot(aes(type, mean_value, fill = type,
                 tooltip = mean_value)) +
      geom_col_interactive(show.legend = F) +
      # geom_text(aes(label = mean_value),
      #           vjust = -1) +
      scale_fill_brewer(palette = "Paired") +
      facet_wrap(~ name, scales = "free_y") +
      labs(x = NULL,
           y = NULL)


    ggiraph(ggobj = f, height_svg = 8, width_svg = 6)
  })


  output$comparison_title <- renderggiraph({

    f <-   type_title_counts %>%
      mutate(yrke = fct_reorder(yrke, n)) %>%
      ggplot(aes(n, yrke, fill = type, tooltip = str_c(yrke, "\n", n))) +
      geom_col_interactive(show.legend = F) +
      scale_fill_brewer(palette = "Paired") +
      facet_wrap(~type, scales = "free_x") +
      labs(x = NULL,
           y = NULL)


    ggiraph(ggobj = f, height_svg = 8)
  })

  output$gini_scatter <- renderggiraph({

  f <- df_census_changes_names %>%
    filter(str_detect(census_change_series, "gini")) %>%
    mutate(value = round(value, 0)) %>%
    distinct() %>%
    pivot_wider(
      names_from = census_change_series,
      values_from = value
    ) %>%
    mutate(tooltip = str_c(
      parish_name, "\n",
      county_name, "\nIncome gini = ",
      `Income gini in 1930`, "\nWealth gini = ",
      `Wealth gini in 1930`
    )) %>%
    ggplot(aes(`Income gini in 1930`, `Wealth gini in 1930`,
               colour = type, group = type,
               tooltip = tooltip
    )) +
    geom_point_interactive(alpha = .6) +
    geom_smooth(se = F) +
    scale_color_brewer(palette = "Dark2") +
    labs(
      colour = NULL
    ) +
    theme(legend.position = "bottom")

  ggiraph(ggobj = f, width_svg = 6, height_svg = 6)

  })


  output$agglomorations_scatter <- renderggiraph({

  f <- df_census_changes_names %>%
    filter(census_change_series %in% c("Population in 1930", "Mean income in 1930 (logged)")) %>%
    distinct() %>%
    pivot_wider(names_from = census_change_series, values_from = value) %>%
    mutate(`Mean income in 1930 (logged)` = round(`Mean income in 1930 (logged)`, 2)) %>%
    mutate(tooltip = str_c(
      parish_name, "\n",
      county_name, "\nPop = ",
      `Population in 1930`, "\nMean income = ",
      `Mean income in 1930 (logged)`
    )) %>%
    ggplot(aes(`Population in 1930`, `Mean income in 1930 (logged)`,
               colour = type, tooltip = tooltip, group = type
    )) +
    geom_point_interactive(alpha = .6) +
    geom_smooth(se = F) +
    scale_x_log10() +
    scale_color_brewer(palette = "Dark2") +
    theme(legend.position = "bottom") +
    labs(
      colour = NULL,
    )

  ggiraph(ggobj = f, width_svg = 6, height_svg = 6)

  })


}

# Run the application
shinyApp(ui = ui, server = server)
