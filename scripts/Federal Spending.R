setwd("~/Downloads")
library(data.table)
library(tidyverse)
library(scales)
library(lubridate)
library(gbm)
library(xtable)

options(scipen=999)


contracts <- fread("DoD_DoN_reduced.csv")

contracts[dollarsobligated < quantile(dollarsobligated, 0.95), hist(dollarsobligated)]
contracts[, hist(log(baseandalloptionsvalue))]

tokeep <- which(sapply(contracts,is.numeric))
numericCols <- contracts[ , tokeep, with=FALSE]
corTable <- cor(x = numericCols, use = "pairwise.complete.obs")
corTable[, "baseandexercisedoptionsvalue"]

# Difference in average contract size between non-Native and Native contracts
contracts[, mean(baseandexercisedoptionsvalue), aiobflag]
plot(log(baseandalloptionsvalue) ~ log(annualrevenue), data = contracts)

# Empty variables
tokeep <- which(sapply(contracts, function(x) ifelse(sum(is.na(x)) == length(x), T, F)))
contracts[, tokeep, with = F] %>% names
contracts <- contracts[, !tokeep, with = F]


# Analyzing by indicators
#tokeep <- sapply(contracts, function(x) ifelse(length(unique(x)) == 2, T, F))

contracts[, ":=" (effectivedate = as.Date(effectivedate, "%m/%d/%Y"),
                  ultimatecompletiondate = as.Date(ultimatecompletiondate, "%m/%d/%Y"),
                  currentcompletiondate = as.Date(currentcompletiondate, "%m/%d/%Y"))]



contracts[, ":=" (competitive = (numberofoffersreceived > 1),
                  plan_required = (subcontractplan != "B: PLAN NOT REQUIRED"),
                  not_firmfixed = (typeofcontractpricing != "J: FIRM FIXED PRICE"),
                  log_revenue = log(annualrevenue))]

contracts[log_revenue == -Inf, log_revenue := 0]
contracts[nchar(vendor_state_code) > 2, vendor_state_code := "FOREIGN"]
contracts[, stateofperformance := substr(placeofperformancecongressionaldistrict, 0, 2)]
# contracts[, competition_type := ifelse(extentcompeted %like% c("A:", "B:", "D:"),
#                                        "COMPETITIVE", ifelse(extentcompeted %like% "C",
#                                                              "NOT COMPETITVE", "SMALL"))]
contracts[, non_navy_request := fundingrequestingagencyid != "1700: DEPT OF THE NAVY"]

contracts[, log_employees := log(numberofemployees + 1)]
contracts[log_employees > 15, log_employees := NA]
contracts[27897, currentcompletiondate := as.Date("03-31-2017", "%m/%d/%Y")]
contracts[, days_of_contract := as.numeric(currentcompletiondate - effectivedate)]
contracts[, log_contractsize := log(baseandalloptionsvalue)]
contracts[, ":=" (days_of_contract_2 = days_of_contract^2,
                  log_days = log(abs(days_of_contract) + 1))]
contracts[, is_ship := fundingrequestingofficeid %like% "USS|USNS"]
contracts[, ":=" (is_rotc = contractingofficeid %like% "ROTC",
                  is_command = contractingofficeid %like% "COMMAND",
                  is_shipbuilding = contractingofficeid %like% "SHIPBUILDING")]


rows <- 0.8*nrow(contracts)
rows <- sample(1:nrow(contracts))[1:rows]
train <- contracts[rows]
test <- contracts[-rows]


fit <- lm(log_contractsize ~ contractactiontype + log_days +
            not_firmfixed + plan_required + log_revenue + log_employees +
            stateofperformance + extentcompeted + emergingsmallbusinessflag +
            non_navy_request + multiyearcontract + contractfinancing +
            costaccountingstandardsclause + purchasecardaspaymentmethod + hospitalflag +
            is_ship + is_rotc + is_command + is_shipbuilding + log_revenue:log_employees +
            multiyearcontract:log_days + (contractactiontype*not_firmfixed*plan_required),
          data = train)
