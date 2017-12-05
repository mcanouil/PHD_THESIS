options(stringsAsFactors = FALSE)

### Load Data (Use GenerateAppData.R to create Base.Rdata)
    # source("../GenerateAppData.R")
    load('./www/Base.Rdata')

### Load libraries
    suppressMessages(library(shiny))
    suppressMessages(library(ggplot2))
    suppressMessages(library(scales))
    suppressMessages(library(grid))
    suppressMessages(library(FactoMineR))
    suppressMessages(library(shinydashboard))
    suppressMessages(library(gapmap))
    suppressMessages(library(ggdendro))
    suppressMessages(library(reshape))
    suppressMessages(library(broom))
    suppressMessages(library(viridis))

### Source functions
    source("UTILS/Enrichment.R")
    source("UTILS/Heatmap.R")
    source("UTILS/Normalization.R")
    source("UTILS/PCAplot.R")

### Custom ggplot theme
    mytheme <- theme_light(base_size = 14) +
        theme(
            panel.grid.major.x = element_line(size = 0.5, colour = "grey"),
            panel.grid.major.y = element_blank(),
            axis.text.y = element_text(face = "bold"),
            axis.text.x = element_text(face = "bold")
        )


shinyServer(function(input, output) {
###############################################################
### Color settings
    customcolourstable <- reactive({
        color.rgb <- t(col2rgb(colors()))
        color.hex <- rgb(color.rgb[, 1], color.rgb[, 2], color.rgb[, 3], maxColorValue = 255)
        color.df <- color.hex
        names(color.df) <- colors()
        color.df <- as.list(color.df)
        return(color.df)
    })
    output$coloursUi <- renderUI({
        color.df <- customcolourstable()
        return(box(
            selectInput(
                inputId = "customcolours",
                label = "Available Colours",
                choices = color.df,
                selected = c("#EE2C2C", "#008B45", "#EE30A7", "#EEB422", "#00BFFF", "#AB82FF"),
                width = "100%",
                selectize = FALSE,
                multiple = TRUE,
                size = 20
            ),
            width = 6,
            collapsible = FALSE,
            title = "Colours Settings",
            solidHeader = TRUE,
            status = "info",
            height = 500
        ))
    })
    myPalette <- reactive({
        validate(need(length(input$plotcolour)!=0, "No data available!"))
        if ("Custom"%in%input$plotcolour) {
            myPalette <- c(input$customcolours)
        } else {
            colorOn <- ifelse(is.null(input$plotcolour), TRUE, "Colour"%in%input$plotcolour)
            if (colorOn) {
                myPalettes <- rbind(
                    c(Name = "dodgerblue", Hex = "#1E90FF", RGB = "rgb(30/255, 144/255, 255/255)"),
                    c(Name = "firebrick2", Hex = "#EE2C2C", RGB = "rgb(238/255, 44/255, 44/255)"),
                    c(Name = "springgreen3", Hex = "#008B45", RGB = "rgb(0/255, 139/255, 69/255)"),
                    c(Name = "maroon2", Hex = "#EE30A7", RGB = "rgb(238/255, 48/255, 167/255)"),
                    c(Name = "goldenrod2", Hex = "#EEB422", RGB = "rgb(238/255, 180/255, 34/255)"),
                    c(Name = "deepskyblue", Hex = "#00BFFF", RGB = "rgb(0/255, 191/255, 255/255)"),
                    c(Name = "mediumpurple1", Hex = "#AB82FF", RGB = "rgb(171/255, 130/255, 255/255)"),
                    c(Name = "tan1", Hex = "#FFA54F", RGB = "rgb(255/255, 165/255, 79/255)")
                )
                myPalette <- myPalettes[, "Name"]
            } else {
                myPalette <- gray.colors(n = 7, start = 0.3, end = 0.75)
            }
        }
        return(myPalette)
    })

###############################################################
### NORMALISATION

###############################
## RAW EXPRESSION
#------------------------------------ Plot of the MFA
    mfaPlot.data  <- reactive({
        pos <- as.character(genes[which(genes[, "CodeClass"] == "Positive"), "Accession"])
        usual <- as.character(genes[which(genes[, "Reason"] == "housekeeping gene"), "Accession"])
        trend <- as.character(genes[which(genes[, "Reason"] == "housekeeping gene publi (Trends Genet. 2013 Oct;29(10):569-74)"), "Accession"])
        dta <- t(rbind.data.frame(expressions[pos, ], expressions[usual, ], expressions[trend, ]))
        colnames(dta) <- c(
            colnames(dta)[seq_along(pos)],
            as.character(genes[match(usual, genes[, "Accession"]), "Name"]),
            as.character(genes[match(trend, genes[, "Accession"]), "Name"])
        )
        res.raw <- MFA(
            dta,
            group = sapply(list(pos, usual, trend), length),
            type = rep("s", 3),
            name.group = c("Control probes (Spikes)", "Usual housekeeping genes", "Housekeeping genes from Eisenberg et al. (2013)"),
            graph = FALSE
        )
        return(plot.MFA(res.raw, choix = 'var', habillage = "group", cex = 0.8, shadowtext = TRUE, title = "Correlation circle of the control genes (PCA)"))
    })
    output$mfaPlot <- renderPlot({
        return(mfaPlot.data())
    })
    output$mfaPlot.download <- downloadHandler(
        filename = function () {
            paste0("CorrelationCirclePlot.",  input$plotformat)
        },
        content = function (file) {
            ggsave(file = file, plot = mfaPlot.data(), width = input$plotwidth, height = input$plotheight, units = input$plotunits, dpi = as.numeric(input$plotdpi))
        }
    )

#------------------------------------ Representation of the raw expression of the HK genes in the endobeta
    genePlot.data <- reactive({
        validate(need(!is.null(input$gene), ""))
        geneSet <- input$gene
        geneSet <- as.character(genes[match(geneSet, genes[, "Name"]), "Accession"])
        sampleSet <- grep("EndoC-BetaH1", sampleID[, "FullName"])
        data.tmp <- expressions[geneSet, sampleSet, drop = FALSE]
        data.tmp <- cbind.data.frame(
            stack(as.data.frame(data.tmp)),
            gene = rep(geneSet, ncol(data.tmp))
        )
        data.tmp[, "ind"] <- factor(
            data.tmp[, "ind"],
            levels = unique(data.tmp[, "ind"])[order(sampleID[, "Groups"], sampleID[, "SampleID"])]
        )
        p <- ggplot(data = data.tmp, aes(x = ind, y = values, group = gene, color = gene)) +
            geom_line() +
            scale_color_viridis(
                discrete = TRUE,
                option = "viridis",
                name = "Genes",
                labels = paste0(
                    levels(data.tmp[, "gene"]),
                    genes[match(unique(data.tmp[, "gene"]), genes[, "Accession"]), "Name"]
                )
            ) +
            theme_light(base_size = 14) +
            theme(
                axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)
            ) +
            labs(x = "Samples", y = "Raw expression")
        return(p)
    })
    output$genePlot <- renderPlot({
        return(genePlot.data())
    })
    output$genePlot.download <- downloadHandler(
        filename = function () {
             paste0("GenePlot.",  input$plotformat)
        },
        content = function (file) {
            ggsave(file = file, plot = genePlot.data(), width = input$plotwidth, height = input$plotheight, units = input$plotunits, dpi = as.numeric(input$plotdpi))
        }
    )

#------------------------------------ Representation of the raw expression of the HK genes in all samples
    geneAllSamplesPlot.data <- reactive({
        validate(need(!is.null(input$gene), ""))
        geneSet <- as.character(genes[match(input$gene, genes[, "Name"]), "Accession"])
        data.tmp <- expressions[geneSet, , drop = FALSE]
        data.tmp <- cbind.data.frame(
            stack(as.data.frame(data.tmp)),
            gene = rep(geneSet, ncol(data.tmp))
        )
        data.tmp[, "ind"] <- factor(
            data.tmp[, "ind"],
            levels = unique(data.tmp[, "ind"])[order(sampleID[, "Groups"], sampleID[, "SampleID"])]
        )
        p <- ggplot(data = data.tmp, aes(x = ind, y = values, group = gene, color = gene)) +
            geom_line() +
            scale_color_viridis(
                discrete = TRUE,
                option = "viridis",
                name = "Genes",
                labels = paste0(
                    levels(data.tmp[, "gene"]),
                    genes[match(unique(data.tmp[, "gene"]), genes[, "Accession"]), "Name"]
                )
            ) +
            theme_light(base_size = 14) +
            theme(
                axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)
            ) +
            labs(x = "Samples", y = "Raw expression")
        return(p)
    })
    output$geneAllSamplesPlot <- renderPlot({
        return(geneAllSamplesPlot.data())
    })
    output$geneAllSamplesPlot.download <- downloadHandler(
        filename = function () {
            paste0("geneAllSamplesPlot.",  input$plotformat)
        },
        content = function (file) {
            ggsave(file = file, plot = geneAllSamplesPlot.data(), width = input$plotwidth, height = input$plotheight, units = input$plotunits, dpi = as.numeric(input$plotdpi))
        }
    )

