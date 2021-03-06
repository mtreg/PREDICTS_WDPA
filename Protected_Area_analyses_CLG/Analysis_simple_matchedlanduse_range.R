rm(list=ls()) 

library(yarg)
library(roquefort)
library(gamm4)

setwd("R:/ecocon_d/clg32/GitHub/PREDICTS_WDPA")
source("compare_randoms.R")
source("model_select.R")
setwd("R:/ecocon_d/clg32/PREDICTS/WDPA analysis")
PREDICTS_WDPA <- read.csv("PREDICTS_WDPA.csv")

validate <- function(x) {
  par(mfrow = c(1,2))
  plot(resid(x)~ fitted(x))
  hist(resid(x))
  par(mfrow = c(1,1))
}

matched.landuse <- subset(PREDICTS_WDPA, matched.landuse == "yes")
nrow(matched.landuse) #5015

### model range

fF <- c("Within_PA") 
fT <- list("ag_suit" = "3", "log_slope" = "3", "log_elevation" = "3")
keepVars <- list()
fI <- character(0)
RS <-  c("Within_PA")

r.best.random <- compare_randoms(matched.landuse, "log_abundance",
				fixedFactors=fF,
        fixedTerms=fT,
        keepVars = keepVars,
        fixedInteractions=fI,
        otherRandoms=character(0),
				fixed_RandomSlopes = RS,
        fitInteractions=FALSE,
				verbose=TRUE)

r.best.random$best.random #"(1+Within_PA|SS)+ (1|SSB)"

range.model <- model_select(all.data  = matched.landuse, 
			     responseVar = "range", 
			     alpha = 0.05,
           fixedFactors= fF,
           fixedTerms= fT,
			     keepVars = keepVars,
           randomStruct = "(Within_PA|SS) + (1|SSB)",
			     otherRandoms=character(0),
           verbose=TRUE)
#range~poly(ag_suit,3)+poly(log_elevation,2)+poly(log_slope,3)+(Within_PA|SS)+(1|SSB) 
range.model$stats 

data <- range.model$data

#model for plot
m1r <- lmer(range ~ Within_PA + poly(ag_suit,3)+poly(log_elevation,2)+poly(log_slope,3)
	+ (Within_PA|SS)+ (1|SSB), 
	 data = data)


# plot

#RANGE

# no link function so plot as relative, not percentage

labels <- c("Unprotected", "Protected")
y <- as.numeric(fixef(m1r)[2])
se <- as.numeric(se.fixef(m1r)[2])
yplus <- y + se*1.96
yminus <- y - se*1.96
y <-(y + 1) # plot as relative to 1
yplus<-(yplus + 1)
yminus<-(yminus + 1)

points <- c(1, y)
CI <- c(yplus, yminus)

plot(points ~ c(1,2), ylim = c(0.8,1.5), xlim = c(0.5,2.5), 
	bty = "l", pch = 16, col = c(1,3), cex = 1.5,
	yaxt = "n", xaxt = "n",
	ylab = "Relative CWM range difference (� 95%CI)",
	xlab = "")
axis(1, c(1,2), labels)
axis(2, c(0.8,1,1.2,1.4), c(80,100,120,140))
arrows(2,CI[1],2,CI[2], code = 3, length = 0.03, angle = 90)
abline(h = 1, lty = 2)
points(points ~ c(1,2), pch = 16, col = c(1,3), cex = 1.5)


#ENDEMICITY

# convert to normal range first, then get percentage

labels <- c("Unprotected", "Protected")
y1 <- 10^as.numeric(fixef(m1r)[1])
e.y1 <- 1/y1
y2 <- 10^(as.numeric(fixef(m1r)[2]) + as.numeric(fixef(m1r)[1]))
e.y2 <- 1/y2

#as a percentage of outside 
e.relative <- e.y2/e.y1*100

# what does this mean?
# difference of 0.3% = e.y2 - e.y1 #0.00057
# or y2 - y0 #- 0.0022 log sq km

