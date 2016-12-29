#!/usr/bin/Rscript

library(dplyr)
library(DT)
# devtools::install_github("tomikauppinen/SPARQL-package-for-R")
library(SPARQL)

endpoint <- "http://lod.springer.com/sparql"

q1 <- "PREFIX spr-p: <http://lod.springer.com/data/ontology/property/>
  PREFIX spr-c: <http://lod.springer.com/data/ontology/class/>
  
  SELECT ?volume ?title ?subtitle ?acronym ?isbn ?eisbn ?scopus ?sdate
WHERE {
  ?volume spr-p:hasConference ?conf ;
  spr-p:isIndexedByScopus ?scopus ;
  spr-p:title ?title ;
  spr-p:subtitle ?subtitle ;
  spr-p:bookSeriesAcronym ?acronym ;
  spr-p:ISBN ?isbn ;
  spr-p:EISBN ?eisbn ;
  spr-p:scopusSearchDate ?sdate .
  FILTER (?scopus = 'false'^^<http://www.w3.org/2001/XMLSchema#boolean>)
}
GROUP BY ?volume ?title ?subtitle ?acronym ?isbn ?eisbn ?scopus ?sdate"

q2 <- "PREFIX spr-p: <http://lod.springer.com/data/ontology/property/>
  PREFIX spr-c: <http://lod.springer.com/data/ontology/class/>
  
  SELECT ?volume ?title ?subtitle ?acronym ?isbn ?eisbn ?scopus ?sdate
WHERE {
  ?volume spr-p:hasConference ?conf ;
  spr-p:isIndexedByScopus ?scopus ;
  spr-p:title ?title ;
  spr-p:subtitle ?subtitle ;
  spr-p:bookSeriesAcronym ?acronym ;
  spr-p:ISBN ?isbn ;
  spr-p:EISBN ?eisbn ;
  spr-p:scopusSearchDate ?sdate .
  FILTER (?scopus = 'true'^^<http://www.w3.org/2001/XMLSchema#boolean>)
}
GROUP BY ?volume ?title ?subtitle ?acronym ?isbn ?eisbn ?scopus ?sdate"

# sdate is NA
result1 <- SPARQL(url = endpoint, q1, ns=c('dateTime', '<http://www.w3.org/2001/XMLSchema#>'), encoding="UTF-8")$results
result1$sdate <- as.POSIXct(result1$sdate, origin="1970-01-01")

result2 <- SPARQL(url = endpoint, q2, ns=c('dateTime', '<http://www.w3.org/2001/XMLSchema#>'), encoding="UTF-8")$results
result2$sdate <- as.POSIXct(result2$sdate, origin="1970-01-01")

result <- rbind(result1, result2)

data <- result %>%
  mutate(indexedByScopus = ifelse(scopus, "No", "Yes")) %>%
  mutate(vol = gsub("<|>", "", volume)) %>%
  mutate(t = gsub('"|@en', '', title)) %>%
  mutate(subt = gsub('"|@en', '', subtitle)) %>%
  mutate(a = gsub('"|\\^\\^<http://www.w3.org/2000/01/rdf-schema#literal>', '', acronym)) %>%
  mutate(i = gsub('"|\\^\\^<http://www.w3.org/2000/01/rdf-schema#literal>', '', isbn)) %>%
  mutate(ei = gsub('"|\\^\\^<http://www.w3.org/2000/01/rdf-schema#literal>', '', eisbn)) %>%
  mutate(volumeUrl = paste0("<a href='",vol,"'>",vol,"</a>")) %>%
  mutate(d = as.Date(sdate, format="%Y-%m-%d")) %>%
  select(a, t, subt, i, ei, volumeUrl, indexedByScopus, d)

names(data) <- c("acronym", "title", "subtitle", "ISBN", "e-ISBN", "volume", "Already indexed by Scopus?", "Scopus query date")

write.csv(data, "/u/30/sonkkila/unix/projektit/springer/springer.csv")

rmarkdown::render("/u/30/sonkkila/unix/projektit/springer/conf_html.Rmd", 
                  output_dir = {normalizePath("/u/30/sonkkila/unix/projektit/springer/")},
                  output_file = "/u/30/sonkkila/unix/projektit/springer/springer.html",
                  params = list(
                    set_subtitle = paste0("Data as of ", Sys.time(), " (CC0 1.0 Universal license)")),
                  encoding = "UTF-8")


