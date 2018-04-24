require(xlsx)
require(readxl)
setwd("C:\\Users\\Vineet\\Documents\\analytixlabs\\R prog\\BA\\regression")


mydata <- readxl::read_excel("Book1.xlsx")
View(mydata)
str(mydata)

mystats <- function(x) {
  nmiss<-sum(is.na(x))
  a <- x[!is.na(x)]
  m <- mean(a)
  n <- length(a)
  s <- sd(a)
  min <- min(a)
  p1<-quantile(a,0.01)
  p5<-quantile(a,0.05)
  p10<-quantile(a,0.10)
  q1<-quantile(a,0.25)
  q2<-quantile(a,0.5)
  q3<-quantile(a,0.75)
  p90<-quantile(a,0.90)
  p95<-quantile(a,0.95)
  p99<-quantile(a,0.99)
  max <- max(a)
  UC <- m+3*s
  LC <- m-3*s
  outlier_flag<- max>UC | min<LC
  return(c(n=n, nmiss=nmiss, outlier_flag=outlier_flag, mean=m, stdev=s,min = min, p1=p1,p5=p5,p10=p10,q1=q1,q2=q2,q3=q3,p90=p90,p95=p95,p99=p99,max=max, UC=UC, LC=LC ))
}

diag_stats<-t(data.frame(apply(mydata, 2, mystats)))

write.csv(diag_stats, file = "diag_stats1.csv")

mydata<- mydata[!is.na(mydata$townsize),] 
mydata<- mydata[!is.na(mydata$longten),] 
mydata<- mydata[!is.na(mydata$lnlongten),] 
mydata<- mydata[!is.na(mydata$commutetime),] 
mydata<- mydata[!is.na(mydata$lnothdebt),] 
mydata<- mydata[!is.na(mydata$othdebt),] 
mydata<- mydata[!is.na(mydata$creddebt),] 

#### 8 variables have high no of missing values

## OUTLIERS

mydata$lnlongten[mydata$lnlongten > 8.452987681] <- 8.452987681
mydata$lnlongten[mydata$lnlongten < 0.875468737] <- 0.875468737
mydata$tollmon[mydata$lnlongmon > 3.605767556] <- 3.605767556
mydata$tollmon[mydata$lnlongmon < 0.615185639] <- 0.615185639
mydata$longmon[mydata$longmon > 36.81] <- 36.81
mydata$tollmon[mydata$longten>2569.95] <- 2569.95
mydata$tollmon[mydata$tollmon>58.7525] <- 58.7525
mydata$lninc[mydata$lninc > 5.606095645] <- 5.606095645
mydata$creddebt[mydata$creddebt > 6.3831072] <- 6.3831072
mydata$lncreddebt[mydata$lncreddebt > 1.853652551] <- 1.853652551
mydata$othdebt[mydata$othdebt > 11.8270464] <- 11.8270464
mydata$lncreddebt[mydata$lncreddebt < -3.401968067] <- -3.401968067
mydata$lnothdebt[mydata$lnothdebt > 2.470388119] <- 2.470388119
mydata$lnothdebt[mydata$lnothdebt < -2.14984977] <- -2.14984977
mydata$carvalue[mydata$carvalue > 71.94] <- 71.94
mydata$commutetime[mydata$commutetime > 35] <- 35
mydata$carditems[mydata$carditems > 16] <- 16
mydata$carditems[mydata$carditems < 2] <- 2 
mydata$card2items[mydata$card2items > 9] <- 9
mydata$card2spent[mydata$card2spent > 419.074] <- 419.074
mydata$debtinc[mydata$debtinc > 21.8] <- 21.8
mydata$longten[mydata$longten > 2569.95] <- 2569.95
mydata$commutetime[mydata$commutetime > 35] <- 35
mydata$lnlongmon[mydata$lnlongmon > 3.605767556] <- 3.605767556



require(corrplot)
corrplot(cor(mydata,use = "pairwise.complete.obs"),method = "circle",tl.cex = 0.7)