se <- as.numeric(se.fixef(m1r)[2])
y2plus <- 10^(as.numeric(fixef(m1r)[2]) + as.numeric(fixef(m1r)[1]) + se*1.96)
e.y2plus <- 1/y2plus
e.relative.plus <- e.y2plus/e.y1*100

y2minus <- 10^(as.numeric(fixef(m1r)[2]) + as.numeric(fixef(m1r)[1]) - se*1.96)
e.y2minus <- 1/y2minus
e.relative.minus <- e.y2minus/e.y1*100

points <- c(100, e.relative)
CI <- c(e.relative.plus, e.relative.minus)

plot(points ~ c(1,2), ylim = c(90,130), xlim = c(0.5,2.5), 
	bty = "l", pch = 16, col = c(1,3), cex = 1.5,
	yaxt = "n", xaxt = "n",
	ylab = "Endemicity difference (% � 95%CI)",
	xlab = "")
axis(1, c(1,2), labels)
axis(2, c(90,100,110,120), c(90,100,110,120))
arrows(2,CI[1],2,CI[2], code = 3, length = 0.03, angle = 90)
abline(h = 100, lty = 2)
points(points ~ c(1,2), pch = 16, col = c(1,3), cex = 1.5)

text(2,90, paste("n =", length(data$SS[which(data$Within_PA == "yes")]), sep = " "))
text(1,90, paste("n =", length(data$SS[which(data$Within_PA == "no")]), sep = " "))


#get details for master plot
r.plot1 <- data.frame(label = c("unprotected", "all protected"), est = points, 
		upper = c(100, CI[1]), lower = c(100,CI[2]),
		n.site = c(length(data$SS[which(data$Within_PA == "no")]), length(data$SS[which(data$Within_PA == "yes")])))





### range and IUCN category


fF <- c("IUCN_CAT") 
fT <- list("ag_suit" = "1", "log_slope" = "1", "log_elevation" = "1")
keepVars <- list()
fI <- character(0)
RS <-  c("IUCN_CAT")


r.best.random.IUCN <- compare_randoms(matched.landuse, "log_abundance",
				fixedFactors=fF,
        fixedTerms=fT,
        keepVars = keepVars,
        fixedInteractions=fI,
        otherRandoms=character(0),
				fixed_RandomSlopes = RS,
        fitInteractions=FALSE,
				verbose=TRUE)

r.best.random.IUCN$best.random #"(1+IUCN_CAT|SS)+ (1|SSB)"


range.model.IUCN <- model_select(all.data  = matched.landuse, 
			     responseVar = "range", 
			     alpha = 0.05,
           fixedFactors= fF,
           fixedTerms= fT,
			     keepVars = keepVars,
           randomStruct = "(IUCN_CAT|SS) + (1|SSB)",
			     otherRandoms=character(0),
           verbose=TRUE)
range.model.IUCN$warnings
range.model.IUCN$stats

#PLOT

labels <- c("Unprotected", "IUCN III  - VI", "unknown", "IUCN I & II" )
data <- range.model.IUCN$data
data$IUCN_CAT <- relevel(data$IUCN_CAT, "0")

m6ri <- lmer(range ~ IUCN_CAT +log_slope + log_elevation + ag_suit
	+ (IUCN_CAT|SS)+ (1|SSB), 
	 data = data,
	control= lmerControl(optimizer="bobyqa",optCtrl=list(maxfun=100000)))


y1 <- 10 ^(as.numeric(fixef(m6ri)[1]))
e.y1 <- 1/y1
pos <- c(grep("4.5", names(fixef(m6ri))),grep("7", names(fixef(m6ri))),grep("1.5", names(fixef(m6ri))))
y2 <- 10^(as.numeric(fixef(m6ri)[pos]) + as.numeric(fixef(m6ri)[1]))
e.y2 <- 1/y2