###############################
## NORMALISATION SET
#------------------------------------ PCA representation expression normalized with the whole set of control genes
    output$pcaGlobPlot <- renderPlot({
        referenceSet <- input$referenceSet
        referenceSet <- unique(as.character(genes[which(genes[, "Reason"] == referenceSet), "Accession"]))
        exp.hou <- normalization(normSet = referenceSet, expressions = expressions, genes = genes)
        dtaForPCA <- cbind.data.frame(
            factor(sampleID[, "Groups"]),
            t(exp.hou)
        )
        res.hou <- PCA(
            dtaForPCA,
            graph = FALSE,
            quali.sup = 1,
            scale = FALSE,
            ncp = Inf
        )
        return(plot.PCA(res.hou, choix = "ind", habillage = 1, shadowtext = TRUE, cex = 0.9, invisible = "quali", title = "Global representation of the tissues (PCA)"))
    })

    #------------------------------------ PCA representation expression normalized with the set of selected genes
    output$ui <- renderUI({
        validate(need(!is.null(input$referenceSet), ""))
        out <- switch(input$referenceSet,
            "housekeeping gene" = {
                checkboxGroupInput(
                    "gene1",
                    label = "",
                    choices = as.character(unique(sort(genes[which(genes[, "Reason"] == "housekeeping gene"), "Name"]))),
                    inline = TRUE,
                    selected = "ACTB"
                )
            },
            "housekeeping gene publi (Trends Genet. 2013 Oct;29(10):569-74)" = {
                checkboxGroupInput(
                    "gene1",
                    label = "",
                    choices = as.character(unique(sort(genes[which(genes[, "Reason"] == "housekeeping gene publi (Trends Genet. 2013 Oct;29(10):569-74)"), "Name"]))),
                    inline = TRUE, selected = "C1orf43")
            },
            "Positive" = {
                checkboxGroupInput(
                    "gene1",
                    label = "",
                    choices = as.character(unique(sort(genes[which(genes[, "Reason"] == "Positive"), "Name"]))),
                    inline = TRUE,
                    selected = "POS_C(8)"
                )
            }
        )
        return(out)
    })
    output$pcaGenePlot <- renderPlot({
        validate(need(!is.null(input$gene1), ""))
        geneSet1 <- input$gene1
        geneSet1 <- unique(as.character(genes[match(geneSet1, genes[, "Name"]), "Accession"]))
        exp.hou <- normalization(normSet = geneSet1, expressions = expressions, genes = genes)
        res.hou <- PCA(
            cbind.data.frame(
                factor(sampleID[, "Groups"]),
                t(exp.hou)
            ),
            graph = FALSE,
            quali.sup = 1,
            scale = FALSE,
            ncp = Inf
        )
        return(plot.PCA(res.hou, choix = "ind", habillage = 1, shadowtext = TRUE, cex = 0.9, invisible = "quali", title = "Global representation of the tissues (PCA)"))
    })


###############################################################
### CARTOGRAPHY
###############################
## Create normalised dataset in the global environment
    normalised.data <- normalization(normSet = normSet, expressions = expressions, genes = genes)

## MARKERS
#------------------------------------ Average expression of the markers
    markerAPlot.data <- reactive({
        validate(need(!is.null(input$marker), ""))
        marker <- input$marker
        geneSet <- as.character(unique(genes[which(genes[, "Reason"] == marker), "Accession"]))
        data.tmp <- normalised.data[geneSet, ]
        if (length(geneSet) > 1) {
            data.tmp <- cbind.data.frame(
                ind = colnames(data.tmp),
                values = colMeans(data.tmp, na.rm = TRUE),
                tissues = sampleID[, "Groups"]
            )
        } else {
            data.tmp <- cbind.data.frame(
                ind = names(data.tmp),
                values = data.tmp,
                tissues = sampleID[, "Groups"]
            )
        }
        data.tmp[, "ind"] <- factor(
            data.tmp[, "ind"],
            levels = unique(data.tmp[, "ind"])[order(sampleID[, "Groups"], sampleID[, "SampleID"])]
        )
        data.tmp[, "values"] <- data.tmp[, "values"] + abs(min(data.tmp[, "values"], na.rm = TRUE))
        p <- ggplot(data = data.tmp, aes(x = ind, y = values, fill = tissues)) +
            geom_bar(stat = "identity", position = position_dodge(), width = 0.75) +
            scale_fill_viridis(discrete = TRUE, option = "viridis", name = "Tissues") +
            labs(x = "Samples", y = "Expression") +
            coord_flip() +
            scale_y_continuous(expand = c(0, 0), limits = c(0, max(data.tmp[, "values"], na.rm = TRUE)*1.05)) +
            guides(fill = guide_legend(ncol = 1)) +
            mytheme
        return(p)
    })
    output$markerAPlot <- renderPlot({
        return(markerAPlot.data())
    })
    output$markerAPlot.download <- downloadHandler(
        filename = function () {
            paste0("CartographyMkAverageExp.",  input$plotformat)
        },
        content = function (file) {
            ggsave(file = file, plot = markerAPlot.data(), width = input$plotwidth, height = input$plotheight, units = input$plotunits, dpi = as.numeric(input$plotdpi))
        }
    )

