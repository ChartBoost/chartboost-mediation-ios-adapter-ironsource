//
//  IronSourceAdapter.swift
//  HeliumAdapterIronSource
//
//  Created by Daniel Barros on 9/22/22.
//

import Foundation
import HeliumSdk

/// An IronSource wrapper compatible with Swift.
private typealias IronSource = CHBHIronSourceWrapper

/// The Helium IronSource adapter.
final class IronSourceAdapter: NSObject, PartnerAdapter {
    
    /// The version of the partner SDK, e.g. "5.13.2"
    let partnerSDKVersion = IronSource.sdkVersion()
    
    /// The version of the adapter, e.g. "2.5.13.2.0"
    /// The first number is Helium SDK's major version. The next 3 numbers are the partner SDK version. The last number is the build version of the adapter.
    let adapterVersion = "4.7.2.1.0"
    
    /// The partner's identifier.
    let partnerIdentifier = "ironsource"
    
    /// The partner's name in a human-friendly version.
    let partnerDisplayName = "IronSource"
    
    /// The last value set on `setGDPRApplies(_:)`.
    private var gdprApplies = false
    
    /// The last value set on `setGDPRConsentStatus(_:)`.
    private var gdprStatus: GDPRConsentStatus = .unknown
    
    private var adAdapters: [String: IronSourceAdAdapter] = [:]
    
    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {
        log(.setUpStarted)
        // Get credentials, fail early if they are unavailable
        guard let appKey = configuration.appKey else {
            let error = error(.missingSetUpParameter(key: .appKeyKey))
            log(.setUpFailed(error))
            completion(error)
            return
        }
        // Initialize IronSource
        IronSource.initISDemandOnly(appKey, adUnits: configuration.lineItems ?? [])
        IronSource.setISDemandOnlyInterstitialDelegate(self)
        IronSource.setISDemandOnlyRewardedVideoDelegate(self)
        
        log(.setUpSucceded)
        completion(nil)
    }
    
    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]) -> Void) {
        // IronSource does not currently provide any bidding token
        log(.fetchBidderInfoStarted(request))
        log(.fetchBidderInfoSucceeded(request))
        completion([:])
    }
    
    /// Indicates if GDPR applies or not.
    /// - parameter applies: `true` if GDPR applies, `false` otherwise.
    func setGDPRApplies(_ applies: Bool) {
        // Save value and set GDPR on IronSource using both gdprApplies and gdprStatus
        gdprApplies = applies
        updateGDPRConsent()
    }
    
    /// Indicates the user's GDPR consent status.
    /// - parameter status: One of the `GDPRConsentStatus` values depending on the user's preference.
    func setGDPRConsentStatus(_ status: GDPRConsentStatus) {
        // Save value and set GDPR on IronSource using both gdprApplies and gdprStatus
        gdprStatus = status
        updateGDPRConsent()
    }
    
    private func updateGDPRConsent() {
        // Set IronSource GDPR consent using both gdprApplies and gdprStatus
        if gdprApplies {
            let value = gdprStatus == .granted
            IronSource.setConsent(value)
            log(.privacyUpdated(setting: "consent", value: value))
        }
    }
    
    /// Indicates the CCPA status both as a boolean and as a IAB US privacy string.
    /// - parameter hasGivenConsent: A boolean indicating if the user has given consent.
    /// - parameter privacyString: A IAB-compliant string indicating the CCPA status.
    func setCCPAConsent(hasGivenConsent: Bool, privacyString: String?) {
        let key: String = .ccpaKey
        let value: String = hasGivenConsent ? .yes : .no
        IronSource.setMetaDataWithKey(key, value: value)
        log(.privacyUpdated(setting: "metaDataWithKey", value: [key: value]))
    }
    
    /// Indicates if the user is subject to COPPA or not.
    /// - parameter isSubject: `true` if the user is subject, `false` otherwise.
    func setUserSubjectToCOPPA(_ isSubject: Bool) {
        let key: String = .coppaKey
        let value: String = isSubject ? .yes : .no
        IronSource.setMetaDataWithKey(key, value: value)
        log(.privacyUpdated(setting: "metaDataWithKey", value: [key: value]))
    }
    
    /// Loads an ad.
    /// - note: Helium SDK will keep the `PartnerAd` returned in the completion, so keeping a strong reference to the loaded ad in the adapter might not be necessary.
    /// - parameter request: Information about the ad load request.
    /// - parameter partnerAdDelegate: The delegate that will receive ad life-cycle notifications.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(request: PartnerAdLoadRequest, partnerAdDelegate: PartnerAdDelegate, viewController: UIViewController?, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        log(.loadStarted(request))
        
        // Create ad adapter and save it
        adAdapters[request.partnerPlacement] = IronSourceAdAdapter(
            request: request,
            delegate: partnerAdDelegate,
            loadCompletion: completion
        )
        
        switch request.format {
        case .interstitial:
            // If ad already loaded succeed immediately
            guard !IronSource.hasISDemandOnlyInterstitial(request.partnerPlacement) else {
                let ad = PartnerAd(ad: nil, details: [:], request: request)
                log(.loadSucceeded(ad))
                completion(.success(ad))
                return
            }
            // Start loading
            IronSource.loadISDemandOnlyInterstitial(request.partnerPlacement)
            
        case .rewarded:
            // If ad already loaded succeed immediately
            guard !IronSource.hasISDemandOnlyRewardedVideo(request.partnerPlacement) else {
                let ad = PartnerAd(ad: nil, details: [:], request: request)
                log(.loadSucceeded(ad))
                completion(.success(ad))
                return
            }
            // Start loading
            IronSource.loadISDemandOnlyRewardedVideo(request.partnerPlacement)
            
        case .banner:
            // Remove previously created ad adapter
            adAdapters[request.partnerPlacement] = nil
            // Fail immediately
            let error = error(.loadFailure(request), description: "Ad format not supported")
            log(.loadFailed(request, error: error))
            completion(.failure(error))
        }
    }
        
    /// Shows a loaded ad.
    /// It will not get called for banner ads.
    /// - note: Helium SDK will keep the `PartnerAd` alive until it is dismissed, so keeping a strong reference to the ad in the adapter might not be necessary.
    /// - parameter partnerAd: The ad to show.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(_ partnerAd: PartnerAd, viewController: UIViewController, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        log(.showStarted(partnerAd))
        
        // Fail if no ad adapter available
        guard let adAdapter = adAdapters[partnerAd.request.partnerPlacement] else {
            let error = error(.noAdReadyToShow(partnerAd))
            log(.showFailed(partnerAd, error: error))
            completion(.failure(error))
            return
        }
        // Keep show completion to execute it later
        adAdapter.showCompletion = completion
        
        switch partnerAd.request.format {
        case .interstitial:
            // If ad not loaded fail immediately
            guard IronSource.hasISDemandOnlyInterstitial(partnerAd.request.partnerPlacement) else {
                let error = error(.noAdReadyToShow(partnerAd), description: "IronSource hasISDemandOnlyInterstitial is false")
                log(.showFailed(partnerAd, error: error))
                completion(.failure(error))
                return
            }
            // Show ad
            IronSource.showISDemandOnlyInterstitial(viewController, instanceId: partnerAd.request.partnerPlacement)
            
        case .rewarded:
            // If ad not loaded fail immediately
            guard IronSource.hasISDemandOnlyRewardedVideo(partnerAd.request.partnerPlacement) else {
                let error = error(.noAdReadyToShow(partnerAd), description: "IronSource hasISDemandOnlyRewardedVideo is false")
                log(.showFailed(partnerAd, error: error))
                completion(.failure(error))
                return
            }
            // Show ad
            IronSource.showISDemandOnlyRewardedVideo(viewController, instanceId: partnerAd.request.partnerPlacement)
            
        case .banner:
            // Fail immediately
            let error = error(.showFailure(partnerAd), description: "Ad format not supported")
            log(.showFailed(partnerAd, error: error))
            completion(.failure(error))
        }
    }
    
    /// Invalidates a loaded ad, freeing up its memory and resetting the adapter to state where it can load a new ad.
    /// - note: Helium SDK will call this method to inform that it won't be showning this ad and thus it should be discarded.
    /// It will also be called on `PartnerAdDelegate.didDismiss(partnerAd:error:)`.
    /// - parameter partnerAd: The ad to invalidate.
    /// - parameter completion: Closure to be performed once the ad has been invalidated.
    func invalidate(_ partnerAd: PartnerAd, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        log(.invalidateStarted(partnerAd))
        if adAdapters[partnerAd.request.partnerPlacement] == nil {
            // Fail if no ad to invalidate
            let error = error(.noAdToInvalidate(partnerAd))
            log(.invalidateFailed(partnerAd, error: error))
            completion(.failure(error))
        } else {
            // Succeed if we had an ad
            adAdapters[partnerAd.request.partnerPlacement] = nil
            log(.invalidateSucceeded(partnerAd))
            completion(.success(partnerAd))
        }
    }
}

