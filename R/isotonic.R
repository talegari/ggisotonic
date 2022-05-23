#' @importFrom dplyr `%>%`
#' @importFrom fdrtool monoreg

StatMonotonic = ggplot2::ggproto(
    "StatMonotonic",
    ggplot2::Stat,
    required_aes = c("x", "y"),
    optional_aes = c("w"),

    compute_group = function(data, scales, params, precision, type) {

        # error when 'w' is a non-numeric column
        if (!is.null(data$w) && !is.numeric(data$w)) {
            stop("weight column should be numeric")
        }

        # determine weights
        equal_weight = TRUE # equal weights
        if (!is.null(data$w) && is.numeric(data$w)) {
            equal_weight = FALSE # weights are provided
        }

        if (equal_weight) {
            df = data.frame("x" = data$x, "y" = data$y, "w" = 1)
        } else {
            df = data.frame("x" = data$x, "y" = data$y, "w" = data$w)
        }

        # aggregate one row per given 'x'
        df = na.omit(df)
        df = dplyr::mutate(df, x = round(x, precision))
        df = dplyr::group_by(df, x)
        df = dplyr::summarise(df,
                              y = weighted.mean(y, w),
                              w = mean(w)
                              )
        df = dplyr::ungroup(df)
        df = dplyr::arrange(df, x)

        # fit isotonic regression
        res_monoreg = fdrtool::monoreg(x = df$x,
                                       y = df$y,
                                       w = df$w,
                                       type = type
                                       )


        res = data.frame("x" = df$x, "y" = res_monoreg$yf)
        return(res)
    }
)

#' @export
#' @name stat_isotonic
#' @aliases stat_isotonic
#' @title stat from isotonic regression
#' @description Adds a stat with isotonic or monotonic regression based on
#'   `fdrtool::monoreg` with optional weights
#' @inheritParams ggplot2::stat_identity
#' @param precision Round 'x' with some precision to remove duplicates values
#' @param increasing (bool) Whether y increases with x (isotonic)
#' @return Returns a object of class 'gg', 'ggplot'
#' @examples
#' library("ggplot2")
#' set.seed(100)
#' dataset = data.frame(x = sort(runif(1e2)),
#'                   y = c(rnorm(1e2/2), rnorm(1e2/2, mean = 4)),
#'                   w = sample(1:3, 1e2, replace = TRUE)
#'                   )
#'
#' # plot isotonic regression line
#' ggplot(dataset, aes(x = x, y = y)) +
#'  geom_point() +
#'  stat_isotonic()
#'
#' # plot weighted isotonic regression line along with facets
#' ggplot(dataset, aes(x = x, y = y)) +
#'  geom_point() +
#'  stat_isotonic(aes(w = w), color = 'red', size = 1.5, show.legend = FALSE) +
#'  facet_wrap(w ~ .)
#'
stat_isotonic = function(mapping = NULL,
                          data = NULL,
                          geom = "line",
                          position = "identity",
                          show.legend = NA,
                          inherit.aes = TRUE,
                          precision = 4,
                          increasing = TRUE,
                          ...){

    # increasing should be a bool
    if (!(is.logical(increasing) && length(increasing) == 1)) {
        stop("increasing should be TRUE or FALSE")
    }

    if (increasing) {
        type = "isotonic"
    } else {
        type = "antitonic"
    }

    if (!(precision > 1 &&
          length(precision == 1) &&
          as.integer(precision) == precision
          )
        ) {
        stop("precision should be an positive integer")
    }

    ggplot2::layer(stat = StatMonotonic,
                   data = data,
                   mapping = mapping,
                   geom = geom,
                   position = position,
                   show.legend = show.legend,
                   inherit.aes = inherit.aes,
                   params = list(precision = precision,
                                 type = type,
                                 ...
                                 )
                  )
}

stat_monotonic = stat_isotonic
