install.packages("car")

library(tidyverse)
library(car)

# ---- 1) Load cross-sectional data ----
dat <- read.csv("life_expectancy_cross_section.csv", stringsAsFactors = FALSE)

# ---- 2) Summary statistics and Correlations ----
summary(dat[, c("life_exp", "gni_pc", "u5_mort", "co2_pc")])
sapply(dat[, c("life_exp", "gni_pc", "u5_mort", "co2_pc")], sd, na.rm = TRUE)

# ---- Correlation matrix ----
cor_vars <- dat %>%
  select(life_exp, gni_pc, u5_mort, co2_pc)

cor_matrix <- cor(cor_vars, use = "complete.obs")

round(cor_matrix, 3)

pairs(cor_vars,
      main = "Scatterplot Matrix: Life Expectancy and Predictors")

# ---- 3) Create transforms (raw/log/sqrt/sq/inv) ----
dat <- dat %>%
  mutate(
    # raw
    gni_raw = gni_pc, u5_raw = u5_mort, co2_raw = co2_pc,
    
    # log (requires >0)
    gni_log = ifelse(!is.na(gni_pc) & gni_pc > 0, log(gni_pc), NA_real_),
    u5_log  = ifelse(!is.na(u5_mort) & u5_mort > 0, log(u5_mort), NA_real_),
    co2_log = ifelse(!is.na(co2_pc) & co2_pc > 0, log(co2_pc), NA_real_),
    
    # sqrt (requires >=0)
    gni_sqrt = ifelse(!is.na(gni_pc) & gni_pc >= 0, sqrt(gni_pc), NA_real_),
    u5_sqrt  = ifelse(!is.na(u5_mort) & u5_mort >= 0, sqrt(u5_mort), NA_real_),
    co2_sqrt = ifelse(!is.na(co2_pc) & co2_pc >= 0, sqrt(co2_pc), NA_real_),
    
    # square
    gni_sq = ifelse(!is.na(gni_pc), gni_pc^2, NA_real_),
    u5_sq  = ifelse(!is.na(u5_mort), u5_mort^2, NA_real_),
    co2_sq = ifelse(!is.na(co2_pc), co2_pc^2, NA_real_),
    
    # inverse (requires >0)
    gni_inv = ifelse(!is.na(gni_pc) & gni_pc > 0, 1 / gni_pc, NA_real_),
    u5_inv  = ifelse(!is.na(u5_mort) & u5_mort > 0, 1 / u5_mort, NA_real_),
    co2_inv = ifelse(!is.na(co2_pc) & co2_pc > 0, 1 / co2_pc, NA_real_)
  )

# 4) INDIVIDUAL REGRESSIONS
# Compare functional forms with AIC

# Under-5
m_u5_raw  <- lm(life_exp ~ u5_raw,  data = dat)
m_u5_log  <- lm(life_exp ~ u5_log,  data = dat)
m_u5_sqrt <- lm(life_exp ~ u5_sqrt, data = dat)
m_u5_sq   <- lm(life_exp ~ u5_sq,   data = dat)
m_u5_inv  <- lm(life_exp ~ u5_inv,  data = dat)

AIC(m_u5_raw, m_u5_log, m_u5_sqrt, m_u5_sq, m_u5_inv)
summary(m_u5_raw); summary(m_u5_log); summary(m_u5_sqrt); summary(m_u5_sq); summary(m_u5_inv)

# GNI
m_gni_raw  <- lm(life_exp ~ gni_raw,  data = dat)
m_gni_log  <- lm(life_exp ~ gni_log,  data = dat)
m_gni_sqrt <- lm(life_exp ~ gni_sqrt, data = dat)
m_gni_sq   <- lm(life_exp ~ gni_sq,   data = dat)
m_gni_inv  <- lm(life_exp ~ gni_inv,  data = dat)

AIC(m_gni_raw, m_gni_log, m_gni_sqrt, m_gni_sq, m_gni_inv)
summary(m_gni_raw); summary(m_gni_log); summary(m_gni_sqrt); summary(m_gni_sq); summary(m_gni_inv)

