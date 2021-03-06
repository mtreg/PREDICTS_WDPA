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
multiple.taxa.matched.landuse <- subset(matched.landuse, multiple_taxa == "yes")
nrow(matched.landuse) #5015


### model species richness

# check polynomials
fF <- c("Within_PA") 
fT <- list("ag_suit" = "3", "log_slope" = "3", "log_elevation" = "3")
keepVars <- list()
fI <- character(0)
RS <-  c("Within_PA")

Species_richness.best.random <- compare_randoms(multiple.taxa.matched.landuse, "Species_richness",
                                                fitFamily = "poisson",
                                                siteRandom = TRUE,
                                                fixedFactors=fF,
                                                fixedTerms=fT,
                                                keepVars = keepVars,
                                                fixedInteractions=fI,
                                                otherRandoms=character(0),
                                                fixed_RandomSlopes = RS,
                                                fitInteractions=FALSE,
                                                verbose=TRUE)

Species_richness.best.random$best.random #"(1+Within_PA|SS)+ (1|SSBS)+ (1|SSB)"


s.model <- model_select(all.data  = multiple.taxa.matched.landuse, 
                        responseVar = "Species_richness", 
                        fitFamily = "poisson", 
                        alpha = 0.05,
                        fixedFactors= fF,
                        fixedTerms= fT,
                        keepVars = keepVars,
                        randomStruct = Species_richness.best.random$best.random,
                        otherRandoms=character(0),
                        verbose=TRUE)
s.model$warnings
s.model$stats
s.model$final.call
#Species_richness~poly(ag_suit,3)+poly(log_elevation,2)+(Within_PA|SS)+(1|SSB)+(1|SSBS)

data <- s.model$data
m1 <- glmer(Species_richness ~ Within_PA +poly(ag_suit,3)+poly(log_elevation,2)
            + (Within_PA|SS) + (1|SSB) + (1|SSBS), 
            family = "poisson", data = data)

# plot

labels <- c("Unprotected", "Protected")
y <- as.numeric(fixef(m1)[2])
se <- as.numeric(se.fixef(m1)[2])
yplus <- y + se*1.96
yminus <- y - se*1.96
y <-(exp(y)*100)
yplus<-(exp(yplus)*100)
yminus<-(exp(yminus)*100)

points <- c(100, y)
CI <- c(yplus, yminus)

plot(points ~ c(1,2), ylim = c(80,150), xlim = c(0.5,2.5), 
     bty = "l", pch = 16, col = c(1,3), cex = 1.5,
     yaxt = "n", xaxt = "n",
     ylab = "Species richness difference (% � 95%CI)",
     xlab = "")

text(2,80, paste("n =", length(data$SS[which(data$Within_PA == "yes")]), sep = " "))
text(1,80, paste("n =", length(data$SS[which(data$Within_PA == "no")]), sep = " "))

axis(1, c(1,2), labels)
axis(2, c(80,100,120,140), c(80,100,120,140))
arrows(2,CI[1],2,CI[2], code = 3, length = 0.03, angle = 90)
abline(h = 100, lty = 2)
points(points ~ c(1,2), pch = 16, col = c(1,3), cex = 1.5)


#keep points for master plot
sp.plot1 <- data.frame(label = c("unprotected", "all protected"), est = points, 
                       upper = c(100, CI[1]), lower = c(100,CI[2]),
                       n.site = c(length(data$SS[which(data$Within_PA == "no")]), length(data$SS[which(data$Within_PA == "yes")])))





#simple species richness with IUCN cat 

fF <- c("IUCN_CAT") 
fT <- list("ag_suit" = "1", "log_slope" = "1", "log_elevation" = "1")
keepVars <- list()
fI <- character(0)
RS <-  c("IUCN_CAT")
#cant converge with non-linear confounding variables


Species_richness.best.random.IUCN <- compare_randoms(multiple.taxa.matched.landuse, "Species_richness",
                                                     fitFamily = "poisson",
                                                     siteRandom = TRUE,
                                                     fixedFactors=fF,
                                                     fixedTerms=fT,
                                                     keepVars = keepVars,
                                                     fixedInteractions=fI,
                                                     otherRandoms=character(0),
                                                     fixed_RandomSlopes = RS,
                                                     fitInteractions=FALSE,
                                                     verbose=TRUE)

