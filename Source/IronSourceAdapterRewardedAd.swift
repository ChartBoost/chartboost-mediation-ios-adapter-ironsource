// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import IronSource

/// Chartboost Mediation IronSource adapter rewarded ad.
final class IronSourceAdapterRewardedAd: IronSourceAdapterAd, PartnerFullscreenAd {
    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Error?) -> Void) {
        log(.loadStarted)

        // If ad already loaded succeed immediately
        guard !IronSource.hasISDemandOnlyRewardedVideo(request.partnerPlacement) else {
            log(.loadSucceeded)
            completion(nil)
            return
        }

        // Start loading
        loadCompletion = completion
        IronSource.loadISDemandOnlyRewardedVideo(request.partnerPlacement)
    }

    /// Shows a loaded ad.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Error?) -> Void) {
        log(.showStarted)

        // If ad not loaded fail immediately
        guard IronSource.hasISDemandOnlyRewardedVideo(request.partnerPlacement) else {
            let error = error(.showFailureAdNotReady)
            log(.showFailed(error))
            completion(error)
            return
        }

        // Show ad
        showCompletion = completion
        IronSource.showISDemandOnlyRewardedVideo(viewController, instanceId: request.partnerPlacement)
    }
}

// MARK: ISDemandOnlyRewardedVideoDelegate

extension IronSourceAdapterRewardedAd: ISDemandOnlyRewardedVideoDelegate {
    func rewardedVideoDidLoad(_ instanceId: String) {
        // Report load success
        log(.loadSucceeded)
        loadCompletion?(nil) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func rewardedVideoDidFailToLoadWithError(_ partnerError: Error, instanceId: String) {
        // Report load failure
        log(.loadFailed(partnerError))
        loadCompletion?(partnerError) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func rewardedVideoDidOpen(_ instanceId: String) {
        // Report show success
        log(.showSucceeded)
        showCompletion?(nil) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    func rewardedVideoDidFailToShowWithError(_ partnerError: Error, instanceId: String) {
        // Report show failure
        log(.showFailed(partnerError))
        showCompletion?(partnerError) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    func rewardedVideoDidClose(_ instanceId: String) {
        // Report dismiss
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, error: nil) ?? log(.delegateUnavailable)
    }

    func rewardedVideoDidClick(_ instanceId: String) {
        // Report click
        log(.didClick(error: nil))
        delegate?.didClick(self) ?? log(.delegateUnavailable)
    }

    func rewardedVideoAdRewarded(_ instanceId: String) {
        // Report reward
        log(.didReward)
        delegate?.didReward(self) ?? log(.delegateUnavailable)
    }
}
