#!/usr/bin/env Rscript

##    This program is free software: you can redistribute it and/or modify
##    it under the terms of the GNU General Public License as published by
##    the Free Software Foundation, either version 3 of the License, or
##    (at your option) any later version.
##
##    This program is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU General Public License for more details.
##
##    You should have received a copy of the GNU General Public License
##    along with this program.  If not, see <http://www.gnu.org/licenses/>.

source("twitter-utils.R")

width <- 600
height <- 500
color <- "red"
tz <- "Europe/Rome"

args <- commandArgs(trailingOnly = TRUE)
source.file <- ifelse(is.null(args[1]), "tweets_df.Rdata", args[1])

load(source.file)

df <- twNormalizeDate(tweets_df, tz)

twHistTweets(df, breaks="30 mins", width=1000, height=500, color="red")

twChartAgents(df, width=width, height=height)
twChartAuthors(df, width=width, height=height)
twChartAuthorsWithRetweets(df, width=width, height=height)
twChartAuthorsWithReplies(df, width=width, height=height)
twChartInfluencers(df, width=width, height=height)

stopwords = c("ddaypirelli", "pirelli", stopwords("english"), stopwords("italian"))


text = tweets_df$text
text <- twCleanText(text)
tdm.matrix <- twBuildTDMMatrix(text, stopwords=stopwords)

twChartWordcloud(tdm.matrix=tdm.matrix, width=width, height=height)
twChartGivenTopics(tdm.matrix=tdm.matrix, width=width, height=height)
twChartWhoRetweetsWhom(tweets_df, width=width, height=height)
twChartDendrogram(tdm.matrix=tdm.matrix, width=width, height=height)