#Splitting data into Training, Validaton and Testing Dataset
train_ind <- sample(1:nrow(mydata), size = floor(0.70 * nrow(mydata)))

training<-mydata[train_ind,]
testing<-mydata[-train_ind,]


# Multiple Linear Regression Example 
fit <- lm(cardspent ~ ., data=training)
summary(fit)

fit1 <- lm(cardspent ~ ed + lninc + debtinc + lnothdebt + carvalue + card + 
             card2 + carditems + card2items + card2spent + tollmon, data=training)
summary(fit1)

require(MASS)
step3<- stepAIC(fit,direction="backward")
?stepAIC()
ls(step3)
step3$anova

library(car)
vif(fit1)

coefficients(fit1) # model coefficients
confint(fit1, level=0.95) # CIs for model parameters 
fitted(fit1) # predicted values
residuals(fit1) # residuals
anova(fit1) # anova table 
influence(fit1) # regression diagnostics


#####

setwd("C:\\Users\\Vineet\\Documents\\analytixlabs\\R prog\\BA\\regression")

df <- readxl::read_excel("Linear Regression Case.xlsx")
str(df)
colnames(df)
require(ggplot2)

##scatterplot b/w 2 vars
Scatter.Plot2 <- ggplot(df, aes(x=hourstv, y=cardspent)) 
Scatter.Plot2 + geom_point(shape=19,alpha = 1/20)  + geom_smooth(method = lm) +ggtitle("Correlation of number of orders with Gross Sales")

### hist of one var
q <- ggplot(data = df,aes(x = hourstv))
q + geom_histogram(binwidth = .1,colour = "black") +coord_cartesian(xlim = c(0,30))

### by qplot
qplot(hourstv,data = df,binwidth = 0.1, geom = c('density'))

##cor.test
cor.test(df$hourstv,df$cardspent) ## 0.03 

colnames(df)

###wireten
log(df$wireten+1)
cor.test(log(df$wireten+1),df$cardspent) ## 0.09782
qplot(wireten,data = df,binwidth = 10, geom = c('density'))
Scatter.Plot2 <- ggplot(df, aes(x=wireten, y=cardspent)) 
Scatter.Plot2 + geom_point(shape=19,alpha = 1/20) + 
geom_smooth(method = lm) + 
ggtitle("Correlation of number of orders with Gross Sales")


### ---cardten--- ###
Scatter.Plot3 <- ggplot(df, aes(x=log(cardten) + 1, y=cardspent)) 
Scatter.Plot3 + geom_point(shape=19,alpha = 1/20) + 
geom_smooth(method = lm) 
qplot(log(cardten+1),data = df,binwidth = 100, geom = c('density'))

cor.test(log(df$cardten+1),df$cardspent) ## 0.0418

# ---cardmon
Scatter.Plot4 <- ggplot(df, aes(x=log(cardmon + 1), y=cardspent)) 
Scatter.Plot4 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(log(cardmon+1),data = df,binwidth = 100, geom = c('density'))
cor.test(log(df$cardmon+1),df$cardspent) ## 0.03051668


###-equipten-###
Scatter.Plot4 <- ggplot(df, aes(x=log(equipten + 1), y=cardspent)) 
Scatter.Plot4 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(equipten,data = df,binwidth = 100, geom = c('density'))
cor.test(df$equipten,df$cardspent) ## 0.03051668

###tollten
Scatter.Plot5 <- ggplot(df, aes(x=log(tollten + 1), y=cardspent)) 
Scatter.Plot5 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(log(tollten+1),data = df,binwidth = 100, geom = c('density'))
cor.test(log(df$tollten+1),df$cardspent) ## 0.0710

##tollmon
Scatter.Plot6 <- ggplot(df, aes(x=log(tollten + 1), y=cardspent)) 
Scatter.Plot6 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(log(tollten+1),data = df,binwidth = 100, geom = c('density'))
cor.test(log(df$tollmon+1),df$cardspent) ## 0.064

