//
//  CRLocationHandler.h
//  CellreefFramework
//
//  Created by Ariel Rodriguez on 6/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CRLocationHandler : NSObject <CLLocationManagerDelegate>
@property (strong) CLLocation *latestKnownLocation;

+ (id)sharedLocationHandler; 
- (BOOL)isReceivingLocationUpdates; 
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;  
@end
