## Hex logo for AgriFusionR, drawn once and rendered to PNG and SVG.
## The picture carries the package's two ideas: layers of data fused over a
## field (soil, canopy, climate) and a growth curve rising through them, with
## the field divided into blocks as spatial resampling divides it.

W <- 174; H <- 200
vx <- c(87, 172, 172,  87,   2,   2)
vy <- c(198, 149,  51,   2,  51, 149)

## x-extent of the hexagon at a given height, so bands follow the outline
hex_x <- function(y) {
    if (y <= 51)  { d <- (y - 2) / 49 * 85;   c(87 - d, 87 + d) }
    else if (y >= 149) { d <- (y - 149) / 49 * 85; c(2 + d, 172 - d) }
    else c(2, 172)
}

band <- function(y0, y1, col, n = 60) {
    ys <- seq(y0, y1, length.out = n)
    L <- t(vapply(ys, hex_x, numeric(2)))
    polygon(c(L[, 1], rev(L[, 2])), c(ys, rev(ys)), col = col, border = NA)
}

draw_logo <- function() {
    par(mar = rep(0, 4), xaxs = "i", yaxs = "i", bg = NA)
    plot(NA, xlim = c(0, W), ylim = c(0, H), asp = 1, axes = FALSE,
         xlab = "", ylab = "")

    ## body
    polygon(vx, vy, col = "#12211C", border = NA)

    ## sky, warming toward the horizon
    ## run the sky right up into the top vertex, or a dark wedge is left there
    sky <- colorRampPalette(c("#102A40", "#1E4A5F"))(46)
    ys <- seq(197, 126, length.out = 46)
    for (i in seq_along(ys)) band(ys[i] - 1.9, ys[i], sky[i])

    ## sun: the heat-stress side of the story
    for (i in 14:1) {
        a <- seq(0, 2 * pi, length.out = 60)
        polygon(136 + i * 1.05 * cos(a), 160 + i * 1.05 * sin(a),
                col = grDevices::adjustcolor("#E8B33C", alpha.f = 0.055),
                border = NA)
    }
    a <- seq(0, 2 * pi, length.out = 80)
    polygon(136 + 8.5 * cos(a), 160 + 8.5 * sin(a), col = "#F0C24E",
            border = NA)

    ## canopy
    band(86, 126, "#2E6B44")
    ## soil, with strata
    band(46, 86, "#4A3B2A")
    for (yy in c(56, 66, 76)) {
        e <- hex_x(yy)
        segments(e[1] + 6, yy, e[2] - 6, yy, col = "#5C4A34", lwd = 2)
    }

    ## the field divided into blocks, as spatial resampling divides it
    for (bx in seq(18, 156, length.out = 7)) {
        e0 <- hex_x(88); e1 <- hex_x(124)
        if (bx > max(e0[1], e1[1]) + 3 && bx < min(e0[2], e1[2]) - 3) {
            segments(bx, 88, bx, 124,
                     col = grDevices::adjustcolor("#12211C", alpha.f = 0.35),
                     lwd = 1.6)
        }
    }
    ## horizon
    e <- hex_x(126); segments(e[1], 126, e[2], 126, col = "#1B3B2A", lwd = 2)

    ## growth curve: thermal time rising through the layers
    tt <- seq(0, 1, length.out = 200)
    gx <- 30 + tt * 112
    gy <- 74 + 74 / (1 + exp(-(tt - 0.5) * 9))
    lines(gx, gy, col = grDevices::adjustcolor("#F0C24E", alpha.f = 0.30),
          lwd = 9, lend = 1)
    lines(gx, gy, col = "#F5D06A", lwd = 4.2, lend = 1)
    points(gx[length(gx)], gy[length(gy)], pch = 19, cex = 1.5,
           col = "#FFE49A")

    ## wordmark, placed where the hex is still wide enough to hold it
    text(87, 30, "AgriFusionR", col = "#EAF2EC", cex = 1.18, font = 2,
         family = "sans")

    ## border last, so nothing overlaps it
    polygon(vx, vy, col = NA, border = "#4E9E6A", lwd = 5)
}

out <- Sys.getenv("OUT")
png(file.path(out, "logo.png"), width = 1044, height = 1200, res = 300,
    bg = "transparent")
draw_logo(); dev.off()
svg(file.path(out, "logo.svg"), width = 174 / 72 * 2, height = 200 / 72 * 2,
    bg = "transparent")
draw_logo(); dev.off()
cat("rendered\n")
