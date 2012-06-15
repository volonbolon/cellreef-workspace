//
//  CRHttpClient.m
//  CellreefFramework
//
//  Created by Ariel Rodriguez on 6/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CRHttpClient.h"
#import "AFJSONRequestOperation.h"

@implementation CRHttpClient
+ (CRHttpClient *)sharedClient {
  static CRHttpClient *_sharedClient = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedClient = [[CRHttpClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://127.0.0.1:5000"]];
  });
  
  return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
  self = [super initWithBaseURL:url]; 
  
  if ( self != nil ) {
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]]; 
    [self setDefaultHeader:@"Accept" value:@"application/json"];
  }
  
  return self; 
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method 
                                      path:(NSString *)path 
                                parameters:(NSDictionary *)parameters  {
  NSMutableURLRequest *request = nil; 
	if ( self.parameterEncoding == CRGPXParameterEncoding && parameters != nil ) {
    NSURL *url = [NSURL URLWithString:path relativeToURL:self.baseURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:method];
    NSDictionary *defaultHeaders = [[NSDictionary alloc] initWithObjectsAndKeys:@"application/json", @"Accept", nil]; 
    [request setAllHTTPHeaderFields:defaultHeaders];
    
    [request setURL:url]; 
    
    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));
    
    [request setValue:[NSString stringWithFormat:@"text/xml; charset=%@", charset] 
   forHTTPHeaderField:@"Content-Type"];
    
    [request setHTTPBody:[parameters objectForKey:@"payload"]]; 
    return request; 
  } else {
    request = [super requestWithMethod:method
                                  path:path
                            parameters:parameters]; 
  }
	return request;
}

@end
