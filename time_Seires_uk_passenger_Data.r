
tsdata <- read.csv('Book3.csv', header=TRUE, sep=",")
View(tsdata)


###for ireland only
myts   <- ts(tsdata$Ireland, start=c(1996, 1), end=c(2005, 4), frequency=4) 

# plot series
plot(myts)

####decompose function###

fit <- decompose(myts, type = c("multiplicative"))
fit$seasonal
fit$trend
fit$type  #multiplicative
plot(fit)  

##stl()

fit <- stl(myts, s.window="period")
plot(fit)  
print(fit$time.series)  
  
#Exponential Models
#Both the HoltWinters() function in the base installation, and the ets() function in the forecast package, can be used to fit exponential models
#Forecast package
# simple exponential - models level
fit1 <- HoltWinters(myts, beta=FALSE, gamma=FALSE)
ls(fit1)
require(forecast)
accuracy(fit1$fitted, myts) #MAPE = 10.80, MAE = 127

# double exponential - models level and trend
fit2 <- HoltWinters(myts, gamma=FALSE)
accuracy(fit2$fitted, myts)
# triple exponential - models level, trend, and seasonal components
fit3 <- HoltWinters(myts)
accuracy(fit3$fitted, myts) #MAPE - 3.304
forecast(fit3, 2)

# predictive accuracy
library(forecast)

###using ets function
fit<-ets(myts)
accuracy(fit$fitted, myts) # MAPE = 2.428
summary(fit)
x <-forecast(fit, 4)  # predict next four future values
plot(forecast(fit, 4))

###
ndiffs(myts)

###
pacf(myts)
acf(myts)

# fit an ARIMA model of order P, D, Q
fit <- arima(myts, order=c(1, 0, 1))
summary(fit)  #MAPE = 10.389

fit <-auto.arima(myts)
ls(fit)
fit$model
fit$series
summary(fit)   ##MAPE = 2.492

# predictive accuracy
library(forecast)
accuracy(fit)

# predict next 4 observations
library(forecast)
forecast(fit, 4)
plot(forecast(fit, 4))

#Automated Forecasting
#The forecast package provides functions for the automatic selection of exponential and ARIMA models. 
#The ets() function supports both additive and multiplicative models. 
#The auto.arima() function can handle both seasonal and nonseasonal ARIMA models. Models are chosen to maximize one of several fit criteria.


##for other EU - not IRELAND##
myts1 <- ts(tsdata$Other.EU.not.Ireland, start=c(1996, 1), end=c(2005, 4), frequency=4) 

# plot series
plot(myts1)

####decompose function###

fit <- decompose(myts1, type = c("multiplicative"))
fit$seasonal
fit$trend
fit$type  
plot(fit)  

##stl()

fit <- stl(myts1, s.window="period")
plot(fit)  
print(fit$time.series)  


# predictive accuracy
library(forecast)
accuracy(fit)

fit<-ets(myts1)
accuracy(fit$fitted, myts1) #MAPE - 2.279
summary(fit)
y <- forecast(fit, 4)
plot(forecast(fit, 4))

# predict next four future values
forecast(fit, 4)
plot(forecast(fit, 4))

###
ndiffs(myts1)

###
pacf(myts)
acf(myts1)

# fit an ARIMA model of order P, D, Q
fit <- arima(myts1, order=c(0, 1, 0))
summary(fit)

fit <-auto.arima(myts1)
ls(fit)
fit$model
fit$series
summary(fit)  #3.094999 accuracy

# predictive accuracy
library(forecast)
accuracy(fit)

