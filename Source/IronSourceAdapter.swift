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
final class IronSourceAdapter: PartnerAdapter {
    
    /// The version of the partner SDK.
    let partnerSDKVersion = IronSource.sdkVersion()
    
    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Helium SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Helium major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    let adapterVersion = "4.7.2.1.0.0"
    
    /// The partner's unique identifier.
    let partnerIdentifier = "ironsource"
    
    /// The human-friendly partner name.
    let partnerDisplayName = "IronSource"
    
    /// Ad storage managed by Helium SDK.
    let storage: PartnerAdapterStorage
    
    /// A router that forwards IronSource delegate calls to the corresponding `PartnerAd` instances.
    private var router: IronSourceAdapterRouter?
    
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
            let error = error(.initializationFailureInvalidCredentials, description: "Missing \(String.appKeyKey)")
            log(.setUpFailed(error))
            completion(error)
            return
        }
        // Initialize IronSource
        IronSource.initISDemandOnly(appKey, adUnits: configuration.lineItems ?? [])
        
        // IronSource provides one single delegate for all ads of the same type.
        // IronSourceAdapterRouter implements these delegate protocols and forwards calls to the corresponding partner ad instances.
        let router = IronSourceAdapterRouter(adapter: self)
        self.router = router    // keep the router instance alive
        IronSource.setISDemandOnlyInterstitialDelegate(router)
        IronSource.setISDemandOnlyRewardedVideoDelegate(router)
        
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
    
    /// Indicates if GDPR applies or not and the user's GDPR consent status.
    /// - parameter applies: `true` if GDPR applies, `false` if not, `nil` if the publisher has not provided this information.
    /// - parameter status: One of the `GDPRConsentStatus` values depending on the user's preference.
    func setGDPR(applies: Bool?, status: GDPRConsentStatus) {
        if applies == true {
            let value = status == .granted
            IronSource.setConsent(value)
            log(.privacyUpdated(setting: "consent", value: value))
        }
    }
    
    /// Indicates the CCPA status both as a boolean and as an IAB US privacy string.
    /// - parameter hasGivenConsent: A boolean indicating if the user has given consent.
    /// - parameter privacyString: An IAB-compliant string indicating the CCPA status.
    func setCCPA(hasGivenConsent: Bool, privacyString: String) {
        // IronSource supports only a boolean value, privacyString is ignored
        let key: String = .ccpaKey
        let value: String = hasGivenConsent ? .yes : .no
        IronSource.setMetaDataWithKey(key, value: value)
        log(.privacyUpdated(setting: "metaDataWithKey", value: [key: value]))
    }
    
    /// Indicates if the user is subject to COPPA or not.
    /// - parameter isChildDirected: `true` if the user is subject to COPPA, `false` otherwise.
    func setCOPPA(isChildDirected: Bool) {
        let key: String = .coppaKey
        let value: String = isChildDirected ? .yes : .no
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
            throw error(.loadFailureUnsupportedAdFormat)
        @unknown default:
            throw error(.loadFailureUnsupportedAdFormat)
        }
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