Species_richness.best.random.IUCN$best.random # "(1+IUCN_CAT|SS)+ (1|SSBS)+ (1|SSB)"

s.model.IUCN <- model_select(all.data  = multiple.taxa.matched.landuse, 
                             responseVar = "Species_richness", 
                             fitFamily = "poisson", 
                             alpha = 0.05,
                             fixedFactors= fF,
                             fixedTerms= fT,
                             keepVars = keepVars,
                             randomStruct = Species_richness.best.random.IUCN$best.random,
                             otherRandoms=character(0),
                             verbose=TRUE)
s.model.IUCN$warnings
#convergence issues dropping IUCN cat

data <- s.model.IUCN$data
# compare full model
#  no convergence warnings
m2i <- glmer(Species_richness ~ 1  + log_slope + log_elevation + ag_suit
             + (IUCN_CAT|SS) + (1|SSB) + (1|SSBS), 
             family = "poisson", data = data,
             control= glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=100000)))
m3i <- glmer(Species_richness ~ IUCN_CAT + log_slope + log_elevation + ag_suit
             + (IUCN_CAT|SS) + (1|SSB) + (1|SSBS), 
             family = "poisson", data = data,
             control= glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=100000)))
anova(m2i, m3i)
#1.6021      3     0.6589
fixef(m2i)

m7i <- glmer(Species_richness ~ 1  
             + (IUCN_CAT|SS) + (1|SSB) + (1|SSBS), 
             family = "poisson", data = multiple.taxa.matched.landuse,
             control= glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=100000)))
m8i <- glmer(Species_richness ~ IUCN_CAT 
             + (IUCN_CAT|SS) + (1|SSB) + (1|SSBS), 
             family = "poisson", data = multiple.taxa.matched.landuse,
             control= glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=100000)))
anova(m7i, m8i)
#1.7963      3     0.6158
fixef(m7i)
#very similar - trust model select outcome

s.model.IUCN$stats

# plot 
labels <- c("Unprotected", "III  - VI", "unknown", "I & II")

data$IUCN_CAT <- relevel(data$IUCN_CAT, "0")

m4i <- glmer(Species_richness ~ IUCN_CAT + log_elevation
             + (IUCN_CAT|SS) + (1|SSB) + (1|SSBS), 
             family = "poisson", data = data,
             control= glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=100000)))

pos <- c(grep("4.5", names(fixef(m4i))),grep("7", names(fixef(m4i))),grep("1.5", names(fixef(m4i))))
y <- as.numeric(fixef(m4i)[pos])
se <- as.numeric(se.fixef(m4i)[pos])
yplus <- y + se*1.96
yminus <- y - se*1.96
y <-(exp(y)*100)
yplus<-(exp(yplus)*100)
yminus<-(exp(yminus)*100)

points <- c(100, y)
CI <- cbind(yplus, yminus)

plot(points ~ c(1,2,3,4), ylim = c(80,150), xlim = c(0.5,4.5),
     bty = "l", pch = 16, col = c(1,3,3,3), cex = 1.5,
     yaxt = "n", xaxt = "n",
     ylab = "Species richness difference (% � 95%CI)",
     xlab = "")
axis(1,seq(1,length(points),1), labels)
axis(2, c(80,100,120,140), c(80,100,120,140))

text(1, 80, paste("n =", length(data$SS[which(data$IUCN_CAT == "0")]), sep = " "))
text(2, 80, paste("n =", length(data$SS[which(data$IUCN_CAT == "4.5")]), sep = " "))
text(3, 80, paste("n =", length(data$SS[which(data$IUCN_CAT == "7")]), sep = " "))
text(4, 80, paste("n =", length(data$SS[which(data$IUCN_CAT == "1.5")]), sep = " "))

arrows(seq(2,length(points),1),CI[,1],
       seq(2,length(points),1),CI[,2], code = 3, length = 0.03, angle = 90)
abline(h = 100, lty = 2)
points(points ~ c(1,2,3,4), pch = 16, col = c(1,3,3,3), cex = 1.5)


IUCN.plot <- data.frame(label = labels[2:4], est = points[2:4], 
                        upper = CI[,1], lower = CI[,2],
                        n.site = c(length(data$SS[which(data$IUCN_CAT == "4.5")]), 
                                   length(data$SS[which(data$IUCN_CAT == "7")]),
                                   length(data$SS[which(data$IUCN_CAT == "1.5")])))
