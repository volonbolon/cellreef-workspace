//
//  CRHttpClient.h
//  CellreefFramework
//
//  Created by Ariel Rodriguez on 6/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AFHTTPClient.h"

typedef enum {
  CRFormURLParameterEncoding = AFFormURLParameterEncoding,
  CRJSONParameterEncoding = AFJSONParameterEncoding,
  CRPropertyListParameterEncoding = AFPropertyListParameterEncoding,
  CRGPXParameterEncoding = AFFormURLParameterEncoding + AFJSONParameterEncoding + AFPropertyListParameterEncoding,
} CRHttpClientParameterEncoding;

@interface CRHttpClient : AFHTTPClient
+ (CRHttpClient *)sharedClient;
@end