#------------------------------------ expression of the markers
    markerPlot.data  <- reactive({
        validate(need(!is.null(input$marker), ""))
        marker <- input$marker
        geneSet <- as.character(unique(genes[which(genes[, "Reason"] == marker), "Accession"]))
        data.tmp <- normalised.data[geneSet, , drop = FALSE]
        data.tmp <- cbind.data.frame(
            stack(data.frame(data.tmp)),
            gene = rep(geneSet, ncol(data.tmp))
        )
        data.tmp[, "ind"] <- factor(
            data.tmp[, "ind"],
            levels = unique(data.tmp[, "ind"])[order(sampleID[, "Groups"], sampleID[, "SampleID"])]
        )
        data.tmp[, "values"] <- data.tmp[, "values"] + abs(min(data.tmp[, "values"], na.rm = TRUE))
        p <- ggplot(data = data.tmp, aes(x = ind, y = values, fill = gene)) +
            geom_bar(stat = "identity", position = position_dodge(), width = 0.75) +
            scale_fill_viridis(
                discrete = TRUE,
                option = "viridis",
                name = "Genes",
                labels = paste(
                    factor(data.tmp[, "gene"]),
                    genes[match(factor(data.tmp[, "gene"]),
                    genes[, "Accession"]), "Name"],
                    sep = " - "
                )
            ) +
            labs(x = "Samples", y = "Expression") +
            coord_flip() +
            scale_y_continuous(expand = c(0, 0), limits = c(0, max(data.tmp[, "values"], na.rm = TRUE)*1.05)) +
            guides(fill = guide_legend(ncol = 1)) +
            mytheme
        return(p)
    })
    output$markerPlot <- renderPlot({
        return(markerPlot.data())
    })
    output$markerPlot.download <- downloadHandler(
        filename = function () {
            paste0("CartographyMkSamplesExp.",  input$plotformat)
        },
        content = function (file) {
            ggsave(file = file, plot = markerPlot.data(), width = input$plotwidth, height = input$plotheight, units = input$plotunits, dpi = as.numeric(input$plotdpi))
        }
    )


###############################
## EXPRESSION PROFIL
#------------------------------------ Probe information
    output$adaGeneInfo <- renderUI({
        gene <- input$geneAda
        rea <- genes[which(genes[, "Name"]==gene), ]
        return(HTML(paste(
            rea[1, "Definition"],
            "<br/>Reasons: ",
            paste0(rea[, "Reason"], collapse = " & ")
        )))
    })

#------------------------------------ Group selection
    output$adaGroupSelect <- renderUI({
        selectInput(
            "adaGroupSelect.input",
            label = "",
            choices = as.list(unique(sampleID[, "Groups"])),
            multiple = TRUE,
            selected = unique(sampleID[, "Groups"]))
    })

#------------------------------------ Representation expression profiles subset samples
    adaGenePlot.data <- reactive({
        validate(need(!is.null(input$geneAda), ""))
        geneN <- input$geneAda
        whichSamples <- row.names(na.omit(sampleID[order(sampleID[, "Order"]), ]))
        geneSet <- as.character(unique(genes[which(genes[, "Name"] == geneN), "Accession"]))
        data.tmp <- normalised.data[geneSet, whichSamples]
        data.tmp <- cbind.data.frame(
            ind = na.omit(sampleID[order(sampleID[, "Order"]), ])[, "FullName"],
            values = data.tmp,
            tissues = na.omit(sampleID[order(sampleID[, "Order"]), ])[, "Groups"]
        )
        data.tmp[, "ind"] <- factor(data.tmp[, "ind"], levels = unique(data.tmp[nrow(data.tmp):1, "ind"]))
        data.tmp[, "tissues"] <- factor(data.tmp[, "tissues"], levels = unique(data.tmp[nrow(data.tmp):1, "tissues"]))
        data.tmp[, "values"] <- data.tmp[, "values"] + abs(min(data.tmp[, "values"], na.rm = TRUE))
        meanvalExprP <- aggregate(data.tmp[, "values"]~data.tmp[, "tissues"], FUN = mean, na.rm = TRUE , na.action = NULL)
        names(meanvalExprP) <- c('Groups', 'Mean')
        samplesubsetExprP <- meanvalExprP[meanvalExprP[, "Groups"]%in%input$adaGroupSelect.input, ]
        p <- ggplot(data = samplesubsetExprP, aes(x = Groups, y = Mean, fill = Groups)) +
            geom_bar(stat = "identity", position = position_dodge(), width = 0.75) +
            labs(x = "Samples", y = paste("Mean expression of", geneN)) +
            scale_fill_viridis(discrete = TRUE,  option = "viridis", name = "Samples", breaks = samplesubsetExprP[, "Groups"]) +
            scale_y_continuous(expand = c(0, 0), limits = c(0, max(samplesubsetExprP[, "Mean"], na.rm = TRUE)*1.05)) +
            coord_flip() +
            mytheme +
            theme(
                legend.position = "none"
            )
        return(p)
    })
    output$adaGenePlot <- renderPlot({
        return(adaGenePlot.data())
    })
    output$adaGenePlot.download <- downloadHandler(
        filename = function () {
             paste0("CartographyMeanExpGenes.",  input$plotformat)
        },
        content = function (file) {
            ggsave(file = file, plot = adaGenePlot.data(), width = input$plotwidth, height = input$plotheight, units = input$plotunits, dpi = as.numeric(input$plotdpi))
        }
    )

#------------------------------------ Representation expression profiles all samples
    output$normGeneSelect1 <- renderUI({
        selectInput(
            "normGeneSelect1.input",
            label = "",
            choices = as.list(unique(sampleID[, "Groups"])),
            multiple = TRUE
        )
    })
    output$normGeneSelect2 <- renderUI({
        selectInput(
            "normGeneSelect2.input",
            label = "",
            choices = as.list(rownames(sampleID[sampleID[, "Groups"]%in%input$normGeneSelect1.input, ])),
            multiple = TRUE
        )
    })
    normGenePlot.data <- reactive({
        validate(need(!is.null(input$geneAda), ""))
        geneN <- input$geneAda
        geneSet <- as.character(unique(genes[which(genes[, "Name"] == geneN), "Accession"]))
        data.tmp <- normalised.data[geneSet, ]
        data.tmp <- cbind.data.frame(
            ind = names(data.tmp),
            fullname = sampleID[, "FullName"],
            values = data.tmp,
            tissues = sampleID[, "Groups"]
        )
        data.tmp[, "ind"] <- factor(
            data.tmp[, "ind"],
            levels = unique(data.tmp[order(sampleID[, "Groups"], sampleID[, "FullName"]), "ind"])
        )
        data.tmp[, "values"] <- data.tmp[, "values"] + abs(min(data.tmp[, "values"], na.rm = TRUE))
        samplesubset <- data.tmp[data.tmp[, "ind"]%in%input$normGeneSelect2.input, ]
        validate(need(nrow(samplesubset)!=0, "No data"))
        p <- ggplot(data = samplesubset, aes(x = ind, y = values, fill = tissues)) +
            geom_bar(stat = "identity", position = position_dodge(), width = 0.75) +
            scale_fill_viridis(discrete = TRUE, option = "viridis", name = "Samples") +
            labs(x = "Samples", y = paste("Expression of", geneN)) +
            coord_flip() +
            scale_y_continuous(expand = c(0, 0), limits = c(0, max(samplesubset[, "values"], na.rm = TRUE)*1.05)) +
            mytheme
        return(p)
    })
    output$normGenePlot <- renderPlot({
        return(normGenePlot.data())
    })
    output$normGenePlot.download <- downloadHandler(
        filename = function () {
            paste0("CartographyExpGenes.",  input$plotformat)
        },
        content = function (file) {
            ggsave(file = file, plot = normGenePlot.data(), width = input$plotwidth, height = input$plotheight, units = input$plotunits, dpi = as.numeric(input$plotdpi))
        }
    )

