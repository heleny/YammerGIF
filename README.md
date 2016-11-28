# YammerGIF

YammerGIF will display a collection of currently trending GIFs from Giphy's API.  

Features included: 
- search locally based on "slug"
- view image detail
- switch between grid view to detail view and vice versa
- previous/next alumn browsing 

Used open sources:
- AFNetworking
- MWPhotoBrowser (customized version due to lots of issues found there)

todo: 
- offline support, sqlite or core data
- infinite scrolling, right now it only fetches the first 100 GIFs (not feasible - Giphy API doesn't seem to support fetching the next page)
- swift version
