//
//  CHBHIronSourceWrapper.h
//  HeliumAdapterIronSource
//
//  Created by Daniel Barros on 9/30/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol CHBHIronSourceWrapperDelegate;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - CHBHIronSourceWrapper

/**
 @abstract A wrapper that allows Helium IronSource adapters written in Swift to communicate with the IronSource SDK.
 @discussion IronSource SDK is not packaged as a module, which means it cannot be used directly within Swift code.
 Not being a module means IronSource headers cannot be exposed to Swift by importing them in the umbrella header of the adapters framework. Thus the existing solution, which consists in not trying to expose IronSource SDK to Swift, and
 instead use an Obj-C layer to communicate with it.
 
 All method signatures and comments included in in this header were obtained directly from IronSource's own headers.
 */
@interface CHBHIronSourceWrapper : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 @abstact Retrieve a string-based representation of the SDK version.
 @discussion The returned value will be in the form of "<Major>.<Minor>.<Revision>".

 @return NSString representing the current IronSource SDK version.
 */
+ (NSString *)sdkVersion;

/**
@abstact Sets the meta data with a key and value.
@discussion This value will be passed to the supporting ad networks.

@param key The meta data key.
@param value The meta data value

*/
+ (void)setMetaDataWithKey:(NSString *)key value:(NSString *)value;

+ (void)setConsent:(BOOL)consent;

/**
 @abstract Initializes ironSource SDK in demand only mode.
 @discussion This method initializes IS_REWARDED_VIDEO and/or IS_INTERSTITIAL ad units.
 @param appKey Application key.
 @param adUnits An array containing IS_REWARDED_VIDEO and/or IS_INTERSTITIAL.
 */
+ (void)initISDemandOnly:(NSString *)appKey adUnits:(NSArray<NSString *> *)adUnits;

// WARNING: THIS METHOD TAKES IN A `CHBHIronSourceWrapperDelegate` WITH THE ASSUMPTION THAT IT CAN BE CASTED AS A `ISDemandOnlyInterstitialDelegate`
/**
 @abstract Sets the delegate for demand only interstitial callbacks.
 @param delegate The 'ISDemandOnlyInterstitialDelegate' for IronSource to send callbacks to.
 */
+ (void)setISDemandOnlyInterstitialDelegate:(id<CHBHIronSourceWrapperDelegate>)delegate;

// WARNING: THIS METHOD TAKES IN A `CHBHIronSourceWrapperDelegate` WITH THE ASSUMPTION THAT IT CAN BE CASTED AS A `ISDemandOnlyRewardedVideoDelegate`
/**
 @abstract Sets the delegate for demand only rewarded video callbacks.
 @param delegate The 'ISDemandOnlyRewardedVideoDelegate' for IronSource to send callbacks to.
 */
+ (void)setISDemandOnlyRewardedVideoDelegate:(id<CHBHIronSourceWrapperDelegate>)delegate;

/**
 @abstract Loads a demand only interstitial.
 @discussion This method will load a demand only interstitial ad.
 @param instanceId The demand only instance id to be used to display the interstitial.
 */
+ (void)loadISDemandOnlyInterstitial:(NSString *)instanceId;

/**
 @abstract Determine if a locally cached interstitial exists for a demand only instance id.
 @discussion A return value of YES here indicates that there is a cached interstitial for the instance id.
 @param instanceId The demand only instance id to be used to display the interstitial.
 @return YES if there is a locally cached interstitial, NO otherwise.
 */
+ (BOOL)hasISDemandOnlyInterstitial:(NSString *)instanceId;

/**
 @abstract Show a demand only interstitial using the default placement.
 @param viewController The UIViewController to display the interstitial within.
 @param instanceId The demand only instance id to be used to display the interstitial.
 */
+ (void)showISDemandOnlyInterstitial:(UIViewController *)viewController instanceId:(NSString *)instanceId;

/**
 @abstract Loads a demand only rewarded video for a non bidder instance.
 @discussion This method will load a demand only rewarded video ad for a non bidder instance.
 @param instanceId The demand only instance id to be used to display the rewarded video.
 */
+ (void)loadISDemandOnlyRewardedVideo:(NSString *)instanceId;

/**
 @abstract Shows a demand only rewarded video using the default placement.
 @param viewController The UIViewController to display the rewarded video within.
 @param instanceId The demand only instance id to be used to display the rewarded video.
 */
+ (void)showISDemandOnlyRewardedVideo:(UIViewController *)viewController instanceId:(NSString *)instanceId;

/**
 @abstract Determine if a locally cached demand only rewarded video exists for an instance id.
 @discussion A return value of YES here indicates that there is a cached rewarded video for the instance id.
 @param instanceId The demand only instance id to be used to display the rewarded video.
 @return YES if rewarded video is ready to be played, NO otherwise.
 */
+ (BOOL)hasISDemandOnlyRewardedVideo:(NSString *)instanceId;

@end

#pragma mark - CHBHIronSourceWrapperDelegate

/**
 @abstract A redefinition of IronSource SDK delegate protocols.
 @discussion This protocol should define the same methods found in `ISDemandOnlyInterstitialDelegate` and `ISDemandOnlyRewardedVideoDelegate`.
 */
@protocol CHBHIronSourceWrapperDelegate <NSObject>

#pragma mark ISDemandOnlyInterstitialDelegate

/**
 Called after an interstitial has been loaded
 */
- (void)interstitialDidLoad:(NSString *)instanceId;

/**
 Called after an interstitial has attempted to load but failed.

 @param error The reason for the error
 */
- (void)interstitialDidFailToLoadWithError:(NSError *)error instanceId:(NSString *)instanceId;

/**
 Called after an interstitial has been opened.
 */
- (void)interstitialDidOpen:(NSString *)instanceId;

/**
  Called after an interstitial has been dismissed.
 */
- (void)interstitialDidClose:(NSString *)instanceId;

/**
 Called after an interstitial has attempted to show but failed.

 @param error The reason for the error
 */
- (void)interstitialDidFailToShowWithError:(NSError *)error instanceId:(NSString *)instanceId;

/**
 Called after an interstitial has been clicked.
 */
- (void)didClickInterstitial:(NSString *)instanceId;

#pragma mark ISDemandOnlyRewardedVideoDelegate

- (void)rewardedVideoDidLoad:(NSString *)instanceId;

- (void)rewardedVideoDidFailToLoadWithError:(NSError *)error instanceId:(NSString *)instanceId;

- (void)rewardedVideoDidOpen:(NSString *)instanceId;

- (void)rewardedVideoDidClose:(NSString *)instanceId;

- (void)rewardedVideoDidFailToShowWithError:(NSError *)error instanceId:(NSString *)instanceId;

- (void)rewardedVideoDidClick:(NSString *)instanceId;

- (void)rewardedVideoAdRewarded:(NSString *)instanceId;

@end

NS_ASSUME_NONNULL_END