###############################
## GLOBAL REPRESENTATION
#------------------------------------ for given groups of samples
    # selection Sample Group
    output$HMGroupSelect <- renderUI({
        selectInput("HMGroupSelect.input",
            label = "",
            choices = as.list(unique(sampleID[, "Groups"])),
            multiple = TRUE,
            selected = c(
		"Liver",
		"Small Intestine",
		"Brain",
		"Kidney",
		"EndoC-BetaH1",
		"Pituitary gland",
		"Hypothalamus",
		"Substantia Nigra",
		"Heart ",
		"Islet",
                "Skeletal muscle",
		"Colon",
                "LCM Beta cell",
                "Caudate Nucleus",
		"Dorsal Root Ganglion",
		"Frontal Lobe",
                "Insula",
                "Hippocampus",
                "FACS sorted Beta cell",
                "Exocrine pancreas",
		"Pre-adipocyte",
                "Lung",
                "Adipose tissue",
		"Mature adipocyte"
            )
        )
    })
    reasonHeatmapPlot.data <- reactive({
        reason <-  input$reason
        ratio <- input$ratio
        height <- input$height
        width <- input$width
        geneSet <- unique(as.character(genes[which(genes[, "Reason"] == reason), "Accession"]))
        validate(need(length(geneSet)>1, 'Only one gene in the selected group of genes'))
        exp.Clean <- normalised.data[geneSet, ]
        exp.Clean <- exp.Clean[, row.names(na.omit(sampleID[order(sampleID[, "Order"]), ]))]
        exp.Clean[is.na(exp.Clean)] <- min(exp.Clean, na.rm = TRUE)
        exp.Clean <- t(exp.Clean)
        Groups <- sampleID[order(sampleID[, "Order"]), "Groups"]
        exp.Clean <- cbind.data.frame(exp.Clean, Groups)
        meanvalHMP <- apply(exp.Clean[, colnames(exp.Clean)%in%genes[, "Accession"]], 2, function (x) { aggregate(x~exp.Clean$Groups, FUN = mean, na.rm = TRUE, na.action = NULL) })
        meanvalHMP <- as.data.frame(meanvalHMP)
        samplesubsetHMP <- meanvalHMP[meanvalHMP[, 1]%in%input$HMGroupSelect.input, ]
        samplesubsetexprHMP <- samplesubsetHMP[, grep('*[:.:]x', names(meanvalHMP))]
        names(samplesubsetexprHMP) <- gsub("*[:.:]x", "", names(samplesubsetexprHMP))
        xlabels <- as.character(samplesubsetHMP[, 1])
        ylabels <- as.character(genes[, "Name"][unique(match(names(samplesubsetexprHMP), genes[, "Accession"]))])
        # hm.data <- as.data.frame(apply(samplesubsetexprHMP, 2, scale))
        hm.data <- scale(samplesubsetexprHMP)
        dimnames(hm.data) <- list(format(xlabels), format(ylabels))
        width_side <- (1-width)/2
        height_side <- (1-height)/2
        row_hc <- hclust(dist(hm.data), "ward.D")
        col_hc <- hclust(dist(t(hm.data)), "ward.D")
        dataFromHeatmap <- as.matrix(hm.data[row_hc$order, col_hc$order])
        out <- list(
            hm.data = hm.data,
            ratio = ratio,
            width_side = width_side,
            width = width,
            height_side = height_side,
            height = height,
            dataFromHeatmap = dataFromHeatmap
        )
        return(out)
    })
    output$reasonHeatmapPlot <- renderPlot({
        alldta <- reasonHeatmapPlot.data()
        hm.data <- alldta$hm.data
        if (prop.table(dim(hm.data))[1]<0.60) {
            hm.data <- as.data.frame(t(hm.data))
            hm.plot(
                x = hm.data,
                ratio = alldta$ratio,
                h_ratio = c(alldta$height_side*0.01, alldta$height, alldta$height_side*1.99)[3:1],
                v_ratio = c(alldta$width_side, alldta$width, alldta$width_side),
                label_size = 5,
                col = c("#ff0000", "#404640", "#00ff06"), # replaced within hm.plot by viridis palette
                x.dendo = TRUE,
                y.dendo = FALSE
            )
        } else {
            hm.plot(
                x = hm.data,
                ratio = alldta$ratio,
                h_ratio = c(alldta$width_side, alldta$width, alldta$width_side),
                v_ratio = c(alldta$height_side*0.01, alldta$height, alldta$height_side*1.99),
                label_size = 5,
                col =  c("#ff0000", "#404640", "#00ff06"), # replaced within hm.plot by viridis palette
                x.dendo = FALSE,
                y.dendo = TRUE
            )
        }
    })
    output$reasonHeatmapPlotui <- renderUI({
        alldta <- reasonHeatmapPlot.data()
        hm.data <- alldta$hm.data
        if (prop.table(dim(hm.data))[1]<0.60) {
            hm.data <- as.data.frame(t(hm.data))
        } else {}
        height <- paste0(max(20*nrow(hm.data)+250, 500), "px")
        return(plotOutput("reasonHeatmapPlot", height = height))
    })
    output$reasonHeatmapPlot.download <- downloadHandler(
        filename = function () {
            inFormat <- input$plotformat
            if (inFormat%in%"jpg") {
                inFormat <- "png"
            } else {}
            if (inFormat%in%"eps") {
                inFormat <- "svg"
            } else {}
            return(paste0("HeatmapOverwiew.",  inFormat))
        },
        content = function (file) {
            alldta <- reasonHeatmapPlot.data()
            hm.data <- alldta$hm.data
            inFormat <- input$plotformat
            if (inFormat%in%"jpg") {
                inFormat <- "png"
            } else {}
            if (inFormat%in%"eps") {
                inFormat <- "svg"
            } else {}
            CMD <- paste0(
                inFormat, '(file = \"', file, '\", width = ', input$plotwidth, ', height = ', input$plotheight, ', units = \"', input$plotunits, '\", res = ', as.numeric(input$plotdpi), ')\n',
                'if (prop.table(dim(hm.data))[1]<0.60) {
                    hm.data <- as.data.frame(t(hm.data))
                    hm.plot(
                        x = hm.data,
                        ratio = alldta$ratio,
                        h_ratio = c(alldta$height_side*0.01, alldta$height, alldta$height_side*1.99)[3:1],
                        v_ratio = c(alldta$width_side, alldta$width, alldta$width_side),
                        label_size = 5,
                        col = c("#ff0000", "#404640", "#00ff06"), # replaced within hm.plot by viridis palette
                        x.dendo = TRUE,
                        y.dendo = FALSE
                    )
                } else {
                    hm.plot(
                        x = hm.data,
                        ratio = alldta$ratio,
                        h_ratio = c(alldta$width_side, alldta$width, alldta$width_side),
                        v_ratio = c(alldta$height_side*0.01, alldta$height, alldta$height_side*1.99),
                        label_size = 5,
                        col = c("#ff0000", "#404640", "#00ff06"), # replaced within hm.plot by viridis palette
                        x.dendo = FALSE,
                        y.dendo = TRUE
                    )
                }\n',
                'dev.off()'
            )
            eval(parse(text = CMD))
        }
    )
