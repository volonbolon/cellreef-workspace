//
//  CellReef.m
//  CellreefFramework
//
//  Created by Ariel Rodriguez on 6/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CellReef.h"
#import "CRLocationHandler.h"
#import <GPX/GPX.h>

@implementation CellReef
+ (CellReef *)shared {
  static dispatch_once_t onceQueue;
  static CellReef *cellReef = nil;
  
  dispatch_once(&onceQueue, ^{ 
    cellReef = [[self alloc] init]; 
  });
  return cellReef;
}

- (void)takeOff:(NSDictionary *)takeoffOptions { 
  GPXRoot *root = [GPXRoot rootWithCreator:@"Sample Application"];
  
  GPXWaypoint *waypoint = [root newWaypointWithLatitude:35.658609f longitude:139.745447f];
  waypoint.name = @"Tokyo Tower";
  waypoint.comment = @"The old TV tower in Tokyo.";
  
  GPXTrack *track = [root newTrack];
  track.name = @"My New Track";
  
  [track newTrackpointWithLatitude:35.658609f longitude:139.745447f];
  [track newTrackpointWithLatitude:35.758609f longitude:139.745447f];
  [track newTrackpointWithLatitude:35.828609f longitude:139.745447f]; 
  
  [[CRLocationHandler sharedLocationHandler] startUpdatingLocation];
  
  NSLog(@"%@", root);
}

@end
