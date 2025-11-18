rm(list = ls())

# 1. Poder analítico ----

# Función de poder analítico para diferencia de proporciones (dos grupos independientes)
power_diff_prop <- function(p1, p2, n1, n2 = n1, alpha = 0.05) {
  delta   <- p2 - p1
  var_hat <- p1 * (1 - p1) / n1 + p2 * (1 - p2) / n2
  se_hat  <- sqrt(var_hat)
  
  z_alpha <- qnorm(1 - alpha / 2)    # test bilateral
  z_eff   <- abs(delta) / se_hat     # tamaño de efecto en unidades-z
  
  # Aproximación: Z ~ N(z_eff, 1)
  power   <- pnorm(z_eff - z_alpha)
  return(power)
}

# poder para detectar una diferencia de -0.15 (0.40 vs 0.25)
p_B <- 0.40  # Björn (hombre sueco)
p_M <- 0.25  # Muhammad (hombre árabe)

Js <- c(500, 750, 1000, 1500)  # número de anuncios
power_vals <- sapply(Js, function(J) power_diff_prop(p1 = p_B, p2 = p_M, n1 = J, n2 = J))

data.frame(J = Js, power_analitico = round(power_vals, 3))


## 2. Simulación con clustering ---

library(sandwich)
library(lmtest)

