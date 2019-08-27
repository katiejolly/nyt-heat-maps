library(raster)
library(sf)
library(tidyverse)
library(ggtext)

library(showtext)
font_add_google("Lato", regular.wt = 300, bold.wt = 700)


landsat_dc_july18 <- raster("data/LST_F_20180708.tif")

boundary <- st_read("https://opendata.arcgis.com/datasets/0c34f6dd309d41d6a9ad7eea2f12883c_0.geojson") %>%
  st_transform(st_crs(landsat_dc_july18))

water <- st_read("https://opendata.arcgis.com/datasets/db65ff0038ed4270acb1435d931201cf_24.geojson") %>%
  st_transform(st_crs(landsat_dc_july18))

trees <- st_read("https://opendata.arcgis.com/datasets/f6c3c04113944f23a7993f2e603abaf2_23.geojson") %>%
  st_transform(st_crs(landsat_dc_july18)) %>%
  st_crop(st_bbox(boundary))

trees_sp <- as(trees, "Spatial")

plot(st_geometry(trees), col = "green", cex = 0.4)

landsat_dc_july18
summary(landsat_dc_july18)
minValue(landsat_dc_july18)

landsat_0718_df <- rasterToPoints(landsat_dc_july18) %>%
  as_data_frame()

library(RColorBrewer)
my.palette <- brewer.pal(n = 11, name = "RdYlBu")

pal2 <- c('#32a881', '#41ad88', '#4fb28f', '#5bb695', '#66bb9c', '#72c0a3', '#7cc5aa', '#87c9b1', '#91ceb8', '#9cd2be', '#a6d7c5', '#b1dccc', '#bbe0d3', '#c5e5da', '#d0e9e1', '#dbeee7', '#e5f2ee', '#f0f7f5', '#fff6d0', '#ffedc0', '#ffe4b1', '#ffdba2', '#ffd293', '#ffc885', '#ffbe78', '#ffb46c', '#ffaa60', '#ff9f54', '#ff944a', '#ff8841', '#ff7c38', '#fe6f32', '#fd612c', '#fc5228', '#fb3f26', '#fa2525')

pal3 <- rev(c('#9e0142','#d53e4f','#f46d43','#fdae61','#fee08b','#ffffbf','#e6f598','#abdda4','#66c2a5','#3288bd','#5e4fa2'))

y <- disaggregate(landsat_dc_july18, 50, method='bilinear')

library(showtext)
## Loading Google fonts (http://www.google.com/fonts)
font_add_google("Didact Gothic")

png("test_text.png")
par(bty = "n", family = "Didact Gothic")
plot(y,
     main = "",
     col = pal2,
     border = "gray90",
     legend = FALSE,
     axes = FALSE,
     interpolate=TRUE)

plot(water,
     add = TRUE,
     col = "white",
     border = "gray90")

text(398000, 138300, "W A S H I N G T O N", cex = 0.75, col = "#656c78")

text(397900, 136600, "downtown", cex = 0.65, col = "#656c78")

text(392100, 140000, "palisades", cex = 0.65, col = "#656c78")

text(401700, 133000, "anacostia", cex = 0.65, col = "#656c78")

text(398000, 140000, "columbia\nheights", cex = 0.65, col = "#656c78")

text(401700, 140500, "brookland", cex = 0.65, col = "#656c78")

# plot(st_geometry(boundary), col = NA, border = "gray90", add = TRUE)



dev.off()


test_spdf <- as(landsat_dc_july18, "SpatialPointsDataFrame")
test_df <- as_tibble(test_spdf)
colnames(test_df) <- c("value", "x", "y") 


water_sp <- as(water, "Spatial")
test_df <- test_df %>%
  mutate(bin = cut(value, 19))

pal <- c('#228179', '#1e9084', '#229f8c', '#35ad94', '#50bb9b', '#6dc8a1', '#8dd4a8', '#addfaf', '#cee9b6', '#f0f3bd', '#ffbd7f', '#ffaa73', '#fc9667', '#f8835b', '#f1704f', '#e95c44', '#e04939', '#d5342f', '#c81d25')

labels <- tibble(x = c(396000, 395900, 390500, 
                       399700, 396000, 399700, 399200, 389070, 390000),
                 y = c(138300, 136600, 140000, 
                       133000, 140000, 140500, 146400, 147000, 130100),
                 lab = c("W A S H I N G T O N", "downtown", "palisades", "anacostia", "columbia<br> heights", "brookland", "**Hotter:** Hotspots in<br>Brookland, Columbia<br>Heights, and LeDroit<br>Park hit **100 to 106 F**", "**Cooler:** Forested Rock<br>Creek Park recorded the<br>city's lowest temperatures<br>and helped to cool down<br>surrounding areas", "**Urban green spaces**<br>are an invaluable<br>resources for cooling<br>urban neighborhoods.<br>They help promote<br>walkability and improve<br>quality of living. Even a<br>few trees help!"))

