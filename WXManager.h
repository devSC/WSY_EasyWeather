//
//  WXManager.h
//  SimpleWeather
//
//  Created by Ryan Nystrom on 11/11/13.
//  Copyright (c) 2013 Ryan Nystrom. All rights reserved.
//


/**
 *  是时候来完成WXManager这个类了，这是将一切融合的一个类。这个类将实现你的应用程序中的一些关键功能：
        它遵循单例设计模式singleton design pattern
        它视图找到设备的位置
        找到位置后，获取响应的气象数据
 */
@import Foundation;
@import CoreLocation;
#import <ReactiveCocoa/ReactiveCocoa.h>

//1.注意如果你没有导入WXDailyForecast.h，你将总是使用WXCondition作为预报类。WXDailyForecast.h只是帮助覆盖的JSON转换成Objective-c
#import "WXCondition.h"

@interface WXManager : NSObject<CLLocationManagerDelegate>

//2.利用instancetype替换WXManager，所以子类会返回适当的类型。
+ (instancetype)sharedManager;
//3.这些属性将储存你的数据，由于WXManager是一个单例，所以这些属性可以访问任何地方。设置公共属性为只读（readonly）是因为只有管理者才可以更改。
@property (nonatomic, strong, readonly) CLLocation *currentLocation;
@property (nonatomic, strong, readonly) WXCondition *currentCondition;//condition 条件 环境
@property (nonatomic, strong, readonly) NSArray *hourlyForecast;
@property (nonatomic, strong, readonly) NSArray *dailyForecast;

//4.这种方法启动或者刷新将获取到整个位置和天气的数据
- (void)findCurrentLocation;



@end