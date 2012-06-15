//
//  CRLocationHandler.h
//  CellreefFramework
//
//  Created by Ariel Rodriguez on 6/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CRLocationHandler : NSObject
@property (strong) CLLocation *latestKnownLocation;
@end