#as a percentage of outside 
e.relative <- e.y2/e.y1*100

se <- as.numeric(se.fixef(m6ri)[pos])
y2plus <- 10^(as.numeric(fixef(m6ri)[pos]) + as.numeric(fixef(m6ri)[1])+ se*1.96)
e.y2plus <- 1/y2plus
e.relative.plus <- e.y2plus/e.y1*100

y2minus <- 10^(as.numeric(fixef(m6ri)[pos]) + as.numeric(fixef(m6ri)[1])- se*1.96)
e.y2minus <- 1/y2minus
e.relative.minus <- e.y2minus/e.y1*100

points <- c(100, e.relative)
CI <- cbind(e.relative.plus, e.relative.minus)

plot(points ~ c(1,2,3,4), ylim = c(90,130), xlim = c(0.5,4.5), 
	bty = "l", pch = 16, col = c(1,3,3,3), cex = 1.5,
	yaxt = "n", xaxt = "n",
	ylab = "Endemicity difference (% � 95%CI)",
	xlab = "")
axis(1, c(1,2,3,4), labels)
axis(2, c(90,100,110,120), c(90,100,110,120))
arrows(c(2,3,4),CI[,1],c(2,3,4),CI[,2], code = 3, length = 0.03, angle = 90)
abline(h = 100, lty = 2)
points(points ~ c(1,2,3,4), pch = 16, col = c(1,3,3,3), cex = 1.5)

text(1, 90, paste("n =", length(data$SS[which(data$IUCN_CAT == "0")]), sep = " "))
text(2, 90, paste("n =", length(data$SS[which(data$IUCN_CAT == "4.5")]), sep = " "))
text(3, 90, paste("n =", length(data$SS[which(data$IUCN_CAT == "7")]), sep = " "))
text(4, 90, paste("n =", length(data$SS[which(data$IUCN_CAT == "1.5")]), sep = " "))

IUCN.plot <- data.frame(label = labels[2:4], est = points[2:4], 
		upper = CI[,1], lower = CI[,2],
		n.site = c(length(data$SS[which(data$IUCN_CAT == "4.5")]), 
			length(data$SS[which(data$IUCN_CAT == "7")]),
			length(data$SS[which(data$IUCN_CAT == "1.5")])))
r.plot2 <- rbind(r.plot1, IUCN.plot)



### endemicity and zone

tropical <- subset(matched.landuse, Zone == "Tropical")
temperate <- subset(matched.landuse, Zone == "Temperate")

# check polynomials for confounding variables
fF <- c("Within_PA" ) 
fT <- list("ag_suit" = "3", "log_slope" = "3", "log_elevation" = "3")
keepVars <- list()
fI <- character(0)
RS <-  c("Within_PA")


r.best.random.trop <- compare_randoms(tropical, "range",
				fixedFactors=fF,
        fixedTerms=fT,
        keepVars = keepVars,
        fixedInteractions=fI,
        otherRandoms=character(0),
				fixed_RandomSlopes = RS,
        fitInteractions=FALSE,
				verbose=TRUE)

r.best.random.trop$best.random #"(1+Within_PA|SS)+ (1|SSB)"

r.best.random.temp <- compare_randoms(temperate, "range",
				fixedFactors=fF,
        fixedTerms=fT,
        keepVars = keepVars,
        fixedInteractions=fI,
        otherRandoms=character(0),
				fixed_RandomSlopes = RS,
        fitInteractions=FALSE,
				verbose=TRUE)

r.best.random.temp$best.random #"(1+Within_PA|SS)+ (1|SSB)"

# get polynomial relationships
r.model.trop <- model_select(all.data  = tropical, 
			     responseVar = "range", 
			     alpha = 0.05,
           fixedFactors= fF,
           fixedTerms= fT,
			     keepVars = keepVars,
           randomStruct =r.best.random.trop$best.random,
			     otherRandoms=character(0),
           verbose=TRUE)
