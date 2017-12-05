source("/disks/RAW/Scripts/theme_black.R")
fig1 <- ggplot(data = callrateSamples) + 
    theme_black(base_size = 14) +
    geom_point(aes(x = seq(nrow(callrateSamples)), y = F_MISS), colour = viridis_pal(begin=0.25, end = 0.25)(1), shape = 1) +
    # geom_text(aes(x = seq(nrow(callrateSamples)), y = F_MISS, label = labs), hjust = 1.25, vjust = 0.5, size = 2) +
    geom_hline(aes(yintercept = callRateThreshInd), colour = myPalette[2], linetype = 2) +
    scale_y_log10(breaks = c(seq(0.2, 1, 0.2), 0.01, 0.02, 0.03, 0.05, 0.1), labels = percent(1-c(seq(0.2, 1, 0.2), 0.01, 0.02, 0.03, 0.05, 0.1))) +
    labs(x = "Individuals", y = "Call rate")
    
 fig2 <- ggplot(data = sexcheck) +
    theme_black(base_size = 14) +
    geom_point(aes(x = F, y = F_MISS, colour = STATUS, shape = SexDisc)) +
    geom_hline(yintercept = callRateThreshInd, colour = myPalette[2], linetype = 2) +
    scale_colour_viridis(discrete = TRUE, begin = 0.25, end = 0.75) +
    scale_shape_manual(values = c(1, 3)) +
    theme(legend.position = "none") +
    scale_y_log10(
        breaks = c(seq(0.2, 1, 0.2), 0.01, 0.02, 0.03, 0.05, 0.1),
        labels = percent(1-c(seq(0.2, 1, 0.2), 0.01, 0.02, 0.03, 0.05, 0.1))
    ) +
    labs(x = "Homozygosity rate", y = "Call rate")
        
fig3 <- ggplot(data = heterozygosity) +
    theme_black(base_size = 14) +
    geom_point(aes(x = F_MISS, y = hrate, colour = colour), size = 2, shape = 1) +
    scale_colour_viridis(trans = "sqrt") +
    geom_vline(aes(xintercept = callRateThreshInd), colour = myPalette[2], linetype = 2) +
    geom_hline(aes(yintercept = mean(heterozygosity[, "hrate"], na.rm = TRUE) - sd(heterozygosity[, "hrate"], na.rm = TRUE)*nSD), colour = myPalette[2], linetype = 2) +
    geom_hline(aes(yintercept = mean(heterozygosity[, "hrate"], na.rm = TRUE) + sd(heterozygosity[, "hrate"], na.rm = TRUE)*nSD), colour = myPalette[2], linetype = 2) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "none") +
    labs(x = "Call rate", y = "Heterozygosity rate") +
    scale_x_log10(breaks = c(seq(0.2, 1, 0.2), 0.01, 0.02, 0.03, 0.05, 0.1), labels = percent(1-c(seq(0.2, 1, 0.2), 0.01, 0.02, 0.03, 0.05, 0.1)))

fig4 <- ggplot(data = heterozygosity_mafinf001) +
    theme_black(base_size = 14) + 
    geom_point(aes(x = F_MISS, y = hrate, colour = colour), size = 2, shape = 1) +
    scale_colour_viridis(trans = "sqrt") +
    geom_vline(aes(xintercept = callRateThreshInd), colour = myPalette[2], linetype = 2) +
    geom_hline(aes(yintercept = mean(heterozygosity_mafinf001[, "hrate"], na.rm = TRUE) - sd(heterozygosity_mafinf001[, "hrate"], na.rm = TRUE)*nSD), colour = myPalette[2], linetype = 2) +
    geom_hline(aes(yintercept = mean(heterozygosity_mafinf001[, "hrate"], na.rm = TRUE) + sd(heterozygosity_mafinf001[, "hrate"], na.rm = TRUE)*nSD), colour = myPalette[2], linetype = 2) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "none") +
    labs(x = "Call rate (MAF<0.01)", y = "Heterozygosity rate") +
    scale_x_log10(breaks = c(seq(0.2, 1, 0.2), 0.01, 0.02, 0.03, 0.05, 0.1), labels = percent(1-c(seq(0.2, 1, 0.2), 0.01, 0.02, 0.03, 0.05, 0.1)))