##longten
Scatter.Plot7 <- ggplot(df, aes(x=log(longten + 1), y=cardspent)) 
Scatter.Plot7 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(log(longten+1),data = df,binwidth = 100, geom = c('density'))
cor.test(log(df$longten+1),df$cardspent) ## 0.067

##longmon
Scatter.Plot8 <- ggplot(df, aes(x=log(longmon + 1), y=cardspent)) 
Scatter.Plot8 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(log(longmon+1),data = df,binwidth = 100, geom = c('density'))
cor.test(log(df$longmon+1),df$cardspent) ## 0.057

#anova of churn
m <- lm(cardspent ~ churn, data = df)
anova(m)

#tenure#
Scatter.Plot9 <- ggplot(df, aes(x=tenure, y=cardspent)) 
Scatter.Plot9 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(tenure,data = df,binwidth = 100, geom = c('density'))
cor.test(df$tenure,df$cardspent) ## 0.0645

#card2spent
Scatter.Plot10 <- ggplot(df, aes(x=card2spent, y=cardspent)) 
Scatter.Plot10 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(log(card2spent+1),data = df,binwidth = 100, geom = c('density'))
cor.test(log(df$card2spent+1),df$cardspent) ## 0.43

##card2tenure
Scatter.Plot11 <- ggplot(df, aes(x=card2tenure, y=cardspent)) 
Scatter.Plot11 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(card2tenure,data = df,binwidth = 100, geom = c('density'))
cor.test(df$card2tenure,df$cardspent) ## 0.074

##cardtenure
Scatter.Plot12 <- ggplot(df, aes(x=log(cardtenure+1), y=cardspent)) 
Scatter.Plot12 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(cardtenure,data = df,binwidth = 100, geom = c('density'))
cor.test(df$cardtenure,df$cardspent) ## 0.0724

##commutetime
Scatter.Plot13 <- ggplot(df, aes(x=log(commutetime+1), y=cardspent)) 
Scatter.Plot13 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(commutetime,data = df,binwidth = 100, geom = c('density'))
cor.test(df$commutetime,df$cardspent) ## 0.0724

##carvalue
Scatter.Plot14 <- ggplot(df, aes(x=carvalue, y=cardspent)) 
Scatter.Plot14 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(carvalue,data = df,binwidth = 100, geom = c('density'))
cor.test(df$carvalue,df$cardspent) ## 0.298

###age
Scatter.Plot15 <- ggplot(df, aes(x=age, y=cardspent)) 
Scatter.Plot15 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(log(age+1),data = df,binwidth = 100, geom = c('density'))
cor.test(log(df$age+1),df$cardspent) ## 0.0579

##ed
Scatter.Plot16 <- ggplot(df, aes(x=ed, y=cardspent)) 
Scatter.Plot16 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(ed,data = df,binwidth = 100, geom = c('density'))
cor.test(df$ed,df$cardspent) ## 0.1037

##employ
Scatter.Plot17 <- ggplot(df, aes(x=employ, y=cardspent)) 
Scatter.Plot17 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(log(employ+1),data = df,binwidth = 100, geom = c('density'))
cor.test(log(df$employ+1),df$cardspent) ## 0.0974


##income
Scatter.Plot18 <- ggplot(df, aes(x=income, y=cardspent)) 
Scatter.Plot18 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(log(income+1),data = df,binwidth = 100, geom = c('density'))
cor.test(log(df$income+1),df$cardspent) ## 0.3681

##debtinc
Scatter.Plot19 <- ggplot(df, aes(x=log(debtinc+1), y=cardspent)) 
Scatter.Plot19 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(log(debtinc+1),data = df,binwidth = 100, geom = c('density'))
cor.test(log(df$debtinc+1),df$cardspent) ## 0.00744


#lncreddebt
Scatter.Plot20 <- ggplot(df, aes(x=lncreddebt, y=cardspent)) 
Scatter.Plot20 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(lncreddebt,data = df,binwidth = 100, geom = c('density'))
cor.test(df$lncreddebt,df$cardspent) ## 0.2296

