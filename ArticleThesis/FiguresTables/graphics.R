library(dplyr)
library(ggplot2)
library(ggrepel)
library(viridis)

dta <- read.table(text = "cDNAs only	6556
RefSeq proteins only	144
UniProt proteins only	209
RefSeq and UniProt proteins only	179
cDNAs and RefSeq proteins only	1238
cDNAs and UniProt proteins only	10944
cDNAs and RefSeq and UniProt proteins	2424", sep = "\t")
dta <- dta[order(dta[, "V2"], decreasing = TRUE), ]
dta[, "V1"] <- factor(dta[, "V1"], levels = unique(dta[, "V1"]))
dta <- dta %>% mutate(pos = (cumsum(rev(V2))-rev(V2)/2))

ggplot(data = dta, aes(x = 1, y = V2, fill = V1)) +
    geom_bar(width = 1, stat = "identity", colour = "white") +
    geom_label_repel(aes(x = 1.25, y = rev(pos), label = V2),
        colour = "black",
        size = 3,
        nudge_x = 0.5,
        # nudge_y = 0.5,
        segment.colour = "black",
        min.segment.length = unit(0, "lines"),

        show.legend = FALSE
    ) +
    coord_polar(theta = "y") +
    scale_fill_viridis(discrete = TRUE, name = NULL, begin = 0.95, end = 0.30) +
    theme_void()