fig5 <- ggplot(data = subset(heterozygosity, F_MISS<callRateThreshInd)) +
    theme_black(base_size = 14) +
    geom_point(aes(x = F_MISS, y = hrate, colour = colour), size = 2, shape = 1) +
    scale_colour_viridis(trans = "sqrt") +
    geom_vline(aes(xintercept = callRateThreshInd), colour = myPalette[2], linetype = 2) +
    geom_hline(aes(yintercept = mean(subset(heterozygosity, F_MISS<callRateThreshInd)[, "hrate"], na.rm = TRUE) - sd(subset(heterozygosity, F_MISS<callRateThreshInd)[, "hrate"], na.rm = TRUE)*nSD), colour = myPalette[2], linetype = 2) +
    geom_hline(aes(yintercept = mean(subset(heterozygosity, F_MISS<callRateThreshInd)[, "hrate"], na.rm = TRUE) + sd(subset(heterozygosity, F_MISS<callRateThreshInd)[, "hrate"], na.rm = TRUE)*nSD), colour = myPalette[2], linetype = 2) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "none") +
    labs(x = paste("Call rate", percent(1-callRateThreshInd)), y = "Heterozygosity rate") +
    scale_x_continuous(breaks = c(seq(0.2, 1, 0.2), 0.01, 0.02, 0.03, 0.05, 0.1), labels = percent(1-c(seq(0.2, 1, 0.2), 0.01, 0.02, 0.03, 0.05, 0.1)))

fig6 <- ggplot(data = subset(heterozygosity_mafinf001, F_MISS<callRateThreshInd)) +
    theme_black(base_size = 14) +
    geom_point(aes(x = F_MISS, y = hrate, colour = colour), size = 2, shape = 1) +
    scale_colour_viridis(trans = "sqrt") +
    geom_vline(aes(xintercept = callRateThreshInd), colour = myPalette[2], linetype = 2) +
    geom_hline(aes(yintercept = mean(subset(heterozygosity_mafinf001, F_MISS<callRateThreshInd)[, "hrate"], na.rm = TRUE) - sd(subset(heterozygosity_mafinf001, F_MISS<callRateThreshInd)[, "hrate"], na.rm = TRUE)*nSD), colour = myPalette[2], linetype = 2) +
    geom_hline(aes(yintercept = mean(subset(heterozygosity_mafinf001, F_MISS<callRateThreshInd)[, "hrate"], na.rm = TRUE) + sd(subset(heterozygosity_mafinf001, F_MISS<callRateThreshInd)[, "hrate"], na.rm = TRUE)*nSD), colour = myPalette[2], linetype = 2) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "none") +
    labs(x = paste("Call rate", percent(1-callRateThreshInd), "(MAF<0.01)"), y = "Heterozygosity rate") +
    scale_x_continuous(breaks = c(seq(0.2, 1, 0.2), 0.01, 0.02, 0.03, 0.05, 0.1), labels = percent(1-c(seq(0.2, 1, 0.2), 0.01, 0.02, 0.03, 0.05, 0.1)))
        

fig7 <- ggplot(data = dataTmp[dataTmp[, "Population"]!="RawData", ], aes(colour = Population)) +
    theme_black(base_size = 14) +
    geom_hline(aes(yintercept = 0), colour = "white") +
    geom_vline(aes(xintercept = 0), colour = "white") +
    geom_point(aes(x = x, y = y), size = 0.75) +
    geom_segment(aes(x = x.centroid, y = y.centroid, xend = x, yend = y), size = 0.25) +
    geom_label_repel(
        data = centroids[centroids[, "Population"]!="RawData", ],
        aes_string(x = "x.centroid", y = "y.centroid", label = "Population", fill = "Population"),
        colour = "white",
        size = 4
    ) +
    scale_shape_manual(values = rep(seq(5), 3)[seq(14)]) +
    scale_colour_viridis(discrete = TRUE) +
    scale_fill_viridis(discrete = TRUE) +
    # theme(legend.position = "right", legend.justification = c(0.5, 0.5)) +
    theme(legend.position = "none", legend.justification = c(0.5, 0.5)) +
    labs(x = "First Principal Component", y = "Second Principal Component") +
    guides(colour = guide_legend(override.aes = list(size = 3), ncol = 2))

fig8<- ggplot(data = na.exclude(dataRecruit[dataRecruit[, "Population"]=="RawData" & dataRecruit[, "Cohort"]=="DESIR", ])) +
    theme_black(base_size = 14) +
    geom_hline(aes(yintercept = 0), colour = "white") +
    geom_vline(aes(xintercept = 0), colour = "white") +
    geom_point(aes_string(x = "x", y = "y", colour = "Cohort"), size = 0.75) +
    geom_segment(aes_string(x = "x.centroid", y = "y.centroid", xend = "x", yend = "y", colour = "Cohort"), size = 0.25) +
    scale_shape_manual(values = rep(seq(5), 3)[seq(14)]) +
    scale_colour_viridis(discrete = TRUE, begin = 0.25, end = 0.25) +
    scale_fill_viridis(discrete = TRUE, begin = 0.25, end = 0.25) +
    theme(legend.position = c(1, 0), legend.justification = c(1, 0)) +
    guides(colour = guide_legend(override.aes = list(size = 3), title = "Cohort")) +
    labs(x = "First Principal Component", y = "Second Principal Component")

