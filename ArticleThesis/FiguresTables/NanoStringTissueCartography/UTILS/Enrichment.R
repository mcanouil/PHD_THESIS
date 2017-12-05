###############################################################
# Enrichment functions


###############################################################
plot.enrichment <- function (resout, reasonName = "Characteristics of the genes") {
    dta <- cbind.data.frame(
        stack(as.data.frame(resout)),
        Tissues = rep(row.names(resout), ncol(resout))
    )
    dta[, "ind"] <- as.factor(gsub("[.]", " ", dta[, "ind"]))
    dta[, "ind"] <- factor(dta[, "ind"], levels = colnames(resout))
    dta[, "values"] <- -log10(dta[, "values"])
    dta[, "Tissues"] <- factor(dta[, "Tissues"], levels = row.names(resout))
    plot.resout <- ggplot(data = dta, aes(x = Tissues, y = values, fill = ind)) +
        geom_bar(stat = "identity", position = position_dodge(), width = 0.75) +
        geom_abline(intercept = -log10(0.05), slope = 0) +
        geom_vline(xintercept = seq_len(max(length(unique(dta[, "Tissues"]))-1, 0))+0.5, colour = "grey", size = 0.5) +
        scale_fill_viridis(name = reasonName, discrete = TRUE, option = "viridis") +
        labs(x = "Samples", y = bquote(-log[10]~"Pvalue")) +
        coord_flip() +
        scale_y_continuous(expand = c(0, 0), limits = c(0, max(c(dta[, "values"], 0.05, na.rm = TRUE))*1.05))
    return(plot.resout)
}

###############################################################
plot.enrichment_count <- function (resout, reasonName = "Characteristics of the genes") {
    dta <- cbind.data.frame(
        stack(as.data.frame(resout)),
        Tissues = rep(row.names(resout), ncol(resout))
    )
    dta[, "ind"] <- as.factor(gsub("[.]", " ", dta[, "ind"]))
    dta[, "ind"] <- factor(dta[, "ind"], levels = colnames(resout))
    # dta[, "values"] <- 100*(dta[, "values"])
    dta[, "Tissues"] <- factor(dta[, "Tissues"], levels = row.names(resout))
    plot.resout <- ggplot(data = dta, aes(x = Tissues, y = values, fill = ind)) +
        geom_bar(stat = "identity", position = position_dodge(), width = 0.75) +
        # geom_abline(intercept = -log10(0.05), slope = 0) +
        geom_vline(xintercept = seq_len(max(length(unique(dta[, "Tissues"]))-1, 0))+0.5, colour = "grey", size = 0.5) +
        scale_fill_viridis(name = reasonName, discrete = TRUE, option = "viridis") +
        labs(x = "Samples", y = "Ratio of expressed genes") +
        coord_flip() +
        scale_y_continuous(labels = percent, expand = c(0, 0), limits = c(0, max(c(dta[, "values"], 0.05, na.rm = TRUE))*1.05))
    return(plot.resout)
}


###############################################################
enrichmentGroupMk <- function (reason, geneSet = NULL, returnOdds = FALSE, threshold = 1, referenceSet = "all", sampleID = sampleID, data.norm = normalised.data, subset.tissue = NULL, genesData) {
    subset.tissue <- intersect(intersect(subset.tissue, colnames(data.norm)), rownames(sampleID))
    sampleID <- sampleID[subset.tissue, , drop = FALSE]
    sampleID <- sampleID[order(sampleID[, "Order"]), ]
    dta <- data.norm[, rownames(sampleID), drop = FALSE]

    if (is.null(geneSet)) {
        geneSet <- unique(as.character(unlist(lapply(reason, function (ireason) {
            genesData[genesData[, "enrichmentMkGroup"] %in% ireason, "Accession"]
        }))))
    } else {}

    dta.genes <- t(dta[geneSet, , drop = FALSE])
    thresholdAd <- colMeans(dta.genes, na.rm = TRUE) + apply(dta.genes, 2, sd, na.rm = TRUE)*threshold
    dta.genes <- dta.genes>thresholdAd
    dta.genes[is.na(dta.genes)] <- FALSE
    dta.genes <- cbind.data.frame(dta.genes, Groups = sampleID[, "Groups"])
    countsExp_permk <- aggregate(. ~ Groups, dta.genes, function (x) {floor(sum(x)/length(x))})
    countsExp_permk[, "Enrich.TRUE"] <- rowSums(countsExp_permk[, geneSet])
    countsExp_permk[, "Enrich.FALSE"] <- length(geneSet) - countsExp_permk[, "Enrich.TRUE"]

    res <- do.call("rbind", lapply(seq_len(nrow(countsExp_permk)), function (i) {
        tabCounts <- rbind(
            countsExp_permk[i, c("Enrich.TRUE", "Enrich.FALSE")],
            colSums(countsExp_permk[-i, c("Enrich.TRUE", "Enrich.FALSE")])
        )
        res <- cbind.data.frame(Groups = countsExp_permk[i, "Groups"], tidy(fisher.test(tabCounts, alternative = "greater")))
        return(res)
    }))
    rownames(res) <- res[, "Groups"]
    if (returnOdds) {
        return(res[, "estimate", drop = FALSE])
    } else {
        return(res[, "p.value", drop = FALSE])
    }
}

