#' In this script, we perform a simple linear regression model 

### --- 0. Loading libraries--- ####
library(INLA)


### -  Bayesian estimation of the parameters of a simple linear regression --- ###
### --- 1. Generating the data --- ####
set.seed(100) #Fix the seed
n <- 10000 #Number of data
sigma <- 0.1 #standard deviation
beta.0 <- 2 #Parameter
beta.1 <- 0.5 #Parameter

#Covariate
x <- runif(n)

#Mean
mu <- beta.0 + beta.1*x

#Response variable
y <- rnorm(n,mu,sigma)

#We create the data.frame
data <- data.frame(y <- y, x <- x)
colnames(data) <- c("y", "x")
#Plot the data
plot(data$x, data$y)

head(data)


formula <- y ~ 1 + x # 1 is refered to the intercept term

### --- Call inla for the estimation --- ###
model1 <- inla(formula, 
               family       = 'gaussian', 
               data         = data,
               control.fixed = list(mean = 0, prec = 1,
                                    mean.intercept = 0, prec.intercept = 0.0001))


summary(model1)





### --- 2. Defining the formula and fitting the model --- ####
formula <- y ~ 1 + x # 1 is refered to the intercept term

### --- Call inla for the estimation --- ###
model1 <- inla(formula, 
               family       = 'gaussian', 
               data         = data)
summary(model1)


### --- 3. Obtaining posterior distribution of the fixed effects --- ####
names(model1$marginals.fixed) #Names of the fixed effects
post.beta0 <- model1$marginals.fixed$`(Intercept)`
post.beta1 <- model1$marginals.fixed$x

### --- Plot both posteriors distribution --- ###
### --- Intercept --- ###
plot(inla.smarginal(post.beta0),
     type = "l",
     xlab = "",
     ylab = "",
     main = expression(paste("Posterior distribution ", 
                             beta[0])))

hpd.beta0 = inla.hpdmarginal(p=0.95,post.beta0)

abline(v = beta.0)
abline(v = hpd.beta0[1],lty=2,col=2)
abline(v = hpd.beta0[2],lty=2,col=2)

### --- Slope --- ###
plot(inla.smarginal(post.beta1),
     type = "l",
     xlab = "",
     ylab = "",
     main = expression(paste("Posterior distribution ", 
                             beta[1])))

hpd.beta1 = inla.hpdmarginal(p=0.95,post.beta1) #95% credible intervals
abline(v = beta.1)
abline(v = hpd.beta1[1],lty=2,col=2)
abline(v = hpd.beta1[2],lty=2,col=2)


### --- 4. Posterior distributions of the hyperparameters --- ####
names(model1$marginals.hyperpar) 
post.sigma = inla.tmarginal(function(x) sqrt(1/x),
                            model1$marginals.hyperpar[[1]])

### --- Plot in the same way than before --- ###
plot(inla.smarginal(post.sigma),
     type = "l",
     xlab = "",
     ylab = "",
     main = expression(paste("Posterior distribution ", 
                             sigma)))
hpd.sigma = inla.hpdmarginal(p=0.95,post.sigma)
abline(v=sigma)
abline(v=hpd.sigma[1],lty=2,col=2)
abline(v=hpd.sigma[2],lty=2,col=2)

### --- summary of sigma --- ###
inla.zmarginal(post.sigma)



#### --- All the posteriors --- ### plot
#pdf("posterioris.pdf", width=10, height=4)
par(mfrow=c(1,3))
par(mar=c(5,5,4,0))
### --- Intercept --- ###
plot(inla.smarginal(post.beta0),type="l",xlab="",ylab="",
     main=expression(paste("Posterior distribution ", beta[0])))
hpd.beta0 = inla.hpdmarginal(p=0.95,post.beta0)
abline(v=beta.0)
abline(v=hpd.beta0[1],lty=2,col=2)
abline(v=hpd.beta0[2],lty=2,col=2)

### --- Slope --- ###
plot(inla.smarginal(post.beta1),type="l",xlab="",ylab="",
     main=expression(paste("Posterior distribution ", beta[1])))
hpd.beta1 = inla.hpdmarginal(p=0.95,post.beta1) #95% credible intervals
abline(v=beta.1)
abline(v=hpd.beta1[1],lty=2,col=2)
abline(v=hpd.beta1[2],lty=2,col=2)

### --- Plot in the same way than before --- ###
plot(inla.smarginal(post.sigma),type="l",xlab="",
     ylab="",main=expression(paste("Posterior distribution ", sigma)))
hpd.sigma = inla.hpdmarginal(p=0.95,post.sigma)
abline(v=sigma)
abline(v=hpd.sigma[1],lty=2,col=2)
abline(v=hpd.sigma[2],lty=2,col=2)
#dev.off()