summary(fit)
stepped <- step(fit, direction = "backward", verbose = T)

predicted <- predict(stepped, test)
rmse <- sqrt(mean((predicted - test$log_contractsize)^2, na.rm = T))
plot(test$log_contractsize ~ predicted)
abline(a = 0, b = 1, col = "red")

contract_boost <- gbm(log_contractsize ~ as.factor(contractactiontype) + log_days +
                        as.factor(not_firmfixed) + as.factor(plan_required) + log_revenue + log_employees +
                        as.factor(stateofperformance) + as.factor(extentcompeted) + as.factor(emergingsmallbusinessflag) +
                        as.factor(non_navy_request) + as.factor(multiyearcontract) + as.factor(contractfinancing) + log_revenue:log_employees +
                        as.factor(costaccountingstandardsclause) + as.factor(purchasecardaspaymentmethod) + as.factor(hospitalflag) +
                        as.factor(is_ship) + as.factor(is_rotc) + as.factor(is_command) + as.factor(is_shipbuilding), 
                      data = train, distribution = "gaussian",n.trees = 1000,
                 shrinkage = 0.01, interaction.depth = 4)
contract_boost
summary(contract_boost)
boost_predict <- predict(contract_boost, test, n.trees = 1000)
boost_mse <- mean((test$log_contractsize-boost_predict)^2, na.rm = T)

library(foreach)
length_divisor<-4
iterations<-1000
predictions<-foreach(m=1:iterations,.combine=cbind) %do% {
  training_positions <- sample(nrow(train), size=floor((nrow(train)/length_divisor)))
  train_pos<-1:nrow(train) %in% training_positions
  lm_fit<-lm(log_contractsize ~ contractactiontype + log_days +
               not_firmfixed + plan_required + log_revenue + log_employees +
               stateofperformance + extentcompeted + emergingsmallbusinessflag +
               non_navy_request + multiyearcontract + contractfinancing + log_revenue:log_employees +
               costaccountingstandardsclause + purchasecardaspaymentmethod + hospitalflag +
               is_ship + is_rotc + is_command + is_shipbuilding,data=train)
  predict(lm_fit,newdata=test)
}
predictions<-rowMeans(predictions)
error<- mean((test$log_contractsize-predictions)^2, na.rm = T)


contracts[c(9549, 37638, 7992)]

ggplot(contracts, aes(x = log_days, y = log_contractsize)) +
  geom_smooth() +
  labs(x = "Log Length of Contract (Days)", y = "Log Contract Size ($)", title = "Contract Size vs. Length") +
  theme_bw()

ggplot(contracts[, .(log_contractsize = mean(log_contractsize), error = sd(log_contractsize)/sqrt(.N)), extentcompeted] %>% .[order(log_contractsize)],
       aes(x = reorder(extentcompeted, -log_contractsize), y = log_contractsize, fill = extentcompeted)) +
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = log_contractsize - 2*error, ymax = log_contractsize + 2*error)) +
  labs(x = "Competition", y = "Log Contract Size ($)", fill = "Legend") +
  scale_x_discrete(labels=rep("", 9)) +
  theme_bw()

ggplot(contracts, aes(x = baseandalloptionsvalue)) +
  geom_histogram() +
  scale_x_log10() +
  labs(x = "Contract Size ($)", y = "Number of Observations", title = "Distribution of Contract Sizes") +
  theme_bw()

fit_dt <- data.table(x = test$log_contractsize, y = predicted, method = "Stepwise Regression")
fit_dt <- rbind(fit_dt, data.table(x = test$log_contractsize, y = boost_predict, method = "Gradient Boosting"))
fit_dt <- rbind(fit_dt, data.table(x = test$log_contractsize, y = predictions, method = "Bagging"))

ggplot(fit_dt, aes(x = x, y = y)) +
  geom_point(alpha = 0.3) +
  facet_grid(. ~ method) +
  geom_abline(intercept = 0, slope = 1, col = "red") +
  labs(x = "Fitted Values", y = "Residuals", title = "Model Results") +
  theme_bw()
