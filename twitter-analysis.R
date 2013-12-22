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

#################################################################
## file history
##################################################################
## 2013-06-24: matteo redaelli: first release
##
##

library(getopt)
library(logging)

## log setup
basicConfig()

#get options, using the spec as defined by the enclosed list.
#we read the options from the default: commandArgs(TRUE).
spec = matrix(c(
  'verbose', 'v', 2, "integer",
  'help' , 'h', 0, "logical",
  'height' , 'H', 1, "character",
  'width' , 'W', 1, "character",
  'data.file' , 'd', 1, "character",
  'tz' , 't', 1, "integer",
  'top' , 'T', 1, "integer",
  'color' , 'c', 1, "logical",
  'stopwords' , 's', 1, "logical",
  'version' , 'V', 0, "logical"
  ), byrow=TRUE, ncol=4)

opt = getopt(spec);
# if help was asked for print a friendly message
# and exit with a non-zero error code
if ( !is.null(opt$help) ) {
  cat(getopt(spec, usage=TRUE))
  q(status=1);
}

if ( !is.null(opt$version) ) {
  cat("version 0.1\n")
  q(status=1)
}

source("twitter-utils.R")

#set some reasonable defaults for the options that are needed,
#but were not specified.
if ( is.null(opt$color ) ) { opt$color = "red" }
if ( is.null(opt$data.file ) ) { opt$data.file = "tweets_df.Rdata" }
if ( is.null(opt$height ) ) { opt$height = 600 }
if ( is.null(opt$width ) ) { opt$width = 600 }
if ( is.null(opt$tz ) ) { opt$tz = "Europe/Rome" }
if ( is.null(opt$top ) ) { opt$top = 10 }
if ( is.null(opt$stopwords) ) {
  opt$stopwords <- stopwords('english')
} else {
  opt$stopwords <- eval(parse(text=opt$stopwords))
}

loginfo(sprintf("Stopwords: %s", paste(opt$stopwords, sep=",", collapse=",")))


loginfo(sprintf("Loading file %s", opt$data.file))
load(opt$data.file)

df <- twNormalizeDate(tweets_df, opt$tz)

twHistTweets(df, breaks="30 mins", width=opt$width, height=opt$height, color=opt$color)

twChartAgents(df, width=opt$width, height=opt$height, color=opt$color, top=opt$top)
twChartAuthors(df, width=opt$width, height=opt$height, color=opt$color, top=opt$top)
twChartAuthorsWithRetweets(df, width=opt$width, height=opt$height, color=opt$color, top=opt$top)
twChartAuthorsWithReplies(df, width=opt$width, height=opt$height, color=opt$color, top=opt$top)
twChartInfluencers(df, width=opt$width, height=opt$height, color=opt$color)

text = tweets_df$text
text <- twCleanText(text)
tdm.matrix <- twBuildTDMMatrix(text, stopwords=opt$stopwords)

twChartWordcloud(tdm.matrix=tdm.matrix, width=opt$width, height=opt$height)
#twChartWordcloud(twTopHashtags(text, top=30), width=opt$width, height=opt$height, output.file="wordcloud-hashtags.png")
twChartGivenTopics(tdm.matrix=tdm.matrix, width=opt$width, height=opt$height)
twChartWhoRetweetsWhom(tweets_df, width=opt$width, height=opt$height)
twChartDendrogram(tdm.matrix=tdm.matrix, width=opt$width, height=opt$height)

# todo: http://bodongchen.com/blog/2013/02/demo-of-using-twitter-hashtag-analytics-package-to-analyze-tweets-from-lak13/