##pets##
require(ggplot2)
Scatter.Plot40 <- ggplot(df, aes(x=pets, y=cardspent)) 
Scatter.Plot40 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(pets,data = df,binwidth = 100, geom = c('density'))
cor.test(df$pets,df$cardspent) ## low

##othdebt
Scatter.Plot21 <- ggplot(df, aes(x=log(othdebt+1), y=cardspent)) 
Scatter.Plot21 + geom_point(shape=19,alpha = 1/20) + geom_smooth(method = lm) 
qplot(log(othdebt+1),data = df,binwidth = 1, geom = c('density'))
cor.test(log(df$othdebt+1),df$cardspent) ## 0.2650

## Region ##
df$region <-as.factor(df$region)
a1<- aov(cardspent~region, data = df)
summary(a1) 

##townsize
df$townsize <-as.factor(df$townsize)
a2<- aov(cardspent~townsize, data = df)
summary(a2) 

##edcat
df$edcat <-as.factor(df$edcat)
a2<- aov(cardspent~edcat, data = df)
summary(a2) 

##jobcat
df$jobcat <-as.factor(df$jobcat)
a3<- aov(cardspent~jobcat, data = df)
summary(a3) 

##empcat
df$empcat <-as.factor(df$empcat)
a3<- aov(cardspent~empcat, data = df)
summary(a3) 


##pets

b1<- aov(cardspent~pets_saltfish, data = df)
summary(b1) 
str(df)


##retire
df$retire <-as.factor(df$retire)
a4<- aov(cardspent~retire, data = df)
summary(a4) 


##inccat
df$inccat <-as.factor(df$inccat)
a5<- aov(cardspent~inccat, data = df)
summary(a5) 

#jobsat
df$jobsat <-as.factor(df$jobsat)
a5<- aov(cardspent~jobsat, data = df)
summary(a5) 

#default
df$default <-as.factor(df$default)
a6<- aov(cardspent~default, data = df)
summary(a6) 

#spousedcat
df$spousedcat <-as.factor(df$spousedcat)
a8<- aov(cardspent~spousedcat, data = df)
summary(a8)  ##0.00429

#reside
df$reside <-as.factor(df$reside)
a9<- aov(cardspent~reside, data = df)
summary(a9) 

###owntv - significant
a9<- aov(cardspent~owntv, data = df)
summary(a9) 


##ownvcr - significant
a35<- aov(cardspent~ownvcr, data = df)
summary(a35) 

##owndvd - significant
a36<- aov(cardspent~owndvd, data = df)
summary(a36) 

##ownpc - significant
a38<- aov(cardspent~ownpc, data = df)
summary(a38) 

#owngame  - significant
a39<- aov(cardspent~owngame, data = df)
summary(a39) 

##news - significant
a40<- aov(cardspent~news, data = df)
summary(a40) 


#homeown
df$homeown <-as.factor(df$homeown)
a9<- aov(cardspent~homeown, data = df)
summary(a9) 

##hometype
df$homeown <-as.factor(df$hometype)
a10<- aov(cardspent~hometype, data = df)
summary(a10) 

##addresscat
df$addresscat <-as.factor(df$addresscat)
a11 <- aov(cardspent~addresscat, data = df)
summary(a11) 

##carown
df$carown <-as.factor(df$carown)
a12 <- aov(cardspent~carown, data = df)
summary(a12) 

##cartype
df$cartype <-as.factor(df$cartype)
a13 <- aov(cardspent~cartype, data = df)
summary(a13) 

##carcatvalue
df$carcatvalue <-as.factor(df$carcatvalue)
a14 <- aov(cardspent~carcatvalue, data = df)
summary(a14) 

##carbought
df$carbought <-as.factor(df$carbought)
a15 <- aov(cardspent~carbought, data = df)
summary(a15) 

##carbuy
df$carbuy <-as.factor(df$carbuy)
a16 <- aov(cardspent~carbuy, data = df)
summary(a16) 

