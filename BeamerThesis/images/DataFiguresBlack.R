# nohup nice -15 R CMD BATCH --vanilla /disks/PROJECT/Mickael/COMMUNICATION/BeamerThesis/images/DataFiguresBlack.R &
# killJobs --k="DataFiguresBlack.R"
rm(list = ls())
options(stringsAsFactors = FALSE)

# setwd("/disks/PROJECT/Mickael/COMMUNICATION/BeamerThesis/images/")
setwd("BeamerThesis/images/")

# ggsave(file = "Pictures/.png", plot = p, width = 7.5, height = 6, units = "in", dpi = 300)
# ggsave(file = "Pictures/.png", plot = p, width = 12, height = 6, units = "in", dpi = 300)


### Define nCores
    nCores <- min(parallel::detectCores(), ifelse(Sys.info()["nodename"]=="bigstat1", 100, 48))


### Load packages
    library(parallel)
    library(ggplot2)
    library(grid)
    library(scales)
    # options(java.parameters = "-Xmx100g")
    # library(xlsx)
    library(tidyr)
    library(dplyr)
    library(broom)
    library(cowplot)
    library(ggrepel)
    # library(viridis)
    library(ellipse)

    library(myScriptsMickael)
    library(ggFunctions)

    source("theme_black.R")