enrichmentGroupHeatmapPlot.dataOR <- reactive({
        validate(need(!is.null(input$reason), ''))
        dataFromHeatmap <- reasonHeatmapPlot.data()$dataFromHeatmap
        dta.hm <- dataFromHeatmap > input$SDgroup
        dta.hm[is.na(dta.hm)] <-  FALSE
        countsExp_permk <- cbind.data.frame(dta.hm, Groups = rownames(dta.hm))
        countsExp_permk[, "Enrich.TRUE"] <- rowSums(countsExp_permk[, colnames(dta.hm)])
        countsExp_permk[, "Enrich.FALSE"] <- rowSums(!countsExp_permk[, colnames(dta.hm)])
        res <- do.call("rbind", lapply(seq_len(nrow(countsExp_permk)), function (i) {
            tabCounts <- rbind(
                countsExp_permk[i, c("Enrich.TRUE", "Enrich.FALSE")],
                colSums(countsExp_permk[-i, c("Enrich.TRUE", "Enrich.FALSE")])
            )
            res <- cbind.data.frame(Groups = countsExp_permk[i, "Groups"], tidy(fisher.test(tabCounts, alternative = "greater")))
            #res <- cbind.data.frame(Groups = countsExp_permk[i, "Groups"], fisher.test(tabCounts, alternative = "greater"))
            return(res)
        }))
        rownames(res) <- res[, "Groups"]
        res[, "Tissues"] <- factor(gsub(" *$", "", res[, "Groups"]), levels = gsub(" *$", "", res[, "Groups"]))
        res[, "Groups"] <- NULL
        rownames(res) <- NULL
        res <- res[, c("Tissues", setdiff(colnames(res), "Tissues"))]
        return(res)
})
    enrichmentGroupHeatmapPlot.data <- reactive({
        res <- enrichmentGroupHeatmapPlot.dataOR()
        p <- ggplot(data = res, aes(x = Tissues, y = -log10(p.value), fill = Tissues, label=round(estimate,2))) +
            geom_bar(stat = "identity", position = position_dodge(), width = 0.75) +
            geom_abline(intercept = -log10(0.05), slope = 0) +
            geom_vline(xintercept = seq_len(max(length(unique(res[, "Tissues"]))-1, 0))+0.5, colour = "grey", size = 0.5) +
            labs(x = "Samples", y = bquote(-log[10]~"Pvalue")) +
            coord_flip() +
            scale_y_continuous(expand = c(0, 0), limits = c(0, max(-log10(c(res[, "p.value"], 0.05)), na.rm = TRUE)*1.05)) +
            mytheme +
            theme(legend.position = "none", axis.text=element_text(size=14)) +
            scale_fill_viridis(discrete = TRUE, option = "viridis")
	    if (input$ORoptionGroup) {
            p <- p + geom_text(hjust = -0.3, nudge_x = 0.0)
	    } else  {}
        return(p)
        # return(list(p = p, res = res))
    })
    output$enrichmentGroupHeatmapPlot <- renderPlot({
        return(enrichmentGroupHeatmapPlot.data()) # return(enrichmentGroupHeatmapPlot.data()$p)
    })
    output$enrichmentGroupHeatmapPlot.download <- downloadHandler(
        filename = function () {
            paste0("enrichmentGroupHeatmapPlot.",  input$plotformat)
        },
        content = function (file) {
            ggsave(file = file, plot = enrichmentGroupHeatmapPlot.data(), width = input$plotwidth, height = input$plotheight, units = input$plotunits, dpi = as.numeric(input$plotdpi))
        }
    )

    #output$tableGroups <- renderDataTable({
        #return(enrichmentGroupHeatmapPlot.dataOR())

    #})
    output$tableGroups <- renderDataTable(enrichmentGroupHeatmapPlot.dataOR(), options = list (paging = FALSE,searching = FALSE))

    output$tableGroups.download <- downloadHandler(
        filename = function() {
            paste0(input$reason, '.csv')
	 },
        content = function(file) {
            write.csv(enrichmentGroupHeatmapPlot.dataOR(), file, row.names = FALSE)
    }
  )