##commute
df$commute <-as.factor(df$commute)
a17 <- aov(cardspent~commute, data = df)
summary(a17) 

##commutecat
df$commutecat <-as.factor(df$commutecat)
a18 <- aov(cardspent~commutecat, data = df)
summary(a18) 

##commutecar
df$commutecar <-as.factor(df$commutecar)
a19 <- aov(cardspent~commutecar, data = df)
summary(a19) 

##commutemotorcycle
df$commutemotorcycle <-as.factor(df$commutemotorcycle)
a20 <- aov(cardspent~commutemotorcycle, data = df)
summary(a20) 

##commutewalk
df$commutewalk <-as.factor(df$commutewalk)
a22 <- aov(cardspent~commutewalk, data = df)
summary(a22) 


##telecommute
df$commutemotorc <-as.factor(df$commutemotorc)
a23 <- aov(cardspent~commutemotorcycle, data = df)
summary(a23) 

##polview
df$polview <-as.factor(df$polview)
a24 <- aov(cardspent~polview, data = df)
summary(a24) 
                           
##polparty
df$polparty <-as.factor(df$polparty)
a25 <- aov(cardspent~polparty, data = df)
summary(a25) 

##pca
x <- df[,-c(1:3)]
df1<- prcomp(mydata,scale. = T)
summary(df1)
df1$rotation

df1$sdev
df1$center
df1$scale
dim(df1$x)

biplot(df1,scale=0)
std_Dev <- df1$sdev
var <- std_Dev**2
var[1:10]
prop_var <- var/sum(var)
prop_var[1:10]

###screeplot
plot(prop_var,xlab ="Principal Component",ylab ="Proportion of Variance Explained",type = "b")

plot(cumsum(prop_var),xlab ="Principal Component",ylab ="Proportion of Variance Explained",type = "b")

dim(df1$rotation)
df1<- as.data.frame(df1$rotation)


####polcontrib
df$polcontrib <-as.factor(df$polcontrib)
a26 <- aov(cardspent~polcontrib, data = df)
summary(a26) 

###vote
df$polcontrib <-as.factor(df$polcontrib)
a26 <- aov(cardspent~polcontrib, data = df)
summary(a26) 

#cardtype
df$cardtype<-as.factor(df$cardtype)
a27 <- aov(cardspent~cardtype, data = df)
summary(a27) 

##cardbenefit
df$cardbenefit<-as.factor(df$benefit)
a28 <- aov(cardspent~cardbenefit, data = df)
summary(a28) 

#cardtenurecat
df$cardtenurecat<-as.factor(df$card2tenurecat)
a29 <- aov(cardspent~cardtenurecat, data = df)
summary(a29) 

###card2tenurecat
df$card2tenurecat<-as.factor(df$card2tenurecat)
a30 <- aov(cardspent~card2tenurecat, data = df)
summary(a30) 

##churn
df$churn<-as.factor(df$churn)
a31 <- aov(cardspent~churn, data = df)
summary(a31) 

##response_01
df$response_01<-as.factor(df$response_01)
a32 <- aov(cardspent~response_01, data = df)
summary(a32) 

##response_02
df$response_02<-as.factor(df$response_02)
a33 <- aov(cardspent~response_02, data = df)
summary(a33) 

##response_03
df$response_03<-as.factor(df$response_03)
a34 <- aov(cardspent~response_03, data = df)
summary(a34) 

##ebill
df$ebill<-as.factor(df$ebill)
a35 <- aov(cardspent~ebill, data = df)
summary(a35) 

#internet
df$internet<-as.factor(df$internet)
a36 <- aov(cardspent~internet, data = df)
summary(a36) 

#-----------------------------------------------------


setwd("C:\\Users\\Vineet\\Documents\\analytixlabs\\R prog\\BA\\regression")

