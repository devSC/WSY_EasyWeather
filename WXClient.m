//
//  WXClient.m
//  SimpleWeather
//
//  Created by Ryan Nystrom on 11/11/13.
//  Copyright (c) 2013 Ryan Nystrom. All rights reserved.
//

#import "WXClient.h"
#import "WXCondition.h"
#import "WXDailyForecast.h"

@interface WXClient ()

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation WXClient

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

- (RACSignal *)fetchJSONFormURL:(NSURL *)url
{
//    NSLog(@"Fetching: %@", url.absoluteString);
    /**
     *  1: 返回信号.这个方法直到信号订阅才会执行. fetchJsonFromeUrl:利用其他方法
     *  创建对象和使用对象,这种行为称为factory pattern;
     */
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        //2.创建NSURLSessionDataTask（iOS7中新的东西）从URL中获取数据。你将随后添加解析数据。
        
        NSURLSessionDataTask *dataTask = [self.session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            if (!error) {
                NSError *jsonError = nil;
                
                id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
                //1.当JSON数据存在并没有错误,将JSON序列号作为一个数据或者字典发送给用户
                if (!jsonError) {
                    [subscriber sendNext:json];
                }else {
                //2.如果有错误就马上通知用户
                    [subscriber sendError:jsonError];
                }
            } else {
            //3.如果有错误就马上通知用户
                [subscriber sendError:error];
            }
            //4.无论请求成功与否都让用户知道请求已经完成。
            [subscriber sendCompleted];
            
        }];
        //3.一旦有人预定信号就启动网络请求
        [dataTask resume];
        
        //4.创建并返回RACDisposable对象来清理已经被销毁的信号
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
        
    }] doError:^(NSError *error) {
        //5.添加一个“副作用”，来添加错误日志。
        NSLog(@"error: %@", error);
    }];
    
}


- (RACSignal *)fetchCurrentConditionsForLocation:(CLLocationCoordinate2D)coordinate
{
    //1.利用CLLocationCoordinate2D对象规定URL为纬度和经度格式
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&units=imperial", coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    //2.用你刚才创建信号的方法。由于返回值是一个信号，所以你可以调用它的其他ReactiveCocoa 方法。NSDictionary中的一个实例—在这里，你将映射返回值到另一个不同的值中。
    return [[self fetchJSONFormURL:url] map:^(NSDictionary *json) {
        
        //3.使用MTLJSONAdapter来转换成JSON的WXCondition对象,使用你的WXCondition创建 MTLJSONSerializing协议
        return [MTLJSONAdapter modelOfClass:[WXCondition class] fromJSONDictionary:json error:nil];
    }];
    
}

- (RACSignal *)fetchHourlyForecastForLocation:(CLLocationCoordinate2D)coordinate
{
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast?lat=%f&lon=%f&units=imperial&cnt=12", coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    //1.使用-fetchJSONFromURL再次格式化为JSON格式作为映射。注意有多少代码来使用这个方法来保存
    return [[self fetchJSONFormURL:url] map:^(NSDictionary *json){
        //2.从JSON的”list”键来创建 RACSequence 。RACSequences让你通过执行ReactiveCocoa来操作列表。
        RACSequence *list = [json[@"list"] rac_sequence];
        //3.映射对象到新的列表,这里被称为-map,在这个列表中的每个对象,都将返回新的对象到新的列表.
        return [[list map:^(NSDictionary *item){
            //4.再次使用MTLJSONAdapterr将WXCondition对象转换成JSON
            return [MTLJSONAdapter modelOfClass:[WXCondition class] fromJSONDictionary:item error:nil];
        }]
                //5.使用RACSequence中的 -map: 返回另一个 RACSequence，利用这个方法可以简单的获取所谓NSArray.返回的数据
        array];
    }];
}

//到这里你是否感觉很熟悉？是啊， 这里的方法完全一样 -fetchHourlyForecastForLocation:除了它使用WXDailyForecast而不是WXCondition和获取daily预报。

- (RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D)coordinate
{
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast/daily?lat=%f&lon=%f&units=imperial&cnt=7",coordinate.latitude,coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    // use the generic fetch method and map results to convert into an array of mantle objects
    return [[self fetchJSONFormURL:url] map:^(NSDictionary *json){
    //从JSON列表中选择一个列创建Sequence
        RACSequence *list = [json[@"list"] rac_sequence];
        //use a function to map results from JSON to mantle objects
        return [list map:^(NSDictionary *item){
            return [MTLJSONAdapter modelOfClass:[WXDailyForecast class] fromJSONDictionary:item error:nil];
        }];
    }];
    
    
}
@end
