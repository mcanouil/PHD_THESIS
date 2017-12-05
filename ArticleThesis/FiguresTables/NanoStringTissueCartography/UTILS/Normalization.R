### normalization: function to normalize nanostring expression data
	# normSet: set of probes used to normalise
	# normCategory: name of a set of probes used to normalise, e.g. "housekeeping gene", then all the HK genes are taken into account
    normalization <- function (normSet = NULL, normCategory = "housekeeping gene", expressions, genes = genes) {
        # 1- get the mean of the normalisation probes
        if (is.null(normSet)) {
            normSet <- unique(genes[which(genes[, "Reason"] == normCategory), "Accession"])
        } else {}
        # 2 - remove background
        background <- apply(expressions[match(genes[which(genes[, "CodeClass"] == "Negative"), "Accession"], row.names(expressions)), ], 2, quantile, probs = 0.2)
        expr <- sweep(expressions, 2, background, "-")
        # 3 - log2 of ratio over housekeeping genes
        if(length(normSet) > 1) {
            normF <- colMeans(expr[normSet, ])
        } else {}
        if (length(normSet) == 1) {
            normF <- expr[normSet, ]
        } else {}
        expr <- sweep(expr, 2, normF, "/", check.margin = FALSE)
        expr[expr<0] <- NA
        expr <- log2(expr)
        expr[is.infinite(expr)] <- NA
        expr <- expr[sort(unique(match(genes[which(genes[, "CodeClass"] == "Endogenous"), "Accession"], row.names(expressions)))), ]
        return(expr)
    }