###############################################################
enrichmentSampleMk <- function (reason, geneSet = NULL, returnOdds = FALSE, threshold = 1, referenceSet = "all", sampleID = sampleID, data.norm = normalised.data, subset.tissue = NULL, genesData) {
    subset.tissue <- intersect(intersect(subset.tissue, colnames(data.norm)), rownames(sampleID))
    sampleID <- sampleID[subset.tissue, , drop = FALSE]
    sampleID <- sampleID[order(sampleID[, "Order"]), ]
    dta <- data.norm[, rownames(sampleID), drop = FALSE]

    if (is.null(geneSet)) {
        geneSet <- unique(as.character(unlist(lapply(reason, function (ireason) {
            genesData[genesData[, "enrichmentMkGroup"]%in%ireason, "Accession"]
        }))))
    } else {}

    dta.genes <- t(dta[geneSet, ])
    thresholdAd <- colMeans(dta.genes, na.rm = TRUE) + apply(dta.genes, 2, sd, na.rm = TRUE)*threshold
    dta.genes <- dta.genes>thresholdAd
    dta.genes[is.na(dta.genes)] <-  FALSE
    countsExp_permk <- cbind.data.frame(dta.genes, Groups = rownames(sampleID))
    countsExp_permk[, "Enrich.TRUE"] <- rowSums(countsExp_permk[, geneSet])
    countsExp_permk[, "Enrich.FALSE"] <- length(geneSet) - countsExp_permk[, "Enrich.TRUE"]
    res <- do.call("rbind", lapply(seq_len(nrow(countsExp_permk)), function (i) {
        tabCounts <- rbind(
            countsExp_permk[i, c("Enrich.TRUE", "Enrich.FALSE")],
            colSums(countsExp_permk[-i, c("Enrich.TRUE", "Enrich.FALSE")])
        )
        res <- cbind.data.frame(Groups = countsExp_permk[i, "Groups"], tidy(fisher.test(tabCounts, alternative = "greater")))
        return(res)
    }))
    rownames(res) <- res[, "Groups"]
    if (returnOdds) {
        return(res[, "estimate", drop = FALSE])
    } else {
        return(res[, "p.value", drop = FALSE])
    }
}



###############################################################
enrichmentGroupGene <- function (reason, geneSet = NULL, returnOdds = FALSE, threshold = 1, referenceSet = "all", sampleID = sampleID, data.norm = normalised.data, subset.tissue = NULL, genesData) {
    subset.tissue <- intersect(intersect(subset.tissue, colnames(data.norm)), rownames(sampleID))
    sampleID <- sampleID[subset.tissue, , drop = FALSE]
    sampleID <- sampleID[order(sampleID[, "Order"]), ]
    dta <- data.norm[, rownames(sampleID), drop = FALSE]

    if (is.null(geneSet)) {
        geneSet <- unique(as.character(unlist(lapply(reason, function (ireason) {
            genesData[genesData[, "enrichmentGeneGroup"] %in% ireason, "Accession"]
        }))))
    } else {}

    dta.genes <- t(dta[geneSet, , drop = FALSE])
    thresholdAd <- colMeans(dta.genes, na.rm = TRUE) + apply(dta.genes, 2, sd, na.rm = TRUE)*threshold
    dta.genes <- dta.genes>thresholdAd
    dta.genes[is.na(dta.genes)] <- FALSE
    dta.genes <- cbind.data.frame(dta.genes, Groups = sampleID[, "Groups"])
    countsExp_permk <- aggregate(. ~ Groups, dta.genes, function (x) {floor(sum(x)/length(x))})
    countsExp_permk[, "Enrich.TRUE"] <- rowSums(countsExp_permk[, geneSet])
    countsExp_permk[, "Enrich.FALSE"] <- length(geneSet) - countsExp_permk[, "Enrich.TRUE"]

    res <- do.call("rbind", lapply(seq_len(nrow(countsExp_permk)), function (i) {
        # tabCounts <- rbind(
            # countsExp_permk[i, c("Enrich.TRUE", "Enrich.FALSE")],
            # colSums(countsExp_permk[-i, c("Enrich.TRUE", "Enrich.FALSE")])
        # )
        # res <- cbind.data.frame(Groups = countsExp_permk[i, "Groups"], tidy(fisher.test(tabCounts, alternative = "greater")))
        res <- cbind.data.frame(
            Groups = countsExp_permk[i, "Groups"],
            p.value = countsExp_permk[i, c("Enrich.TRUE")]/sum(countsExp_permk[i, c("Enrich.TRUE", "Enrich.FALSE")])
        )
        return(res)
    }))
    rownames(res) <- res[, "Groups"]
    if (returnOdds) {
        return(res[, "estimate", drop = FALSE])
    } else {
        return(res[, "p.value", drop = FALSE])
    }
}