sp.plot2 <- rbind(sp.plot1, IUCN.plot)



# simple species richness for Zone data


sp.tropical <- subset(multiple.taxa.matched.landuse, Zone == "Tropical")
sp.temperate <- subset(multiple.taxa.matched.landuse, Zone == "Temperate")

# check polynomials for confounding variables
fF <- c("Within_PA" ) 
fT <- list("ag_suit" = "3", "log_slope" = "3", "log_elevation" = "3")
keepVars <- list()
fI <- character(0)
RS <-  c("Within_PA")

Sp.best.random.trop <- compare_randoms(sp.tropical, "Species_richness",
                                       fitFamily = "poisson",
                                       siteRandom = TRUE,
                                       fixedFactors=fF,
                                       fixedTerms=fT,
                                       keepVars = keepVars,
                                       fixedInteractions=fI,
                                       otherRandoms=character(0),
                                       fixed_RandomSlopes = RS,
                                       fitInteractions=FALSE,
                                       verbose=TRUE)

Sp.best.random.trop$best.random #"(1+Within_PA|SS)+ (1|SSBS)+ (1|SSB)"

Sp.best.random.temp <- compare_randoms(sp.temperate, "Species_richness",
                                       fitFamily = "poisson",
                                       siteRandom = TRUE,
                                       fixedFactors=fF,
                                       fixedTerms=fT,
                                       keepVars = keepVars,
                                       fixedInteractions=fI,
                                       otherRandoms=character(0),
                                       fixed_RandomSlopes = RS,
                                       fitInteractions=FALSE,
                                       verbose=TRUE)

Sp.best.random.temp$best.random #"(1+Within_PA|SS)+ (1|SSBS)+ (1|SSB)"

# get polynomial relationships
sp.model.trop <- model_select(all.data  = sp.tropical, 
                              responseVar = "Species_richness", 
                              fitFamily = "poisson", 
                              alpha = 0.05,
                              fixedFactors= fF,
                              fixedTerms= fT,
                              keepVars = keepVars,
                              randomStruct = Sp.best.random.trop$best.random,
                              otherRandoms=character(0),
                              verbose=TRUE)
sp.model.trop$warnings
sp.model.trop$stats
sp.model.trop$final.call
#"Species_richness~poly(ag_suit,3)+poly(log_elevation,3)+(1+Within_PA|SS)+(1|SSBS)+(1|SSB)"



sp.model.temp <- model_select(all.data  = sp.temperate, 
                              responseVar = "Species_richness", 
                              fitFamily = "poisson", 
                              alpha = 0.05,
                              fixedFactors= fF,
                              fixedTerms= fT,
                              keepVars = keepVars,
                              randomStruct = Sp.best.random.temp$best.random,
                              otherRandoms=character(0),
                              verbose=TRUE)
sp.model.temp$warnings
sp.model.temp$stats
sp.model.temp$final.call
#"Species_richness~poly(log_elevation,1)+(1+Within_PA|SS)+(1|SSBS)+(1|SSB)"

# run models for plot
data.trop <- sp.model.trop$data
data.temp <- sp.model.temp$data

m1ztr <- glmer(Species_richness ~ Within_PA + poly(ag_suit,3)+poly(log_elevation,3)
               + (1+Within_PA|SS)+ (1|SSBS)+ (1|SSB), family = "poisson",
               data = data.trop)

m1zte <- glmer(Species_richness ~ Within_PA + poly(log_elevation,1) 
               + (1+Within_PA|SS)+ (1|SSBS)+ (1|SSB), family = "poisson", 
               data = data.temp)


#add results to master plot
ztr.est <- exp(fixef(m1ztr)[2])*100
ztr.upper <- exp(fixef(m1ztr)[2] + 1.96* se.fixef(m1ztr)[2])*100
ztr.lower <- exp(fixef(m1ztr)[2] - 1.96* se.fixef(m1ztr)[2])*100

zte.est <- exp(fixef(m1zte)[2])*100
zte.upper <- exp(fixef(m1zte)[2] + 1.96* se.fixef(m1zte)[2])*100
zte.lower <- exp(fixef(m1zte)[2] - 1.96* se.fixef(m1zte)[2])*100

