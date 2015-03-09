##########################
# Download & import data #
##########################
library(RCurl)

# this contains pH, conductivity, total phosphorus, secchi depth, and chlorophyll a
URL <- "http://water.epa.gov/type/lakes/assessmonitor/lakessurvey/upload/NLA2007_WaterQuality_20091123.csv"
X <- getURL(URL, ssl.verifypeer = FALSE)
data_water_qual <- read.csv(textConnection(X))

# this contains lake size, shoreline development index, and maximum depth 
URL <- "http://water.epa.gov/type/lakes/assessmonitor/lakessurvey/upload/NLA2007_SampledLakeInformation_20091113.csv"
X <- getURL(URL, ssl.verifypeer = FALSE)
data_lake_info <- read.csv(textConnection(X))

# this contains dissolved oxygen and temperature 
# NOTE: this is the entire depth profile (i.e., multiple readings for each water body surveyed) 
URL <- "http://water.epa.gov/type/lakes/assessmonitor/lakessurvey/upload/NLA2007_Profile_20091008.csv"
X <- getURL(URL, ssl.verifypeer = FALSE)
data_profile <- read.csv(textConnection(X))

# clean up your workspace
rm(list=c("X","URL")) 

#######################################
# Examine characteristics of the data #
#######################################
# check out the names of all of the variables 
names(data_water_qual)
names(data_lake_info)
names(data_profile)

# check out the sizes of the data frames 
dim(data_water_qual)
dim(data_lake_info)
dim(data_profile)

# plot chlorophyll a 
par(mfrow=c(1,2))
hist(data_water_qual$CHLA)
hist(log(data_water_qual$CHLA))

# get summary stats on chlorophyll a 
summary(data_water_qual$CHLA)

#####################
# Merge data frames #
#####################
# combine the three data frames into one 

# first make an ID variable for each water body 
data_water_qual$ID <- paste(data_water_qual$SITE_ID, data_water_qual$DATE_COL, sep="_")
data_lake_info$ID <- paste(data_lake_info$SITE_ID, data_lake_info$DATE_COL, sep="_")
data_profile$ID <- paste(data_profile$SITE_ID, data_profile$DATE_PROFILE, sep="_")

# only choose the variables that are recorded at the water surface 
data_profile <- subset(data_profile, data_profile$DEPTH ==0)

# combine the data frames 
data_merge <- merge(data_water_qual, data_lake_info, by=c("ID")) # merge the first two 
data_merge <- merge(data_merge, data_profile, by=c("ID")) # then merge the result to the third 

# this is the size now 
dim(data_merge)

#########################
# Clean up a few things #
#########################
# remove and observations with missing values for chlorophyll a 
data_merge <- data_merge[!rowSums(is.na(data_merge["CHLA"])), ]

# convert the formatting for the date 
data_merge$DATE <- strftime(as.Date(data_merge$DATE_COL.x, "%m/%d/%Y"), format = "%j")
data_merge$DATE <- as.numeric(data_merge$DATE)

#############################################
# Split data into training and testing sets #
#############################################
library(caret)

# take 75% of the observations as training data 
inTrain <- createDataPartition(y=data_merge$CHLA, p=0.75, list=FALSE) # use 75% of data to train to the model 
training <- data_merge[inTrain,]
testing <- data_merge[-inTrain,]

#####################################
# Plotting univariate relationships #
#####################################
library(ggplot2)

predict_vars <- c("SECMEAN","PH_LAB","COND","PTL","TEMP_FIELD","DO_FIELD","DEPTHMAX","LAKEAREA","SLD","DATE")

for(i in unique(predict_vars)){
  plots <- ggplot(training,aes_string(y="CHLA",x=i)) + geom_point(alpha=0.4)
  plots <- plots + scale_x_log10() + scale_y_log10()
  print(plots)
}

#######################
# Fit a random forest #
#######################
library(caret)

# set a seed so this analysis is repeatable 
set.seed(12321)

modFit_RF <- train(CHLA ~ SECMEAN + PH_LAB + COND + PTL + TEMP_FIELD + DO_FIELD + DEPTHMAX + LAKEAREA + SLD + DATE, 
                   method="rf", 
                   data=training)

# save the final model 
finMod_RF <- modFit_RF$finalModel

# get summary of model tuning 
print(modFit_RF)

# summary of the final model 
print(finMod_RF)

# get variable importance 
finMod_RF$importance

########################################
# Observed vs. predicted chlorophyll a #
########################################
# remove the test cases that have missing predictors
cols <- c("SECMEAN","PH_LAB","COND","PTL","TEMP_FIELD","DO_FIELD","DEPTHMAX","LAKEAREA","SLD","DATE")
testing <- testing[!rowSums(is.na(testing[cols])), ]

# Make predictions and add them to to the testing data frame
testing$pred_RF <- predict(modFit_RF, testing)

# Calculate the root mean square error (RMSE) on the testing data
sqrt(sum((testing$pred_RF - testing$CHLA)^2))

###########
# Plot it #
###########
plot_RF_log <- ggplot(testing, aes(x=CHLA, y=pred_RF)) + geom_point(size=2) 
plot_RF_log <- plot_RF_log + geom_abline(slope=1,intercept=0,size=1,colour="red")
plot_RF_log <- plot_RF_log + xlab("Observed chl a") + ylab("Predicted chl a")
plot_RF_log <- plot_RF_log + theme_classic(base_size=18)
plot_RF_log <- plot_RF_log + expand_limits(x=0, y=0)
plot_RF_log <- plot_RF_log + scale_x_log10(expand=c(0,0)) + scale_y_log10(expand=c(0,0)) 
plot_RF_log

#######################
# Parallel Processing #
#######################
library(caret)
library(doSNOW)

# set-up the cluster 
cl <- makeCluster(4, type="SOCK") 
registerDoSNOW(cl)

# fit the model 
modFit_RF_par <- train(CHLA ~ SECMEAN + PH_LAB + COND + PTL + TEMP_FIELD + DO_FIELD + DEPTHMAX + LAKEAREA + SLD + DATE, 
                       method="rf", 
                       data=training)

# end the cluster 
stopCluster(cl)

####################
# Even bigger data #
####################
library(ff)

URL <- "http://water.epa.gov/type/lakes/assessmonitor/lakessurvey/upload/NLA2007_WaterQuality_20091123.csv"
X <- getURL(URL, ssl.verifypeer = FALSE)
data_water_qual <- read.table.ffdf(file=textConnection(X), FUN="read.csv")
