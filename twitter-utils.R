#!/usr/bin/env Rscript

library(lattice)
library(stringr)
library(ggplot2)
library(igraph)
library(tm)
library(wordcloud)
library(RColorBrewer)
library(cluster)
library(FactoMineR)

twNormalizeDate <- function(df, tz) {
    df$created <- as.POSIXct(format(df$created, tz=tz, usetz=TRUE))
    df <- tweets_df[with(df, order(created)), ]
    #df <- df[37:nrow(df),]
    return(df)
}


twTopAttribute <- function(df, attribute, top=10) {
    t <- rev(sort(table(df[[attribute]])))
    top <- min(top, length(t))
    return(t[1:top])
}

twTopContributors <- function(df, top=10) {
    return(twTopAttribute(df, attribute="screenName", top=top))
}

twTopAgents <- function(df, top=10) {
    d = df$statusSource
    d <- gsub("</a>", "", d)
    d <- strsplit(d, ">")
    d <- sapply(d, function(x) ifelse(length(x) > 1, x[2], x[1]))
    t <- rev(sort(table(d)))
    top <- min(top, length(t))
    return(t[1:top])
}


#########
## tot
##########
twHistTweets <- function(df, breaks="30 mins", output.dir=".", output.file="tweets.png", width=1000, height=500, color="red") {
    filename <- file.path(output.dir, output.file)
    png(filename, width=width, height=height, units="px")
    p <- histogram(cut(df$created, breaks=breaks), scales = list(x = list(rot = 90)), main="Tweets overt time", type="count", xlab="time", ylab="tweets", col=color)
    print(p)
    dev.off()
}

#########
## agent
##########
twChartAgents <- function(df, output.dir=".", output.file="agents.png", width=1000, height=500, color="red", top=10) {
    filename <- file.path(output.dir, output.file)
    png(filename, width=width, height=height, units="px")
    sources <- twTopAgents(df, top=top)
    p <- barchart(sources, col=color, xlab="tweets", ylab="people")
    print(p)
    dev.off()
}

#########
## top contributors
##########
twChartAuthors <- function(df, output.dir=".", output.file="authors.png", width=1000, height=500, color="red", top=10) {
    filename <- file.path(output.dir, output.file)
    png(filename, width=width, height=height, units="px")
    sources = twTopContributors(df)
    p <- barchart(sources, col=color, xlab="tweets", ylab="people")
    print(p)
    dev.off()
}

#########
## retweeed-people
##########
twChartAuthorsWithRetweets <- function(df, output.dir=".", output.file="authors-with-retweets.png", width=1000, height=500, color="red", top=10) {
    filename <- file.path(output.dir, output.file)
    png(filename, width=width, height=height, units="px")
    d = aggregate(df$retweetCount, by=list(df$screenName), FUN=sum)
    colnames(d) = c("User", "retweets")
    p <- barchart( User ~ retweets, data=d, col=color, xlab="retweets", ylab="people")
    print(p)
    dev.off()
}

twChartAuthorsWithReplies <- function(df, output.dir=".", output.file="authors-with-replies.png", width=1000, height=500, color="red", top=10) {
    filename <- file.path(output.dir, output.file)
    png(filename, width=width, height=height, units="px")
    d = table(df[!is.na(df$replyToSID),]$screenName)
    p <- barchart( d, col=color, xlab="replies", ylab="people", title="Top Authors with replies")
    print(p)
    dev.off()
}

twChartInfluencers <- function(df, output.dir=".", output.file="influencers.png", width=1000, height=500, color="red", top=10) {
    filename <- file.path(output.dir, output.file)
    png(filename, width=width, height=height, units="px")
    
    d = aggregate(df$retweetCount, by=list(df$screenName), FUN=sum)
    colnames(d) = c("User", "retweets")
    
    d2 <- as.data.frame(table(df$replyToSN))
    colnames(d2) = c("User", "replies")

    m = merge(d, d2, all=TRUE)
    m[is.na(m)] = 0

    d1 <- table(df[["screenName"]])
    d1 <- as.data.frame(d1)
    colnames(d1) = c("User", "tweets")
    
    m2 = merge(m, d1, all=TRUE)
    m2[is.na(m2)] = 0
    
    ##m3 <- m2[order(-m2$tweets),]
    png(filename, width=width, height=height, units="px")
    p <- ggplot(m2, aes(x=tweets, y=retweets, size=replies, label=User),legend=FALSE) + geom_point(colour="white", fill="red", shape=21) + geom_text(size=4)+ theme_bw()
    print(p)
    dev.off()
}

