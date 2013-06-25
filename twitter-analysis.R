#!/usr/bin/env Rscript


width=900
height=900
color="red"
tz <- "Europe/Rome"

load("tweets_df.Rdata")


source("twitter-utils.R")

df <- twNormalizeDate(tweets_df, tz)

twHistTweets(df, breaks="30 mins", width=1000, height=500, color="red")

twChartAgents(df)
twChartAuthors(df)
twChartAuthorsWithRetweets(df)
twChartAuthorsWithRetweets(df)
twChartInfluencers(df)

stopwords = c("ddaypirelli", "pirelli", stopwords("english"), stopwords("italian"))


text = tweets_df$text
text <- twCleanText(text)
tdm.matrix <- twBuildTDMMatrix(text, stopwords=stopwords)

twChartWordcloud(tdm.matrix=tdm.matrix)
twChartGivenTopics(tdm.matrix=tdm.matrix)
twChartWhoRetweetsWhom(df$text)
twChartDendrogram(tdm.matrix=tdm.matrix)
