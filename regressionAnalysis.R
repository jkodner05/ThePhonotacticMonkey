
###########################
## 0. Read in data files ##
###########################
working_dir = '' # e.g. path/to/ThePhonotacticMonkey/
output_dir = '' # e.g. path/to/ThePhonotacticMonkey/
input_pointer = '' # e.g. path/to/ThePhonotacticMonkey/

args = commandArgs(trailingOnly=TRUE)
if (length(args)>2) {
  working_dir = args[1]
  output_dir = args[2]
  input_pointer = args[3]
}

lastCharWorkDir = substr(working_dir, nchar(working_dir), nchar(working_dir))
if (lastCharWorkDir == '/') {
  auxSource = paste(working_dir,"aux-functions.R",sep="")
} else {
  auxSource = paste(working_dir,"/aux-functions.R",sep="")
}
source(auxSource)
load_in_limited()

fileList <- scan(input_pointer, what="", sep="\n")
###########################
###########################
###########################


#################################
## 1. Loop and fit regressions ##
#################################
setwd(output_dir)
for (currFile in fileList) {
  print(currFile)
  currHeader = str_sub(currFile,0,-5)
  currOutputfilename = paste(currHeader,"__stats.txt",sep="")
  currData = read.csv(currFile,header=T)
  
  # Normalizing to match PTG:
  # "For all regression analyses, we standardized the covariates by subtracting the mean and dividing by 1 standard deviation"
  currData$normednumsylls = (currData$numsylls-mean(currData$numsylls))/sd(currData$numsylls)
  currData$normedwordneglogprob = (currData$wordneglogprob-mean(currData$wordneglogprob))/sd(currData$wordneglogprob)
  currData$normedphonsuprise = (currData$phonsuprise-mean(currData$phonsuprise))/sd(currData$phonsuprise)
  
  print(currOutputfilename)
  
  write("WORD SENSES BY NUM SYLLS", file = currOutputfilename)
  s1 = summary(glm(currData$numwordsenses~currData$normednumsylls,family=quasipoisson(),control = list(maxit = 1000)))
  capture.output(s1, file = currOutputfilename, append=TRUE)
  
  write("WORD SENSES BY NEG LOG PROB", file = currOutputfilename, append=TRUE)
  s2 = summary(glm(currData$numwordsenses~currData$normedwordneglogprob,family=quasipoisson(),control = list(maxit = 1000)))
  capture.output(s2, file = currOutputfilename, append=TRUE)
  
  write("WORD SENSES BY PHON SURPRISAL", file = currOutputfilename, append=TRUE)
  s3 = summary(glm(currData$numwordsenses~currData$normedphonsuprise,family=quasipoisson(),control = list(maxit = 1000)))
  capture.output(s3, file = currOutputfilename, append=TRUE)
}

print("Finished applying regressions")
###########################
###########################
###########################