###
load("DataFiguresBlack1.Rdata")
# ggsave(file = "Fig01.png", plot = fig1, width = 7.5, height = 6, units = "in", dpi = 300)
fig2 <- fig2 + scale_colour_viridis(begin = 0.75, end = 0.75, discrete = TRUE)+theme(axis.text = element_text(size = rel(0.8), colour = "white"))
ggsave(file = "Fig02.png", plot = fig2, width = 12, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig03.png", plot = fig3, width = 12, height = 6, units = "in", dpi = 300)
# fig4 <- fig4+theme(axis.text = element_text(size = rel(0.8), colour = "white")) +
#     labs(
#         x = "Fasting plasma glucose per allele effect (mmol/L)",
#         y = expression(atop("Type 2 diabetes hazard ratio", paste("(fasting plasma glucose " >= "7.0mmol/L)")))
#     )
# ggsave(file = "Fig04.png", plot = fig4, width = 12, height = 6, units = "in", dpi = 300)

ggdata <- fig5$data
ggdata[, "exp.alpha.estimate"] <- exp(ggdata[, "alpha.estimate"])
ggdata.ellipse <- do.call("rbind", lapply(names(tail(sort(table(ggdata[, "GeneSymbol.Closest"])), 5)), function (g) {
    cbind(as.data.frame(with(
            subset(ggdata, GeneSymbol.Closest==g)[, c("gamma.estimate", "exp.alpha.estimate")],
            ellipse(
                cor(get("gamma.estimate"), get("exp.alpha.estimate")),
                scale = c(sd(get("gamma.estimate")), sd(get("exp.alpha.estimate"))),
                centre = c(mean(get("gamma.estimate")), mean(get("exp.alpha.estimate")))
            )
        )),
        class = g
    )
}))
ggdata.ellipse[, "GeneSymbol.Closest"] <- ggdata.ellipse[, "class"]
ggdata.ellipse <- subset(ggdata.ellipse, GeneSymbol.Closest%in%setdiff(names(which(table(ggdata[, "GeneSymbol.Closest"])>2)), "ARL15"))
ggdata.ellipse[, "GeneSymbol.Closest"] <- factor(ggdata.ellipse[, "GeneSymbol.Closest"], levels = sort(unique(ggdata[, "GeneSymbol.Closest"])))
ggdata.label <- do.call("rbind", by(ggdata.ellipse, ggdata.ellipse[, "GeneSymbol.Closest"], function (idta) {
    idta[which.max(idta[, "y"]), ]
}))
fig5 <- ggplot(
        data = ggdata,
        aes(x = gamma.estimate, y = exp(alpha.estimate), fill = GeneSymbol.Closest, shape = GeneSymbol.Closest)
    ) +
    theme_black(base_size = 14) +theme(axis.text = element_text(size = rel(0.8), colour = "white"))+
    geom_hline(yintercept = 1, linetype = 2, colour = "white") +
    geom_vline(xintercept = 0, linetype = 2, colour = "white") +
    geom_path(data = ggdata.ellipse, aes(x = x, y = y, colour = GeneSymbol.Closest), colour = "white", size = 1.5, show.legend = FALSE) +
    geom_path(data = ggdata.ellipse, aes(x = x, y = y, colour = GeneSymbol.Closest), size = 0.75, alpha = 1, show.legend = FALSE) +
    geom_point(size = 4) +
    geom_label_repel(data = ggdata.label, aes(x = x, y = y, label = GeneSymbol.Closest), colour = "white", nudge_y = 0.075, show.legend = FALSE, min.segment.length = unit(0, "lines"))  +
    scale_colour_viridis(name = "Gene Symbol", option = "viridis", discrete = TRUE) +
    scale_fill_viridis(name = "Gene Symbol", option = "viridis", discrete = TRUE) +
    scale_shape_manual(name = "Gene Symbol", values = rep(c(21, 22, 23, 24, 25), 4)) +
    scale_y_continuous(breaks = c(0.5, 1, 1.5, 2)) +
    labs(
        x = "Fasting plasma glucose per allele effect (mmol/L)",
        y = expression(atop("Type 2 diabetes hazard ratio", paste("(fasting plasma glucose " >= "7.0mmol/L)")))
    ) +
    lims(x = c(0, 0.15))
ggsave(file = "Fig05.png", plot = fig5, width = 12, height = 6, units = "in", dpi = 300)
fig5a <- ggplot(
    data = ggdata,
    aes(x = gamma.estimate, y = exp(alpha.estimate), fill = GeneSymbol.Closest, shape = GeneSymbol.Closest)
) +
    theme_black(base_size = 14)+theme(axis.text = element_text(size = rel(0.8), colour = "white")) +
    geom_hline(yintercept = 1, linetype = 2, colour = "white") +
    geom_vline(xintercept = 0, linetype = 2, colour = "white") +
    # geom_path(data = ggdata.ellipse, aes(x = x, y = y, colour = GeneSymbol.Closest), colour = "white", size = 1.5, show.legend = FALSE) +
    # geom_path(data = ggdata.ellipse, aes(x = x, y = y, colour = GeneSymbol.Closest), size = 0.75, alpha = 1, show.legend = FALSE) +
    geom_point(size = 4) +
    # geom_label_repel(data = ggdata.label, aes(x = x, y = y, label = GeneSymbol.Closest), colour = "white", nudge_y = 0.075, show.legend = FALSE, min.segment.length = unit(0, "lines"))  +
    scale_colour_viridis(name = "Gene Symbol", option = "viridis", discrete = TRUE) +
    scale_fill_viridis(name = "Gene Symbol", option = "viridis", discrete = TRUE) +
    scale_shape_manual(name = "Gene Symbol", values = rep(c(21, 22, 23, 24, 25), 4)) +
    scale_y_continuous(breaks = c(0.5, 1, 1.5, 2)) +
    labs(
        x = "Fasting plasma glucose per allele effect (mmol/L)",
        y = expression(atop("Type 2 diabetes hazard ratio", paste("(fasting plasma glucose " >= "7.0mmol/L)")))
    ) +
    lims(x = c(0, 0.15))
# ggsave(file = "Fig05a.png", plot = fig5a, width = 12, height = 6, units = "in", dpi = 300)
    tmp <- do.call("rbind", by(fig4$data, fig4$data[, "GeneSymbol.Closest"], function (itab) {
        itab[which.max(itab[, "TheoPower"]), ]
    }))
    fig4 <- ggplot(
            data = subset(tmp, sign(gamma.estimate)==sign(alpha.estimate) & !InGWAS),
            aes(x = gamma.estimate, y = exp(alpha.estimate), fill = TheoPower)
        ) +
        theme_black(base_size = 14) +
        geom_hline(yintercept = 1, linetype = 2, colour = "white") +
        geom_vline(xintercept = 0, linetype = 2, colour = "white") +
        geom_point(size = 4, shape = 21) +
        scale_fill_viridis(name = "GWAS", option = "viridis", labels = percent) +
        scale_y_continuous(breaks = c(0.5, 1, 1.5, 2)) +
        geom_label_repel(aes(label = GeneSymbol.Closest)) +
        labs(x = "Fasting glucose per allele effect (mmol/L)", y = "Type 2 diabetes odds ratio (fasting glucose >7.0mmol/L)") +
        theme(axis.text = element_text(size = rel(0.8), colour = "white")) 
ggsave(file = "Fig04.png", plot = fig4, width = 12, height = 6, units = "in", dpi = 300)
# fig6 <- fig6 + labs(
#     x = "Fasting plasma glucose per allele effect (mmol/L)",
#     y = expression(atop("Type 2 diabetes hazard ratio", paste("(fasting plasma glucose " >= "7.0mmol/L)")))
# )+theme(axis.text = element_text(size = rel(0.8), colour = "white"))
# ggsave(file = "Fig06.png", plot = fig6, width = 12, height = 6, units = "in", dpi = 300)
# fig7 <- fig7 + labs(
#     x = "Fasting plasma glucose per allele effect (mmol/L)",
#     y = expression(atop("Type 2 diabetes hazard ratio", paste("(fasting plasma glucose " >= "7.0mmol/L)")))
# )+theme(axis.text = element_text(size = rel(0.8), colour = "white"))
# ggsave(file = "Fig07.png", plot = fig7, width = 12, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig08.png", plot = fig8+theme(axis.text = element_text(size = rel(0.8), colour = "white")), width = 7.5, height = 6, units = "in", dpi = 300)
ratio.p <- 9/10
fig9.p1 <- fig9.p1+theme(axis.text = element_text(size = rel(0.8), colour = "white")) + labs(y = bquote("RMSE"==sqrt(symbol(E)((hat(alpha)-alpha)^2)))) +
    theme(
        axis.line = element_line(colour = "white"),
        strip.background = element_rect(fill = "grey20", colour = "white"),
        panel.grid.minor = element_line(colour = "grey40", size = rel(0.25)),
        panel.grid.major = element_line(size = rel(0.5)),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank()
    )
fig9.p2 <- fig9.p2+theme(axis.text = element_text(size = rel(0.8), colour = "white")) + labs(y = bquote("RMSE"==sqrt(symbol(E)((hat(alpha)-alpha)^2)))) +
    theme(
        axis.line = element_line(colour = "white"),
        strip.background = element_rect(fill = "grey20", colour = "white"),
        panel.grid.minor = element_line(colour = "grey40", size = rel(0.25)),
        panel.grid.major = element_line(size = rel(0.5)),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank()
    )
fig9 <- ggdraw(plot = ggplot()+theme_black(base_size = 14)+theme(plot.background = element_rect(colour = "grey20", fill = "grey20")), theme_dark = TRUE) +
    draw_plot(fig9.p1 + theme(legend.position = "none") + theme(
        axis.line = element_line(colour = "white"),
        strip.background = element_rect(fill = "grey20", colour = "white")
    ), x = 0, y = 1-ratio.p, width = 0.575, height = ratio.p) +
    draw_plot(fig9.p2 + theme(legend.position = "none") + theme(
        axis.line = element_line(colour = "white"),
        strip.background = element_rect(fill = "grey20", colour = "white")
    ), x = 0.575, y = 1-ratio.p, width = 0.425, height = ratio.p) +
    draw_plot(get_legend(fig9.p1 + theme(legend.direction = "horizontal")), x = 0, y = 0, width = 1, height = 1-ratio.p) +
    draw_plot_label(label = c("A", "B"), x = c(0, 0.575), y = c(1, 1), colour = "white")
ggsave(file = "Fig09.png", plot = fig9, width = 12, height = 6, units = "in", dpi = 300)
fig10 <- fig10+theme(axis.text = element_text(size = rel(0.8), colour = "white")) +
    theme(
        axis.line = element_line(colour = "white"),
        strip.background = element_rect(fill = "grey20", colour = "white"),
        panel.grid.minor = element_line(colour = "grey40", size = rel(0.25)),
        panel.grid.major = element_line(size = rel(0.5)),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank()
    ) +
    labs(y = bquote("RMSE"==sqrt(symbol(E)((hat(gamma)-gamma)^2)))) +
    theme(legend.position = "bottom") +
    scale_fill_manual(
        breaks = c("JointModel", "MixedModel", "SurvivalModelTime"),
        labels = c("Joint Model", "Two Step", "Cox Model with\ntime varying covariate"),
        values = c("#3B528B", "#287C8E", "#5DC863")
    )
ggsave(file = "Fig10.png", plot = fig10, width = 12, height = 6, units = "in", dpi = 300)
fig11 <- fig11+theme(axis.text = element_text(size = rel(0.8), colour = "white")) +
    theme(
        axis.line = element_line(colour = "white"),
        strip.background = element_rect(fill = "grey20", colour = "white"),
        panel.grid.minor = element_line(colour = "grey40", size = rel(0.25)),
        panel.grid.major = element_line(size = rel(0.5)),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank()
    ) +
    labs(y = bquote("RMSE"==sqrt(symbol(E)((hat(beta)-beta)^2)))) +
    theme(legend.position = "bottom") +
    scale_fill_manual(
        breaks = c("JointModel", "TwoStep", "SurvivalModelTime"),
        labels = c("Joint Model", "Two Step", "Cox Model with\ntime varying covariate"),
        values = c("#3B528B", "#287C8E", "#5DC863")
    )
ggsave(file = "Fig11.png", plot = fig11, width = 12, height = 6, units = "in", dpi = 300)
ggsave(file = "Fig12.png", plot = fig12, width = 12, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig13.png", plot = fig13+theme(axis.text = element_text(size = rel(0.8), colour = "white")), width = 7.5, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig14.png", plot = fig14+theme(axis.text = element_text(size = rel(0.8), colour = "white")), width = 7.5, height = 6, units = "in", dpi = 300)
ggsave(file = "Fig15.png", plot = fig17, width = 12, height = 6, units = "in", dpi = 300)


load("DataFiguresBlack2.Rdata")
# ggsave(file = "Fig16.png", plot = fig1, width = 7.5, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig16.png", plot = fig2+theme(axis.text = element_text(size = rel(0.8), colour = "white")), width = 7.5, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig18.png", plot = fig3, width = 12, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig19.png", plot = fig4, width = 12, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig20.png", plot = fig5, width = 12, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig21.png", plot = fig6, width = 12, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig17.png", plot = fig7, width = 7.5, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig18.png", plot = fig8, width = 7.5, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig24.png", plot = fig9, width = 12, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig25.png", plot = fig10, width = 12, height = 6, units = "in", dpi = 300)

# fig11 <- plot_grid(
#     fig7 + coord_cartesian(
#         xlim = range(c(fig7$data[, "x"], fig8$data[, "x"])),
#         ylim = range(c(fig7$data[, "y"], fig8$data[, "y"]))
#     ),
#     fig8 + coord_cartesian(
#         xlim = range(c(fig7$data[, "x"], fig8$data[, "x"])),
#         ylim = range(c(fig7$data[, "y"], fig8$data[, "y"]))
#     ), ncol = 2, theme_dark = TRUE
# )
# ggsave(file = "Fig19.png", plot = fig11, width = 12, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig20.png", plot = fig12, width = 7.5, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig21.png", plot = fig13, width = 7.5, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig29.png", plot = fig14, width = 7.5, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig30.png", plot = fig17, width = 12, height = 6, units = "in", dpi = 300)


###
# load(file = "App01.Rdata")
# app01 <- ggplot(data = blankdta) + theme_black(base_size = 14) +
#     geom_density(aes(x = ODdiff, y = ..scaled..), colour = viridis_pal(begin = 0.25, end = 0.25)(1), fill = viridis_pal(begin = 0.25, end = 0.25)(1), alpha = 0.75) +
#     geom_vline(xintercept = thresholdBlank, linetype = 2, colour = "firebrick2") +
#     geom_vline(xintercept = -thresholdBlank, linetype = 2, colour = "firebrick2") +
#     geom_text(label = percent(thresholdBlank), x = thresholdBlank, y = 1, colour = "firebrick2", hjust = -0.05, vjust = 1, size = 6) +
#     geom_text(label = paste0("-", percent(thresholdBlank)), x = -thresholdBlank, y = 1, colour = "firebrick2", hjust = 1.05, vjust = 1, size = 6) +
#     scale_x_continuous(labels = percent, limits = c(-1, 1)) +
#     labs(x = bquote("Relative error"~((OD[2]-OD[1])/OD[1])), y = "Density")
# ggsave(file = "Fig22.png", plot = app01, width = 7.5, height = 6, units = "in", dpi = 300)
#
# load(file = "App02.Rdata")
# app02 <- ggplot(data = dataset) + theme_black(base_size = 14) +
#     geom_density(aes(x = ODdiff, y = ..scaled..), colour = viridis_pal(begin = 0.25, end = 0.25)(1), fill = viridis_pal(begin = 0.25, end = 0.25)(1), alpha = 0.75) +
#     geom_vline(xintercept = thresholdCell, linetype = 2, colour = "firebrick2") +
#     geom_vline(xintercept = -thresholdCell, linetype = 2, colour = "firebrick2") +
#     geom_text(label = percent(thresholdCell), x = thresholdCell, y = 1, colour = "firebrick2", hjust = -0.05, vjust = 1, size = 6) +
#     geom_text(label = paste0("-", percent(thresholdCell)), x = -thresholdCell, y = 1, colour = "firebrick2", hjust = 1.05, vjust = 1, size = 6) +
#     scale_x_continuous(labels = percent, limits = c(-1, 1)) +
#     labs(x = bquote("Relative error"~((OD[2]-OD[1])/OD[1])), y = "Density")
# ggsave(file = "Fig23.png", plot = app02, width = 7.5, height = 6, units = "in", dpi = 300)
#
# load(file = "App03.Rdata")
# FCthreshold <- 1.2
# app03 <- ggplot(data = subset(foldChangedta, Samples=="Glc")) + theme_black(base_size = 14) +
#     geom_density(aes(x = Value, y = ..scaled..), colour = viridis_pal(begin = 0.25, end = 0.25)(1), fill = viridis_pal(begin = 0.25, end = 0.25)(1), alpha = 0.75) +
#     geom_vline(xintercept = FCthreshold, linetype = 2, colour = "firebrick2") +
#     geom_text(label = FCthreshold, x = FCthreshold, y = 1, colour = "firebrick2", hjust = 1.05, vjust = 1, size = 6) +
#     scale_x_continuous(limits = range(pretty_breaks()(range(foldChangedta[, "Value"], na.rm = TRUE)), na.rm = TRUE), breaks = seq(0, 12, 2)) +
#     labs(x = "Fold Change Insulin Secretion (Glc)", y = "Density")
# ggsave(file = "Fig24.png", plot = app03, width = 7.5, height = 6, units = "in", dpi = 300)
#
# load(file = "App04.Rdata")
# widthbar <- 0.9
# app04 <- ggplot(data =  subset(FullDta, !LowFC), aes(x = Samples, y = Insulin, colour = ExpType, fill = ExpType)) + theme_black(base_size = 14) +
#     geom_boxplot(fill = "grey20", outlier.shape = NA) +
#     geom_point(position = position_jitterdodge(jitter.width = widthbar/2), shape = 19) +
#     scale_colour_viridis(
#         name = NULL,
#         discrete = TRUE,
#         begin = 0.25,
#         end = 0.75,
#         labels = function (x) { gsub("CT_stat_(..).*_(.*)", "\\1_\\2", x) }
#     ) +
#     scale_fill_viridis(
#         name = NULL,
#         discrete = TRUE,
#         begin = 0.25,
#         end = 0.75,
#         labels = function (x) { gsub("CT_stat_(..).*_(.*)", "\\1_\\2", x) }
#     ) +
#     scale_x_discrete(labels = function (value) { gsub(",", ".", gsub("mM Glc", "mM\nGlc", gsub("_", " ", value))) }) +
#     scale_y_continuous(limits = c(0, 20)) +
#     labs(x = "Stimulus", y = "Insulin secretion (% of content)")  +
#     theme(legend.position = c(0, 0.95), legend.justification = c(-0.05, 1))
# ggsave(file = "Fig25.png", plot = app04, width = 7.5, height = 6, units = "in", dpi = 300)
#
#
# load(file = "App05.Rdata")
# app05 <- ggplot() +
#     theme_black(base_size = 14) +
#     geom_errorbar(data = foldChangedtaplot, aes(x = Samples, y = Mean, ymin = Mean*0.95, ymax = Mean+Sd, colour = ExpType, fill = ExpType), width = 0.2, position = position_dodge(widthbar)) +
#     geom_bar(data = foldChangedtaplot, aes(x = Samples, y = Mean, colour = ExpType, fill = ExpType), stat = "identity", position = "dodge", width = widthbar) +
#     geom_text(
#         data = foldChangedtaplot,
#         aes(x = Samples, y = Mean, label = paste0("N=", N), colour = ExpType, fill = ExpType),
#         position = position_dodge(widthbar),
#         colour = "white",
#         hjust = 0.5,
#         vjust = 2,
#         size = 5
#     ) +
#     scale_colour_viridis(name = NULL, discrete = TRUE, begin = 0.25, end = 0.75) +
#     scale_fill_viridis(name = NULL, discrete = TRUE, begin = 0.25, end = 0.75) +
#     geom_errorbarh(data = lmAnnot, aes(x = x, y = y, xmin = xmin, xmax = xmax, colour = ExpType), height = 0) +
#     geom_text(data = lmAnnot, aes(x = x, y = y, xmin = xmin, xmax = xmax, label = labels, colour = ExpType), vjust = -0.25, size = 8) +
#     scale_x_discrete(labels = function (value) {
#         gsub(",", ".",
#             gsub("+", " + ",
#                 gsub("mM Glc", "mM\nGlc",
#                     gsub("_", " ", value)
#                 ),
#                 fixed = TRUE
#             )
#         )
#     }) +
#     scale_y_continuous(limits = c(0, 2.5)) +
#     labs(x = "Stimulus", y = "Fold Change") +
#     theme(legend.position = c(1, 0.775), legend.justification = c(1, 1))
# ggsave(file = "Fig26.png", plot = app05, width = 7.5, height = 6, units = "in", dpi = 300)
#
#
# ggsave(file = "Fig27.png", plot = plot_grid(app01, app02, ncol = 2, theme_dark = TRUE, labels = c("A", "B")), width = 12, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig28.png", plot = plot_grid(app04+theme(legend.position = "none"), app05+theme(legend.position = "right", legend.justification = c(0.5, 0.5)), ncol = 2, theme_dark = TRUE, labels = c("A", "B")), width = 12, height = 6, units = "in", dpi = 300)


# load(file = "DataFiguresBlack3.Rdata")
# ggsave(file = "Fig29.png", plot = qqp, width = 7.5, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig30.png", plot = mp, width = 7.5, height = 6, units = "in", dpi = 300)
# ggsave(file = "Fig31.png", plot = p, width = 7.5, height = 6, units = "in", dpi = 300)
#
#
# source("/disks/OLD/Marie/Documents/Adipotox/Data/Heatmaps_Adipotox/Results_Graphs.R") # Next => Fig36