twCleanText <- function(text, remove.retweets=TRUE, remove.at=TRUE) {
    results = text

    ## remove retweet entities
    if (remove.retweets)
        results = gsub("(RT|via)((?:\\b\\W*@\\w+)+)", "", results)
    ## remove at people
    if (remove.at)
        results = gsub("@\\w+", "", results)
    ## remove punctuation
    results = gsub("[[:punct:]]", "", results)
    ## remove numbers
    results = gsub("[[:digit:]]", "", results)
    ## remove html links
    results = gsub("http\\w+", "", results)
    ## remove unnecessary spaces
    results = gsub("[ \t]{2,}", "", results)
    results = gsub("^\\s+|\\s+$", "", results)
    names(results) = NULL
    
    ## remove empty results (if any)
    results = results[results != ""]
    return(results)
}

#https://sites.google.com/site/miningtwitter/questions/talking-about/wordclouds/wordcloud1


twBuildTDMMatrix <- function(text, stopwords=c(stopwords("english"), stopwords("italian"))) {
    ## create a corpus
    corpus <- Corpus(VectorSource(text))

    ## create document term matrix applying some transformations
    tdm <- TermDocumentMatrix(corpus,
                              control = list(removePunctuation = TRUE,
                                  stopwords =stopwords, stemDocument=TRUE,
                                  minWordLength=4,
                                  removeNumbers = TRUE, tolower = TRUE))
    ## define tdm as matrix
    m <- as.matrix(tdm)
    return(m)
}

twChartWordcloud <- function(text=NULL, tdm.matrix=NULL, output.dir=".", output.file="wordcloud.png", stopwords=c(stopwords("english"), stopwords("italian"))) {
    filename <- file.path(output.dir, output.file)
    png(filename, width=width, height=height, units="px")

    if(is.null(tdm.matrix))
        tdm.matrix <- twBuildTDMMatrix(text, stopwords=stopwords)
    
    ## get word counts in decreasing order
    word_freqs = sort(rowSums(tdm.matrix), decreasing=TRUE) 
    ## create a data frame with words and their frequencies
    dm <- data.frame(word=names(word_freqs), freq=word_freqs)
 
    p <- wordcloud(dm$word, dm$freq, random.order=FALSE, max.words=Inf,
                   colors=brewer.pal(8, "Dark2"))
    print(p)
    ##colors=brewer.pal(8, "Dark2"), vfont=c("sans serif","plain"))
    dev.off()
}

twChartGivenTopics <- function(text=NULL, tdm.matrix=NULL, output.dir=".", output.file="given-topics.png", stopwords=c(stopwords("english"), stopwords("italian"))) {
    if(is.null(tdm.matrix))
        tdm.matrix <- twBuildTDMMatrix(text, stopwords=stopwords)
    
    filename <- file.path(output.dir, output.file)
    png(filename, width=width, height=height, units="px")                         
    ## https://sites.google.com/site/miningtwitter/questions/talking-about/given-topic
    wc = rowSums(tdm.matrix)

    ## get those words above the 3rd quantile
    lim = quantile(wc, probs=0.9)
    good = tdm.matrix[wc > lim,]

    ## remove columns (docs) with zeroes
    good = good[,colSums(good)!=0]
    ## adjacency matrix
    M = good %*% t(good)

    ## set zeroes in diagonal
    diag(M) = 0

    ## graph
    g = graph.adjacency(M, weighted=TRUE,
        mode="undirected",
        add.rownames=TRUE)
    ## layout
    glay = layout.fruchterman.reingold(g)

    ## let's superimpose a cluster structure with k-means clustering
    kmg = kmeans(M, centers=8)
    gk = kmg$cluster

    ## create nice colors for each cluster
    gbrew = c("red", brewer.pal(8, "Dark2"))
    gpal = rgb2hsv(col2rgb(gbrew))
    gcols = rep("", length(gk))
    for (k in 1:8) {
        gcols[gk == k] = hsv(gpal[1,k], gpal[2,k], gpal[3,k], alpha=0.5)
    }

    ## prepare ingredients for plot
    V(g)$size = 10
    V(g)$label = V(g)$name
    V(g)$degree = degree(g)
    ##V(g)$label.cex = 1.5 * log10(V(g)$degree)
    V(g)$label.color = hsv(0, 0, 0.2, 0.55)
    V(g)$frame.color = NA
    V(g)$color = gcols
    E(g)$color = hsv(0, 0, 0.7, 0.3)

    ## plot
    plot(g, layout=glay)
    title("\nGiven topics",
          col.main="gray40", cex.main=1.5, family="serif")
    dev.off()
}