# Una simulación para un J dado
simulate_once <- function(J, p_B = 0.40, p_A = 0.45, p_M = 0.25) {
  # 1) Construir data frame con 3 solicitantes por anuncio
  listing_id <- 1:J
  df <- expand.grid(
    listing = listing_id,
    type    = c("B", "A", "M"),  # Björn, Astrid, Muhammad
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  
  # 2) Asignar probabilidades según tipo
  df$p <- ifelse(df$type == "B", p_B,
                 ifelse(df$type == "A", p_A, p_M))
  
  # 3) Simular outcome de callback
  df$Y <- rbinom(n = nrow(df), size = 1, prob = df$p)
  
  # 4) Variables de tratamiento (base: Björn)
  df$A <- as.integer(df$type == "A")  # Astrid (mujer sueca)
  df$M <- as.integer(df$type == "M")  # Muhammad (hombre árabe)
  
  # 5) Modelo de probabilidad lineal con cluster a nivel anuncio
  mod <- lm(Y ~ A + M, data = df)
  vcov_cl <- vcovCL(mod, cluster = ~ listing)  # clustering por anuncio
  
  test_M <- coeftest(mod, vcov. = vcov_cl)["M", ]  # efecto Muhammad vs Björn
  p_value_M <- test_M["Pr(>|t|)"]
  
  return(p_value_M)
}

# Función de poder simulado para un tamaño J
power_simulation <- function(J, p_B = 0.40, p_A = 0.45, p_M = 0.25,
                             R = 1000, alpha = 0.05, seed = 123) {
  set.seed(seed)
  pvals <- replicate(R, simulate_once(J, p_B, p_A, p_M))
  power_hat <- mean(pvals < alpha, na.rm = TRUE)
  return(power_hat)
}

# curva de poder simulada para distintos J
Js <- c(500, 750, 1000, 1500)
power_sim <- sapply(Js, function(J) power_simulation(J, R = 500))  # R = 500

data.frame(J = Js, power_simulado = round(power_sim, 3))


## 3. MDE analítico ----

# MDE analítico aproximado para dos proporciones (delta >= 0)
mde_diff_prop <- function(p_base, J, alpha = 0.05,
                          target_power = 0.80,
                          max_delta = 0.5) {
  
  f <- function(delta) {
    p1 <- p_base
    p2 <- p_base + delta
    # mantener p2 dentro de (0,1)
    if (p2 >= 1) p2 <- 1 - 1e-8
    if (p2 <= 0) p2 <- 1e-8
    power_diff_prop(p1 = p1, p2 = p2, n1 = J, n2 = J, alpha = alpha) - target_power
  }
  
  # En delta = 0 el poder es básicamente el nivel
  f0   <- f(0)
  fmax <- f(max_delta)
  
  # Si ni con max_delta alcanzamos el poder objetivo, no hay solución en el rango
  if (fmax < 0) {
    warning("No se alcanza el poder deseado con el max_delta especificado.")
    return(NA_real_)
  }
  
  # Si ya en delta muy pequeño se alcanza el poder, MDE ~ 0
  if (f0 >= 0) {
    return(0)
  }
  
  # f(0) < 0, f(max_delta) >= 0
  uniroot(f, lower = 0, upper = max_delta)$root
}

# MDE para p_B = 0.40, J en {500, 1000, 1500}
Js <- c(500, 1000, 1500)
mde_vals <- sapply(Js, function(J) mde_diff_prop(p_base = 0.40, J = J))

data.frame(J = Js, MDE = round(mde_vals, 3))

# Tabla
Js <- c(500, 750, 1000, 1500)

power_analitico <- sapply(Js, function(J) power_diff_prop(p1 = p_B, p2 = p_M, n1 = J, n2 = J))
power_simulado  <- sapply(Js, function(J) power_simulation(J, R = 500))
mde_vals        <- sapply(Js, function(J) mde_diff_prop(p_base = 0.40, J = J))

tabla_resumen <- data.frame(
  J                = Js,
  power_analitico  = round(power_analitico, 3),
  power_simulado   = round(power_simulado, 3),
  MDE_80pct        = round(mde_vals, 3)
)

tabla_resumen


# 4. Poder para heterogeneidad privado vs empresa ----

simulate_once_hetero <- function(J,
                                 p_E_priv = 0.45, p_A_priv = 0.25,
                                 p_E_emp  = 0.35, p_A_emp  = 0.30,
                                 share_priv = 0.5) {
  listing_id <- 1:J
  # Asignar tipo de arrendador a cada anuncio (1 = privado, 0 = empresa)
  priv <- rbinom(J, size = 1, prob = share_priv)
  
  df <- expand.grid(listing = listing_id,
                    type    = c("E", "M", "A"),
                    KEEP.OUT.ATTRS = FALSE,
                    stringsAsFactors = FALSE)
  df$private <- priv[df$listing]
  
  # Probabilidades según tipo y private empresa
  df$p <- NA_real_
  df$p[df$type == "E" & df$private == 1] <- p_E_priv
  df$p[df$type == "A" & df$private == 1] <- p_A_priv
  df$p[df$type == "E" & df$private == 0] <- p_E_emp
  df$p[df$type == "A" & df$private == 0] <- p_A_emp
  
  # Para M, fijamos una probabilidad fija (0.45)
  df$p[df$type == "M"] <- 0.45
  
  df$Y <- rbinom(nrow(df), 1, df$p)
  
  df$A <- as.integer(df$type == "A")
  df$M <- as.integer(df$type == "M")
  
  mod <- lm(Y ~ A * private + M * private, data = df)
  vcov_cl <- vcovCL(mod, cluster = ~ listing)
  
  # Interacción A:private = diferencia-en-diferencias de la brecha A–E
  test_inter_A  <- coeftest(mod, vcov. = vcov_cl)["A:private", ]
  p_val_inter_A <- test_inter_A["Pr(>|t|)"]
  
  return(p_val_inter_A)
}

power_sim_hetero <- function(J, R = 1000, alpha = 0.05, seed = 123) {
  set.seed(seed)
  pvals <- replicate(R, simulate_once_hetero(J = J))
  mean(pvals < alpha, na.rm = TRUE)
}

# poder para detectar heterogeneidad con J = 1000
power_hetero_J1000 <- power_sim_hetero(J = 1000, R = 500)
power_hetero_J1000


## 5. Cobertura del IC para el efecto A vs E ---

coverage_simulation <- function(J, p_E = 0.40, p_M = 0.45, p_A = 0.25,
                                R = 1000, alpha = 0.05, seed = 123) {
  set.seed(seed)
  true_tau <- p_A - p_E
  
  inside <- logical(R)
  
  for (r in 1:R) {
    # Simulemos el exp
    listing_id <- 1:J
    df <- expand.grid(listing = listing_id,
                      type    = c("E", "M", "A"),
                      KEEP.OUT.ATTRS = FALSE,
                      stringsAsFactors = FALSE)
    df$p <- ifelse(df$type == "E", p_E,
                   ifelse(df$type == "M", p_M, p_A))
    df$Y <- rbinom(nrow(df), 1, df$p)
    df$A <- as.integer(df$type == "A")
    df$M <- as.integer(df$type == "M")
    
    mod <- lm(Y ~ A + M, data = df)
    vcov_cl <- vcovCL(mod, cluster = ~ listing)
    
    beta_hat <- coef(mod)["A"]
    se_hat   <- sqrt(diag(vcov_cl))["A"]
    
    z_alpha  <- qnorm(1 - alpha / 2)
    ci_lower <- beta_hat - z_alpha * se_hat
    ci_upper <- beta_hat + z_alpha * se_hat
    
    inside[r] <- (true_tau >= ci_lower && true_tau <= ci_upper)
  }
  
  coverage_hat <- mean(inside)
  return(coverage_hat)
}

# cobertura con J = 1000
coverage_J1000 <- coverage_simulation(J = 1000, R = 500)
coverage_J1000


