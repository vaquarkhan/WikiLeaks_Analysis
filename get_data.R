# File-Name:       wikileaks_analysis.R                 
# Date:            2010-07-26                                
# Author:          Drew Conway
# Email:           drew.conway@nyu.edu                                      
# Purpose:         Load and format WikiLeaks data, to be loaded in the header of all subsequent files
# Data Used:       afg.csv (http://leakmirror.wikileaks.org/file/straw-glass-and-bottle/afg-war-diary.csv.7z)
# Packages Used:   ggplot2,plyr,maptools,Zelig,
# Output File:     
# Data Output:     
# Machine:         Drew Conway's MacBook Pro

# Copyright (c) 2010, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved.                                                         

# For data manipulation and visualization
library(ggplot2)
library(plyr)
library(maptools)
library(RColorBrewer)

library(spatstat)
library(geoR)
library(maptools)
library(mapproj)

# For models
# library(geoR)
# library(topicmodels)

# Shapefile directory
shape.files<-"shapefiles/"

### DATA CLEAN ###

# This will take several seconds on most laptops
cat("reading data\n")
afg<-read.csv("~/Dropbox/Wikileaks_project/Wikidata/afg.csv",stringsAsFactors=FALSE)

# Add header data leftout by WikiLeaks, label reference taken from http://wardiary.wikileaks.org/
colnames(afg)<-c("ReportKey","DateOccurred","Type","Category","TrackingNumber","Title","Summary","Region","AttackOn",
    "ComplexAttack","ReportingUnit","UnitName","TypeOfUnit","FriendlyWIA","FriendlyKIA","HostNationWIA","HostNationKIA",
    "CivilianWIA","CivilianKIA","EnemyWIA","EnemyKIA","EnemyDetained","MGRS","Latitude","Longitude","OriginatorGroup",
    "UpdatedByGroup","CCIR","Sigact","Affiliation","DColor","Classification")

cat("converting date\n")    
# Convert date to R format
afg$DateOccurred <- as.Date(afg$DateOccurred)
year <- format.Date(afg$DateOccurred,"%Y")

# Collapse bad region data
afg$Region[grep("RC ",afg$Region,fixed=T,invert=T)]<-"UNKNOWN"
afg$Region<-as.factor(afg$Region)

# Aggregate WIA and KIA data into new columns
all.wia<-afg$FriendlyWIA+afg$HostNationWIA+afg$CivilianWIA+afg$EnemyWIA
all.kia<-afg$FriendlyKIA+afg$HostNationKIA+afg$CivilianKIA+afg$EnemyKIA
all.cas<-all.wia+all.kia

# Create a new column to identify where Summary column includes the word 'contractor'
has.cntr<-rep(FALSE,nrow(afg))
has.cntr[grep("contractor",afg$Summary,fixed=FALSE,ignore.case=TRUE)]<-TRUE

# Add new columns to afg dataframe
afg<-transform(afg,AllKIA=all.kia,AllWIA=all.wia,AllCasualty=all.cas,Year=year,HasCntr=has.cntr)

# Load shapefiles
# Afghanistan adminstrative file
afg.shp <- readShapePoly(paste(shape.files,"admin/admin3_poly_32.shp",sep=""))
afg.poly <- fortify.SpatialPolygons(afg.shp)


# rough lat/lon limits of Afghanistan:
max_lat = max(afg.poly$lat)
min_lat = min(afg.poly$lat)
max_lon = max(afg.poly$lon)
min_lon = min(afg.poly$lon)

# filter out events not in Afghanistan (?!)
afg_boundary<-subset(afg, Latitude>=min_lat & Latitude<=max_lat & Longitude>=min_lon & Longitude<=max_lon)

# Subset of only IED events
afg_ied<-subset(afg_boundary, Type=="Explosive Hazard")