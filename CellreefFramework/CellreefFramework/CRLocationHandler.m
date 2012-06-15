//
//  CRLocationHandler.m
//  CellreefFramework
//
//  Created by Ariel Rodriguez on 6/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CRLocationHandler.h"
#import "CRHttpClient.h"
#import <GPX/GPX.h>

static NSString *const kLatKey = @"lat";
static NSString *const kLngKey = @"lng";
static NSString *const kAltitudeKey = @"altitude";
static NSString *const kHorizontalAccuracyKey = @"horizontalAccuracy";
static NSString *const kVerticalAccuracyKey = @"verticalAccuracy";
static NSString *const kTimestampKey = @"timestamp";
static NSString *const kSpeedKey = @"speed";
static NSString *const kCourseKey = @"course";

@interface CRLocationHandler ()
@property (strong) CLLocationManager *locationManager;
@property (strong) CLLocation *sleepLocation; 
@property (assign) BOOL isSleeping; 
@property (strong) NSTimer *sleepTimer; 
@property (atomic, strong) NSDate *lastServerUpdate; 

- (void)goToSleep:(NSTimer *)timer;
- (void)awakeFromSleep:(NSTimer *)timer; 
- (NSString *)locationsPath; 
- (void)pushLocationsToServer:(NSArray *)locations; 
@end

@implementation CRLocationHandler
@synthesize latestKnownLocation; 
@synthesize locationManager; 
@synthesize isSleeping; 
@synthesize sleepLocation; 
@synthesize sleepTimer;  

- (NSString *)locationsPath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  //2) Create the full file path by appending the desired file name
  NSString *locationsPath = [documentsDirectory stringByAppendingPathComponent:@"locations.plist"];

  NSLog(@"locationsPath: %@", locationsPath);
  
  return locationsPath;
}

+ (id)sharedLocationHandler {
  static dispatch_once_t onceQueue;
  static CRLocationHandler *locationHandler = nil;
  
  dispatch_once(&onceQueue, ^{ 
    locationHandler = [[self alloc] init];
    
    CLLocationManager *lm = [[CLLocationManager alloc] init]; 
    [locationHandler setLocationManager:lm]; 
    [[locationHandler locationManager] setDelegate:locationHandler]; 
    [[locationHandler locationManager] setDesiredAccuracy:kCLLocationAccuracyBest]; 
    [[locationHandler locationManager] setDistanceFilter:20]; 
  });
  return locationHandler;
}

- (BOOL)isReceivingLocationUpdates {
	return ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized);
}

- (void)startUpdatingLocation {
	NSLog(@"startUpdatingLocation");
	if ( ![self isSleeping] ) {
    [[self locationManager] startUpdatingLocation];
  }
}

- (void)stopUpdatingLocation {
	NSLog(@"stopUpdatingLocation");
	[[self locationManager] stopUpdatingLocation];
	[[self locationManager] stopMonitoringSignificantLocationChanges];
}

- (void)goToSleep:(NSTimer *)timer {
  [self setIsSleeping:YES]; 
  [self setSleepLocation:[self latestKnownLocation]]; 
  [[self locationManager] stopUpdatingLocation];
  
  [[self locationManager] stopUpdatingLocation]; 
	
	// Sleep implementation ideas: set a timer to periodically awaken and check location? start significant location change monitoring? set up a region around user and do region monitoring?
	[[self locationManager] startMonitoringSignificantLocationChanges];
}

