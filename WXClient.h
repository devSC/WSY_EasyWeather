//
//  WXClient.h
//  SimpleWeather
//
//  Created by Ryan Nystrom on 11/11/13.
//  Copyright (c) 2013 Ryan Nystrom. All rights reserved.
//

@import Foundation;

@import CoreLocation;
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface WXClient : NSObject

- (RACSignal *)fetchJSONFormURL:(NSURL *)url;

- (RACSignal *)fetchCurrentConditionsForLocation:(CLLocationCoordinate2D)coordinate;

- (RACSignal *)fetchHourlyForecastForLocation:(CLLocationCoordinate2D)coordinate;

- (RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D)coordinate;



@end
