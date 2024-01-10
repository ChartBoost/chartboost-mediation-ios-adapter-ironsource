// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import IronSource

/// Routes IronSource singleton delegate calls to the corresponding `PartnerAd` instances.
class IronSourceAdapterRouter: NSObject {
    
    /// The IronSource partner adapter.
    let adapter: IronSourceAdapter

    init(adapter: IronSourceAdapter) {
        self.adapter = adapter
    }
}

// MARK: ISDemandOnlyInterstitialDelegate

extension IronSourceAdapterRouter: ISDemandOnlyInterstitialDelegate {
    
    func interstitialDidLoad(_ instanceId: String) {
        interstitialAd(for: instanceId)?.interstitialDidLoad(instanceId)
    }
    
    func interstitialDidFailToLoadWithError(_ error: Error, instanceId: String) {
        interstitialAd(for: instanceId)?.interstitialDidFailToLoadWithError(error, instanceId: instanceId)
    }
    
    func interstitialDidOpen(_ instanceId: String) {
        interstitialAd(for: instanceId)?.interstitialDidOpen(instanceId)
    }
    
    func interstitialDidFailToShowWithError(_ error: Error, instanceId: String) {
        interstitialAd(for: instanceId)?.interstitialDidFailToShowWithError(error, instanceId: instanceId)
    }
    
    func interstitialDidClose(_ instanceId: String) {
        interstitialAd(for: instanceId)?.interstitialDidClose(instanceId)
    }
    
    func didClickInterstitial(_ instanceId: String) {
        interstitialAd(for: instanceId)?.didClickInterstitial(instanceId)
    }
}

// MARK: ISDemandOnlyRewardedVideoDelegate

extension IronSourceAdapterRouter: ISDemandOnlyRewardedVideoDelegate {
    
    func rewardedVideoDidLoad(_ instanceId: String) {
        rewardedAd(for: instanceId)?.rewardedVideoDidLoad(instanceId)
    }
    
    func rewardedVideoDidFailToLoadWithError(_ error: Error, instanceId: String) {
        rewardedAd(for: instanceId)?.rewardedVideoDidFailToLoadWithError(error, instanceId: instanceId)
    }
    
    func rewardedVideoDidOpen(_ instanceId: String) {
        rewardedAd(for: instanceId)?.rewardedVideoDidOpen(instanceId)
    }
    
    func rewardedVideoDidFailToShowWithError(_ error: Error, instanceId: String) {
        rewardedAd(for: instanceId)?.rewardedVideoDidFailToShowWithError(error, instanceId: instanceId)
    }
    
    func rewardedVideoDidClose(_ instanceId: String) {
        rewardedAd(for: instanceId)?.rewardedVideoDidClose(instanceId)
    }
    
    func rewardedVideoDidClick(_ instanceId: String) {
        rewardedAd(for: instanceId)?.rewardedVideoDidClick(instanceId)
    }
    
    func rewardedVideoAdRewarded(_ instanceId: String) {
        rewardedAd(for: instanceId)?.rewardedVideoAdRewarded(instanceId)
    }
}

// MARK: - Delegate Helpers

private extension IronSourceAdapterRouter {
    
    func interstitialAd(for partnerPlacement: String, functionName: StaticString = #function) -> IronSourceAdapterInterstitialAd? {
        ad(for: partnerPlacement, functionName: functionName) as IronSourceAdapterInterstitialAd?
    }
    
    func rewardedAd(for partnerPlacement: String, functionName: StaticString = #function) -> IronSourceAdapterRewardedAd? {
        ad(for: partnerPlacement, functionName: functionName) as IronSourceAdapterRewardedAd?
    }
    
    /// Fetches a stored ad adapter and logs an error if none is found.
    func ad<T: PartnerAd>(for partnerPlacement: String, functionName: StaticString = #function) -> T? {
        guard let ad = adapter.storage.ads.first(where: { $0.request.partnerPlacement == partnerPlacement }) else {
            adapter.log("\(functionName) call ignored with instanceId \(partnerPlacement), no corresponding partner ad found.")
            return nil
        }
        guard let ad = ad as? T else {
            adapter.log("\(functionName) call ignored with instanceId \(partnerPlacement), ad found with unexpected type.")
            return nil
        }
        return ad
    }
}
