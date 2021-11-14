#' @importFrom magrittr %>%

StatMonotonic = ggplot2::ggproto(
    "StatMonotonic",
    ggplot2::Stat,
    required_aes = c("x", "y", "w"),

    compute_group = function(data, scales, params, precision) {

        if (all(data$w == 1)) {
            df = data.frame("x" = data$x, "y" = data$y) %>%
                    na.omit() %>%
                    dplyr::mutate(x = round(x, precision)) %>%
                    dplyr::group_by(x) %>%
                    dplyr::summarise(y = mean(y)) %>%
                    dplyr::ungroup() %>%
                    dplyr::arrange(x)

            res_monoreg = fdrtool::monoreg(x = df$x, y = df$y)

        } else {

            df = data.frame("x" = data$x, "y" = data$y, "w" = data$w) %>%
                    dplyr::mutate(x = round(x, precision)) %>%
                    dplyr::group_by(x) %>%
                    dplyr::summarise(y = weighted.mean(y, w),
                                     w = mean(w)
                    ) %>%
                    dplyr::ungroup() %>%
                    dplyr::arrange(x)

            res_monoreg = fdrtool::monoreg(x = df$x, y = df$y, w = df$w)
        }

        res = data.frame("x" = df$x, "y" = res_monoreg$yf)
        return(res)
    }
)

#' @export
#' @name stat_isotonic
#' @title stat from isotonic regression
#' @description Adds a stat with isotonic or monotonic regression based on
#'   `fdrtool::monoreg` with optional weights
#' @inheritParams ggplot2::stat_identity
#' @param precision Round 'x' with some precision to remove duplicates values
#' @examples
#' library("ggplot2")
#' dataset = data.frame(x = sort(runif(1e2)),
#'                      y = c(rnorm(1e2/2), rnorm(1e2/2, mean = 4)),
#'                      w = sample(1:3, 1e2, replace = TRUE)
#'                      )
#'
#' # plot unweighted isotonic regression line
#' ggplot(dataset, aes(x = x, y = y)) +
#'     geom_point() +
#'     stat_isotonic(aes(w = 1))
#'
#' # plot weighted isotonic regression line
#' ggplot(dataset, aes(x = x, y = y)) +
#'     geom_point() +
#'     stat_isotonic(aes(w = w, color = 'red'), show.legend = FALSE) +
#'     facet_wrap(w ~ .)
#'
stat_isotonic = function(mapping = NULL,
                          data = NULL,
                          geom = "line",
                          position = "identity",
                          show.legend = NA,
                          inherit.aes = TRUE,
                          precision = 4,
                          ...){

    ggplot2::layer(stat = StatMonotonic,
                   data = data,
                   mapping = mapping,
                   geom = geom,
                   position = position,
                   show.legend = show.legend,
                   inherit.aes = inherit.aes,
                   params = list(precision = precision, ...)
    )
}

stat_monotonic = stat_isotonic