#------------------------------------ for given samples
    # heatmap par samples selectionnes
    output$HeatmapPlotSelect1 <- renderUI({
        selectInput(
            "HeatmapPlotSelect1.input",
            label = "",
            choices = as.list(unique(sampleID[, "Groups"])),
            multiple = TRUE,
        selected = c(
		 		"Liver",
		"Small Intestine",
		"Brain",
		"Kidney",
		"EndoC-BetaH1",
		"Pituitary gland",
		"Hypothalamus",
		"Substantia Nigra",
		"Heart ",
		"Islet",
                "Skeletal muscle",
		"Colon",
                "LCM Beta cell",
                "Caudate Nucleus",
		"Dorsal Root Ganglion",
		"Frontal Lobe",
                "Insula",
                "Hippocampus",
                "FACS sorted Beta cell",
                "Exocrine pancreas",
		"Pre-adipocyte",
                "Lung",
                "Adipose tissue",
		"Mature adipocyte"
            )
        )
    })
    output$HeatmapPlotSelect2 <- renderUI({
        selectInput(
            "HeatmapPlotSelect2.input",
            label = "",
            choices = as.list(rownames(sampleID[sampleID[, "Groups"]%in%input$HeatmapPlotSelect1.input, ])),
            multiple = TRUE
        )
    })
    reasonHeatmapPlot2.data <- reactive({
        reason <- input$reason2
        ratio2 <- input$ratio2
        height2 <- input$height2
        width2 <- input$width2
        validate(need(!is.null(input$HeatmapPlotSelect1.input)&!is.null(input$HeatmapPlotSelect2.input), 'Please select "something"!'))
        validate(need(!is.null(input$HeatmapPlotSelect1.input)&length(input$HeatmapPlotSelect2.input)>1, 'Please select "more  something"!'))
        geneSet <- unique(as.character(genes[which(genes[, "Reason"] == reason), "Accession"]))
        validate(need(length(geneSet)>1, ""))
        exp.Clean2 <- normalised.data[geneSet, ]
        exp.Clean2 <- exp.Clean2[, row.names(na.omit(sampleID[order(sampleID[, "Order"]), ]))]
        exp.Clean2[is.na(exp.Clean2)] <- min(exp.Clean2, na.rm = TRUE)
        exp.Clean2 <- t(exp.Clean2)
        samplesubsetHMP2 <- exp.Clean2[which(rownames(exp.Clean2)%in%input$HeatmapPlotSelect2.input),]
        xlabels <- as.character(rownames(samplesubsetHMP2))
        ylabels <- as.character(genes[unique(match(colnames(samplesubsetHMP2), genes[, "Accession"])), "Name"])
        #hm2.data <- as.data.frame(apply(samplesubsetHMP2, 2, scale))
        hm2.data <- scale(samplesubsetHMP2)
        dimnames(hm2.data) <- list(format(xlabels), format(ylabels))
        width_side2 <- (1-width2)/2
        height_side2 <- (1-height2)/2
        row_hc <- hclust(dist(hm2.data), "ward.D")
        col_hc <- hclust(dist(t(hm2.data)), "ward.D")
        dataFromHeatmap <- as.matrix(hm2.data[row_hc$order, col_hc$order])
        ### save for loading : load('/home/cecile/disks/PROJECT/NanoStringTissueCartography/ShinyApp/NanoStringTissueCartography/EnrichmentHMsample.Rdata')
        #save(list = c("exp.Clean2", "samplesubsetHMP2", "hm2.data", "xlabels", "ylabels", "row_hc", "col_hc", "genes", "dataFromHeatmap"), file = "EnrichmentHMsample.Rdata")
        out <- list(
            hm.data = hm2.data,
            ratio = ratio2,
            width_side = width_side2,
            width = width2,
            height_side = height_side2,
            height = height2,
            dataFromHeatmap = dataFromHeatmap
        )
        return(out)
    })
    output$reasonHeatmapPlot2 <- renderPlot({
        alldta <- reasonHeatmapPlot2.data()
        hm.data <- alldta$hm.data
        if (prop.table(dim(hm.data))[1]<0.60) {
            hm.data <- as.data.frame(t(hm.data))
            hm.plot(
                x = hm.data,
                ratio = alldta$ratio,
                h_ratio = c(alldta$height_side*0.01, alldta$height, alldta$height_side*1.99)[3:1],
                v_ratio = c(alldta$width_side, alldta$width, alldta$width_side),
                label_size = 5,
                col = c("#ff0000", "#404640", "#00ff06"), # replaced within hm.plot by viridis palette
                x.dendo = TRUE,
                y.dendo = FALSE
            )
        } else {
            hm.plot(
                x = hm.data,
                ratio = alldta$ratio,
                h_ratio = c(alldta$width_side, alldta$width, alldta$width_side),
                v_ratio = c(alldta$height_side*0.01, alldta$height, alldta$height_side*1.99),
                label_size = 5,
                col = c("#ff0000", "#404640", "#00ff06"), # replaced within hm.plot by viridis palette
                x.dendo = FALSE,
                y.dendo = TRUE
            )
        }
    })
    output$reasonHeatmapPlotui2 <- renderUI({
        alldta <- reasonHeatmapPlot2.data()
        hm.data <- alldta$hm.data
        if (prop.table(dim(hm.data))[1]<0.60) {
            hm.data <- as.data.frame(t(hm.data))
        } else {}
        height <- paste0(max(20*nrow(hm.data)+250, 500), "px")
        return(plotOutput("reasonHeatmapPlot2", height = height))
    })
    output$reasonHeatmapPlot2.download <- downloadHandler(
        filename = function () {
            inFormat <- input$plotformat
            if (inFormat%in%"jpg") {
                inFormat <- "png"
            } else {}
            if (inFormat%in%"eps") {
                inFormat <- "svg"
            } else {}
            return(paste0("HeatmapFocus.", inFormat))
        },
        content = function (file) {
            alldta <- reasonHeatmapPlot2.data()
            hm.data <- alldta$hm.data
            inFormat <- input$plotformat
            if (inFormat%in%"jpg") {
                inFormat <- "png"
            } else {}
            if (inFormat%in%"eps") {
                inFormat <- "svg"
            } else {}
            CMD <- paste0(
                inFormat, '(file = \"', file, '\", width = ', input$plotwidth, ', height = ', input$plotheight, ', units = \"', input$plotunits, '\", res = ', as.numeric(input$plotdpi), ')\n',
                'if (prop.table(dim(hm.data))[1]<0.60) {
                    hm.data <- as.data.frame(t(hm.data))
                    hm.plot(
                        x = hm.data,
                        ratio = alldta$ratio,
                        h_ratio = c(alldta$height_side*0.01, alldta$height, alldta$height_side*1.99)[3:1],
                        v_ratio = c(alldta$width_side, alldta$width, alldta$width_side),
                        label_size = 5,
                        col = c("#ff0000", "#404640", "#00ff06"), # replaced within hm.plot by viridis palette
                        x.dendo = TRUE,
                        y.dendo = FALSE
                    )
                } else {
                    hm.plot(
                        x = hm.data,
                        ratio = alldta$ratio,
                        h_ratio = c(alldta$width_side, alldta$width, alldta$width_side),
                        v_ratio = c(alldta$height_side*0.01, alldta$height, alldta$height_side*1.99),
                        label_size = 5,
                        col = c("#ff0000", "#404640", "#00ff06"), # replaced within hm.plot by viridis palette
                        x.dendo = FALSE,
                        y.dendo = TRUE
                    )
                }\n',
                'dev.off()'
            )
            eval(parse(text = CMD))
        }
    )

    enrichmentSampleHeatmapPlot.dataOR <- reactive({
    validate(need(!is.null(input$reason2), ''))
        dataFromHeatmap <- reasonHeatmapPlot2.data()$dataFromHeatmap
        dta.hm <- dataFromHeatmap > input$SDsample
        dta.hm[is.na(dta.hm)] <-  FALSE
        countsExp_permk <- cbind.data.frame(dta.hm, Groups = rownames(dta.hm))
        countsExp_permk[, "Enrich.TRUE"] <- rowSums(countsExp_permk[, colnames(dta.hm)])
        countsExp_permk[, "Enrich.FALSE"] <- rowSums(!countsExp_permk[, colnames(dta.hm)])
        res <- do.call("rbind", lapply(seq_len(nrow(countsExp_permk)), function (i) {
            tabCounts <- rbind(
                countsExp_permk[i, c("Enrich.TRUE", "Enrich.FALSE")],
                colSums(countsExp_permk[-i, c("Enrich.TRUE", "Enrich.FALSE")])
            )
            res <- cbind.data.frame(Groups = countsExp_permk[i, "Groups"], tidy(fisher.test(tabCounts, alternative = "greater")))
            return(res)
        }))
        rownames(res) <- res[, "Groups"]
        res[, "Tissues"] <- factor(gsub(" *$", "", res[, "Groups"]), levels = gsub(" *$", "", res[, "Groups"]))
	res[, "Groups"] <- NULL
        rownames(res) <- NULL
        res <- res[, c("Tissues", setdiff(colnames(res), "Tissues"))]
        return(res)
    })

    enrichmentSampleHeatmapPlot.data <- reactive({
        res <- enrichmentSampleHeatmapPlot.dataOR()
        p <- ggplot(data = res, aes(x = Tissues, y = -log10(p.value), fill = Tissues, label=round(estimate,2))) +
            geom_bar(stat = "identity", position = position_dodge(), width = 0.75) +
            geom_abline(intercept = -log10(0.05), slope = 0) +
            geom_vline(xintercept = seq_len(max(length(unique(res[, "Tissues"]))-1, 0))+0.5, colour = "grey", size = 0.5) +
            labs(x = "Samples", y = bquote(-log[10]~"Pvalue")) +
            coord_flip() +
            scale_y_continuous(expand = c(0, 0), limits = c(0, max(-log10(c(res[, "p.value"], 0.05)), na.rm = TRUE)*1.05)) +
            mytheme +
            theme(legend.position = "none", axis.text=element_text(size=14)) +
            scale_fill_viridis(discrete = TRUE, option = "viridis")
	    if (input$ORoptionSample) {
	    p <- p + geom_text(hjust = -0.3, nudge_x = 0.0)
	    } else  {}
        return(p)
    })
    output$enrichmentSampleHeatmapPlot <- renderPlot({
        return(enrichmentSampleHeatmapPlot.data())
    })
    output$enrichmentSampleHeatmapPlot.download <- downloadHandler(
        filename = function () {
            paste0("enrichmentSampleHeatmapPlot.",  input$plotformat)
        },
        content = function (file) {
            ggsave(file = file, plot = enrichmentSampleHeatmapPlot.data (), width = input$plotwidth, height = input$plotheight, units = input$plotunits, dpi = as.numeric(input$plotdpi))
        }
    )

    #output$tableSamples <- renderDataTable({# renderTable({
        #oreturn(enrichmentSampleHeatmapPlot.dataOR())
    #})
    output$tableSamples <- renderDataTable(enrichmentSampleHeatmapPlot.dataOR(), options = list (paging = FALSE,searching = FALSE))

    output$tableSamples.download <- downloadHandler(
        filename = function() {
            paste0(input$reason, '.csv')
	 },
        content = function(file) {
            write.csv(enrichmentSampleHeatmapPlot.dataOR(), file, row.names = FALSE)
    }
  )


