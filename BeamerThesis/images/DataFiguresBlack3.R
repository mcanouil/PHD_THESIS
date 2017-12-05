rm(list = ls())
options(stringsAsFactors = FALSE)

myHome <- "/disks/DATA/"
dir.create(paste0(myHome, "Epigenetic_PDGFA/Pictures"))
setwd(paste0(myHome, "Epigenetic_PDGFA/"))
# ggsave(file = "Pictures/.png", plot = p, width = 7.5, height = 6, units = "in", dpi = 300)
# ggsave(file = "Pictures/.png", plot = p, width = 12, height = 6, units = "in", dpi = 300)


### Define nCores
    nCores <- 48


### Load packages
    library(parallel)
    library(ggplot2)
    library(grid)
    library(scales)
    library(xlsx)
    library(tidyr)
    library(broom)
    library(cowplot)
    library(viridis)
    source("/disks/RAW/Scripts/theme_black.R")
    
### Load data
    load(file = "assocMethAdj.Rdata")
    load(file = "assocMethAdjRefFree.Rdata")
    Kknown <- cbind.data.frame(
        myRefFree$RefFreeEWASModel$Beta[, "STATUS", drop = FALSE],
        myRefFree$seBeta[, "STATUS", drop = FALSE],
        myRefFree$RefFreeEWASModel$Beta[, "STATUS", drop = FALSE]/myRefFree$seBeta[, "STATUS", drop = FALSE],
        myRefFree$pvBeta[, "STATUS", drop = FALSE]
    )
    colnames(Kknown) <- c("Beta", "SE", "Tval", "Pval")
    Kknown <- Kknown[order(Kknown[, "Pval"]), ]
    gcCorrFactorreffree <- median(Kknown[, "Tval"]^2)/qchisq(0.5, 1)
    Kknown[, "Pcorr"] <- pchisq(q = (Kknown[, "Tval"]^2)/gcCorrFactorreffree, df = 1, lower.tail = FALSE)
    Kknown[, "Qval"] <- p.adjust(Kknown[, "Pcorr"], method = "fdr")

    assocMeth <- cbind(
        assocMethAdj[intersect(rownames(assocMethAdj), rownames(Kknown)), c("Pval", "Pcorr")],
        Kknown[intersect(rownames(assocMethAdj), rownames(Kknown)), c("Pval", "Pcorr")]
    )
    colnames(assocMeth) <- c("RAW", "COR", "RAWCELL", "CORCELL")

    dtaqqplot <- do.call("rbind", mclapply(colnames(assocMeth)[c(1, 2)], mc.cores = 4, function (i) {
        pv <- assocMeth[, i]
        names(pv) <- rownames(assocMeth)
        X2 <- qnorm(pv/2)^2
        gc <- median(X2, na.rm = TRUE)/qchisq(0.5, df = 1)
        obspval <- sort(pv)
        logobspval <- -(log10(obspval))
        exppval <- seq_along(obspval)
        logexppval <- -(log10((exppval-0.5)/length(exppval)))
        labnames <- round(gc, 4)
        tmp <- data.frame(
            logexppval,
            logobspval,
            labnames,
            i,
            labels = ifelse(names(logobspval)%in%"cg14496282", "cg14496282\n  (PDGFA)", "")
        )
        return(tmp)
    }))
    dtaqqplot[dtaqqplot[, "labels"]!="" & dtaqqplot[, "i"]=="Pval", "labels"] <- ""
    lambdanames <- unique(dtaqqplot[, c("labnames", "i")])
    lambdanames[, "i"] <- factor(
        lambdanames[, "i"],
        levels = sort(lambdanames[, "i"], decreasing = TRUE)
    )
    dtaqqplot[, "labnames"] <- factor(
        paste(dtaqqplot[, "i"], dtaqqplot[, "labnames"], sep = "="),
        levels = sort(unique(paste(dtaqqplot[, "i"], dtaqqplot[, "labnames"], sep = "=")), decreasing = TRUE)
    )

    library(dplyr)
    qqp <- ggplot(data = dtaqqplot) + 
        theme_black(base_size = 14) +
        geom_abline(intercept = 7, slope = 0, colour = "firebrick2", linetype = 2) +
        geom_abline(intercept = 0, slope = 1, colour = "white") +
        geom_point(aes(x = logexppval, y = logobspval, shape = labels, size = labels, alpha = labels, colour = labnames)) +
        geom_label(data = subset(dtaqqplot, labels!="", c(1, 2, 5)) %>% summarise(x = mean(logexppval), y = mean(logobspval), labels = unique(labels)), aes(x = x, y = y, label = labels), colour = viridis_pal(begin = 0.5, end = 0.5)(1), hjust = 0, vjust = 0.5, size = 4, inherit.aes = FALSE) +
        labs(
            x = bquote(Expected -log[10](P[value])),
            y = bquote(Observed -log[10](P[value]))
        ) +
        scale_shape_manual(values = c(20, 18)) +
        scale_alpha_manual(values = c(1, 1)) +
        scale_size_manual(values = c(3, 4)) +
        scale_colour_viridis(
            name = NULL,
            labels = c(
                bquote(lambda[GC]^.(as.character(lambdanames[1, "i"])) == .(round(lambdanames[1, "labnames"], 1))),
                bquote(lambda[GC]^.(as.character(lambdanames[2, "i"])) == .(round(lambdanames[2, "labnames"], 1)))
            ),
            discrete = TRUE,
            begin = 0.25,
            end = 0.75
        ) +
        guides(shape = FALSE, size = FALSE, alpha = FALSE) +
        theme(legend.position = c(0, 1), legend.justification = c(0, 1)) +
        scale_x_continuous(breaks = pretty_breaks(3)(seq_len(9)), limits = c(0, 9)) +
        scale_y_continuous(breaks = pretty_breaks(3)(seq_len(9)), limits = c(0, 9))
        
    load("../../OLD/ABOS_Methylation_StephaneCauchi/Run/Mstory/Meth_Expr_QC.Rdata")
    lz <- cbind(assocMethAdj[, c("Beta", "SE", "Pcorr")], meth.annot[rownames(assocMethAdj), c("chr", "pos", "Name", "UCSC_RefGene_Name")])
    lz <- lz[which(lz$chr=="chr7"), ]
    lz <- lz[which(abs(lz$pos-544525)<50000), ]
    gs <- 536.897
    ge <- 559.481
    lz[, "labels"] <- ifelse(rownames(lz)%in%"cg14496282", "cg14496282", "")
    mp <- ggplot(data = lz, aes(x = pos/1000, y = -log10(Pcorr))) + 
        theme_black(base_size = 14) +
        geom_abline(intercept = 7, slope = 0, colour = "firebrick2", linetype = 2) +
        geom_vline(xintercept = gs, colour = viridis_pal(begin = 0.5, end = 0.5)(1), linetype = 2) +
        geom_vline(xintercept = ge, colour = viridis_pal(begin = 0.5, end = 0.5)(1), linetype = 2) +
        geom_point(aes(shape = labels, size = labels, alpha = labels), fill = viridis_pal(begin = 0.75, end = 0.75)(1)) +
        geom_text(aes(label = labels), size = 4, colour = viridis_pal(begin = 0.5, end = 0.5)(1), vjust = 2) +
        geom_segment(
            aes(x = gs, y = 4, xend = ge, yend = 4),
            arrow = arrow(length = unit(0.03, "npc"), ends = "both"),
            colour = viridis_pal(begin = 0.5, end = 0.5)(1)
        ) +
        geom_text(aes(x = (gs+ge)/2, y = 4, label = "PDGFA"), size = 4, colour = viridis_pal(begin = 0.5, end = 0.5)(1), vjust = 2) +
        labs(
            x = "Physical position on Chromosome 7 (kb)",
            y = bquote(Observed -log[10](P[value])),
            title = ""
        ) +
        scale_x_continuous(labels = round) +
        scale_shape_manual(values = c(21, 23)) +
        scale_alpha_manual(values = c(1, 1)) +
        scale_size_manual(values = c(3, 4)) +
        guides(shape = FALSE, size = FALSE, alpha = FALSE)
        
    source("/disks/PROJECT/Epigenetic_PDGFA/Scripts/02-Epigenetic_PDGFA_Network.R")
    load(file = "/disks/PROJECT/Mickael/COMMUNICATION/BeamerThesis/images/DataFiguresBlack3.Rdata")
    save(list = c("p", "qqp", "mp", "lambdanames", "gs", "ge"), file = "/disks/PROJECT/Mickael/COMMUNICATION/BeamerThesis/images/DataFiguresBlack3.Rdata")
