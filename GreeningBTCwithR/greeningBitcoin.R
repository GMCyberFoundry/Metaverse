#install.packages("qmao", repos="http://R-Forge.R-project.org")
#devtools::install_github("amrrs/coinmarketcapr")
library(readr)
#library(qmao)
library(lubridate)
library(tidyverse)
library(dplyr)
library(jsonlite)
library(coinmarketcapr)

key <- 'ef9213cc-b044-46fe-8a9d-1b46300853ca'
coinmarketcapr::setup(key)
setwd("~/R/win-library/4.1")
greeningTable <- read_csv("greeningBitcoinTable.csv", col_names = FALSE)

#get the coinmarketcap data for Bitcoin assign it to a dataframe
btcStats <- get_crypto_listings(limit = 1)
#price
greeningTable[2,2] <- btcStats[1,16]
#supply
greeningTable[3,2] <- btcStats[1,9]
#supply with loss
greeningTable[4,2] <- (greeningTable[3,2] * 0.8)
#mcap
greeningTable[5,2] <- btcStats[1,25]
#adjusted mcap
greeningTable[6,2] <- greeningTable[2,2] * greeningTable[4,2]
#hashrate
greeningTable[7,2] <- jsonlite::fromJSON("https://blockchain.info/q/hashrate")/1000000000
#target hashrate
greeningTable[8,2] <- (greeningTable[1,2] * greeningTable[2,2] * greeningTable[7,2])/greeningTable[6,2]
#target terrahash
greeningTable[9,2] <- greeningTable[8,2] * 1000000 
#cleanspark mining capacity
greeningTable[14,2] <- greeningTable[14,2] * 100000000000  #inline exa to terra
greeningTable[17,2] <- (((greeningTable[9,2])*greeningTable[16,2])/ greeningTable[14,2])*greeningTable[15,2]
greeningTable[19,2] <- greeningTable[17,2] / greeningTable[18,2]
write.csv(greeningTable,'greeningBitcoinTable.csv')