r.model.trop$warnings
r.model.trop$stats
#"range~poly(ag_suit,2)+poly(log_elevation,3)+(1+Within_PA|SS)+(1|SSB)"

r.model.temp <- model_select(all.data  = temperate, 
			     responseVar = "range", 
			     alpha = 0.05,
           fixedFactors= fF,
           fixedTerms= fT,
			     keepVars = keepVars,
           randomStruct = r.best.random.temp$best.random,
			     otherRandoms=character(0),
           verbose=TRUE)
r.model.temp$warnings
r.model.temp$stats
# range~poly(ag_suit,3)+poly(log_elevation,2)+poly(log_slope,3)+Within_PA+(1+Within_PA|SS)+(1|SSB)

# run models for plots
data.trop <- r.model.trop$data
data.temp <- r.model.temp$data

m1aztr <- lmer(range ~ Within_PA +  poly(ag_suit,2)+poly(log_elevation,3)
	+ (Within_PA|SS)+ (1|SSB), 
	 data = data.trop)

m1azte <- lmer(range ~ Within_PA +poly(ag_suit,3)+poly(log_elevation,2)+poly(log_slope,3)
	+ (Within_PA|SS)+ (1|SSB), 
	 data = data.temp )


#add results to master plot
y1 <- 10^(fixef(m1aztr)[1])
e.y1 <- 1/y1
y2 <- 10^(fixef(m1aztr)[1] + fixef(m1aztr)[2])
e.y2 <- 1/y2
aztr.est <- e.y2/e.y1*100

se <- se.fixef(m1aztr)[2]
y.upper <- 10^(fixef(m1aztr)[1] + fixef(m1aztr)[2]+ 1.96*se)
e.y.upper <- 1/y.upper
aztr.upper <- e.y.upper/e.y1*100
y.lower <- 10^(fixef(m1aztr)[1] + fixef(m1aztr)[2]- 1.96*se)
e.y.lower <- 1/y.lower
aztr.lower <- e.y.lower/e.y1*100


y1 <- 10^(fixef(m1azte)[1])
e.y1 <- 1/y1
y2 <- 10^(fixef(m1azte)[1] + fixef(m1azte)[2])
e.y2 <- 1/y2
azte.est <- e.y2/e.y1*100

se <- se.fixef(m1azte)[2]
y.upper <- 10^(fixef(m1azte)[1] + fixef(m1azte)[2]+ 1.96*se)
e.y.upper <- 1/y.upper
azte.upper <- e.y.upper/e.y1*100
y.lower <- 10^(fixef(m1azte)[1] + fixef(m1azte)[2]- 1.96*se)
e.y.lower <- 1/y.lower
azte.lower <- e.y.lower/e.y1*100


a.zone <- data.frame(label = c("Tropical", "Temperate"),
				est = c(aztr.est, azte.est), 
				upper = c(aztr.upper, azte.upper), 
				lower = c(aztr.lower, azte.lower), 
				n.site = c(nrow(data.trop[which(data.trop$Within_PA == "yes"),]), 
					nrow(data.temp[which(data.temp$Within_PA == "yes"),])))
r.plot3 <- rbind(r.plot2, a.zone)





# endemicity and taxon

plants <- subset(matched.landuse, taxon_of_interest == "Plants")
inverts <- subset(matched.landuse, taxon_of_interest == "Invertebrates")
verts <- subset(matched.landuse, taxon_of_interest == "Vertebrates")
nrow(plants)
nrow(inverts)
nrow(verts)

# check polynomials for confounding variables
fF <- c("Within_PA" ) 
fT <- list("ag_suit" = "3", "log_slope" = "3", "log_elevation" = "3")
keepVars <- list()
fI <- character(0)
RS <-  c("Within_PA")


r.best.random.p <- compare_randoms(plants, "range",
				fixedFactors=fF,
                        fixedTerms=fT,
			     	keepVars = keepVars,
                       	fixedInteractions=fI,
                        otherRandoms=character(0),
				fixed_RandomSlopes = RS,
                        fitInteractions=FALSE,
				verbose=TRUE)
