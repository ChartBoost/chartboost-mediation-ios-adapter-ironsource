//
//  IronSourceAdapterRewardedAd.swift
//  HeliumAdapterIronSource
//
//  Created by Daniel Barros on 9/22/22.
//

import Foundation
import HeliumSdk

/// Helium IronSource adapter rewarded ad.
final class IronSourceAdapterRewardedAd: IronSourceAdapterAd, PartnerAd {
    
    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)
        
        // If ad already loaded succeed immediately
        guard !IronSource.hasISDemandOnlyRewardedVideo(request.partnerPlacement) else {
            log(.loadSucceeded)
            completion(.success([:]))
            return
        }
        
        // Start loading
        loadCompletion = completion
        IronSource.loadISDemandOnlyRewardedVideo(request.partnerPlacement)
    }
    
    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.showStarted)
        
        // If ad not loaded fail immediately
        guard IronSource.hasISDemandOnlyRewardedVideo(request.partnerPlacement) else {
            let error = error(.noAdReadyToShow)
            log(.showFailed(error))
            completion(.failure(error))
            return
        }
        
        // Show ad
        showCompletion = completion
        IronSource.showISDemandOnlyRewardedVideo(viewController, instanceId: request.partnerPlacement)
    }
}

// MARK: ISDemandOnlyRewardedVideoDelegate

extension IronSourceAdapterRewardedAd: CHBHIronSourceWrapperRewardedDelegate {
    
    func rewardedVideoDidLoad(_ instanceId: String) {
        // Report load success
        log(.loadSucceeded)
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
    
    func rewardedVideoDidFailToLoadWithError(_ partnerError: Error, instanceId: String) {
        // Report load failure
        let error = error(.loadFailure, error: partnerError)
        log(.loadFailed(error))
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }
    
    func rewardedVideoDidOpen(_ instanceId: String) {
        // Report show success
        log(.showSucceeded)
        showCompletion?(.success([:])) ?? log(.showResultIgnored)
        showCompletion = nil
    }
    
    func rewardedVideoDidFailToShowWithError(_ partnerError: Error, instanceId: String) {
        // Report show failure
        let error = error(.showFailure, error: partnerError)
        log(.showFailed(error))
        showCompletion?(.failure(error)) ?? log(.showResultIgnored)
        showCompletion = nil
    }
    
    func rewardedVideoDidClose(_ instanceId: String) {
        // Report dismiss
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, details: [:], error: nil) ?? log(.delegateUnavailable)
    }
    
    func rewardedVideoDidClick(_ instanceId: String) {
        // Report click
        log(.didClick(error: nil))
        delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }
    
    func rewardedVideoAdRewarded(_ instanceId: String) {
        // Report reward
        log(.didReward)
        delegate?.didReward(self, details: [:]) ?? log(.delegateUnavailable)
    }
}
