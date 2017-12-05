gap_heatmap2 <- function (
        m,
        row_gap = NULL,
        col_gap = NULL,
        row_labels = TRUE,
        col_labels = TRUE,
        rotate = FALSE,
        col
) {
    sort_row <- FALSE
    r_order <- rownames(m)
    if (!is.null(row_gap)) {
        if (nrow(m) == nrow(row_gap$labels)) {
            sort_row <- TRUE
            r_order <- match(row_gap$labels$label, rownames(m))
        } else {
            stop(paste0("The numbers of rows between the matrix and row_gapdata are different. matrix:", nrow(m), " row:", nrow(row_gap$labels)))
            return(NULL)
        }
    } else {}
    sort_col <- FALSE
    c_order <- colnames(m)
    if (!is.null(col_gap)) {
        if (ncol(m) == nrow(col_gap$labels)) {
            sort_col <- TRUE
            c_order <- match(col_gap$labels$label, colnames(m))
        } else {
            stop(paste0("The numbers of columns between the matrix and col_gapdata are different. matrix:", ncol(m), " col:", nrow(col_gap$labels)))
            return(NULL)
        }
    }
    M <- m[r_order, c_order]
    if (sort_col) {
        colnames(M) <- as.character(col_gap$labels$x)
    } else {
        colnames(M) <- colnames(m)
    }
    if (sort_row) {
        rownames(M) <- as.character(row_gap$labels$x)
    } else {
        rownames(M) <- rownames(m)
    }
    M <- melt(M)
    colnames(M) <- c("y", "x", "value")
    if (!row_labels & !col_labels) {
        p <- ggplot(data = M, aes_string(x = "x", y = "y")) +
            geom_tile(aes_string(fill = "value")) +
            # scale_fill_gradient2(name = "Scaled\nexpression", low = col[1], mid = col[2], high = col[3]) +
            scale_fill_viridis(name = "Scaled\nexpression", option = "viridis") +
            theme(
                plot.margin = grid::unit(c(0, 0, grid::unit(-0.4, "line"), grid::unit(-0.4, "line")), "lines"),
                panel.background = element_blank(),
                panel.grid.major = element_blank(),
                panel.grid.minor = element_blank(),
                panel.border = element_blank(),
                axis.line = element_blank(),
                axis.text.x = element_blank(),
                axis.text.y = element_blank(),
                axis.ticks = element_blank(),
                axis.title.x = element_blank(),
                axis.title.y = element_blank(),
                line = element_blank(),
                legend.position = "none"
            ) +
            labs(x = NULL, y = NULL, title = NULL) +
            scale_x_continuous(expand = c(0, 0)) +
            scale_y_continuous(expand = c(0, 0))
    }
    else {
        p <- ggplot(data = M, aes_string(x = "x", y = "y")) +
            geom_tile(aes_string(fill = "value")) +
            # scale_fill_gradient2(name = "Scaled\nexpression", low = col[1], mid = col[2], high = col[3]) +
            scale_fill_viridis(name = "Scaled\nexpression", option = "viridis") +
            labs(title = NULL) +
            theme(
                plot.margin = grid::unit(c(0, 0, 0, 0), "lines"),
                panel.background = element_blank(),
                panel.grid.major = element_blank(),
                panel.grid.minor = element_blank(),
                panel.border = element_blank(),
                axis.line = element_blank(),
                axis.ticks = element_blank(),
                axis.title.x = element_blank(),
                axis.title.y = element_blank(),
                line = element_blank(),
                legend.position = "none"
            )
        if (row_labels & !is.null(row_gap)) {
            p <- p + scale_y_continuous(breaks = row_gap$labels$x, labels = row_gap$labels$label)
            if (rotate) {
                p <- p + theme(axis.text.y = element_text(color = "black", angle = 90))
            } else {
                p <- p + theme(axis.text.y = element_text(color = "black"))
            }
        } else {
            if (!row_labels | is.null(row_gap)) {
                p <- p + labs(y = NULL) + theme(axis.text.y = element_blank())
            } else {}
        }
        if (col_labels & !is.null(col_gap)) {
            p <- p + scale_x_continuous(breaks = col_gap$labels$x, labels = col_gap$labels$label) + theme(axis.text.x = element_text(color = "black"))
        } else {
            p <- p + labs(x = NULL) + theme(axis.text.x = element_blank())
        }
    }
    return(p)
}

