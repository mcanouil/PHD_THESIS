### Open R version 3.2.3 or higher version
## Type the following command
install.packages(pkgs = c("shiny","shinydashboard", "parallel", "ggplot2", "grid", "scales", "broom", "xlsx", "lme4", "tidyr"), repos = "https://pbil.univ-lyon1.fr/CRAN", dependencies = TRUE)

## Launch Shiny by typing the following (with the exact location of the extract directory (EndoC_Beta) from the zip archive)
shiny::runApp("D:/Profils/mcanouil/Desktop/EndoC_Beta") # For example, if I unzipped the archive in my "Desktop" environment.
# or
library(shiny)
runApp("D:/Profils/mcanouil/Desktop/EndoC_Beta")