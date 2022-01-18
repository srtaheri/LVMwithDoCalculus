library(purrr)
library(rstan)
library(bayesplot)
library(ggplot2)
library(mvtnorm)
library(parallel)
library(usethis)
library(reshape2)
library(ggplot2)

#seed = 60
seed = 20 #250 #252 #254
set.seed(seed)
L = 1
D = 10 #50 $10
N = 1

#create the true parameters
#Sigma_uu <- matrix(0, nrow = L, ncol = 1)
Sigma_uu = diag(L)
mu <- matrix(0, nrow = 1, ncol = L)
for (i in 1:L) {
    mu[1,i] <- rnorm(1,0,10)
}
theta_UX <- matrix(0, nrow = L, ncol = N)
for(i in 1:L){
    for(j in 1:N){
        theta_UX[i, j] <- rnorm(1, 0, 1)
    }
}
theta_XM <- matrix(0, nrow = N, ncol = 1)
theta_UY <- matrix(0, nrow = L, ncol = 1)
for (i in 1:N) {
    theta_XM[i,1] <- rnorm(1,0,1)
}
for (i in 1:L) {
    theta_UY[i,1] <- rnorm(1,0, 10)
}
theta_MY <- matrix(rnorm(1,0,10), nrow = 1, ncol = 1)

set.seed(seed)
f_u <- function(mu, Sigma_uu){
    #Sigma_uu = diag(L)
    u <- matrix(0, nrow=D, ncol=L)
    for(i in 1:D){
        for(j in 1:L){
            u[i, j] <- rnorm(1, mu[1,j], sqrt(Sigma_uu[j,j]))
        }
    }
    return(list(u = u
                #, Sigma_uu = Sigma_uu
    ))
}
sim <- f_u(mu, Sigma_uu)
u_train <- sim$u
#Sigma_uu  <- sim$Sigma_uu

f_x <- function(u, Sigma_uu, theta_UX){
    linear_exp = u %*% theta_UX
    Sigma_xx = t(theta_UX) %*% Sigma_uu %*% theta_UX + diag(N)
    x <- matrix(0, nrow = D, ncol = N)
    for(i in 1:D){
        for(j in 1:N){
            x[i, j] <- rnorm(1, linear_exp[i,j],sqrt(Sigma_xx[j,j]))
        }
    }
    return(list(x = x, Sigma_xx = Sigma_xx))
}
sim_x <- f_x(u_train, Sigma_uu, theta_UX)
x_train <- sim_x$x
Sigma_xx <- sim_x$Sigma_xx

f_m <- function(x, Sigma_xx, theta_XM){
    linear_exp = x %*% theta_XM
    Sigma_mm = t(theta_XM) %*% Sigma_xx %*% theta_XM + 1
    m <- matrix(0, nrow = D, ncol = 1)
    for(i in 1:D){
        m[i, 1] <- rnorm(1, linear_exp[i,1],sqrt(Sigma_mm[1,1]))
    }
    return(list(m = m, Sigma_mm = Sigma_mm[1,1]))
}
sim_m <- f_m(x_train, Sigma_xx, theta_XM)
m_train <- sim_m$m
Sigma_mm <- sim_m$Sigma_mm

f_y <- function(u, m, Sigma_uu, Sigma_mm, theta_UX, theta_XM, theta_UY, theta_MY){
    linear_exp = m %*% theta_MY + u %*% theta_UY
    Sigma_yy = t(theta_MY) %*% Sigma_mm %*% theta_MY +
        2 * (t(theta_UY) %*% Sigma_uu %*% theta_UX %*% theta_XM %*% theta_MY) +
        t(theta_UY) %*% Sigma_uu %*% theta_UY + 1
    y <- matrix(0, nrow = D, ncol = 1)
    for(i in 1:D){
        y[i, 1] <- rnorm(1, linear_exp[i,1],sqrt(Sigma_yy[1,1]))
    }
    return(list(y = y, Sigma_yy = Sigma_yy[1,1]))
}
sim_y <- f_y(u_train, m_train, Sigma_uu, Sigma_mm, theta_UX, theta_XM, theta_UY, theta_MY)
y_train <- sim_y$y
Sigma_yy <- sim_y$Sigma_yy