r.best.random.p$best.random # "(1+Within_PA|SS)"

r.best.random.i <- compare_randoms(inverts, "range",
				fixedFactors=fF,
                        fixedTerms=fT,
			     	keepVars = keepVars,
                       	fixedInteractions=fI,
                        otherRandoms=character(0),
				fixed_RandomSlopes = RS,
                        fitInteractions=FALSE,
				verbose=TRUE)
r.best.random.i$best.random # "(1+Within_PA|SS)+ (1|SSB)"

r.best.random.v <- compare_randoms(verts, "range",
				fixedFactors=fF,
                        fixedTerms=fT,
			     	keepVars = keepVars,
                       	fixedInteractions=fI,
                        otherRandoms=character(0),
				fixed_RandomSlopes = RS,
                        fitInteractions=FALSE,
				verbose=TRUE)
r.best.random.v$best.random #"(1+Within_PA|SS)+ (1|SSB)"


# get polynomial relationships
r.model.p <- model_select(all.data  = plants, 
			     responseVar = "range", 
			     alpha = 0.05,
                       fixedFactors= fF,
                       fixedTerms= fT,
			     keepVars = keepVars,
                       randomStruct =r.best.random.p$best.random,
			     otherRandoms=character(0),
                       verbose=TRUE)
r.model.p$warnings
r.model.p$stats
#"range~poly(log_elevation,3)+(1+Within_PA|SS)"

r.model.i <- model_select(all.data  = inverts, 
			     responseVar = "range", 
			     alpha = 0.05,
                       fixedFactors= fF,
                       fixedTerms= fT,
			     keepVars = keepVars,
                       randomStruct =r.best.random.i$best.random,
			     otherRandoms=character(0),
                       verbose=TRUE)
r.model.i$warnings
r.model.i$stats
#"range~poly(log_elevation,1)+Within_PA+(1+Within_PA|SS)+(1|SSB)"

r.model.v <- model_select(all.data  = verts, 
			     responseVar = "range", 
			     alpha = 0.05,
                       fixedFactors= fF,
                       fixedTerms= fT,
			     keepVars = keepVars,
                       randomStruct =r.best.random.v$best.random,
			     otherRandoms=character(0),
                       verbose=TRUE)
r.model.v$warnings
r.model.v$stats
#"range~poly(ag_suit,3)+poly(log_elevation,3)+poly(log_slope,3)+(1+Within_PA|SS)+(1|SSB)"

# run models for plot
data.p <- r.model.p$data
data.i <- r.model.i$data
data.v <- r.model.v$data

m1txp <- lmer(range ~ Within_PA + poly(log_elevation,3)
	+ (Within_PA|SS)+ (1|SSB), 
	 data = data.p)

m1txi <- lmer(range ~ Within_PA + poly(log_elevation,1)
	+ (Within_PA|SS)+ (1|SSB), 
	 data = data.i)

m1txv <- lmer(range ~ Within_PA + poly(ag_suit,3)+poly(log_elevation,3)+poly(log_slope,3)
	+ (Within_PA|SS)+ (1|SSB), 
	 data = data.v)

#add results to master plot
y1 <- 10^(fixef(m1txp)[1])
e.y1 <- 1/y1
y2 <- 10^(fixef(m1txp)[1] + fixef(m1txp)[2])
e.y2 <- 1/y2
txp.est <- e.y2/e.y1*100
se <- se.fixef(m1txp)[2]
y.upper <- 10^(fixef(m1txp)[1] + fixef(m1txp)[2]+ 1.96*se)
e.y.upper <- 1/y.upper
txp.upper <- e.y.upper/e.y1*100
y.lower <- 10^(fixef(m1txp)[1] + fixef(m1txp)[2]- 1.96*se)
e.y.lower <- 1/y.lower
txp.lower <- e.y.lower/e.y1*100