fig9 <- fig7 + coord_cartesian(
    xlim = range(dataTmp[dataTmp[, "Population"]=="RawData", "x"]),
    ylim = range(dataTmp[dataTmp[, "Population"]=="RawData", "y"])
)
fig10 <- fig8 + coord_cartesian(
    xlim = range(dataTmp[dataTmp[, "Population"]=="RawData", "x"]),
    ylim = range(dataTmp[dataTmp[, "Population"]=="RawData", "y"])
)

fig12 <- ggplot(data = subset(dataRecruitDirect, Cohort=="DESIR")) +
    theme_black(base_size = 14) + 
    geom_point(aes(x = PC1, y = PC2, colour = as.factor(Cohort), shape = as.factor(Extremes)), size = 1) +
    scale_shape_manual(guide = FALSE, values = c(1, 3)) +
    scale_colour_viridis(name = "Cohort", discrete = TRUE, begin = 0.25, end = 0.25) +
    scale_fill_viridis(name = "Cohort", discrete = TRUE, begin = 0.25, end = 0.25) +
    guides(colour = guide_legend(override.aes = list(size = 3))) +
    geom_hline(aes(yintercept = 0), colour = "white", linetype = 2) +
    geom_vline(aes(xintercept = 0), colour = "white", linetype = 2) +
    labs(x = "First Principal Component", y = "Second Principal Component")
        
fig13 <- ggplot(data = inertia[seq(10), ], aes(x = x, y = y)) + 
    theme_black(base_size = 14) +
    geom_bar(stat = "identity", width = 0.5, colour = viridis_pal(begin=0.25, end=0.25)(1), fill = viridis_pal(begin=0.25, end=0.25)(1)) +
    labs(y = "Inertia", x = "PCA Components") +
    scale_x_continuous(breaks = seq_len(10), expand = c(0, 0)) +
    scale_y_continuous(labels = percent)

fig14 <- lapply(seq(ncol(plotPCA)), function (iComb) {
    ggplot(data = subset(dataRecruitDirect, Cohort=="DESIR")) +
        theme_black(base_size = 14) +
        geom_point(aes_string(x = paste0("PC", plotPCA[1, iComb]), y = paste0("PC",  plotPCA[2, iComb]), colour = "Cohort"), size = 1) +
        scale_shape_manual(guide = FALSE, values = c(1, 3)) +
        scale_colour_viridis(name = "Cohort", discrete = TRUE, begin = 0.25, end = 0.25) +
        scale_fill_viridis(name = "Cohort", discrete = TRUE, begin = 0.25, end = 0.25) +
        guides(colour = guide_legend(override.aes = list(size = 3))) +
        geom_hline(aes(yintercept = 0), colour = "white", linetype = 2) +
        geom_vline(aes(xintercept = 0), colour = "white", linetype = 2) +
        theme(legend.position = "none")
})
    
fig15 <- ggplot(data = callratesnp) + 
    theme_black(base_size = 14) +
    geom_point(aes(x = seq(nrow(callratesnp)), y = F_MISS), colour = viridis_pal(begin=0.25, end=0.25)(1), shape = 1) +
    geom_hline(aes(yintercept = callRateThreshSNP), colour = myPalette[2], linetype = 2) +
    scale_y_log10(
        breaks = c(seq(0.2, 1, 0.2), 0.01, 0.02, 0.03, 0.05, 0.1),
        labels = percent(1-c(seq(0.2, 1, 0.2), 0.01, 0.02, 0.03, 0.05, 0.1))
    ) +
    labs(x = "Cohort (Variants)", y = "Call rate")
    
fig16 <- ggplot(data = freqsnpnoNA) + 
    theme_black(base_size = 14) + 
    geom_bar(aes(x = mafdist), fill =  viridis_pal(begin=0.25, end=0.25)(1)) +
    labs(x = "MAF", y = "Number of SNPs")
        
fig17 <- ggplot(data = hardyweinberg0001) + 
    theme_black(base_size = 14) +
    geom_point(aes(x = seq(nrow(hardyweinberg0001)), y = P), colour = viridis_pal(begin=0.25, end=0.25)(1), size = 2, shape = 1) +
    geom_hline(aes(yintercept = hwepvalues/10), colour = myPalette[2]) +
    scale_y_continuous(breaks = yscale, labels = yscaleLabs) +
    labs(x = "Cohort (Variants)", y = "Hardy-Weinberg Equilibrium Pvalue")
    
save(list = setdiff(grep("^fig.*", ls(), value = TRUE), "figCounter"), file = "/disks/PROJECT/Mickael/COMMUNICATION/BeamerThesis/images/DataFiguresBlack2.Rdata")