/// Holds all the info relative to an ad.
class IronSourceAdAdapter {
    
    /// The load request that originated this ad.
    let request: PartnerAdLoadRequest
    
    /// The partner ad delegate to send ad life-cycle events to.
    private(set) weak var delegate: PartnerAdDelegate?
    
    /// The completion for the ongoing load operation.
    var loadCompletion: ((Result<PartnerAd, Error>) -> Void)?
    
    /// The completion for the ongoing show operation.
    var showCompletion: ((Result<PartnerAd, Error>) -> Void)?
    
    /// The partner ad model passed in PartnerAdDelegate callbacks.
    lazy var partnerAd = PartnerAd(ad: nil, details: [:], request: request)
    
    init(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate, loadCompletion: @escaping (Result<PartnerAd, Error>) -> Void) {
        self.request = request
        self.delegate = delegate
        self.loadCompletion = loadCompletion
    }
}

// IronSource delegate protocols conformance
extension IronSourceAdapter: CHBHIronSourceWrapperDelegate {
    
    // MARK: ISDemandOnlyInterstitialDelegate
    
    func interstitialDidLoad(_ instanceId: String) {
        guard let adapter = adAdapter(for: instanceId) else { return }
        
        // Report load success
        log(.loadSucceeded(adapter.partnerAd))
        adapter.loadCompletion?(.success(adapter.partnerAd)) ?? log(.loadResultIgnored)
        adapter.loadCompletion = nil
    }
    