y1 <- 10^(fixef(m1txi)[1])
e.y1 <- 1/y1
y2 <- 10^(fixef(m1txi)[1] + fixef(m1txi)[2])
e.y2 <- 1/y2
txi.est <- e.y2/e.y1*100
se <- se.fixef(m1txi)[2]
y.upper <- 10^(fixef(m1txi)[1] + fixef(m1txi)[2]+ 1.96*se)
e.y.upper <- 1/y.upper
txi.upper <- e.y.upper/e.y1*100
y.lower <- 10^(fixef(m1txi)[1] + fixef(m1txi)[2]- 1.96*se)
e.y.lower <- 1/y.lower
txi.lower <- e.y.lower/e.y1*100

y1 <- 10^(fixef(m1txv)[1])
e.y1 <- 1/y1
y2 <- 10^(fixef(m1txv)[1] + fixef(m1txv)[2])
e.y2 <- 1/y2
txv.est <- e.y2/e.y1*100
se <- se.fixef(m1txv)[2]
y.upper <- 10^(fixef(m1txv)[1] + fixef(m1txv)[2]+ 1.96*se)
e.y.upper <- 1/y.upper
txv.upper <- e.y.upper/e.y1*100
y.lower <- 10^(fixef(m1txv)[1] + fixef(m1txv)[2]- 1.96*se)
e.y.lower <- 1/y.lower
txv.lower <- e.y.lower/e.y1*100

tax <- data.frame(label = c("Plants", "Invertebrates", "Vertebrates"),
				est = c(txp.est, txi.est, txv.est), 
				upper = c(txp.upper, txi.upper, txv.upper), 
				lower = c(txp.lower, txi.lower, txv.lower), 
				n.site = c(nrow(data.p[which(data.p$Within_PA == "yes"),]),
					nrow(data.i[which(data.i$Within_PA == "yes"),]), 
					nrow(data.v[which(data.v$Within_PA == "yes"),])))
r.plot <- rbind(r.plot3, tax)


# master plot

tiff( "R:/ecocon_d/clg32/PREDICTS/WDPA analysis/plots/06_15/simple models matchedlanduse endemicity.tif",
	width = 10, height = 15, units = "cm", pointsize = 12, res = 300)

trop.col <- rgb(0.9,0,0)
temp.col <- rgb(0,0.1,0.7)
p.col <- rgb(0.2,0.7,0.2)
i.col <- rgb(0,0.7,0.9)
v.col <- rgb(0.9,0.5,0)

par(mar = c(9,6,4,1))
plot(1,1, 
	ylim = c(60,145), xlim = c(0.5,nrow(r.plot)),
	bty = "l", 
	axes = F,
	ylab = "Endemicity difference (%)",
	cex.lab = 1.5,
	xlab = "")
abline(v = c(2.5,5.5,7.5), lty = 2)
abline(h= 100, col = 8)
arrows(1:nrow(r.plot),r.plot$upper,
	col = c(1,1,rep(rgb(0.5, 0.5, 0.5), 3), c(trop.col, temp.col, p.col, i.col, v.col)),
	lwd = 2,
	1:nrow(r.plot),r.plot$lower, code = 3, length = 0, angle = 90)
points(r.plot$est ~ c(1:nrow(r.plot)),
	pch = c(21, rep(16,4), rep(15,2),rep(17,3)), 
	lwd = 2,
	col = c(1,1,rep(rgb(0.5, 0.5, 0.5), 3), c(trop.col, temp.col, p.col, i.col, v.col)),
	bg ="white", 
	cex = 1.5)
text(1:nrow(r.plot),62, r.plot$n.site, srt = 90)
#axis(1, c(1:nrow(r.plot)), r.plot$label, cex.axis = 1.5, las = 2)
axis(2, c(80,100,120,140), c(-20,0,20,40))


dev.off()