gapmap2 <- function (
    m,
    d_row,
    d_col,
    mode = c("quantitative", "threshold"),
    mapping = c("exponential", "linear"),
    ratio = 0,
    scale = 0.5,
    threshold = 0,
    row_threshold = NULL,
    col_threshold = NULL,
    rotate_label = TRUE,
    verbose = FALSE,
    left = "label",
    top = "dendrogram",
    right = "dendrogram",
    bottom = "label",
    col = c("#ff0000", "#404640", "#00ff06"),
    h_ratio = c(0.15, 0.70, 0.15),
    v_ratio = c(0.15, 0.70, 0.15),
    label_size = 3,
    show_legend = TRUE,
    x.dendo = FALSE,
    y.dendo = TRUE, ...
) {
    if (is.null(m) | !inherits(m, "matrix")) {
        stop("You need to provide a matrix object.")
    } else {}
    noRowGaps <- FALSE
    if (!is.null(d_row) & !inherits(d_row, "dendrogram")) {
        stop("You need to provide a dendrogram object for d_row")
    } else if (is.null(d_row)) {
        noRowGaps <- TRUE
    }
    noColGaps <- FALSE
    if (!is.null(d_col) & !inherits(d_col, "dendrogram")) {
        stop("You need to provide a dendrogram object for d_col")
    } else if (is.null(d_col)) {
        noColGaps <- TRUE
    }
    if (nrow(m) != attr(d_row, "members")) {
        stop("The number of rows between the matrix and the d_row is not consistent.")
    } else {}
    if (ncol(m) != attr(d_col, "members")) {
        stop("The number of columns between the matrix and the d_col is not consistent.")
    } else {}

    mode <- match.arg(mode)
    mapping <- match.arg(mapping)
    if (is.null(row_threshold)) {
        row_threshold = threshold
    } else {}
    if (is.null(col_threshold)) {
        col_threshold = threshold
    } else {}

    left_item = NULL
    right_item = NULL
    top_item = NULL
    bottom_item = NULL

    if (noRowGaps) {
        row_data <- NULL
    } else {
        row_data <- gap_data(
            d = d_row,
            mode = mode,
            mapping = mapping,
            ratio = ratio,
            threshold = row_threshold,
            verbose = verbose,
            scale = scale
        )
    }

    if (noColGaps) {
        col_data <- NULL
    } else {
        col_data <- gap_data(
            d = d_col,
            mode = mode,
            mapping = mapping,
            ratio = ratio,
            threshold = col_threshold,
            verbose = verbose,
            scale = scale
        )
    }

    if (left == "dendrogram") {
        left_item = gap_dendrogram(data = row_data, leaf_labels = FALSE, orientation = "left")
    } else if (left == "label") {
        left_item = gap_label(row_data, "left", label_size)
    }

    if (top == "dendrogram") {
        top_item = gap_dendrogram(data = col_data, leaf_labels = FALSE, orientation = "top")
    } else if (left == "label") {
        top_item = gap_label(col_data, "top", label_size)
    }

    if (right == "dendrogram") {
        right_item = gap_dendrogram(data = row_data, leaf_labels = FALSE, orientation = "right")
    } else if (right == "label") {
        right_item = gap_label(row_data, "right", label_size)
    }

    if (bottom == "dendrogram") {
        bottom_item = gap_dendrogram(data = col_data, leaf_labels = FALSE, orientation = "bottom")
    } else if (bottom == "label") {
        bottom_item = gap_label(col_data, "bottom", label_size)
    }

    center_item = gap_heatmap2(
        m,
        row_gap = row_data,
        col_gap = col_data,
        row_labels = FALSE,
        col_labels = FALSE,
        col = col
    )
    hm <- center_item + theme(legend.position = c(0.50, 0.5)) +
        guides(fill = guide_colourbar(direction = "horizontal", title.position = "top"))
    tmp <- ggplot2::ggplot_gtable(ggplot2::ggplot_build(hm))
    leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
    legend <- tmp$grobs[[leg]]
    top.height = v_ratio[1]
    center.height = v_ratio[2]
    bottom.height = v_ratio[3]
    left.width = h_ratio[1]
    center.width = h_ratio[2]
    right.width = h_ratio[3]
    row.n = 3
    col.n = 3
    grid::grid.newpage()
    grid_layout <- grid::grid.layout(
        nrow = row.n,
        ncol = col.n,
        widths = grid::unit(c(left.width, center.width, right.width), "null"),
        heights = grid::unit(c(top.height, center.height, bottom.height), "null")
    )
    grid::pushViewport(grid::viewport(layout = grid_layout))

    if (left.width > 0 & !is.null(left_item)) {
        print(left_item, vp = grid::viewport(layout.pos.col = 1, layout.pos.row = 2))
    } else {}
    if ((top.height > 0 & !is.null(top_item)) & !y.dendo) {
        print(top_item, vp = grid::viewport(layout.pos.col = 2, layout.pos.row = 1))
    } else {}
    if ((right.width > 0 & !is.null(right_item)) & !x.dendo) {
        print(right_item, vp = grid::viewport(layout.pos.col = 3, layout.pos.row = 2))
    } else {}
    if (bottom.height > 0 & !is.null(bottom_item)) {
        print(bottom_item, vp = grid::viewport(layout.pos.col = 2, layout.pos.row = 3))
        print(center_item, vp = grid::viewport(layout.pos.col = 2, layout.pos.row = 2))
    } else {}
    if (show_legend) {
        grid::pushViewport(grid::viewport(layout.pos.col = 1, layout.pos.row = 3))
        grid::grid.draw(legend)
    } else {}
    grid::upViewport(0)
}

hm.plot <- function (
    x,
    ratio = 0.05,
    h_ratio = c(0.15, 0.70, 0.15),
    v_ratio = c(0.15, 0.70, 0.15),
    label_size = 3,
    col = c("#ff0000", "#404640", "#00ff06"),
    x.dendo = FALSE,
    y.dendo = TRUE
) {
    library(gapmap)
    x <- as.matrix(x)
    dimnames(x) <- list(gsub(" *$", "  ", rownames(x)), gsub(" *$", "  ", colnames(x)))

    row_hc <- hclust(dist(x), "ward.D")
    col_hc <- hclust(dist(t(x)), "ward.D")
    col_d <- as.dendrogram(col_hc)
    row_d <- as.dendrogram(row_hc)

    gapmap2(
        m = as.matrix(x),
        d_row = rev(row_d),
        d_col = col_d,
        ratio = ratio,
        h_ratio = h_ratio,
        v_ratio = v_ratio,
        label_size = label_size,
        col = col,
        show_legend = TRUE,
        x.dendo = x.dendo,
        y.dendo = y.dendo
    )
}