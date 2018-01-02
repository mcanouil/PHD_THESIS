library(xtable)
library(dplyr)
xtable::xtable(t(phenotypesDesirData %>% group_by(incT2D) %>% 
    summarise(
        SEX = paste0("1:", sum(SEX==1), "; 2:", sum(SEX==2)),
        AGE=paste0(signif(mean(AGE_D0, na.rm = TRUE), digits = 2), "(", signif(sd(AGE_D0, na.rm = TRUE), digits = 2), ")"),
        FG=paste0(signif(mean(FG_D0, na.rm = TRUE), digits = 2), "(", signif(sd(FG_D0, na.rm = TRUE), digits = 2), ")"),
        BMI=paste0(signif(mean(BMI_D0, na.rm = TRUE), digits = 2), "(", signif(sd(BMI_D0, na.rm = TRUE), digits = 2), ")"),
        HBA1C=paste0(signif(mean(HBA1C_D0, na.rm = TRUE), digits = 2), "(", signif(sd(HBA1C_D0, na.rm = TRUE), digits = 2), ")")
    )))


results.sign[, c("term", "RiskAllele", "RiskAlleleFrequency")]
results.topsign.unique[, "term"] <- results.topsign.unique[, "RSID"]