###############################################################
enrichmentSampleGene <- function (reason, geneSet = NULL, returnOdds = FALSE, threshold = 1, referenceSet = "all", sampleID = sampleID, data.norm = normalised.data, subset.tissue = NULL, genesData) {
    subset.tissue <- intersect(intersect(subset.tissue, colnames(data.norm)), rownames(sampleID))
    sampleID <- sampleID[subset.tissue, , drop = FALSE]
    sampleID <- sampleID[order(sampleID[, "Order"]), ]
    dta <- data.norm[, rownames(sampleID), drop = FALSE]

    if (is.null(geneSet)) {
        geneSet <- unique(as.character(unlist(lapply(reason, function (ireason) {
            genesData[genesData[, "enrichmentGeneGroup"] %in% ireason, "Accession"]
        }))))
    } else {}

    dta.genes <- t(dta[geneSet, ])
    thresholdAd <- colMeans(dta.genes, na.rm = TRUE) + apply(dta.genes, 2, sd, na.rm = TRUE)*threshold
    dta.genes <- dta.genes>thresholdAd
    dta.genes[is.na(dta.genes)] <-  FALSE
    countsExp_permk <- cbind.data.frame(dta.genes, Groups = rownames(sampleID))
    countsExp_permk[, "Enrich.TRUE"] <- rowSums(countsExp_permk[, geneSet])
    countsExp_permk[, "Enrich.FALSE"] <- length(geneSet) - countsExp_permk[, "Enrich.TRUE"]
    res <- do.call("rbind", lapply(seq_len(nrow(countsExp_permk)), function (i) {
        # tabCounts <- rbind(
            # countsExp_permk[i, c("Enrich.TRUE", "Enrich.FALSE")],
            # colSums(countsExp_permk[-i, c("Enrich.TRUE", "Enrich.FALSE")])
        # )
        # res <- cbind.data.frame(Groups = countsExp_permk[i, "Groups"], tidy(fisher.test(tabCounts, alternative = "greater")))
        res <- cbind.data.frame(
            Groups = countsExp_permk[i, "Groups"],
            p.value = countsExp_permk[i, c("Enrich.TRUE")]/sum(countsExp_permk[i, c("Enrich.TRUE", "Enrich.FALSE")])
        )
        return(res)
    }))
    rownames(res) <- res[, "Groups"]
    if (returnOdds) {
        return(res[, "estimate", drop = FALSE])
    } else {
        return(res[, "p.value", drop = FALSE])
    }
}


###############################################################
# enrichment <- function (reason, geneSet = NULL, returnOdds = FALSE, threshold = 1, referenceSet = "all", sampleID = sampleID, normSet = normSet, expressions = expressions, genes = genes, normalization = normalization) {
    # dta <- normalization(normSet = normSet, expressions = expressions, genes = genes)[, !is.na(sampleID[, "Order"]), drop = FALSE]
    # dta <- dta[, order(na.exclude(sampleID[, "Order"]))]
    # Groups <- na.omit(sampleID[order(sampleID[, "Order"]), ])[, "Groups"]
    # colnames(dta) <- na.omit(sampleID[order(sampleID[, "Order"]), ])[, "FullName"]
    # TissueID <- as.factor(gsub(" [0-9]$", "", colnames(dta)))
    # TissueID <- factor(TissueID, levels = unique(TissueID))
    # Groups <- factor(Groups, levels = unique(Groups))

    # if (is.null(geneSet)) {
        # geneSet <- unique(as.character(unlist(lapply(reason, function (ireason) {
            # genes[which(genes[, "Reason"] %in% ireason), "Accession"]
        # }))))
    # } else {}

    # dta.genes <- t(dta[geneSet, ])
    # thresholdAd <- colMeans(dta.genes, na.rm = TRUE) + apply(dta.genes, 2, sd, na.rm = TRUE)*threshold
    # dta.genes <- dta.genes>thresholdAd
    # dta.genes[ is.na(dta.genes)] <- 0
    # countsExp <- as.numeric(by(dta.genes, TissueID, sum))
    # countsTissus <- ncol(dta.genes) * summary(TissueID)

    # res <- lapply(seq_along(levels(TissueID)), function (i) {
        # if (referenceSet == "all") {
            # refIndex <- unlist(sapply(unique(TissueID[grep(Groups[grep(levels(TissueID)[i], TissueID)[1]], Groups)]), grep, levels(TissueID)))
            # tabCounts <- matrix(
                # c(
                    # countsExp[i],
                    # countsTissus[i] - countsExp[i],
                    # sum(countsExp[-refIndex]),
                    # sum((countsTissus - countsExp)[-refIndex])
                # ),
                # nrow = 2,
                # ncol = 2,
                # byrow = TRUE
            # )
        # } else {}
        # res <- fisher.test(tabCounts, alternative = "greater")
        # return(res)
    # })
    # if (returnOdds) {
        # res <- as.numeric(simplify2array(res)[3, ])
    # } else {
        # res <- as.numeric(simplify2array(res)[1, ])
    # }
    # names(res) <- levels(TissueID)
    # return(res)
# }