a.zone <- data.frame(label = c("Tropical", "Temperate"),
                     est = c(ztr.est, zte.est), 
                     upper = c(ztr.upper, zte.upper), 
                     lower = c(ztr.lower, zte.lower), 
                     n.site = c(nrow(data.trop[which(data.trop$Within_PA == "yes"),]), 
                                nrow(data.temp[which(data.temp$Within_PA == "yes"),])))
sp.plot3 <- rbind(sp.plot2, a.zone)



# species richness and taxon

plants <- subset(multiple.taxa.matched.landuse, taxon_of_interest == "Plants")
inverts <- subset(multiple.taxa.matched.landuse, taxon_of_interest == "Invertebrates")
verts <- subset(multiple.taxa.matched.landuse, taxon_of_interest == "Vertebrates")
nrow(plants)
nrow(inverts)
nrow(verts)

# check polynomials for confounding variables
fF <- c("Within_PA" ) 
fT <- list("ag_suit" = "3", "log_slope" = "3", "log_elevation" = "3")
keepVars <- list()
fI <- character(0)
RS <-  c("Within_PA")


best.random.p <- compare_randoms(plants, "Species_richness",
                                 fitFamily = "poisson",
                                 siteRandom = TRUE,
                                 fixedFactors=fF,
                                 fixedTerms=fT,
                                 keepVars = keepVars,
                                 fixedInteractions=fI,
                                 otherRandoms=character(0),
                                 fixed_RandomSlopes = RS,
                                 fitInteractions=FALSE,
                                 verbose=TRUE)
best.random.p$best.random # "(1+Within_PA|SS)+ (1|SSBS)"

best.random.i <- compare_randoms(inverts, "Species_richness",
                                 fitFamily = "poisson",
                                 siteRandom = TRUE,
                                 fixedFactors=fF,
                                 fixedTerms=fT,
                                 keepVars = keepVars,
                                 fixedInteractions=fI,
                                 otherRandoms=character(0),
                                 fixed_RandomSlopes = RS,
                                 fitInteractions=FALSE,
                                 verbose=TRUE)
best.random.i$best.random # "(1+Within_PA|SS)+ (1|SSBS)+ (1|SSB)"

best.random.v <- compare_randoms(verts, "Species_richness",
                                 fitFamily = "poisson",
                                 siteRandom = TRUE,
                                 fixedFactors=fF,
                                 fixedTerms=fT,
                                 keepVars = keepVars,
                                 fixedInteractions=fI,
                                 otherRandoms=character(0),
                                 fixed_RandomSlopes = RS,
                                 fitInteractions=FALSE,
                                 verbose=TRUE)
best.random.v$best.random #"(1+Within_PA|SS)+ (1|SSBS)+ (1|SSB)"


# get polynomial relationships
model.p <- model_select(all.data  = plants, 
                        fitFamily = "poisson",
                        responseVar = "Species_richness", 
                        alpha = 0.05,
                        fixedFactors= fF,
                        fixedTerms= fT,
                        keepVars = keepVars,
                        randomStruct =best.random.p$best.random,
                        otherRandoms=character(0),
                        verbose=TRUE)
model.p$stats
model.p$warnings
model.p$final.call
# "Species_richness~poly(ag_suit,1)+poly(log_elevation,2)+(1+Within_PA|SS)+(1|SSBS)"

model.i <- model_select(all.data  = inverts, 
                        responseVar = "Species_richness", 
                        fitFamily = "poisson",
                        alpha = 0.05,
                        fixedFactors= fF,
                        fixedTerms= fT,
                        keepVars = keepVars,
                        randomStruct =best.random.i$best.random,
                        otherRandoms=character(0),
                        verbose=TRUE)
model.i$stats
model.i$warnings
model.i$final.call
#"Species_richness~poly(log_elevation,1)+(1+Within_PA|SS)+(1|SSBS)+(1|SSB)"


model.v <- model_select(all.data  = verts, 
                        responseVar = "Species_richness", 
                        fitFamily = "poisson",
                        alpha = 0.05,
                        fixedFactors= fF,
                        fixedTerms= fT,
                        keepVars = keepVars,
                        randomStruct =best.random.v$best.random,
                        otherRandoms=character(0),
                        verbose=TRUE)