- (void)awakeFromSleep:(NSTimer *)timer {
	[self setIsSleeping:NO];
	[self setSleepLocation:nil];
	[[self locationManager] stopMonitoringSignificantLocationChanges];
	[[self locationManager] startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager 
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
	NSLog(@"New location! It is %f seconds old.", [newLocation.timestamp timeIntervalSinceNow]);
	
	// check timestamp; if it's older than 5 mins, discard
	if([newLocation.timestamp timeIntervalSinceNow] < -300) {
		NSLog(@"ignoring old location. timestamp: %@", [newLocation timestamp]);
		return;
	}
	
	// If we don't already have a current location, or it's been 15 seconds, OR we've more than doubled our accuracy, save the new location
	if( [self latestKnownLocation] == nil || ([[newLocation timestamp] timeIntervalSinceDate:[[self latestKnownLocation] timestamp]] > 15) || (([self latestKnownLocation].horizontalAccuracy / 2) > newLocation.horizontalAccuracy) ) {
		// if we were asleep, make sure we've moved enough and then wake up!
		if( [self isSleeping] ) {
			if( [[self sleepLocation] distanceFromLocation:newLocation] > 100 ) {
				[self awakeFromSleep:nil];
			} else {
				return;
			}
		}
    
		NSLog(@"Storing location");
		// update current location
		[self setLatestKnownLocation:newLocation]; 
    
		[[self sleepTimer] invalidate];
		sleepTimer = [NSTimer scheduledTimerWithTimeInterval:200 target:self selector:@selector(goToSleep:) userInfo:nil repeats:NO];
    
    NSArray *keys = [[NSArray alloc] initWithObjects:kLatKey, kLngKey, kAltitudeKey, kHorizontalAccuracyKey, kVerticalAccuracyKey, kTimestampKey, kSpeedKey, kCourseKey, nil]; 
    NSArray *values = [[NSArray alloc] initWithObjects:
                       [NSNumber numberWithDouble:[newLocation coordinate].latitude],
                       [NSNumber numberWithDouble:[newLocation coordinate].longitude], 
                       [NSNumber numberWithDouble:[newLocation altitude]], 
                       [NSNumber numberWithDouble:[newLocation horizontalAccuracy]],
                       [NSNumber numberWithDouble:[newLocation verticalAccuracy]], 
                       [newLocation timestamp], 
                       [NSNumber numberWithDouble:[newLocation speed]], 
                       [NSNumber numberWithDouble:[newLocation course]], 
                       nil]; 
    NSDictionary *locationAsDict = [[NSDictionary alloc] initWithObjects:values 
                                                                 forKeys:keys];
    
    NSURL *fileURL = [NSURL fileURLWithPath:[self locationsPath]
                                isDirectory:NO]; 
    
    NSError *error = nil; 
    NSMutableArray *locations = nil; 
    if ( [fileURL checkResourceIsReachableAndReturnError:&error] ) {
      locations = [[[NSArray alloc] initWithContentsOfURL:fileURL] mutableCopy]; 
    } else {
      locations = [[NSMutableArray alloc] init];  
    }
    
    [locations addObject:locationAsDict]; 
    
    if ( fabs([[self lastServerUpdate] timeIntervalSinceNow]) > 120 ) {
      [self pushLocationsToServer:locations]; 
    }
    
    [locations writeToURL:fileURL
               atomically:YES]; 
	}
}

- (void)setLastServerUpdate:(NSDate *)lastServerUpdate_ {
  @synchronized(self) {
    NSDate *storedDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastServerUpdate"]; 
    if ( ![storedDate isEqualToDate:lastServerUpdate_] ) {
      [[NSUserDefaults standardUserDefaults] setObject:lastServerUpdate_
                                                forKey:@"lastServerUpdate"]; 
      [[NSUserDefaults standardUserDefaults] synchronize]; 
    }
  }
}

- (NSDate *)lastServerUpdate {
  @synchronized(self) {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"lastServerUpdate"]; 
  }
}

- (void)pushLocationsToServer:(NSArray *)locations {
  GPXRoot *root = [GPXRoot rootWithCreator:@"Cellreef"];
  
  for ( NSDictionary *location in locations ) {
    GPXWaypoint *wp = [root newWaypointWithLatitude:[[location objectForKey:kLatKey] floatValue] 
                                          longitude:[[location objectForKey:kLngKey] floatValue]]; 
    
    [wp setGeoidHeight:[[location objectForKey:kAltitudeKey] floatValue]]; 
    [wp setHorizontalDilution:[[location objectForKey:kHorizontalAccuracyKey] floatValue]]; 
    [wp setVerticalDilution:[[location objectForKey:kVerticalAccuracyKey] floatValue]]; 
    [wp setTime:[location objectForKey:kTimestampKey]]; 
  }
  
  NSData *requestData = [[root gpx] dataUsingEncoding:NSASCIIStringEncoding];
  
  NSDictionary *parameters = [[NSDictionary alloc] initWithObjectsAndKeys:requestData, @"payload", nil]; 
  
  CRHttpClient *client = [CRHttpClient sharedClient]; 
  client.parameterEncoding = CRGPXParameterEncoding; 
  
  [client postPath:@"/api/v1/locations"
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"responseObject: %@", responseObject); 
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"error: %@", error); 
           }]; 
}
@end
