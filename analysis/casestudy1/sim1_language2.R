
nruns <- 10000

# function generating responses from a Bayesian learner with a beta prior
# with and probability matching rule
learner <- function(counts,a,b,nresp) { 
  
  # for my sanity
  nheads <- counts[1]
  ntails <- counts[2]
  
  # sample from posterior
  theta <- rbeta(1,nheads+a,ntails+b)  
  
  # generate new responses
  newheads <- rbinom(n=1,size = nresp,prob = theta)
  return(c(newheads,nresp-newheads))
  
}

chain <- function() {
  
  obs <- matrix(NA,nits+1,2)
  ltype <- vector(length=nits)
  obs[1,] <- c(nresp/2,nresp/2) # seed the chain at 5 heads, 5 tails
  for( i in 1:nits ) {
    
    ltype[i] <- as.numeric(runif(1)>mix)+1 # learner type
    if( ltype[i] == 1) {
      obs[i+1,] <- learner(obs[i,],a1,b1,nresp)
    } else {
      obs[i+1,] <- learner(obs[i,],a2,b2,nresp)
    }
    
  }
  return(data.frame(obs=obs[-1,1], ltype=ltype)) 
}


layout(matrix(1:4,2,2))
op <- par(no.readonly=TRUE)
par(mar=c(5,5,2,2))


#### 50-50 mixture ####

mix <- .5 # proportions of each learner type in population
a1 <- 2  # beta prior for learner type 1
b1 <- 1
a2 <- 1 # beta prior for learner type2 
b2 <- 10

nresp <- 10 # responses per person
nits<-20 # how long to run the chain for

# now run lots of chains to get average number of heads
nheads <- vector(length=nits)
iteratedoutcomes <- matrix(0,nresp+1,2,dimnames=list("heads"=0:nresp,"learner"=1:2))
nheads_all <- matrix(NA,nits,nruns)
ltype_all <- matrix(NA,nits,nruns)
for( i in 1:nruns ){
  ch <- chain()
  nheads <- nheads + ch$obs
  nheads_all[,i] <- ch$obs
  ltype_all[,i] <- ch$ltype
  iteratedoutcomes[ch$obs[nits]+1, ch$ltype[nits]] <- 
    iteratedoutcomes[ch$obs[nits]+1, ch$ltype[nits]] + 1
}
nheads <- nheads/nruns
for(i in 1:2) iteratedoutcomes[,i] <- iteratedoutcomes[,i]/sum(iteratedoutcomes[,i])

# mixture of the two priors?
p1 <- a1/(a1+b1)
p2 <- a2/(a2+b2)
mixp <- mix*p1 + (1-mix)*p2
priornh <- mixp*nresp


# response distribution from the mixture of priors
priorsamples <- vector(length=nruns)
priorltype <- vector(length=nruns)
for( i in 1:nruns) {
  
  ltype <- as.numeric(runif(1)>mix)+1 # learner type
  if( ltype == 1) {
    priorsamples[i] <- learner(c(0,0),a1,b1,nresp)[1]
  } else {
    priorsamples[i] <- learner(c(0,0),a2,b2,nresp)[1]
  }
  priorltype[i] <- ltype
}


for(ltype in 1:2) {

  nh <- vector()
  for(i in 1:nits){
    nh[i] <- mean( nheads_all[i,ltype_all[i,]==ltype])
  }

  if(ltype==1) {
    mstr <- "Weak Learners in Mixed Chain"
  } else {
    mstr <- "Strong Learners in Mixed Chain"
  }
  
  # plot the trajectory of the chain
  plot(c(5,nh),type="o",pch=19,xlab="Iteration",ylab="Average Response",
       ylim=c(0,10),main=mstr)
  abline(h=ifelse(ltype==1,p1,p2)*nresp)

  if(ltype==2) legend(x = "topleft", pch=c(19,NA), col=c("black","black"),
         lty=c(1,1),lwd=c(1,1),
         legend=c("Iterated","Prior"),bty="n")

  
  # plot the response distribution at the end
  x <- table(factor(nheads_all[nits,ltype_all[nits,]==ltype],levels=0:10)) # counts for iterated
  y <- table(factor(priorsamples[priorltype==ltype],levels=0:10)) # counts for prior
  x <- x/sum(x) # iterated prob
  y <- y/sum(y) # prior prob
  z <- barplot(y,ylim=c(0,.6),main=mstr,xlab="Response",ylab="Probability") # prior as bars
  lines(z,x,type="o",pch=19) # iterated as dots
  
  box()
  
  if(ltype==2) legend(x = "topright", pch=c(19,15), col=c("black","grey50"),pt.cex=c(1,2),
         legend=c("Final Iterated","Prior"),bty="n")
  
}

layout(1)
par(op)

#dev.print(pdf,file="./coinsfail2.pdf",width=7,height=7)