###############################################################
### ENRICHMENT
###############################
### MARKERS
#------------------------------------ Enrichment of the markers by selected samples from a same tissue
    output$MkGroup <- renderUI({
        checkboxGroupInput(
            "MkGroup.input",
            label = "",
            choices = as.list(na.omit(unique(genes[, "enrichmentMkGroup"]))),
            selected = unique(genes[, "enrichmentMkGroup"])
        )
    })
    output$MkEnrichmentGrPlotSelect <- renderUI({
        selectInput(
            "MkEnrichmentGrPlotSelect.input",
            label = "",
            choices = as.list(unique(sampleID[, "Groups"])),
            multiple = TRUE,
            selected = unique(sampleID[, "Groups"])
        )
    })
    enrichmentGroupPlot.data <- reactive({
        threshold <- input$thresholdMarker
        validate(need(!is.null(input$MkEnrichmentGrPlotSelect.input) & !is.null(input$MkGroup.input), ""))
        mestissues <- c(
            "Pancreas", "Exocrine pancreas", "Islet", "LCM Beta cell", "FACS sorted Beta cell",
            "EndoC-BetaH1", "Liver", "Small Intestine", "Colon", "Placenta", "Kidney", "Lung",
            "Adipose tissue", "Heart ", "Skeletal muscle", "Brain", "Hypothalamus",
            "Substantia Nigra", "Caudate Nucleus", "Frontal Lobe", "Insula",
            "Hippocampus", "Dorsal Root Ganglion", "Pituitary gland"
        )
        cnames <- rownames(subset(sampleID, Groups%in%mestissues))
        res <- do.call("cbind", lapply(
            as.list(na.omit(unique(genes[, "enrichmentMkGroup"]))),
            FUN = enrichmentGroupMk,
            threshold = threshold,
            sampleID = sampleID,
            data.norm = normalised.data,
            subset.tissue = cnames,
            genesData = genes
        ))
        colnames(res) <- as.list(na.omit(unique(genes[, "enrichmentMkGroup"])))
        subres <- res[rownames(res)%in%as.list(input$MkEnrichmentGrPlotSelect.input), colnames(res)%in%as.list(input$MkGroup.input), drop = FALSE]
        markerEnrichment <- plot.enrichment(subres, reasonName = NULL) + mytheme
        return(markerEnrichment)
    })

    output$enrichmentGroupPlot <- renderPlot({
        return(enrichmentGroupPlot.data())
    })

    output$enrichmentGroupPlot.download <- downloadHandler(
        filename = function () {
             paste0("EnrichmentMarkerGroup.",  input$plotformat)
        },
        content = function (file) {
            ggsave(file = file, plot = enrichmentGroupPlot.data(), width = input$plotwidth, height = input$plotheight, units = input$plotunits, dpi = as.numeric(input$plotdpi))
        }
    )

#------------------------------------ Enrichment of the markers by selected samples from a same tissue
    output$MkEnrichmentPlotSelect <- renderUI({
        selectInput(
            "MkEnrichmentPlotSelect.input",
            label = "",
            choices = as.list(rownames(sampleID[sampleID[, "Groups"]%in%input$MkEnrichmentGrPlotSelect.input, ])),
            multiple = TRUE
        )
    })
    enrichmentPlot.data <- reactive({
        threshold <- input$thresholdMarker
        validate(need(!is.null(input$MkEnrichmentPlotSelect.input) & !is.null(input$MkGroup.input), 'Please select at least one sample'))
        mestissues <- c(
            "Pancreas", "Exocrine pancreas", "Islet", "LCM Beta cell", "FACS sorted Beta cell",
            "EndoC-BetaH1", "Liver", "Small Intestine", "Colon", "Placenta", "Kidney", "Lung",
            "Adipose tissue", "Heart ", "Skeletal muscle", "Brain", "Hypothalamus",
            "Substantia Nigra", "Caudate Nucleus", "Frontal Lobe", "Insula",
            "Hippocampus", "Dorsal Root Ganglion", "Pituitary gland"
        )
        cnames <- rownames(subset(sampleID, Groups%in%mestissues))
        res <- do.call("cbind", lapply(
            as.list(na.omit(unique(genes[, "enrichmentMkGroup"]))),
            FUN = enrichmentSampleMk,
            threshold = threshold,
            sampleID = sampleID,
            data.norm = normalised.data,
            subset.tissue = cnames,
            genesData = genes
        ))
        colnames(res) <- as.list(na.omit(unique(genes[, "enrichmentMkGroup"])))
        subres <- res[rownames(res)%in%as.list(input$MkEnrichmentPlotSelect.input), colnames(res)%in%as.list(input$MkGroup.input), drop = FALSE]
        markerEnrichment <- plot.enrichment(subres, reasonName = NULL) + mytheme
        return(markerEnrichment)
    })
    output$enrichmentPlot <- renderPlot({
        return(enrichmentPlot.data())
    })
    output$enrichmentPlot.download <- downloadHandler(
        filename = function () {
             paste0("EnrichmentMarkerSample.",  input$plotformat)
        },
        content = function (file) {
            ggsave(file = file, plot = enrichmentPlot.data(), width = input$plotwidth, height = input$plotheight, units = input$plotunits, dpi = as.numeric(input$plotdpi))
        }
    )


