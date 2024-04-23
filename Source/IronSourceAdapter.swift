// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import IronSource

/// The Chartboost Mediation IronSource adapter.
final class IronSourceAdapter: PartnerAdapter {
    
    /// The version of the partner SDK.
    let partnerSDKVersion = IronSource.sdkVersion()
    
    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    let adapterVersion = "4.7.9.1.0.0"
    
    /// The partner's unique identifier.
    let partnerID = "ironsource"
    
    /// The human-friendly partner name.
    let partnerDisplayName = "IronSource"
    
    /// Ad storage managed by Chartboost Mediation SDK.
    let storage: PartnerAdapterStorage
    
    /// A router that forwards IronSource delegate calls to the corresponding `PartnerAd` instances.
    private var router: IronSourceAdapterRouter?
    
    /// The designated initializer for the adapter.
    /// Chartboost Mediation SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Chartboost Mediation SDK to the adapter.
    /// It includes a list of created `PartnerAd` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage) {
        self.storage = storage
    }
    
    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        log(.setUpStarted)
        // Get credentials, fail early if they are unavailable
        guard let appKey = configuration.appKey else {
            let error = error(.initializationFailureInvalidCredentials, description: "Missing \(String.appKeyKey)")
            log(.setUpFailed(error))
            completion(.failure(error))
            return
        }

        // Initialize IronSource. Must be performed on the main queue.
        DispatchQueue.main.async {
            IronSource.initISDemandOnly(appKey, adUnits: configuration.lineItems ?? [])

            let router = IronSourceAdapterRouter(adapter: self)
            self.router = router    // keep the router instance alive

            // IronSource provides one single delegate for all ads of the same type.
            // IronSourceAdapterRouter implements these delegate protocols and forwards calls to the corresponding partner ad instances.
            IronSource.setISDemandOnlyInterstitialDelegate(router)
            IronSource.setISDemandOnlyRewardedVideoDelegate(router)

            self.log(.setUpSucceded)
            completion(.success([:]))
        }
    }
    
    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(request: PartnerAdPreBidRequest, completion: @escaping (Result<[String : String], Error>) -> Void) {
        // IronSource does not currently provide any bidding token
        log(.fetchBidderInfoNotSupported)
        completion(.success([:]))
    }
    
    /// Indicates that the user consent has changed.
    /// - parameter consents: The new consents value, including both modified and unmodified consents.
    /// - parameter modifiedKeys: A set containing all the keys that changed.
    func setConsents(_ consents: [ConsentKey: ConsentValue], modifiedKeys: Set<ConsentKey>) {
        // See https://developers.is.com/ironsource-mobile/ios/regulation-advanced-settings/#step-1
        if modifiedKeys.contains(partnerID) || modifiedKeys.contains(ConsentKeys.gdprConsentGiven) {
            let consent = consents[partnerID] ?? consents[ConsentKeys.gdprConsentGiven]
            switch consent {
            case ConsentValues.granted:
                IronSource.setConsent(true)
                log(.privacyUpdated(setting: "consent", value: true))
            case ConsentValues.denied:
                IronSource.setConsent(false)
                log(.privacyUpdated(setting: "consent", value: false))
            default:
                break   // do nothing
            }
        }

        // See https://developers.is.com/ironsource-mobile/ios/regulation-advanced-settings/#step-2
        // IronSource supports only a boolean value, privacyString is ignored
        // Note the value is flipped to account for the opposite meanings of "giving consent" and "do not sell"
        if modifiedKeys.contains(ConsentKeys.ccpaOptIn) {
            let hasGivenConsent = consents[ConsentKeys.ccpaOptIn] == ConsentValues.granted
            let key: String = .doNotSellKey
            let value: String = hasGivenConsent ? .no : .yes
            IronSource.setMetaDataWithKey(key, value: value)
            log(.privacyUpdated(setting: "metaDataWithKey", value: [key: value]))
        }
    }

    /// Indicates that the user is underage signal has changed.
    /// - parameter isUserUnderage: `true` if the user is underage as determined by the publisher, `false` otherwise.
    func setIsUserUnderage(_ isUserUnderage: Bool) {
        // See https://developers.is.com/ironsource-mobile/ios/regulation-advanced-settings/#step-3
        let key: String = .coppaKey
        let value: String = isUserUnderage ? .yes : .no
        IronSource.setMetaDataWithKey(key, value: value)
        log(.privacyUpdated(setting: "metaDataWithKey", value: [key: value]))
    }
    
    /// Creates a new banner ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeBannerAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerBannerAd {
        throw error(.loadFailureUnsupportedAdFormat)
    }

    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeFullscreenAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerFullscreenAd {
        // Prevent multiple loads for the same partner placement, since the partner SDK cannot handle them.
        guard !storage.ads.contains(where: { $0.request.partnerPlacement == request.partnerPlacement }) else {
            log("Failed to load ad for already loading placement \(request.partnerPlacement)")
            throw error(.loadFailureLoadInProgress)
        }

        switch request.format {
        case PartnerAdFormats.interstitial:
            return IronSourceAdapterInterstitialAd(adapter: self, request: request, delegate: delegate)
        case PartnerAdFormats.rewarded:
            return IronSourceAdapterRewardedAd(adapter: self, request: request, delegate: delegate)
        default:
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
    static let doNotSellKey = "do_not_sell"
    /// IronSource COPPA metadata key
    static let coppaKey = "is_child_directed"
    /// IronSource affirmative consent metadata value
    static let yes = "YES"
    /// IronSource negative consent metadata value
    static let no = "NO"
}