# CO2
m_co2_raw  <- lm(life_exp ~ co2_raw,  data = dat)
m_co2_log  <- lm(life_exp ~ co2_log,  data = dat)
m_co2_sqrt <- lm(life_exp ~ co2_sqrt, data = dat)
m_co2_sq   <- lm(life_exp ~ co2_sq,   data = dat)
m_co2_inv  <- lm(life_exp ~ co2_inv,  data = dat)

AIC(m_co2_raw, m_co2_log, m_co2_sqrt, m_co2_sq, m_co2_inv)
summary(m_co2_raw); summary(m_co2_log); summary(m_co2_sqrt); summary(m_co2_sq); summary(m_co2_inv)

# 5) STEPWISE MULTIPLE REGRESSION 

step_dat <- dat %>%
  mutate(
    # re-assert transforms in case you edited earlier
    gni_raw  = gni_pc,
    u5_raw   = u5_mort,
    co2_raw  = co2_pc,
    
    gni_log  = ifelse(gni_pc  > 0, log(gni_pc),  NA_real_),
    u5_log   = ifelse(u5_mort > 0, log(u5_mort), NA_real_),
    co2_log  = ifelse(co2_pc  > 0, log(co2_pc),  NA_real_),
    
    gni_sqrt = ifelse(gni_pc  >= 0, sqrt(gni_pc),  NA_real_),
    u5_sqrt  = ifelse(u5_mort >= 0, sqrt(u5_mort), NA_real_),
    co2_sqrt = ifelse(co2_pc  >= 0, sqrt(co2_pc),  NA_real_),
    
    gni_sq   = gni_pc^2,
    u5_sq    = u5_mort^2,
    co2_sq   = co2_pc^2,
    
    gni_inv  = ifelse(gni_pc  > 0, 1 / gni_pc,  NA_real_),
    u5_inv   = ifelse(u5_mort > 0, 1 / u5_mort, NA_real_),
    co2_inv  = ifelse(co2_pc  > 0, 1 / co2_pc,  NA_real_)
  ) %>%
  
  filter(
    complete.cases(
      life_exp,
      gni_raw, gni_log, gni_inv, gni_sqrt, gni_sq,
      u5_raw,  u5_log,  u5_inv,  u5_sqrt,  u5_sq,
      co2_raw, co2_log, co2_inv, co2_sqrt, co2_sq
    )
  )

nrow(step_dat)

m_null <- lm(life_exp ~ 1, data = step_dat)

m_upper <- lm(
  life_exp ~
    gni_raw + gni_log + gni_inv + gni_sqrt + gni_sq +
    u5_raw  + u5_log  + u5_inv  + u5_sqrt  + u5_sq  +
    co2_raw + co2_log + co2_inv + co2_sqrt + co2_sq,
  data = step_dat
)

m_step0 <- step(
  m_null,
  scope = list(lower = m_null, upper = m_upper),
  direction = "both",
  trace = TRUE
)

# Enforce hierarchy for sqrt/sq
terms_now <- attr(terms(m_step0), "term.labels")

need_raw <- character(0)
if (any(grepl("^gni_(sqrt|sq)$", terms_now))) need_raw <- c(need_raw, "gni_raw")
if (any(grepl("^u5_(sqrt|sq)$",  terms_now))) need_raw <- c(need_raw, "u5_raw")
if (any(grepl("^co2_(sqrt|sq)$", terms_now))) need_raw <- c(need_raw, "co2_raw")
need_raw <- setdiff(unique(need_raw), terms_now)

if (length(need_raw) == 0) {
  m_final <- m_step0
} else {
  f_new <- update(formula(m_step0), paste(". ~ . +", paste(need_raw, collapse = " + ")))
  m_fix <- lm(f_new, data = step_dat)
  
  m_lower <- lm(
    as.formula(paste("life_exp ~", paste(c("1", need_raw), collapse = " + "))),
    data = step_dat
  )
  
  m_final <- step(
    m_fix,
    scope = list(lower = m_lower, upper = m_upper),
    direction = "both",
    trace = TRUE
  )
}
vif(m_final)

summary(m_final)

# 6) PLOTS