###############################
## GENES
#------------------------------------ Enrichment of a group of genes by samples from a same tissue
    output$GeneGroup <- renderUI({
        checkboxGroupInput(
            "GeneGroup.input",
            label = "",
            choices = as.list(na.omit(unique(genes[, "enrichmentGeneGroup"]))),
            selected = unique(genes[, "enrichmentGeneGroup"]))
    })
    output$GeneEnrichmentGrPlotSelect <- renderUI({
        selectInput(
            "GeneEnrichmentGrPlotSelect.input",
            label = "",
            choices = as.list(unique(sampleID[, "Groups"])),
            multiple = TRUE
        )
    })
    geneEnrichmentGroupPlot.data <- reactive({
        threshold <- input$thresholdGene
        validate(need(!is.null(input$GeneEnrichmentGrPlotSelect.input) & !is.null(input$GeneGroup.input), ""))
        mestissues <- c(
            "Pancreas", "Exocrine pancreas", "Islet", "LCM Beta cell", "FACS sorted Beta cell",
            "EndoC-BetaH1", "Liver", "Small Intestine", "Colon", "Placenta", "Kidney", "Lung",
            "Adipose tissue", "Heart ", "Skeletal muscle", "Brain", "Hypothalamus",
            "Substantia Nigra", "Caudate Nucleus", "Frontal Lobe", "Insula",
            "Hippocampus", "Dorsal Root Ganglion", "Pituitary gland"
        )
        cnames <- rownames(subset(sampleID, Groups%in%mestissues))
        res <- do.call("cbind", lapply(
            as.list(na.omit(unique(genes[, "enrichmentGeneGroup"]))),
            FUN = enrichmentGroupGene,
            threshold = threshold,
            sampleID = sampleID,
            data.norm = normalised.data,
            subset.tissue = cnames,
            genesData = genes
        ))
        colnames(res) <- as.list(na.omit(unique(genes[, "enrichmentGeneGroup"])))
        subres <- res[rownames(res)%in%as.list(input$GeneEnrichmentGrPlotSelect.input), colnames(res)%in%as.list(input$GeneGroup.input), drop = FALSE]
        geneEnrichment <- plot.enrichment_count(subres, reasonName = NULL) + mytheme
        return(geneEnrichment)
    })
    output$geneEnrichmentGroupPlot <- renderPlot({
        return(geneEnrichmentGroupPlot.data())
    })
    output$geneEnrichmentGroupPlot.download <- downloadHandler(
        filename = function () {
             paste0("EnrichmentGeneGroup.",  input$plotformat)
        },
        content = function (file) {
            ggsave(file = file, plot = geneEnrichmentGroupPlot.data(), width = input$plotwidth, height = input$plotheight, units = input$plotunits, dpi = as.numeric(input$plotdpi))
        }
    )

#------------------------------------ Enrichment of one group of genes by selected samples from a same tissue
    output$GeneEnrichmentPlotSelect <- renderUI({
        selectInput(
            "GeneEnrichmentPlotSelect.input",
            label = "",
            choices = as.list(rownames(sampleID[sampleID[, "Groups"]%in%input$GeneEnrichmentGrPlotSelect.input, ])),
            multiple = TRUE
        )
    })
    geneEnrichmentPlot.data <- reactive({
        threshold <- input$thresholdGene
        validate(need(!is.null(input$GeneEnrichmentPlotSelect.input) & !is.null(input$GeneGroup.input), 'Please select at least one sample'))
        mestissues <- c(
            "Pancreas", "Exocrine pancreas", "Islet", "LCM Beta cell", "FACS sorted Beta cell",
            "EndoC-BetaH1", "Liver", "Small Intestine", "Colon", "Placenta", "Kidney", "Lung",
            "Adipose tissue", "Heart ", "Skeletal muscle", "Brain", "Hypothalamus",
            "Substantia Nigra", "Caudate Nucleus", "Frontal Lobe", "Insula",
            "Hippocampus", "Dorsal Root Ganglion", "Pituitary gland"
        )
        cnames <- rownames(subset(sampleID, Groups%in%mestissues))
        res <- do.call("cbind", lapply(
            as.list(na.omit(unique(genes[, "enrichmentGeneGroup"]))),
            FUN = enrichmentSampleGene,
            threshold = threshold,
            sampleID = sampleID,
            data.norm = normalised.data,
            subset.tissue = cnames,
            genesData = genes
        ))
        colnames(res) <- as.list(na.omit(unique(genes[, "enrichmentGeneGroup"])))
        subres <- res[rownames(res)%in%as.list(input$GeneEnrichmentPlotSelect.input), colnames(res)%in%as.list(input$GeneGroup.input), drop = FALSE]
        geneEnrichment <- plot.enrichment_count(subres, reasonName = NULL) + mytheme
        return(geneEnrichment)
    })
    output$geneEnrichmentPlot <- renderPlot({
        return(geneEnrichmentPlot.data())
    })
    output$geneEnrichmentPlot.download <- downloadHandler(
        filename = function () {
             paste0("EnrichmentGeneSample.",  input$plotformat)
        },
        content = function (file) {
            ggsave(file = file, plot = geneEnrichmentPlot.data(), width = input$plotwidth, height = input$plotheight, units = input$plotunits, dpi = as.numeric(input$plotdpi))
        }
    )


###############################
## GENES and MARKERS
    # allEnrichmentGroupPlot.data <- reactive({
        # threshold <- input$threshold
        # validate(need(!is.null(input$MkEnrichmentGrPlotSelect.input) & !is.null(input$MkGroup.input), ""))
        # mestissues <- c(
            # "Pancreas", "Exocrine pancreas", "Islet", "LCM Beta cell", "FACS sorted Beta cell",
            # "EndoC-BetaH1", "Liver", "Small Intestine", "Colon", "Placenta", "Kidney", "Lung",
            # "Adipose tissue", "Heart ", "Skeletal muscle", "Brain", "Hypothalamus",
            # "Substantia Nigra", "Caudate Nucleus", "Frontal Lobe", "Insula",
            # "Hippocampus", "Dorsal Root Ganglion", "Pituitary gland"
        # )
        # cnames <- rownames(subset(sampleID, Groups%in%mestissues))

        ## Markers enrichment data
        # res.Markers <- do.call("cbind", lapply(
            # as.list(na.omit(unique(genes[, "enrichmentMkGroup"]))),
            # FUN = enrichmentGroupMk,
            # threshold = threshold,
            # sampleID = sampleID,
            # data.norm = normalised.data,
            # subset.tissue = cnames,
            # genesData = genes
        # ))
        # colnames(res.Markers) <- as.list(na.omit(unique(genes[, "enrichmentMkGroup"])))
        # subres.Markers <- res.Markers[rownames(res.Markers)%in%as.list(input$MkEnrichmentGrPlotSelect.input), colnames(res.Markers)%in%as.list(input$MkGroup.input), drop = FALSE]

        ## Genes enrichment data
        # res.Genes <- do.call("cbind", lapply(
            # as.list(na.omit(unique(genes[, "enrichmentGeneGroup"]))),
            # FUN = enrichmentGroupGene,
            # threshold = threshold,
            # sampleID = sampleID,
            # data.norm = normalised.data,
            # subset.tissue = cnames,
            # genesData = genes
        # ))
        # colnames(res.Genes) <- as.list(na.omit(unique(genes[, "enrichmentGeneGroup"])))
        # subres.Genes <- res.Genes[rownames(res.Genes)%in%as.list(input$GeneEnrichmentGrPlotSelect.input), colnames(res.Genes)%in%as.list(input$GeneGroup.input), drop = FALSE]
    # })
})



