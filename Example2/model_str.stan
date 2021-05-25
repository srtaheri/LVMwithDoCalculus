//
// This Stan program defines a simple model, with a
// vector of values 'y' modeled as normally distributed
// with mean 'mu' and standard deviation 'sigma'.
//
// Learn more about model development with Stan at:
//
//    http://mc-stan.org/users/interfaces/rstan.html
//    https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started
//
data {
  int L;
  int D;
  int N;
  matrix[D, N] x;
  matrix[D, 1] m;
  matrix[D, 1] y;
}
parameters {
  matrix[1, L] mu;
  matrix[L, N] theta_UX;
  matrix[N, 1] theta_XM;
  matrix[L, 1] theta_UY;
  matrix[1,1] theta_MY;
  vector<lower=0>[L] u_scale;
  matrix[D, L] u;
}
transformed parameters {
  cov_matrix[L] sigma_uu;
  matrix[D, N] x_loc;
  matrix[D, 1] m_loc;
  matrix[D, 1] y_loc;
  vector[N] x_scale;
  vector[1] y_scale;
  vector[1] m_scale;
  matrix[N, N] sigma_xx;
  matrix[1,1] sigma_mm;
  matrix[1,1] sigma_yy;
  sigma_uu = diag_matrix(u_scale);
  sigma_xx = theta_UX'*sigma_uu*theta_UX + diag_matrix(rep_vector(1, N));
  x_scale = sqrt(diagonal(sigma_xx));
  sigma_mm = theta_XM'*sigma_xx*theta_XM + diag_matrix(rep_vector(1, 1));
  m_scale = sqrt(diagonal(sigma_mm));
  sigma_yy = theta_MY'*sigma_mm*theta_MY + 2*theta_UY'*sigma_uu*theta_UX*theta_XM*theta_MY + theta_UY'*sigma_uu*theta_UY + diag_matrix(rep_vector(1, 1));
  y_scale = sqrt(diagonal(sigma_yy));
  for (i in 1:D){
    x_loc[i, ] = u[i, ] * theta_UX;
    m_loc[i, ] = x[i, ] * theta_XM;
    y_loc[i, ] = m[i,] * theta_MY + u[i,] * theta_UY;
  }
}
// The model to be estimated. We model the output
// 'y' to be normally distributed with mean 'mu'
// and standard deviation 'sigma'.
model {
  target += normal_lpdf(u_scale[1] | 1, 1);
  target += normal_lpdf(mu[1,] | 0, 10);
  target += normal_lpdf(theta_MY[1,1] | 0, 10);
  for (j in 1:L){
    target += normal_lpdf(theta_UX[j, ] | 0, 1);
    target += normal_lpdf(theta_UY[j, ] | 0, 10);
  }
  for (j in 1:N){
    target += normal_lpdf(theta_XM[j, ] | 0, 1);
  }
  for (i in 1:D){
    target += normal_lpdf(u[i, ] | mu[1,], u_scale);      // likelihood
    target += normal_lpdf(x[i, ] | x_loc[i, ], x_scale);
    target += normal_lpdf(m[i, ] | m_loc[i, ], m_scale);
    target += normal_lpdf(y[i, ] | y_loc[i, ], y_scale);
  }
}
