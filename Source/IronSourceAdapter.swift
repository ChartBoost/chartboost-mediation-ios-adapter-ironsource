//
//  IronSourceAdapter.swift
//  HeliumAdapterIronSource
//
//  Created by Daniel Barros on 9/22/22.
//

import Foundation
import HeliumSdk

/// An IronSource wrapper compatible with Swift.
typealias IronSource = CHBHIronSourceWrapper

/// The Helium IronSource adapter.
final class IronSourceAdapter: NSObject, PartnerAdapter {
    
    /// The version of the partner SDK.
    let partnerSDKVersion = IronSource.sdkVersion()
    
    /// The version of the adapter.
    /// The first digit is Helium SDK's major version. The last digit is the build version of the adapter. The intermediate digits correspond to the partner SDK version.
    let adapterVersion = "4.7.2.1.0"
    
    /// The partner's unique identifier.
    let partnerIdentifier = "ironsource"
    
    /// The human-friendly partner name.
    let partnerDisplayName = "IronSource"
    
    /// The last value set on `setGDPRApplies(_:)`.
    private var gdprApplies = false
    
    /// The last value set on `setGDPRConsentStatus(_:)`.
    private var gdprStatus: GDPRConsentStatus = .unknown
    
    /// Ad storage managed by Helium SDK.
    private let storage: PartnerAdapterStorage
    
    /// The designated initializer for the adapter.
    /// Helium SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Helium SDK to the adapter.
    /// It includes a list of created `PartnerAd` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage) {
        self.storage = storage
    }
    
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
        
        // IronSource provides one delegate for all ads of the same type.
        // IronSourceAdapter implements these delegate protocols and forwards calls to the corresponding partner ad instances.
        IronSource.setISDemandOnlyInterstitialDelegate(self)
        IronSource.setISDemandOnlyRewardedVideoDelegate(self)
        
        log(.setUpSucceded)
        completion(nil)
    }
    
    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]?) -> Void) {
        // IronSource does not currently provide any bidding token
        completion(nil)
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
    
    /// Indicates the CCPA status both as a boolean and as an IAB US privacy string.
    /// - parameter hasGivenConsent: A boolean indicating if the user has given consent.
    /// - parameter privacyString: An IAB-compliant string indicating the CCPA status.
    func setCCPAConsent(hasGivenConsent: Bool, privacyString: String?) {
        // IronSource supports only a boolean value, privacyString is ignored
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
    
    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Helium SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Helium SDK takes care of storing and disposing of ad instances so you don't need to.
    /// `invalidate()` is called on ads before disposing of them in case partners need to perform any custom logic before the object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerAd {
        switch request.format {
        case .interstitial:
            return IronSourceAdapterInterstitialAd(adapter: self, request: request, delegate: delegate)
        case .rewarded:
            return IronSourceAdapterRewardedAd(adapter: self, request: request, delegate: delegate)
        case .banner:
            throw error(.adFormatNotSupported(request))
        }
    }
}

// MARK: ISDemandOnlyInterstitialDelegate

extension IronSourceAdapter: CHBHIronSourceWrapperInterstitialDelegate {
    
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

extension IronSourceAdapter: CHBHIronSourceWrapperRewardedDelegate {
    
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

private extension IronSourceAdapter {
    
    /// Fetches a stored ad adapter and logs an error if none is found.
    func ad(for partnerPlacement: String, functionName: StaticString = #function) -> PartnerAd? {
        guard let ad = storage.ads.first(where: { $0.request.partnerPlacement == partnerPlacement }) else {
            log("\(functionName) call ignored with instanceId \(partnerPlacement)")
            return nil
        }
        return ad
    }
    
    func interstitialAd(for partnerPlacement: String, functionName: StaticString = #function) -> IronSourceAdapterInterstitialAd? {
        ad(for: partnerPlacement, functionName: functionName) as? IronSourceAdapterInterstitialAd
    }
    
    func rewardedAd(for partnerPlacement: String, functionName: StaticString = #function) -> IronSourceAdapterRewardedAd? {
        ad(for: partnerPlacement, functionName: functionName) as? IronSourceAdapterRewardedAd
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
    /// IronSource affirmative consent metadata value
    static let yes = "YES"
    /// IronSource negative consent metadata value
    static let no = "NO"
}