twChartWhoRetweetsWhom <- function(text, output.dir=".", output.file="who-retweets-whom.png") {
    filename <- file.path(output.dir, output.file)
    png(filename, width=width, height=height, units="px")   
    ##https://sites.google.com/site/miningtwitter/questions/user-tweets/who-retweet
    dm_txt <- text
    ## regular expressions to find retweets
    grep("(RT|via)((?:\\b\\W*@\\w+)+)", dm_txt, 
         ignore.case=TRUE, value=TRUE)

    ## which tweets are retweets
    rt_patterns = grep("(RT|via)((?:\\b\\W*@\\w+)+)", 
        dm_txt, ignore.case=TRUE)

    ## show retweets (these are the ones we want to focus on)
    dm_txt[rt_patterns]
    ## create list to store user names
    who_retweet = as.list(1:length(rt_patterns))
    who_post = as.list(1:length(rt_patterns))

    ## for loop
    for (i in 1:length(rt_patterns)) { 
        ## get tweet with retweet entity
        twit = tweets_df[rt_patterns[i],]
        ## get retweet source 
        poster = str_extract_all(twit$text,
            "(RT|via)((?:\\b\\W*@\\w+)+)") 
        ## remove ':'
        poster = gsub(":", "", poster) 
        ## name of retweeted user
        who_post[[i]] = gsub("(RT @|via @)", "", poster, ignore.case=TRUE) 
        ## name of retweeting user 
        who_retweet[[i]] = rep(twit$screenName, length(poster)) 
    }

    ## unlist
    who_post = unlist(who_post)
    who_retweet = unlist(who_retweet)
    ## two column matrix of edges
    retweeter_poster = cbind(who_retweet, who_post)

    ## generate graph
    rt_graph = graph.edgelist(retweeter_poster)

    ## get vertex names
    ver_labs = get.vertex.attribute(rt_graph, "name", index=V(rt_graph))

    ## choose some layout
    glay = layout.fruchterman.reingold(rt_graph)

    ## plot

    par(bg="white", mar=c(1,1,1,1))
    plot(rt_graph, layout=glay,
         vertex.color=hsv(h=.35, s=1, v=.7, alpha=0.1),
         vertex.frame.color=hsv(h=.35, s=1, v=.7, alpha=0.1),
         vertex.size=5,
         vertex.label=ver_labs,
         vertex.label.family="mono",
         vertex.label.color="blue",
         ##  vertex.label.color=hsv(h=0, s=0, v=.95, alpha=0.5),
         vertex.label.cex=0.85,
         edge.arrow.size=0.8,
         edge.arrow.width=0.5,
         edge.width=3,
         edge.color=hsv(h=.35, s=1, v=.7, alpha=0.4))
# add title
    title("\nWho retweets whom",
          cex.main=1, col.main="red", family="mono")
    dev.off()
}


twChartDendrogram <- function(text=NULL, tdm.matrix=NULL, output.dir=".", output.file="dendrogram.png", stopwords=c(stopwords("english"), stopwords("italian"))) {
    if(is.null(tdm.matrix))
        tdm.matrix <- twBuildTDMMatrix(text, stopwords=stopwords)

    m = tdm.matrix
    
    filename <- file.path(output.dir, output.file)
    png(filename, width=width, height=height, units="px")                         

    ## remove sparse terms (word frequency > 90% percentile)
    wf = rowSums(m)
    m1 = m[wf>quantile(wf,probs=0.95), ]

    ## remove columns with all zeros
    m1 = m1[,colSums(m1)!=0]

    ## for convenience, every matrix entry must be binary (0 or 1)
    m1[m1 > 1] = 1

    ## distance matrix with binary distance
    m1dist = dist(m1, method="binary")

    ## cluster with ward method
    clus1 = hclust(m1dist, method="ward")

    ## plot dendrogram
    plot(clus1, cex=0.7)
    dev.off()
}