ggplot() +
  geom_raster(data = test_df, aes(x = x, y = y,  fill = value), interpolate = TRUE) +
  geom_polygon(data = water_sp, aes(x = long, y = lat, group = group), color = "gray90", fill = "white") +
  geom_richtext(data = labels, aes(x = x, y = y, label = lab), fill = NA, label.color = NA, # remove background and outline
                label.padding = grid::unit(rep(0, 4), "pt"),  color = "#656c78", hjust = 0)+
  theme_minimal() +
  coord_equal() +
  scale_fill_gradientn(colors = rcartocolor::carto_pal(name = "TealRose", n = 7), breaks = c(72.5, 88, 106.6), labels = c("72", "88", "106"), name = "") +
  theme(legend.position = "bottom",
        axis.text = element_blank(),
        axis.title = element_blank(),
        panel.grid = element_line("transparent"),
        text = element_text(color = "#656c78", family = "Lato"),
        plot.caption = element_text(hjust = 0)) +
  guides(fill = guide_colourbar(barheight = 0.3, barwidth = 15, direction = "horizontal", ticks = FALSE)) +
  labs(caption = "July 8, 2018\nSource: DC Open Data")

over100 <- test_df %>%
  filter(value >=95)

labels2 <- tibble(x = c(396000, 395900, 390500, 
                       399700, 396000, 399700, 399200, 389000),
                 y = c(138300, 136600, 140000, 
                       133000, 140000, 140500, 146400, 132500),
                 lab = c("W A S H I N G T O N", "downtown", "palisades", "anacostia", "columbia<br> heights", "brookland", "The locations in **red** all<br>reached at least **95 F** while<br> the median was only **88 F**", "The hotter areas are primarily<br>in the NE quadrant which has<br>historically been more industrial"))

ggplot() +
  geom_raster(data = test_df, aes(x = x, y = y), fill = "gray90", interpolate = TRUE) +
  geom_raster(data = over100, aes(x = x, y = y), fill = "#d0587e") +
  geom_polygon(data = water_sp, aes(x = long, y = lat, group = group), color = "gray90", fill = "white") +
  geom_richtext(data = labels2, aes(x = x, y = y, label = lab), fill = NA, label.color = NA, # remove background and outline
                label.padding = grid::unit(rep(0, 4), "pt"),  color = "#656c78", hjust = 0)+
  theme_minimal() +
  coord_equal() +
  scale_fill_gradientn(colors = rcartocolor::carto_pal(name = "TealRose", n = 7), breaks = c(72.5, 88, 106.6), labels = c("72", "88", "106"), name = "") +
  theme(legend.position = "bottom",
        axis.text = element_blank(),
        axis.title = element_blank(),
        panel.grid = element_line("transparent"),
        text = element_text(color = "#656c78", family = "Lato"),
        plot.caption = element_text(hjust = 0)) +
  guides(fill = guide_colourbar(barheight = 0.3, barwidth = 15, direction = "horizontal", ticks = FALSE)) +
  labs(caption = "July 8, 2018\nSource: DC Open Data")


under80 <- test_df %>%
  filter(value <= 80)

labels3 <- tibble(x = c(396000, 395900, 390500, 
                        399700, 396000, 399700, 399200, 389000),
                  y = c(138300, 136600, 140000, 
                        133000, 140000, 140500, 146400, 132100),
                  lab = c("W A S H I N G T O N", "downtown", "palisades", "anacostia", "columbia<br> heights", "brookland", "The locations in **green** all<br>reached only **80 F** while<br> the median was **88 F**", "The cooler areas are primarily<br>in parks like Rock Creek Park,<br>the National Arboretum, and<br>Fort Circle Park"))

ggplot() +
  geom_raster(data = test_df, aes(x = x, y = y), fill = "gray90", interpolate = TRUE) +
  geom_raster(data = under80, aes(x = x, y = y), fill = "#009392") +
  geom_polygon(data = water_sp, aes(x = long, y = lat, group = group), color = "gray90", fill = "white") +
  geom_richtext(data = labels3, aes(x = x, y = y, label = lab), fill = NA, label.color = NA, # remove background and outline
                label.padding = grid::unit(rep(0, 4), "pt"),  color = "#656c78", hjust = 0)+
  theme_minimal() +
  coord_equal() +
  theme(legend.position = "bottom",
        axis.text = element_blank(),
        axis.title = element_blank(),
        panel.grid = element_line("transparent"),
        text = element_text(color = "#656c78", family = "Lato"),
        plot.caption = element_text(hjust = 0)) +
  guides(fill = guide_colourbar(barheight = 0.3, barwidth = 15, direction = "horizontal", ticks = FALSE)) +
  labs(caption = "July 8, 2018\nSource: DC Open Data")