# predict next 4 observations
library(forecast)
forecast(fit, 4)
plot(forecast(fit, 4))




  ####### for rest of Europe ########
  
  ##for rest europe##
  myts3 <- ts(tsdata$Rest.of.Europe..and.Med, start=c(1996, 1), end=c(2005, 4), frequency=4) 
  
  # plot series
  plot(myts3)
  
  ####decompose function###
  fit <- decompose(myts3, type = c("multiplicative"))
  fit$seasonal
  fit$trend
  fit$type  
  plot(fit)  
  
  ##stl()
  
  fit <- stl(myts3, s.window="period")
  plot(fit)  
  print(fit$time.series)  
  
  
  # predictive accuracy
  library(forecast)
  accuracy(fit)
  
  fit<-ets(myts3)
  accuracy(fit$fitted, myts3)   ###MAPE - 2.8717
  summary(fit)
  
  # predict next four future values
  u <- forecast(fit, 4)
  plot(forecast(fit, 4))
  
  ###
  ndiffs(myts3)
  
  ###
  pacf(myts3)
  acf(myts3)
  
  # fit an ARIMA model of order P, D, Q
  fit <- arima(myts3, order=c(1, 0, 1))
  summary(fit)
  
  fit <-auto.arima(myts3)
  ls(fit)
  fit$model
  fit$series
  summary(fit)  # MAPE - 3.568
  
  # predictive accuracy
  library(forecast)
  
  # predict next 4 observations
  forecast(fit, 4)
  plot(forecast(fit, 4))
  
  
  ####### for rest of world########
  
  myts4 <- ts(tsdata$Rest.of.World, start=c(1996, 1), end=c(2005, 4), frequency=4) 
  
  # plot series
  plot(myts4)
  
  ####decompose function###
  fit <- decompose(myts4, type = c("multiplicative"))
  fit$seasonal
  fit$trend
  fit$type  
  plot(fit)  
  
  ##stl()
  
  fit <- stl(myts4, s.window="period")
  plot(fit)  
  print(fit$time.series)  
  
  # simple exponential - models level
  fit1 <- HoltWinters(myts4, beta=FALSE, gamma=FALSE)
  ls(fit1)
  require(forecast)
  accuracy(fit1$fitted, myts4)
  
  # double exponential - models level and trend
  fit2 <- HoltWinters(myts4, gamma=FALSE)
  accuracy(fit2$fitted, myts4)
  # triple exponential - models level, trend, and seasonal components
  fit3 <- HoltWinters(myts4)
  accuracy(fit3$fitted, myts4)
  forecast(fit3, 4) ##8.74 acc
  
  # predictive accuracy
  library(forecast)
  
  fit<-ets(myts4)
  accuracy(fit$fitted, myts4) ##7.70 is MAPE
  summary(fit) 
  
  # predict next four future values
  v <- forecast(fit, 4)
  plot(forecast(fit, 4))
  

  # fit an ARIMA model of order P, D, Q
  fit <- arima(myts4, order=c(1, 0, 1))
  summary(fit)
  
  fit <-auto.arima(myts4)
  ls(fit)
  fit$model
  fit$series
  summary(fit)  #8.607 is the accuracy
  
  # predictive accuracy
  library(forecast)
  accuracy(fit)
  
  # predict next 4 observations
  library(forecast)
  forecast(fit, 4)
  plot(forecast(fit, 4))
  
  
  
  #for total##
  myts5 <- ts(tsdata$Total, start=c(1996, 1), end=c(2005, 4), frequency=4) 
  
  # plot series
  plot(myts5)
  
  ####decompose function###
  fit <- decompose(myts5, type = c("multiplicative"))
  fit$seasonal
  fit$trend
  fit$type  
  plot(fit)  
  
  ##stl()
  
  fit <- stl(myts5, s.window="period")
  plot(fit)  
  print(fit$time.series)  
  
  
  # predictive accuracy
  library(forecast)
  
  fit<-ets(myts5)
  accuracy(fit$fitted, myts5) ##MAPE = 1.9487
  summary(fit)
  
  # predict next four future values
  z <- forecast(fit, 4)
  plot(forecast(fit, 4))
  
  ###
  ndiffs(myts5)
  
  ###
  pacf(myts5)
  acf(myts5)
  
  # fit an ARIMA model of order P, D, Q
  fit <- arima(myts5, order=c(1, 0, 1))
  summary(fit)
  
  fit <-auto.arima(myts5)
  ls(fit)
  fit$model
  fit$series
  summary(fit)  #2.429914 is the accuracy
  
  # predictive accuracy
  library(forecast)
  accuracy(fit)
  
  # predict next 4 observations
  library(forecast)
  forecast(fit, 4)
  total <-  plot(forecast(fit, 4))
  
  