    func interstitialDidFailToLoadWithError(_ partnerError: Error, instanceId: String) {
        guard let adapter = adAdapter(for: instanceId) else { return }
        
        // Report load failure
        adAdapters[instanceId] = nil
        let error = error(.loadFailure(adapter.request), error: partnerError)
        log(.loadFailed(adapter.request, error: error))
        adapter.showCompletion?(.failure(error)) ?? log(.showResultIgnored)
        adapter.showCompletion = nil
    }
    
    func interstitialDidOpen(_ instanceId: String) {
        guard let adapter = adAdapter(for: instanceId) else { return }
        
        // Report show success
        log(.showSucceeded(adapter.partnerAd))
        adapter.showCompletion?(.success(adapter.partnerAd)) ?? log(.showResultIgnored)
        adapter.showCompletion = nil
    }
    
    func interstitialDidFailToShowWithError(_ partnerError: Error, instanceId: String) {
        guard let adapter = adAdapter(for: instanceId) else { return }
        
        // Report show failure
        let error = error(.showFailure(adapter.partnerAd), error: partnerError)
        log(.showFailed(adapter.partnerAd, error: error))
        adapter.showCompletion?(.failure(error)) ?? log(.showResultIgnored)
        adapter.showCompletion = nil
    }
    
    func interstitialDidClose(_ instanceId: String) {
        guard let adapter = adAdapter(for: instanceId) else { return }
        
        // Report dismiss
        log(.didDismiss(adapter.partnerAd, error: nil))
        adapter.delegate?.didDismiss(adapter.partnerAd, error: nil) ?? log(.delegateUnavailable)
    }
    