df <- readxl::read_excel("Linear Regression Case.xlsx")
str(df[vars])
colnames(df)
str(df)
df$card <- as.numeric(df$card)
df$card2 <- as.numeric(df$card2)
df$carditems <- as.numeric(df$carditems)
df$card2items <- as.numeric(df$card2items)

##total spend
df$totalspend <- df$cardspent + df$card2spent

df$log_longmon <- log(df$longmon+1)
df$log_longten <- log(df$longten+1)
df$log_tollmon <- log(df$tollmon+1)
df$log_card2spent <- log(df$card2spent +1)
df$log_cardten <- log(df$cardten+1)

vars <- c("tollten","tenure","log_longmon","log_longten","log_tollmon",
          "cardtenure","income","totalspend","lncreddebt","debtinc",
          "othdebt","log_cardten","wireten",
          "edcat","jobcat","empcat","inccat","jobsat","spousedcat",
          "homeown","addresscat","carown","carvalue","cardtenurecat","owntv","ownvcr","ownpc","owngame",
          "news","response_02","response_03","internet","card","card2","carditems","card2items")

mystats <- function(x) {
  nmiss<-sum(is.na(x))
  a <- x[!is.na(x)]
  m <- mean(a)
  n <- length(a)
  s <- sd(a)
  min <- min(a)
  p1<-quantile(a,0.01)
  p5<-quantile(a,0.05)
  p10<-quantile(a,0.10)
  q1<-quantile(a,0.25)
  q2<-quantile(a,0.5)
  q3<-quantile(a,0.75)
  p90<-quantile(a,0.90)
  p95<-quantile(a,0.95)
  p99<-quantile(a,0.99)
  max <- max(a)
  UC <- m+3*s
  LC <- m-3*s
  outlier_flag<- max>UC | min<LC
  return(c(n=n, nmiss=nmiss, outlier_flag=outlier_flag, mean=m, stdev=s,min = min, p1=p1,p5=p5,p10=p10,q1=q1,q2=q2,q3=q3,p90=p90,p95=p95,p99=p99,max=max, UC=UC, LC=LC ))
}

diag_stats<-t(data.frame(apply(df[vars], 2, mystats)))

write.csv(diag_stats, file = "diag_stats1.csv")
write.csv(new_df, file = "new_df1.csv")

df<- df[!is.na(df$log_longten),]
df<- df[!is.na(df$lncreddebt),] 
df<- df[!is.na(df$log_cardten),] 

## Capping Outliers ##
#df$cardspent[df$cardspent > 1072.797598] <- 1072.797598
df$tollten[df$tollten > 2620.2125] <- 2620.2125
df$log_longmon[df$log_longmon < 1.351649482]<- 1.351649482
df$carvalue[df$carvalue > 71.925] <- 71.925
df$log_longten[df$log_longten <1.758799628]<- 1.758799628
df$log_longmon[df$log_longmon > 1.647264563] <- 1.647264563
df$log_longten[df$log_longten > 2.246361069] <- 2.246361069
df$income[df$income > 147] <- 147
df$lncreddebt[df$lncreddebt > 1.852297333] <- 1.852297333
df$lncreddebt[df$lncreddebt < -2.291630319] <- -2.291630319
df$debtinc[df$debtinc > 22.2] <- 22.2
df$othdebt[df$othdebt > 11.822304] <- 11.822304
df$wireten[df$wireten > 2687.9225] <- 2687.9225
df$totalspend[df$totalspend > 1145.2925] <- 1145.2925

#df$log_card2spent[df$log_card2spent > 2.024170626] <- 2.024170626
#df$log_card2spent[df$log_card2spent < 0.822871409] <- 0.822871409

##removing few observations##
df <- df[-c(2042,3751,160,4989,3620,880,1657),]
##pca
str(df[vars])
df1<- prcomp(df[vars],scale. = T)
summary(df1)
df1$rotation

df1$sdev
df1$center
df1$scale
dim(df1$x)

