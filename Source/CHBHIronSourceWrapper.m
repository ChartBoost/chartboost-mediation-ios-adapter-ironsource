// Copyright 2022-2023 Chartboost, Inc.
// 
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

//
//  CHBHIronSourceWrapper.m
//  HeliumAdapterIronSource
//
//  Created by Daniel Barros on 9/30/22.
//

#import "CHBHIronSourceWrapper.h"
#import "IronSource.h"

@implementation CHBHIronSourceWrapper

+ (NSString *)sdkVersion {
    return [IronSource sdkVersion];
}

+ (void)setMetaDataWithKey:(NSString *)key value:(NSString *)value {
    [IronSource setMetaDataWithKey:key value:value];
}

+ (void)setConsent:(BOOL)consent {
    [IronSource setConsent:consent];
}

+ (void)initISDemandOnly:(NSString *)appKey adUnits:(NSArray<NSString *> *)adUnits {
    [IronSource initISDemandOnly:appKey adUnits:adUnits];
}

+ (void)setISDemandOnlyInterstitialDelegate:(id<CHBHIronSourceWrapperInterstitialDelegate>)delegate {
    [IronSource setISDemandOnlyInterstitialDelegate:(id<ISDemandOnlyInterstitialDelegate>)delegate];
}

+ (void)setISDemandOnlyRewardedVideoDelegate:(id<CHBHIronSourceWrapperRewardedDelegate>)delegate {
    [IronSource setISDemandOnlyRewardedVideoDelegate:(id<ISDemandOnlyRewardedVideoDelegate>)delegate];
}

+ (void)loadISDemandOnlyInterstitial:(NSString *)instanceId {
    [IronSource loadISDemandOnlyInterstitial:instanceId];
}

+ (BOOL)hasISDemandOnlyInterstitial:(NSString *)instanceId {
    return [IronSource hasISDemandOnlyInterstitial:instanceId];
}

+ (void)showISDemandOnlyInterstitial:(UIViewController *)viewController instanceId:(NSString *)instanceId {
    [IronSource showISDemandOnlyInterstitial:viewController instanceId:instanceId];
}

+ (void)loadISDemandOnlyRewardedVideo:(NSString *)instanceId {
    [IronSource loadISDemandOnlyRewardedVideo:instanceId];
}

+ (void)showISDemandOnlyRewardedVideo:(UIViewController *)viewController instanceId:(NSString *)instanceId {
    [IronSource showISDemandOnlyRewardedVideo:viewController instanceId:instanceId];
}

+ (BOOL)hasISDemandOnlyRewardedVideo:(NSString *)instanceId {
    return [IronSource hasISDemandOnlyRewardedVideo:instanceId];
}

@end