    func didClickInterstitial(_ instanceId: String) {
        guard let adapter = adAdapter(for: instanceId) else { return }
        
        // Report click
        log(.didClick(adapter.partnerAd, error: nil))
        adapter.delegate?.didClick(adapter.partnerAd) ?? log(.delegateUnavailable)
    }
    
    // MARK: ISDemandOnlyRewardedVideoDelegate
    
    func rewardedVideoDidLoad(_ instanceId: String) {
        guard let adapter = adAdapter(for: instanceId) else { return }
        
        // Report load success
        log(.loadSucceeded(adapter.partnerAd))
        adapter.loadCompletion?(.success(adapter.partnerAd)) ?? log(.loadResultIgnored)
        adapter.loadCompletion = nil
    }
    
    func rewardedVideoDidFailToLoadWithError(_ partnerError: Error, instanceId: String) {
        guard let adapter = adAdapter(for: instanceId) else { return }
        
        // Report load failure
        adAdapters[instanceId] = nil
        let error = error(.loadFailure(adapter.request), error: partnerError)
        log(.loadFailed(adapter.request, error: error))
        adapter.showCompletion?(.failure(error)) ?? log(.showResultIgnored)
        adapter.showCompletion = nil
    }
    
    func rewardedVideoDidOpen(_ instanceId: String) {
        guard let adapter = adAdapter(for: instanceId) else { return }
        
        // Report show success
        log(.showSucceeded(adapter.partnerAd))
        adapter.showCompletion?(.success(adapter.partnerAd)) ?? log(.showResultIgnored)
        adapter.showCompletion = nil
    }
    
    func rewardedVideoDidFailToShowWithError(_ partnerError: Error, instanceId: String) {
        guard let adapter = adAdapter(for: instanceId) else { return }
        
        // Report show failure
        let error = error(.showFailure(adapter.partnerAd), error: partnerError)
        log(.showFailed(adapter.partnerAd, error: error))
        adapter.showCompletion?(.failure(error)) ?? log(.showResultIgnored)
        adapter.showCompletion = nil
    }
    
    func rewardedVideoDidClose(_ instanceId: String) {
        guard let adapter = adAdapter(for: instanceId) else { return }
        
        // Report dismiss
        log(.didDismiss(adapter.partnerAd, error: nil))
        adapter.delegate?.didDismiss(adapter.partnerAd, error: nil) ?? log(.delegateUnavailable)
    }
    
    func rewardedVideoDidClick(_ instanceId: String) {
        guard let adapter = adAdapter(for: instanceId) else { return }
        
        // Report click
        log(.didClick(adapter.partnerAd, error: nil))
        adapter.delegate?.didClick(adapter.partnerAd) ?? log(.delegateUnavailable)
    }
    
    func rewardedVideoAdRewarded(_ instanceId: String) {
        guard let adapter = adAdapter(for: instanceId) else { return }
        
        // Report reward
        let reward = Reward(amount: nil, label: nil)
        log(.didReward(adapter.partnerAd, reward: reward))
        adapter.delegate?.didReward(adapter.partnerAd, reward: reward) ?? log(.delegateUnavailable)
    }
    
    /// Fetches a stored ad adapter and logs an error if none is found.
    private func adAdapter(for partnerPlacement: String, functionName: StaticString = #function) -> IronSourceAdAdapter? {
        if adAdapters[partnerPlacement] == nil {
            log("\(functionName) call ignored with instanceId \(partnerPlacement)")
        }
        return adAdapters[partnerPlacement]
    }
}

/// Convenience extension to access IronSource credentials from the configuration.
private extension PartnerConfiguration {
    var appKey: String? { credentials[.appKeyKey] as? String }
    var lineItems: [String]? { credentials[.lineItemsKey] as? [String] }
}

private extension String {
    /// IronSource app key credentials key
    static let appKeyKey = "app_key"
    /// IronSource line items credentials key
    static let lineItemsKey = "line_items"
    /// IronSource CCPA metadata key
    static let ccpaKey = "do_not_sell"
    /// IronSource COPPA metadata key
    static let coppaKey = "is_child_directed"
    static let yes = "YES"
    static let no = "NO"
}