### --- 5. Modifying priors --- ####
### ----- 5.1. Fixed effects --- ####
formula <- y ~ 1 + x
# formula <- y ~1 + f(x, model = "linear", 
#                     mean.linear = 0, 
#                     prec.linear = 0.001)
model2 <- inla(formula, 
               family        = "gaussian", 
               data          = data,
               control.inla  = list(strategy = "simplified.laplace"),
               control.fixed = list(mean = 0, prec = 1,
                                mean.intercept = 0, prec.intercept = 0.0001))
              

### --- Intercept --- ###
plot(inla.smarginal(post.beta0),
     type = "l",
     xlab = "",
     ylab = "",
     main = expression(paste("Posterior distribution ", 
                             beta[0])))

lines(inla.smarginal(model2$marginals.fixed[[1]]), col="red")

abline(v=beta.0)
legend("topleft",col=c(1,2),lty=c(1,1),
       legend=c("Default","Normal(0,0.0001)"),box.lty=0)

### --- Slope --- ###
plot(inla.smarginal(post.beta1),
     type = "l",
     xlab = "",
     ylab = "",
     main = expression(paste("Posterior distribution ", 
                             beta[1])))
lines(inla.smarginal(model2$marginals.fixed[[2]]), col="red")
abline(v = beta.1)
legend("topleft", 
       col    = c(1,2),
       lty    = c(1,1),
       legend = c("Default","Normal(0,1)"),box.lty=0)


### ----- 5.2. Hyperparameters --- ####
### ------- 5.2.1. Gaussian for the log.precision --- ###
model3 <- inla(formula, 
               family         = "gaussian", 
               data           = data,
               control.family =list(hyper=list(
                 prec = list(prior = "gaussian",
                             param = c(0,1))))
)

### ------- 5.2.2. logGamma modifying parameters --- ####
model4 <- inla(formula, 
               family         = "gaussian", 
               data           = data,
               control.family = list(hyper = list(
                 prec = list(prior = "loggamma", 
                             param = c(1, 0.01))))
)


### --- Posteriors distribution for sigma --- ###
post.sigma3 = inla.tmarginal(function(x) sqrt(1/x),
                             model3$marginals.hyperpar[[1]])
post.sigma4 = inla.tmarginal(function(x) sqrt(1/x),
                             model4$marginals.hyperpar[[1]])

plot(inla.smarginal(post.sigma),type="l",xlab="",
     ylab="",main=expression(paste("Posterior distribution ", sigma)))
lines(inla.smarginal(post.sigma3),col=2)
lines(inla.smarginal(post.sigma4),col=3)
abline(v=sigma)
legend("topright",col=c(1,2,3),lty=c(1,1,1),
       legend=c("Default","Normal(0,1)","logGamma(1,0.01)"),box.lty=0)



#pdf("posterioris2.pdf", width=12, height=4)
par(mfrow=c(1,3))
### --- Intercept --- ###
plot(inla.smarginal(post.beta0),type="l",xlab="",ylab="",
     main=expression(paste("Posterior distribution ", beta[0])))
lines(inla.smarginal(model2$marginals.fixed[[1]]), col="red")
abline(v=beta.0)
legend("topleft",col=c(1,2),lty=c(1,1),
       legend=c("Default","Normal(0,0.0001)"),box.lty=0)

### --- Slope --- ###
plot(inla.smarginal(post.beta1),type="l",xlab="",ylab="",
     main=expression(paste("Posterior distribution ", beta[1])))
lines(inla.smarginal(model2$marginals.fixed[[2]]), col="red")
abline(v=beta.1)
legend("topleft",col=c(1,2),lty=c(1,1),
       legend=c("Default","Normal(0,1)"),box.lty=0)

### --- Deviation --- ###
plot(inla.smarginal(post.sigma),type="l",xlab="",
     ylab="",main=expression(paste("Post. marg. of ", sigma)))
lines(inla.smarginal(post.sigma3),col=2)
lines(inla.smarginal(post.sigma4),col=3)
abline(v=sigma)
legend("topright",col=c(1,2,3),lty=c(1,1,1),
       legend=c("Default","Normal(0,1)","logGamma(1,0.01)"),box.lty=0)
#dev.off()



### --- 6. Model Selection --- #######

### Again, we fit he model1, and we also calculate DIC, WAIC and LCPO. After, we
# with the null model.
formula_null <- y~1
model_null <- inla(formula_null, 
                   family          = 'gaussian', 
                   data            = data,
                   control.compute = list(dic=TRUE, waic=TRUE, cpo=TRUE))
summary(model_null)

model1<- inla(formula, 
              family          = 'gaussian', 
              data            = data,
              control.compute = list(dic=TRUE, waic=TRUE, cpo=TRUE))
summary(model1)

selection <- data.frame(DIC  = c(model_null$dic$dic, model1$dic$dic),
                        WAIC = c(model_null$waic$waic, model1$waic$waic),
                        LCPO = c(-mean(log(model_null$cpo$cpo)), -mean(log(model1$cpo$cpo))))
rownames(selection)<-c("null", "covariate")
selection

## Model1 has improved the fit of the null model
model_null$cpo$cpo



