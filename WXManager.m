//
//  WXManager.m
//  SimpleWeather
//
//  Created by Ryan Nystrom on 11/11/13.
//  Copyright (c) 2013 Ryan Nystrom. All rights reserved.
//

#import "WXManager.h"
#import "WXClient.h"

#import <TSMessages/TSMessage.h>
@interface WXManager ()
// 1.声明你在公共接口中加入相同的属性，但是这一次把他们定义为读写（readwrite），因此您可以在后台更改值
@property (nonatomic, strong, readwrite) WXCondition *currentCondition;
@property (nonatomic, strong, readwrite) CLLocation *currentLocation;
@property (nonatomic, strong, readwrite) NSArray *hourlyForecast;
@property (nonatomic, strong, readwrite) NSArray *dailyForecast;
// 2.声明为定位的发现和数据抓取其他一些私人位置，添加@implementation和@end:之间的下列通用单例构造函数：
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isFirstUpdate;
@property (nonatomic, strong) WXClient *client;
@end

@implementation WXManager

+(instancetype)sharedManager
{
    static id _sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

//接下来，你需要设置你的 properties 和observables
- (id)init {
    if (self = [super init]) {
        
        // 1.创建一个位置管理器并且以self.来设置它的委托
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        [_locationManager setDesiredAccuracy: kCLLocationAccuracyBest];//设置精确度

        // 2.为管理者创建WXClient对象。这将处理所有的网络和数据请求，根据我们的最佳实践的这个主张。
        _client = [[WXClient alloc] init];
        
        // 3.类似KVO但是比KVO更加强大,不明白KVO你可以看这里Key-Value Observing
            //kvo: https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html
        [[[[RACObserve(self, currentLocation)
            
          //4.为了继续， currentLocation不能为零
          ignore:nil]
           
         //5. -flattenMap:非常类似于-map:： ，将值扁平化代替映射值，并返回包含所有三个信号中的一个对象。通过这种方式，你可以考虑所有三个进程作为单个工作单元。
           
         //Flatteb and subscribe to all 3 signals when currentLocation updates
         flattenMap:^(CLLocation *newLocation) {
             return [RACSignal merge:@[
                                       [self updateCurrentConditions],
                                       [self updateDaildyForecast],
                                       [self updateHourlyForecast]
                                       ]];
             
             //6将信号传递到主线程上的用户。
         }] deliverOn:[RACScheduler mainThreadScheduler]]
         
        //7. 这不是很好的做法，从你的模型中的UI交互，但出于演示的目的，每当发生错误时你会显示一个标语。
        subscribeError:^(NSError *error) {
            [TSMessage showNotificationWithTitle:@"Error" subtitle:@"There was a problem fetching the latest weather." type:TSMessageNotificationTypeError];
        }];
    }
    return self;
}

- (void)findCurrentLocation
{
    self.isFirstUpdate = YES;
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
//    [self.locationManager startUpdatingLocation];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:40.0876  longitude:116.4316];
    self.currentLocation = location;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{

}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //1..总是忽略第一个位置更新，因为它几乎总是缓存
    if (self.isFirstUpdate) {
        self.isFirstUpdate = NO;
        return;
    }
    
    CLLocation *location = [locations lastObject];
    
    //2.一旦你有适当的精度的位置，停止更新
    if (location.horizontalAccuracy > 0) {
        
        //3.设置currentLocation键将触发你在init执行前设置的RACObservable
        self.currentLocation = location;
        [self.locationManager stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{

}
//Retrieve the Weather Data
/*retrieve 检索*/
//最后,现在是时候添加三个取其中调用客户端上的方法的方法和保存价值的manager。所有这三种方法都捆绑起来，由RACObservable订阅创建的init方法之前添加。您将返回客户端返回相同的信号，这也可以订阅。
- (RACSignal *)updateCurrentConditions
{
    /*coordinte 坐标*/
    return [[self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate] doNext:^(WXCondition *condition) {
        self.currentCondition = condition;
    }];
}

- (RACSignal *)updateHourlyForecast
{
    return [[self.client fetchHourlyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.dailyForecast = conditions;
    }];
}

- (RACSignal *)updateDaildyForecast
{
    return [[self.client fetchDailyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.dailyForecast = conditions;
    }];
}



@end