model.v$stats
model.v$warnings
model.v$final.call
#"Species_richness~poly(ag_suit,3)+poly(log_elevation,3)+(1+Within_PA|SS)+(1|SSBS)+(1|SSB)"


# run models for plot
data.p <- model.p$data
data.i <- model.i$data
data.v <- model.v$data

m1txp <- glmer(Species_richness ~ Within_PA + poly(ag_suit,1)+poly(log_elevation,2)
               + (Within_PA|SS)+  (1|SSBS), family = "poisson", 
               data = data.p)

m1txi <- glmer(Species_richness ~ Within_PA +poly(log_elevation,1)
               + (Within_PA|SS)+ (1|SSB)+ (1|SSBS), family = "poisson", 
               data = data.i)

m1txv <- glmer(Species_richness ~ Within_PA + poly(ag_suit,3)+poly(log_elevation,3)
               + (Within_PA|SS)+ (1|SSB)+ (1|SSBS), family = "poisson", 
               data = data.v)

#add results to master plot
txp.est <- exp(fixef(m1txp)[2])*100
txp.upper <- exp(fixef(m1txp)[2] + 1.96* se.fixef(m1txp)[2])*100
txp.lower <- exp(fixef(m1txp)[2] - 1.96* se.fixef(m1txp)[2])*100

txi.est <- exp(fixef(m1txi)[2])*100
txi.upper <- exp(fixef(m1txi)[2] + 1.96* se.fixef(m1txi)[2])*100
txi.lower <- exp(fixef(m1txi)[2] - 1.96* se.fixef(m1txi)[2])*100

txv.est <- exp(fixef(m1txv)[2])*100
txv.upper <- exp(fixef(m1txv)[2] + 1.96* se.fixef(m1txv)[2])*100
txv.lower <- exp(fixef(m1txv)[2] - 1.96* se.fixef(m1txv)[2])*100



tax <- data.frame(label = c("Plants", "Inverts", "Verts"),
                  est = c(txp.est, txi.est, txv.est), 
                  upper = c(txp.upper, txi.upper, txv.upper), 
                  lower = c(txp.lower, txi.lower, txv.lower), 
                  n.site = c(nrow(data.p[which(data.p$Within_PA == "yes"),]), 
                             nrow(data.i[which(data.i$Within_PA == "yes"),]), 
                             nrow(data.v[which(data.v$Within_PA == "yes"),])))
sp.plot <- rbind(sp.plot3, tax)


# master plot

tiff( "simple models matchedlanduse sp rich.tif",
      width = 10, height = 15, units = "cm", pointsize = 12, res = 300)

trop.col <- rgb(0.9,0,0)
temp.col <- rgb(0,0.1,0.7)
p.col <- rgb(0.2,0.7,0.2)
i.col <- rgb(0,0.7,0.9)
v.col <- rgb(0.9,0.5,0)

par(mar = c(9,6,4,1))
plot(1,1, 
     ylim = c(60,145), xlim = c(0.5,nrow(sp.plot)),
     bty = "l", 
     axes = F,
     ylab = "Species richness difference (%)",
     cex.lab = 1.5,
     xlab = "")
abline(v = c(2.5,5.5,7.5), lty = 2)
abline(h= 100, col = 8)
arrows(1:nrow(sp.plot),sp.plot$upper,
       col = c(1,1,rep(rgb(0.5, 0.5, 0.5), 3), c(trop.col, temp.col, p.col, i.col, v.col)),
       lwd = 2,
       1:nrow(sp.plot),sp.plot$lower, code = 3, length = 0, angle = 90)
points(sp.plot$est ~ c(1:nrow(sp.plot)),
       pch = c(21, rep(16,4), rep(15,2),rep(17,3)), 
       lwd = 2,
       col = c(1,1,rep(rgb(0.5, 0.5, 0.5), 3), c(trop.col, temp.col, p.col, i.col, v.col)),
       bg = "white", 
       cex = 1.5)

text(1:nrow(sp.plot),62, sp.plot$n.site, srt = 90)
axis(1, c(1:nrow(sp.plot)), sp.plot$label, cex.axis = 1.5, las = 2, tick = 0)
axis(2, c(80,100,120,140), c(-20,0,20,40))

dev.off()