# Histograms 
ggplot(dat, aes(life_exp)) +
  geom_histogram(bins = 20, fill = "grey80", color = "black") +
  labs(
    title = "Distribution of Life Expectancy",
    x = "Life Expectancy (years)",
    y = "Number of Countries"
  ) +
  theme(plot.title = element_text(hjust = 0.5))

ggplot(dat, aes(gni_pc)) +
  geom_histogram(bins = 25, fill = "grey80", color = "black") +
  scale_x_log10() +
  labs(
    title = "Distribution of GNI per Capita",
    x = "GNI per Capita (log scale, USD)",
    y = "Number of Countries"
  ) +
  theme(plot.title = element_text(hjust = 0.5))

ggplot(dat, aes(u5_mort)) +
  geom_histogram(bins = 25, fill = "grey80", color = "black") +
  scale_x_log10() +
  labs(
    title = "Distribution of Under-5 Mortality Rates",
    x = "Under-5 Mortality (per 1,000 live births, log scale)",
    y = "Number of Countries"
  ) +
  theme(plot.title = element_text(hjust = 0.5))

ggplot(dat, aes(co2_pc)) +
  geom_histogram(bins = 25, fill = "grey80", color = "black") +
  scale_x_log10() +
  labs(
    title = "Distribution of CO₂ Emissions per Capita",
    x = "CO₂ Emissions per Capita (log scale, metric tons)",
    y = "Number of Countries"
  ) +
  theme(plot.title = element_text(hjust = 0.5))


# Boxplot: life expectancy by income quartile (raw GNI)
dat <- dat %>%
  mutate(
    income_group = cut(
      gni_pc,
      breaks = quantile(gni_pc, c(0, .25, .5, .75, 1), na.rm = TRUE),
      labels = c("Low", "Lower-Middle", "Upper-Middle", "High"),
      include.lowest = TRUE
    )
  )

ggplot(dat, aes(income_group, life_exp)) +
  geom_boxplot(fill = "grey80", color = "black") +
  labs(
    title = "Life Expectancy by Income Group",
    x = "Income Group (based on GNI per Capita)",
    y = "Life Expectancy (years)"
  ) +
  theme(plot.title = element_text(hjust = 0.5))


# Scatterplots (raw x, log x-axis + log-fit line)
ggplot(dat, aes(gni_pc, life_exp)) +
  geom_point(alpha = 0.7) +
  scale_x_log10() +
  geom_smooth(method = "lm", formula = y ~ log(x), se = TRUE) +
  labs(
    title = "Life Expectancy vs GNI per Capita",
    x = "GNI per Capita (log scale, USD)",
    y = "Life Expectancy (years)"
  ) +
  theme(plot.title = element_text(hjust = 0.5))


ggplot(dat, aes(u5_mort, life_exp)) +
  geom_point(alpha = 0.7) +
  scale_x_log10() +
  geom_smooth(method = "lm", formula = y ~ log(x), se = TRUE) +
  labs(
    title = "Life Expectancy vs Under-5 Mortality Rate",
    x = "Under-5 Mortality (per 1,000 live births, log scale)",
    y = "Life Expectancy (years)"
  ) +
  theme(plot.title = element_text(hjust = 0.5))

ggplot(dat, aes(co2_pc, life_exp)) +
  geom_point(alpha = 0.7) +
  scale_x_log10() +
  geom_smooth(method = "lm", formula = y ~ log(x), se = TRUE) +
  labs(
    title = "Life Expectancy vs CO₂ Emissions per Capita",
    x = "CO₂ Emissions per Capita (log scale, metric tons)",
    y = "Life Expectancy (years)"
  ) +
  theme(plot.title = element_text(hjust = 0.5))

# 7) DIAGNOSTICS (4-panel)
par(mfrow = c(2, 2)); plot(m_u5_log);  par(mfrow = c(1, 1))
par(mfrow = c(2, 2)); plot(m_gni_log); par(mfrow = c(1, 1))
par(mfrow = c(2, 2)); plot(m_co2_log); par(mfrow = c(1, 1))
par(mfrow = c(2, 2)); plot(m_final);   par(mfrow = c(1, 1))


