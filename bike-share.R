library(tidyverse)
library(here)
library(skimr)
library(dplyr)
library(janitor)
library(lubridate) #library for date functions
#library(ggplot) #library for plotting

Aug2021 <- read_csv('Aug-2021.csv') 
Sep2021 <- read_csv('Sep-2021.csv') 
Oct2021 <- read_csv('Oct-2021.csv') 
Nov2021 <- read_csv('Nov-2021.csv') 
Dec2021 <- read_csv('Dec-2021.csv') 
Jan2022 <- read_csv('Jan-2022.csv') 
Feb2022 <- read_csv('Feb-2022.csv') 
Mar2022 <- read_csv('Mar-2022.csv') 
Apr2022 <- read_csv('Apr-2022.csv') 
May2022 <- read_csv('May-2022.csv') 
Jun2022 <- read_csv('Jun-2022.csv') 
Jul2022 <- read_csv('Jul-2022.csv') 
Aug2022 <- read_csv('Aug-2022.csv') 

# colnames(Aug2021)
# colnames(Sep2021)
# colnames(Oct2021)
# colnames(Nov2021)
# colnames(Dec2021)
# colnames(Jan2022)
# colnames(Feb2022)
# colnames(Mar2022)
# colnames(Apr2022)
# colnames(May2022)
# colnames(Jun2022)
# colnames(Jul2022)
# colnames(Aug2022)

all <- bind_rows(Aug2021, Sep2021, Oct2021, Nov2021, Dec2021, Jan2022, Feb2022, Mar2022, Apr2022, May2022, Jun2022, Jul2022, Aug2022)

all <- all %>% 
  select(-c(start_lat, start_lng, end_lat, end_lng))

colnames(all)

nrow(all)

dim(all)

head(all)
tail(all)

str(all)
summary(all)

# all <-  all %>% 
#   mutate(member_casual = recode(member_casual
#                                 ,"Subscriber" = "member"
#                                 ,"Customer" = "casual"))

table(all$member_casual) # to see the number of members and casuals

all$date <- as.Date(all$started_at) #The default format is yyyy-mm-dd
all$month <- format(as.Date(all$date), "%m")
all$day <- format(as.Date(all$date), "%d")
all$year <- format(as.Date(all$date), "%Y")
all$day_of_week <- format(as.Date(all$date), "%A")

library(hydroTSM) # for seasons
all$season <- time2season(all$date, out.fmt = "seasons")
table(all$season)



all$ride_length <- difftime(all$ended_at,all$started_at) # get the difference using difftime()


str(all)

#ride length should be numeric

is.factor(all$ride_length)
all$ride_length <- as.numeric(as.character(all$ride_length))
is.numeric(all$ride_length) # to check

all_v2 <- drop_na(all)
all_v2 <-  all_v2[!(all_v2$ride_length<0 | all_v2$start_station_name == "HQ QR"), ] # to remove bad data


#https://www.datasciencemadesimple.com/delete-or-drop-rows-in-r-with-conditions-2/
#all_v2 <- all[!(all$ride_length<0 | all$start_station_name == "HQ QR"), ]

glimpse(all_v2)

mean(all_v2$ride_length) #straight average (total ride length / rides)
median(all_v2$ride_length) #midpoint number in the ascending array of ride lengths
max(all_v2$ride_length) #longest ride
min(all_v2$ride_length) #shortest ride


#above can be get summary(all_v2$ride_length)

summary(all_v2$ride_length)

aggregate(all_v2$ride_length ~ all_v2$member_casual, FUN = mean)
aggregate(all_v2$ride_length ~ all_v2$member_casual, FUN = median)
aggregate(all_v2$ride_length ~ all_v2$member_casual, FUN = max)
aggregate(all_v2$ride_length ~ all_v2$member_casual, FUN = min)

aggregate(all_v2$ride_length ~ all_v2$member_casual + all_v2$day_of_week, FUN = mean)  # to see the average ride time each day, members vs. casual

# to order the days

all_v2$day_of_week <- ordered(all_v2$day_of_week, levels=c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"))

aggregate(all_v2$ride_length ~ all_v2$member_casual + all_v2$day_of_week, FUN = mean)


aggregate(all_v2$ride_length ~ all_v2$member_casual + all_v2$season, FUN = mean) # to see the average ride time each season, members vs. casual
#analyze by season

all_v2 %>%
  group_by(member_casual, season) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>% 
  arrange(member_casual, season)

#analyze data by type and weekday

all_v2 %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>%  #creates weekday field using wday()
  group_by(member_casual, weekday) %>%  #groups by usertype and weekday
  summarise(number_of_rides = n()							#calculates the number of rides and average duration 
            ,average_duration = mean(ride_length)) %>% 		# calculates the average duration
  arrange(member_casual, weekday)								# sorts

#visualize number of rides by ride types

all_v2 %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>% 
  arrange(member_casual, weekday)  %>% 
  ggplot(aes(x = weekday, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge")

#visualization for average duration

all_v2 %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>% 
  arrange(member_casual, weekday)  %>% 
  ggplot(aes(x = weekday, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge")

#visualization for rideable type

all_v2 %>%
  group_by(member_casual, rideable_type) %>%
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>%
  arrange(member_casual, rideable_type) %>%
  ggplot(aes(x = rideable_type, y = average_duration, fill = member_casual)) +
    geom_col(position = "dodge")

#visualization for seasons

all_v2 %>%
  group_by(member_casual, season) %>%
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>%
  arrange(member_casual, season) %>%
  ggplot(aes(x = season, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge")
# export

counts <- aggregate(all_v2$ride_length ~ all_v2$member_casual + all_v2$day_of_week, FUN = mean)
write.csv(counts, file = '~/Desktop/avg_ride_length.csv')