biplot(df1,scale=0)
ncol(df[,vars])
library("ggplot2") 
new_df <- data.frame(df[vars])
colnames(new_df)
View(new_df)
# plot scores 
scores <- as.data.frame(df1$x) 
qplot(x = PC1, y = PC2, data = scores, geom = "point") 

# Loadings on PC1 (few variables) 
loadings <- as.data.frame(df1$rotation) 
loadings$var <- colnames(new_df) 
qplot(x = var, y = PC1, data = loadings, geom = "bar") 

write.csv(loadings,file = "loadings1.csv")

##

std_Dev <- df1$sdev
var <- std_Dev**2
var[1:10]
prop_var <- var/sum(var)
prop_var[1:10]

###screeplot
plot(prop_var,xlab ="Principal Component",ylab ="Proportion of Variance Explained",type = "b")

plot(cumsum(prop_var),xlab ="Principal Component",ylab ="Proportion of Variance Explained",type = "b")

dim(df1$rotation)
df1<- as.data.frame(df1$rotation)

#Splitting data into Training, Validaton and Testing Dataset
train_ind <- sample(1:nrow(new_df), size = floor(0.70 * nrow(new_df)))

training<-new_df[train_ind,]
testing<-new_df[-train_ind,]

fit <- lm(totalspend ~ tollten+tenure+log_longmon+log_longten+log_tollmon+cardtenure + owntv+ownpc+ownvcr+owngame + news
            +income+lncreddebt+debtinc+othdebt+log_cardten+wireten+edcat+jobcat+empcat+inccat
          +jobsat+spousedcat+homeown+addresscat+carown+response_02+response_03+internet+carvalue, data=training)
summary(fit)

fit1 <- lm(cardspent ~ carown+log_tollmon+cardtenure + 
            income+log_card2spent+empcat
          +carown+internet+wireten+othdebt+log_cardten+inccat +response_02+response_03+card+card2+card2items+carditems
, data=training)

summary(fit1)
# Multiple Linear Regression Example
fit <- lm(cardspent ~ ., data=training)
summary(fit)
new_df$cardspent <- df$cardspent

step3<- stepAIC(fit,direction="backward")
?stepAIC()
ls(step3)
step3$anova

cor.test(df$log_card2spent,df$carditems)


fit2 <- lm(cardspent ~ log_longten + ownpc + carown+owngame + income + log_card2spent + carditems+card + 
             internet+empcat + inccat + response_03 ,data = training)
summary(fit2)

fit3 <- lm(cardspent ~ log_longten + ownpc + owngame + income + log_card2spent + carditems+card
           +empcat + inccat + response_03 ,data = testing)
summary(fit3)

fit4 <- lm(log(totalspend) ~ tenure + lncreddebt + debtinc + othdebt + 
             log_cardten + empcat + inccat+card2items+carditems,data = training)
summary(fit4)

fit_valid <- fit4 <- lm(log(totalspend) ~ tenure  + lncreddebt + debtinc + othdebt + 
                          log_cardten + empcat + inccat+card2items+carditems,data = testing)
summary(fit_valid)
fit4.pred <- predict(fit4,testing)
fit_valid_pred <- predict(fit_valid,testing)
fit4_valid.res <- testing$totalspend -fit_valid_pred
accuracy(fit_valid_pred,testing$totalspend)

spend.residuals <- testing$totalspend - fit4.pred 
options(scipen = 999)

#accuracy
require(forecast)
accuracy(fit4.pred,testing$totalspend)
hist(spend.residuals,breaks = 20, xlab = "residuals")


##plot training model
plot(fit4)
plot(fit_valid)
library(car)
vif(fit4)
vif(fit_valid)

https://www.analyticsvidhya.com/blog/2016/07/deeper-regression-analysis-assumptions-plots-solutions/
  
  https://www.analyticsvidhya.com/blog/2013/12/residual-plots-regression-model/
  https://www.analyticsvidhya.com/blog/2016/12/45-questions-to-test-a-data-scientist-on-regression-skill-test-regression-solution/
#lead, lag, fread functions
#to retrieve data from db to in faster way
