// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import IronSource

/// Base class for Chartboost Mediation IronSource adapter ads.
class IronSourceAdapterAd: NSObject {
    
    /// The partner adapter that created this ad.
    let adapter: PartnerAdapter
    
    /// Extra ad information provided by the partner.
    var details: PartnerDetails = [:]

    /// The ad load request associated to the ad.
    /// It should be the one provided on `PartnerAdapter.makeAd(request:delegate:)`.
    let request: PartnerAdLoadRequest
    
    /// The partner ad delegate to send ad life-cycle events to.
    /// It should be the one provided on `PartnerAdapter.makeAd(request:delegate:)`.
    weak var delegate: PartnerAdDelegate?
    
    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView? { nil }

    /// The loaded partner ad banner size.
    /// Should be `nil` for full-screen ads.
    var bannerSize: PartnerBannerSize? { nil }

    /// The completion for the ongoing load operation.
    var loadCompletion: ((Result<PartnerDetails, Error>) -> Void)?
    
    /// The completion for the ongoing show operation.
    var showCompletion: ((Result<PartnerDetails, Error>) -> Void)?
    
    init(adapter: PartnerAdapter, request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) {
        self.adapter = adapter
        self.request = request
        self.delegate = delegate
    }
}
