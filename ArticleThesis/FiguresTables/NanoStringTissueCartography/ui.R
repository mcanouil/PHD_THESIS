# /ep10/disks/PROJECT/NanoStringTissueCartography/ShinyApp/NanoStringTissueCartography

options(stringsAsFactors = FALSE)

### Load Data (Use GenerateAppData.R to create Base.Rdata)
    # source("GenerateAppData.R")
    load('./www/Base.Rdata')

### Load libraries
    library(shiny)
    library(ggplot2)
    library(scales)
    library(grid)
    library(FactoMineR)
    library(shinydashboard)
    library(gapmap)
    library(ggdendro)
    library(reshape)
    library(broom)
    library(viridis)

### Source functions
    source("UTILS/Enrichment.R")
    source("UTILS/Heatmap.R")
    source("UTILS/Normalization.R")


#################################################################
shinyUI(dashboardPage(skin = "blue",
	dashboardHeader(
		title = "NanoString Tissue Cartography",
		dropdownMenu(type = "notifications",
            notificationItem(
                text = "Version 3.1",
                icon("cog")
            )
        ),
        titleWidth = 350
	),

################################################################
############################# Sidebar ##############################

	dashboardSidebar(
        width = 350,
		sidebarMenu(
            menuItem(
                text = "Pictures Settings",
                tabName = "PicturesSettings",
                icon = tags$i(style = "color:#1995dc", icon("picture", lib = "glyphicon"))
            ),
			menuItem("Normalisation",
				menuSubItem("Raw expression", tabName = "Raw-Expression", icon = icon("table"), selected = FALSE),
				menuSubItem("Normalisation set", tabName = "Normalisation-Set", icon = icon("filter"), selected = FALSE),
				icon = icon("check-circle")
			),
			menuItem("Cartography",
				menuSubItem("Markers", tabName = "Markers", icon = icon("line-chart"), selected = TRUE),
				menuSubItem("Expression profiles", tabName = "Expression-profiles", icon = icon("bar-chart"), selected = FALSE),
				menuSubItem("Global representations (tissues)", tabName = "Global-representations-tissues", icon = icon("area-chart"), selected = FALSE),
				menuSubItem("Global representations (samples)", tabName = "Global-representations-samples", icon = icon("area-chart"), selected = FALSE),
				icon = icon("map-marker")
			)#,
			# menuItem("Enrichment",
				# menuSubItem("Markers", tabName = "Markers-enrichment", icon = icon("line-chart"), selected = FALSE),
				# menuSubItem("Genes", tabName = "Genes", icon = icon("bar-chart"), selected = FALSE),
				# icon = icon("pie-chart")
			# )
		)
	),

################################################################
############################# Body ##############################

	dashboardBody(
        tags$head(
            tags$link(rel = "stylesheet", type = "text/css", href = "css/theme.css")
        ),
        tabItems(
            tabItem(tabName = "PicturesSettings",
                fluidRow(
                    box(
                        HTML(
                        '<div id="plotunits" class="form-group shiny-input-radiogroup shiny-input-container shiny-input-container-inline">
                            <label class="control-label" for="plotunits">Unit:</label>
                            <div class="shiny-options-group">
                                <label class="radio-inline">
                                    <input type="radio" name="plotunits" value="in" checked="checked"/>
                                    <span>inch</span>
                                </label>
                                <label class="radio-inline">
                                    <input type="radio" name="plotunits" value="cm"/>
                                    <span>centimetre</span>
                                </label>
                                <label class="radio-inline">
                                    <input type="radio" name="plotunits" value="mm"/>
                                    <span>millimetre</span>
                                </label>
                            </div>
                        </div>
                        <div class="form-group shiny-input-container">
                            <label for="plotwidth">Width:</label>
                            <input id="plotwidth" type="number" class="form-control" value="15" min="1" max="100"/>
                        </div>
                        <div class="form-group shiny-input-container">
                            <label for="plotheight">Height:</label>
                            <input id="plotheight" type="number" class="form-control" value="12" min="1" max="100"/>
                        </div>
                        <div id="plotformat" class="form-group shiny-input-radiogroup shiny-input-container shiny-input-container-inline">
                            <label class="control-label" for="plotformat">Format:</label>
                            <div class="shiny-options-group">
                                <label class="radio-inline">
                                    <input type="radio" name="plotformat" value="jpg" checked="checked"/>
                                    <span>jpg</span>
                                </label>
                                <label class="radio-inline">
                                    <input type="radio" name="plotformat" value="svg"/>
                                    <span>svg</span>
                                </label>
                                <label class="radio-inline">
                                    <input type="radio" name="plotformat" value="tiff"/>
                                    <span>tiff</span>
                                </label>
                                <label class="radio-inline">
                                    <input type="radio" name="plotformat" value="eps"/>
                                    <span>eps</span>
                                </label>
                                <label class="radio-inline">
                                    <input type="radio" name="plotformat" value="png"/>
                                    <span>png</span>
                                </label>
                            </div>
                        </div>
                        <div id="plotdpi" class="form-group shiny-input-radiogroup shiny-input-container shiny-input-container-inline">
                            <label class="control-label" for="plotdpi">Resolution:</label>
                            <div class="shiny-options-group">
                                <label class="radio-inline">
                                    <input type="radio" name="plotdpi" value="150"/>
                                    <span>150 dpi</span>
                                </label>
                                <label class="radio-inline">
                                    <input type="radio" name="plotdpi" value="300" checked="checked"/>
                                    <span>300 dpi</span>
                                </label>
                                <label class="radio-inline">
                                    <input type="radio" name="plotdpi" value="600"/>
                                    <span>600 dpi</span>
                                </label>
                                <label class="radio-inline">
                                    <input type="radio" name="plotdpi" value="1200"/>
                                    <span>1200 dpi</span>
                                </label>
                            </div>
                        </div>
                        <div id="plotcolour" class="form-group shiny-input-radiogroup shiny-input-container shiny-input-container-inline">
                            <label class="control-label" for="plotcolour">Colour:</label>
                            <div class="shiny-options-group">
                                <label class="radio-inline">
                                    <input type="radio" name="plotcolour" value="Colour"/>
                                    <span>Colour</span>
                                </label>
                                <label class="radio-inline">
                                    <input type="radio" name="plotcolour" value="Gray" checked="checked"/>
                                    <span>Gray</span>
                                </label>
                                <label class="radio-inline">
                                    <input type="radio" name="plotcolour" value="Custom"/>
                                    <span>Custom</span>
                                </label>

                            </div>
                        </div>'
                        ),
                        width = 6,
                        collapsible = TRUE,
                        title = "Pictures Settings",
                        solidHeader = TRUE,
                        status = "info",
                        height = 500
                    ),
                    htmlOutput("coloursUi")
                )
            ),

########################### Panel 1 #########################
			tabItem(tabName = "Raw-Expression",
				h1("Study of the housekeeping genes"),
				br(), br(),

#----------- ROW 1
				fluidRow(
					box(
						title = "Correlation circle",
						plotOutput("mfaPlot", height = "600px"),
						width = 6,
						solidHeader = TRUE,
						status = "primary",
						collapsible = TRUE
					),
				# ),

#----------- ROW 2
				# fluidRow(
					box(
						title = "Select a set of genes",
						checkboxGroupInput(
                            "gene", label = "",
                            choices = as.character(unique(sort(genes$Name[genes$Reason == "housekeeping gene" | genes$Reason == "housekeeping gene publi (Trends Genet. 2013 Oct;29(10):569-74)"]))),
                            inline = TRUE,
                            selected = "ACTB"
                        ),
						width = 6,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					)
				),
				fluidRow(
					box(
						title = "Representation of the raw expressions of the housekeeping genes in the EndoBeta cells",
						HTML(
    						    '<div style="text-align:center">
       						         <a id="genePlot.download" class="btn btn-default shiny-download-link " href="" target="_blank">
            						     <i class="fa fa-download" style="text-align:center"></i>
             						        Download
           							 </a>
       								  </div>'
   								   ),
						plotOutput("genePlot", height = "600px"),
						width = 6,
						solidHeader = TRUE,
						status = "primary",
						collapsible = TRUE
					),
				# ),
#----------- ROW 3
				# fluidRow(
					box(
						title = "Representation of the raw expressions of the housekeeping genes in all the samples",
                        HTML(
                        '<div style="text-align:center">
                            <a id="geneAllSamplesPlot.download" class="btn btn-default shiny-download-link " href="" target="_blank">
                                <i class="fa fa-download" style="text-align:center"></i>
                                Download
                            </a>
                        </div>'
                        ),
						plotOutput("geneAllSamplesPlot", height = "600px"),
						width = 6,
						solidHeader = TRUE,
						status = "primary",
						collapsible = TRUE
					)
				)
			),

########################### Panel 2 #########################
#----------- ROW 1
			tabItem(tabName = "Normalisation-Set",
				h1("Study of the housekeeping genes"),
				br(),
                br(),
				fluidRow(
					box(
						title = "Study of a set of reference genes",
						radioButtons("referenceSet", label = "", choices = list("Usual housekeeping genes" = "housekeeping gene", "Housekeeping genes from Eisenberg et al. (2013)" = "housekeeping gene publi (Trends Genet. 2013 Oct;29(10):569-74)", "Control probes (Spikes)" = "Positive"), selected = "housekeeping gene", inline = TRUE),
						uiOutput("ui"),
						width = 12,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					)
				),
				fluidRow(
					box(
						title = "Normalisation according to the whole set of selected control genes",
						plotOutput("pcaGlobPlot", height = "600px"),
						width = 12,
						solidHeader = TRUE,
						status = "primary",
						collapsible = TRUE
					)
				),
				fluidRow(
					box(
						title = "Normalisation according to the set of selected genes",
						plotOutput("pcaGenePlot", height = "600px"),
						width = 12,
						solidHeader = TRUE,
						status = "primary",
						collapsible = TRUE
					)
				)
			),
########################### Panel 3 #########################
			tabItem(tabName = "Markers",
				h1("Study of the markers"),
				br(),
                br(),
				fluidRow(
					box(
						title = "Select a set of markers",
						selectInput("marker", label = "", choices = as.character(markers)),
						width = 12,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					)
				),
				fluidRow(
					box(
						title = "Average expression of the markers",
						HTML(
                        '<div style="text-align:center">
                            <a id="markerAPlot.download" class="btn btn-default shiny-download-link " href="" target="_blank">
                                <i class="fa fa-download" style="text-align:center"></i>
                                Download
                            </a>
                        </div>'
                        ),
						plotOutput("markerAPlot", height = "1200px"),
						width = 12,
						solidHeader = TRUE,
						status = "primary",
						collapsible = TRUE,
						footer = "*Expressions are normalised with the following housekeeping genes C1orf43, PSMB2, PSMB4, VCP, VPS29"
					)
				),
				fluidRow(
					box(
						title = "Expression of the markers",
						HTML(
                        '<div style="text-align:center">
                            <a id="markerPlot.download" class="btn btn-default shiny-download-link " href="" target="_blank">
                                <i class="fa fa-download" style="text-align:center"></i>
                                Download
                            </a>
                        </div>'
                        ),
						plotOutput("markerPlot", height = "1200px"),
						width = 12,
						solidHeader = TRUE,
						status = "primary",
						collapsible = TRUE,
						footer = "*Expressions are normalised with the following housekeeping genes C1orf43, PSMB2, PSMB4, VCP, VPS29"
					)
				)
			),
########################### Panel 3 #########################
			tabItem(tabName = "Expression-profiles",
				h1("Study of the genes"),
				br(),
                br(),
				fluidRow(
					box(
						title = "Select a gene",
						selectInput("geneAda", label = "", choices = as.character(sort(unique(genes$Name[genes$CodeClass == "Endogenous"])))),
						width = 5,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					),
					infoBox(
						title = "Probe information",
						htmlOutput("adaGeneInfo"),
						width = 7,
						fill = TRUE,
						icon = icon("random")
					)
				),
				fluidRow(
					box(
						title = "Selection of group(s) of samples",
						uiOutput("adaGroupSelect"),
						width = 12,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					)
				),
				fluidRow(
					box(
						title = "Representation of the expression profile of the gene",
						HTML(
                        '<div style="text-align:center">
                            <a id="adaGenePlot.download" class="btn btn-default shiny-download-link " href="" target="_blank">
                                <i class="fa fa-download" style="text-align:center"></i>
                                Download
                            </a>
                        </div>'
                        ),
						plotOutput("adaGenePlot", height = "1200px"),
						width = 12,
						solidHeader = TRUE,
						status = "primary",
						collapsible = TRUE
					)
				),
				################### AJOUT d'une liste deroulante pour choisir un groupe de samples et d'une liste pour selectionner des samples ##############################################

				fluidRow(
					box(
						title = "Sample group",
						uiOutput("normGeneSelect1"),
						width = 3,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					),
					box(
						title = "Selection of samples",
						uiOutput("normGeneSelect2"),
						width = 9,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					)
				),
				############### Adapater ce graphe en fonction du choix effectue ci-dessus ###############################
				fluidRow(
					box(
						title = "Representation of the expression profile of the gene across all samples",
						HTML(
                        '<div style="text-align:center">
                            <a id="normGenePlot.download" class="btn btn-default shiny-download-link " href="" target="_blank">
                                <i class="fa fa-download" style="text-align:center"></i>
                                Download
                            </a>
                        </div>'
                        ),
                        plotOutput("normGenePlot", height = "600px"),
						width = 12,
						solidHeader = TRUE,
						status = "primary",
						collapsible = TRUE
					)
				)
				##########################################################################################################""
			),

########################### Panel 4 #########################
			tabItem(tabName = "Global-representations-tissues",
				h1("Heatmap and enrichment representations"),
				br(),
                br(),
				fluidRow(
					box(
						title = "Selection of the group of genes",
						### selection parmi les reason markers et others
						selectInput("reason", label = "", choices = as.character(c(markers,others))),
						width = 12,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					)
				),
				fluidRow(
					box(
						title = "Selection of group(s) of samples",
						uiOutput("HMGroupSelect"),
						width = 12,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE

					)
				),
				fluidRow(
					box(
						title = "For adding cluster separation in the heatmap",
						sliderInput("ratio", label = "", min = 0, max = 1, value = 0.00, step = 0.01, animate = TRUE),
						width = 4,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					),
					box(
						title = "For adjusting the heatmap height",
						sliderInput("height", label = "", min = 0.50, max = 0.95, value = 0.90, step = 0.025, animate = TRUE),
						width = 4,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					),
					box(
						title = "For adjusting the heatmap width",
						sliderInput("width", label = "", min = 0.1, max = 0.95, value = 0.70, step = 0.05, animate = TRUE),
						width = 4,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					)
				),
				fluidRow(
					box(
						title = "Heatmap representation in groups of samples",
						HTML(
                        '<div style="text-align:center">
                            <a id="reasonHeatmapPlot.download" class="btn btn-default shiny-download-link " href="" target="_blank">
                                <i class="fa fa-download" style="text-align:center"></i>
                                Download
                            </a>
                        </div>'
                        ),
						uiOutput("reasonHeatmapPlotui"),
						width = 12,
						solidHeader = TRUE,
						status = "primary",
						collapsible = TRUE
					)
				),
				fluidRow(
					box(
						title = "Standard deviation added to the mean for declaring expressed value",
						sliderInput("SDgroup", label = "", min = 0, max = 2, value = 1.5, step = 0.10, animate = TRUE),
						width = 12,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE

					)
				),
				fluidRow(
					box(
						title = "Enrichment representation in groups of samples",
						HTML(
                        '<div style="text-align:center">
                            <a id="enrichmentGroupHeatmapPlot.download" class="btn btn-default shiny-download-link " href="" target="_blank">
                                <i class="fa fa-download" style="text-align:center"></i>
                                Download
                            </a>
                        </div>'
                        ),
			HTML(
                            '<div style="text-align:center">
                                    <div class="radio-inline">
                                        <label>
					    <input id="ORoptionGroup" type="checkbox"/>
                                            <span>Odds Ratios</span>
                                        </label>
                                    </div>
                            </div>'
                        ),
						plotOutput("enrichmentGroupHeatmapPlot"),
						width = 12,
						solidHeader = TRUE,
						status = "primary",
						collapsible = TRUE
					)
				),
				fluidRow(
					box(
						title = "Enrichment in groups of samples: table of pvalues, OR[95%CI]",
						HTML(
                        '<div style="text-align:center">
                            <a id="tableGroups.download" class="btn btn-default shiny-download-link " href="" target="_blank">
                                <i class="fa fa-download" style="text-align:center"></i>
                                Download
                            </a>
                        </div>'
                        ),
						dataTableOutput("tableGroups"),
						width = 12,
						solidHeader = TRUE,
						status = "primary",
						collapsible = TRUE
					)
				)
				),

########################### Panel 5 #########################
			tabItem(tabName = "Global-representations-samples",
				h1("Heatmap and enrichment representations"),
				br(),
                br(),
				fluidRow(
					box(
						title = "Selection of the group of genes",
						### selection parmi les reason markers et others
						selectInput("reason2", label = "", choices = as.character(c(markers,others))),
						width = 12,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					)
				),
				fluidRow(
					box(
						title = "Selection of group(s) of samples",
						uiOutput("HeatmapPlotSelect1"),
						width = 6,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE

					),
					box(
						title = "Selection of samples",
						uiOutput("HeatmapPlotSelect2"),
						width = 6,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					)
				),
				fluidRow(
					box(
						title = "For adding cluster separation in the heatmap",
						sliderInput("ratio2", label = "", min = 0, max = 1, value = 0.00, step = 0.01, animate = TRUE),
						width = 4,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					),
					box(
						title = "For adjusting the heatmap height",
						sliderInput("height2", label = "", min = 0, max = 1, value = 0.70, step = 0.1, animate = TRUE),
						width = 4,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					),
					box(
						title = "For adjusting the heatmap width",
						sliderInput("width2", label = "", min = 0, max = 1, value = 0.70, step = 0.1, animate = TRUE),
						width = 4,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE
					)
				),
				fluidRow(
					box(
						title = "Heatmap representation in selected samples",
                        HTML(
                        '<div style="text-align:center">
                            <a id="reasonHeatmapPlot2.download" class="btn btn-default shiny-download-link " href="" target="_blank">
                                <i class="fa fa-download" style="text-align:center"></i>
                                Download
                            </a>
                        </div>'
                        ),
						uiOutput("reasonHeatmapPlotui2"),
						width = 12,
						solidHeader = TRUE,
						status = "primary",
						collapsible = TRUE
					)
				),
				fluidRow(
					box(
						title = "Standard deviation added to the mean for declaring expressed value",
						sliderInput("SDsample", label = "", min = 0, max = 2, value = 1.5, step = 0.10, animate = TRUE),
						width = 12,
						solidHeader = TRUE,
						status = "info",
						collapsible = TRUE

					)
				),

				fluidRow(
					box(
						title = "Enrichment representation in samples",
						HTML(
                        '<div style="text-align:center">
                            <a id="enrichmentSampleHeatmapPlot.download" class="btn btn-default shiny-download-link " href="" target="_blank">
                                <i class="fa fa-download" style="text-align:center"></i>
                                Download
                            </a>
                        </div>'
                        ),
			HTML(
                            '<div style="text-align:center">
                                    <div class="radio-inline">
                                        <label>
					    <input id="ORoptionSample" type="checkbox"/>
                                            <span>Odds Ratios</span>
                                        </label>
                                    </div>
                            </div>'
                        ),
						plotOutput("enrichmentSampleHeatmapPlot"),
						width = 12,
						solidHeader = TRUE,
						status = "primary",
						collapsible = TRUE
					)
				),
				fluidRow(
					box(
						title = "Enrichment in samples: table of pvalues, OR[95%CI]",
						HTML(
                        '<div style="text-align:center">
                            <a id="tableSamples.download" class="btn btn-default shiny-download-link " href="" target="_blank">
                                <i class="fa fa-download" style="text-align:center"></i>
                                Download
                            </a>
                        </div>'
                        ),
						dataTableOutput("tableSamples"),
						width = 12,
						solidHeader = TRUE,
						status = "primary",
						collapsible = TRUE
					)
				)
			)#,

########################### Panel 6 #########################
			# tabItem(tabName = "Markers-enrichment",
				# h1("Study of the enrichment among the markers"),
				# br(),
                # br(),
				# fluidRow(
					# box(
						# title = "Select a threshold to determine if a gene is expressed",
						# sliderInput("thresholdMarker", label = "", min = 0, max = 2, value = 1, step = 0.1, animate = TRUE),
						# width = 6,
						# solidHeader = TRUE,
						# status = "info",
						# collapsible = TRUE
					# ),
					# box(
						# title = "Select the marker groups",
						# uiOutput("MkGroup"),
						# width = 6,
						# solidHeader = TRUE,
						# status = "info",
						# collapsible = TRUE
					# )
				# ),
				# fluidRow(
					# box(
						# title = "Select the groups of samples",
						# uiOutput("MkEnrichmentGrPlotSelect"),
						# width = 12,
						# solidHeader = TRUE,
						# status = "info",
						# collapsible = TRUE
					# )
				# ),
				# fluidRow(
					# box(
						# title = "Enrichment analysis of the markers across the groups of samples",
                        # HTML(
                        # '<div style="text-align:center">
                            # <a id="enrichmentGroupPlot.download" class="btn btn-default shiny-download-link " href="" target="_blank">
                                # <i class="fa fa-download" style="text-align:center"></i>
                                # Download
                            # </a>
                        # </div>'
                        # ),
						# plotOutput("enrichmentGroupPlot", height = "600px"),
						# width = 12,
						# solidHeader = TRUE,
						# status = "primary",
						# collapsible = TRUE
					# )
				# ),
				# fluidRow(
					# box(
						# title = "Select the samples",
						# uiOutput("MkEnrichmentPlotSelect"),
						# width = 12,
						# solidHeader = TRUE,
						# status = "info",
						# collapsible = TRUE
					# )
				# ),
				# fluidRow(
					# box(
						# title = "Enrichment analysis of the markers across the samples",
                        # HTML(
                        # '<div style="text-align:center">
                            # <a id="enrichmentPlot.download" class="btn btn-default shiny-download-link " href="" target="_blank">
                                # <i class="fa fa-download" style="text-align:center"></i>
                                # Download
                            # </a>
                        # </div>'
                        # ),
						# plotOutput("enrichmentPlot", height = "600px"),
						# width = 12,
						# solidHeader = TRUE,
						# status = "primary",
						# collapsible = TRUE
					# )
				# )

			# ),

########################### Panel 7 #########################
			# tabItem(tabName = "Genes",
				# h1("Study of the enrichment among the genes"),
				# br(), br(),

				# fluidRow(
					# box(
						# title = "Select a threshold to determine if a gene is expressed",
						# sliderInput("thresholdGene", label = "", min = 0, max = 2, value = 1, step = 0.1, animate = TRUE),
						# width = 9,
						# solidHeader = TRUE,
						# status = "info",
						# collapsible = TRUE
					# ),
					# box(
						# title = "Select the gene groups",
						# uiOutput("GeneGroup"),
						# width = 3,
						# solidHeader = TRUE,
						# status = "info",
						# collapsible = TRUE
					# )
				# ),
				# fluidRow(
					# box(
						# title = "Select the groups of samples",
						# uiOutput("GeneEnrichmentGrPlotSelect"),
						# width = 12,
						# solidHeader = TRUE,
						# status = "info",
						# collapsible = TRUE
					# )
				# ),
				# fluidRow(
					# box(
						# title = "Enrichment analysis of the groups of genes across the samples",
                        # HTML(
                        # '<div style="text-align:center">
                            # <a id="geneEnrichmentGroupPlot.download" class="btn btn-default shiny-download-link " href="" target="_blank">
                                # <i class="fa fa-download" style="text-align:center"></i>
                                # Download
                            # </a>
                        # </div>'
                        # ),
						# plotOutput("geneEnrichmentGroupPlot", height = "600px"),
						# width = 12,
						# solidHeader = TRUE,
						# status = "primary",
						# collapsible = TRUE
					# )
				# ),
				# fluidRow(
					# box(
						# title = "Select the samples",
						# uiOutput("GeneEnrichmentPlotSelect"),
						# width = 12,
						# solidHeader = TRUE,
						# status = "info",
						# collapsible = TRUE
					# )
				# ),
				# fluidRow(
					# box(
						# title = "Representation of the enriched genes across the selected samples",
                        # HTML(
                        # '<div style="text-align:center">
                            # <a id="geneEnrichmentPlot.download" class="btn btn-default shiny-download-link " href="" target="_blank">
                                # <i class="fa fa-download" style="text-align:center"></i>
                                # Download
                            # </a>
                        # </div>'
                        # ),
						# plotOutput("geneEnrichmentPlot", height = "600px"),
						# width = 12,
						# solidHeader = TRUE,
						# status = "primary",
						# collapsible = TRUE
					# )
				# )
			# )

#################################################################
		)
	)
))
