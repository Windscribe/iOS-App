//
//  swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-18.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation

struct TextsAsset {
    static var slogan: String {
        return "Keep Your Secrets.".localize()
    }
    static var getStarted: String {
        return "Get Started".localize()
    }
    static var loading: String {
        return "Loading".localize()
    }
    static var login: String {
        return "Login".localize()
    }
    static var get10GbAMonth: String {
        return "Get 10GB/Mo".localize()
    }
    static var tenGbAMonth: String {
        return "10GB/Mo".localize()
    }
    static var continueWithoutAccount: String {
        return "Continue without account".localize()
    }
    static var ghostAccountInfoLabel: String {
        return "Limited to 2GB/Mo".localize()
    }
    static var `continue`: String {
        return "Continue".localize()
    }
    static var setupLater: String {
        return "Setup later".localize()
    }
    static var signUp: String {
        return "Sign up".localize()
    }
    static var signUpFree: String {
        return "Sign up free".localize()
    }
    static var createAccount: String {
        return "Create Account".localize()
    }
    static var accountSetupTitle: String {
        return "Account setup".localize()
    }
    static var accountSetupMessage: String {
        return "Safeguard your Pro account and access it from any device.".localize()
    }
    static var signUpInfo: String {
        return "Safeguard your account, access your settings from any device and get more data.".localize()
    }
    static var optional: String {
        return "Optional".localize()
    }
    static var getMoreData: String {
        return "Get More Data".localize()
    }
    static var username: String {
        return "Username".localize()
    }
    static var password: String {
        return "Password".localize()
    }
    static var addEmail: String {
        return "Add Email".localize()
    }
    static var addEmailInfo: String {
        return "For password recovery, updates & promo only. No spam".localize()
    }
    static var setupAccount: String {
        return "Setup Account".localize()
    }
    static var email: String {
        return "Email".localize()
    }
    static var yourEmail: String {
        return "Your email".localize()
    }
    static var emailInfoLabel: String {
        return "For password recovery, updates & promo only. No spam".localize()
    }
    static var enterYourEmail: String {
        return "Enter your email".localize()
    }
    static var verifyYourPassword: String {
        return "Verify your password".localize()
    }
    static var forgotPassword: String {
        return "Forgot password?".localize()
    }
    static var chooseUsername: String {
        return "Choose Username".localize()
    }
    static var choosePassword: String {
        return "Choose Password".localize()
    }
    static var confirmPassword: String {
        return "Confirm password".localize()
    }
    static var referredBySomeone: String {
        return "Referred by someone?".localize()
    }
    static var mustConfirmEmail: String {
        return "You must confirm your email in order for the benefits above to apply to you and the referrer.".localize()
    }
    static var yes: String {
        return "Yes".localize()
    }
    static var no: String {
        return "No".localize()
    }
    static var okay: String {
        return "Okay".localize()
    }
    static var error: String {
        return "Error".localize()
    }
    static var twoFactorCode: String {
        return "2FA Code".localize()
    }
    static var loginFailed: String {
        return "The username and password combination is wrong.".localize()
    }
    static var pleaseDisconnectFirst: String {
        return "You can't make changes while connected to a VPN.".localize()
    }
    static var youWillBothGetTenGb: String {
        return "You will both get an additional 1GB per month when you sign up.".localize()
    }
    static var ifYouGoPro: String {
        return "If you go Pro, they’ll go Pro too!".localize()
    }
    static var signInProgress: [String] {
        return ["Getting Server List".localize(),
                "Getting IKEv2 Server Credentials".localize(),
                "Getting OpenVPN Server Credentials".localize(),
                "Getting Static IPs".localize(),
                "Getting Port Maps".localize(),
                "Getting Mobile Plans".localize(),
                "Getting Configurations".localize(),
                "Getting Notifications".localize(),
                "Preparing Your Dashboard".localize()
        ]
    }

    static var passwordsDontMatch: String {
        return "The passwords don't match.".localize()
    }
    static var cannotRegister: String {
        return "Registration failed, please contact support.".localize()
    }
    static var pleaseContactSupport: String {
        return "Please contact support.".localize()
    }
    static var usernameIsTaken: String {
        return "Awww! This username is taken.".localize()
    }
    static var emailIsTaken: String {
        return "Awww! This email already exists.".localize()
    }
    static var disposableEmail: String {
        return "Disposable emails are not allowed. Provide a valid email, or leave the email field blank.".localize()
    }
    static var cannotChangeExistingEmail: String {
        return "Cannot change existing email because it is already confirmed.".localize()
    }
    static var usernameValidationError: String {
        return "Must only contain letters, numbers and underscores.".localize()
    }
    static var passwordValidationError: String {
        return "Must be longer than 7 characters.".localize()
    }
    static var emailValidationError: String {
        return "Enter a valid email.".localize()
    }
    static var ghostModeError: String {
        return "Unfortunately you cannot use Windscribe without an account as we detected potential abuse. Please make one, it's really easy.".localize()
    }
    static var pleaseEnterEmailFirst: String {
        return "Please provide an email first".localize()
    }
    static var referringUsername: String {
        return "Referring Username".localize()
    }
    struct SignInError {
        static var usernameExpectedEmailProvided: String {
            return "Please login with your username, not your email".localize()
        }
    }
    struct Permission {
        static var locationDescription: String {
            return "Location permission is denied . Settings > Privacy > Location services > Windscribe > check while in use and presise location.".localize()
        }
        static var locationPermissionLabel: String {
            return "Location".localize()
        }
        static var disclousarDescription: String {
            return "Windscribe needs the location permission in order to make the \"Network Whitelist\" feature work.  This permission is required to access Wifi network names. This permission is used solely for this feature. Your location data does not leave your device, and is not used for anything else.".localize()
        }
        static var disclaimer: String {
            return "Disclaimer".localize()
        }
        static var grantPermission: String {
            return "Grant Permission".localize()
        }
        static var openSettings: String {
            return "Open Settings".localize()
        }
    }

    struct ConnectingAlert {
        static var title: String {
            return "Connecting...".localize()
        }
        static var message: String {
            return "Please terminate the current connection before starting new connection.".localize()
        }
    }
    struct DisconnectingAlert {
        static var title: String {
            return "Disconnecting...".localize()
        }
        static var message: String {
            return "Please wait until you are disconnected before starting new connection.".localize()
        }
    }
    struct NoInternetAlert {
        static var title: String {
            return "No Internet".localize()
        }
        static var message: String {
            return "Your device is currently offline. Please enable WiFi or cellular connection.".localize()
        }
    }
    struct AutomaticModeFailedAlert {
        static var title: String {
            return "Sorry! We tried our best and couldn't connect you.".localize()
        }
        static var message: String {
            return "Well, we gave it our best shot, but we couldn't connect you on this network. Please send us a debug log via the button below and open a support ticket on Windscribe.com".localize()
        }
    }
    struct UnableToConnect {
        static var title: String {
            return "Unable to connect".localize()
        }
        static var message: String {
            return "Windscribe was unable to connect to this location, please try another location or contact support.".localize()
        }
    }
    static var appLogSubmitSuccessAlert: String {
        return "App Log Submitted.".localize()
    }
    static var appLogSubmitFailAlert: String {
        return "App log cannot be submitted at this time.".localize()
    }

    struct ConfirmationEmailSentAlert {
        static var title: String {
            return "Confirmation Email Sent".localize()
        }
        static var message: String {
            return "Please check your inbox and junk/spam folder.".localize()
        }
    }

    static var SubmitEmailFailAlertMessage: String {
        return "Please make sure you have entered a correct password and a valid email.".localize()
    }

    struct PurchaseRestoredAlert {
        static var title: String {
            return "Purchases Restored".localize()
        }
        static var message: String {
            return "All purchases restored.".localize()
        }
        static var error: String {
            return "No valid transaction found to restore."
        }
    }

    struct Status {
        static var connectedTo: String {
            return "CONNECTED".localize()
        }
        static var connecting: String {
            return "CONNECTING".localize()
        }
        static var disconnected: String {
            return "DISCONNECTED".localize()
        }
        static var disconnecting: String {
            return "DISCONNECTING".localize()
        }
        static var connectivityTest: String {
            return "CONNECTIVITY TEST".localize()
        }
        static var lowWifiSignal: String {
            return "LOW WIFI SIGNAL".localize()
        }
        static var failed: String {
            return "FAILED".localize()
        }
        static var on: String {
            return "ON".localize()
        }
        static var off: String {
            return "OFF".localize()
        }
    }

    static var yourIP: String {
        return "Your IP".localize()
    }
    static var trusted: String {
        return "Trusted".localize()
    }
    static var upgrade: String {
        return "Upgrade".localize()
    }
    static var left: String {
        return "Left".localize()
    }
    static var bestLocation: String {
        return "Best Location".localize()
    }
    static var nothingToSeeHere: String {
        return "Nothing to see here".localize()
    }
    static var noStaticIPs: String {
        return "No Static IP's".localize()
    }
    static var noConfiguredLocations: String {
        return "No Custom Configs".localize()
    }

    struct Preferences {
        static var title: String { return "Preferences".localize() }
        static var general: String { return "General".localize() }
        static var account: String { return "Account".localize()}
        static var robert: String { return "R.O.B.E.R.T.".localize()}
        static var connection: String { return "Connection".localize()}
        static var networkSecurity: String { return "Network Options".localize()}
        static var debug: String { return "Debug".localize()}
        static var logout: String { return "Log Out".localize()}
        static var helpMe: String { return "Help Me!".localize()}
        static var leaderboard: String { return "Leaderboard".localize()}
        static var about: String { return "About".localize()}
        static var logOutAlert: String { return "Are you sure you want to log out of Windscribe?".localize()}
        static var referForData: String { return "Refer for Data".localize()}
        static var advanceParameters: String { return "Advance Parameters".localize()}
    }

    struct Robert {
        static var learnMore: String {
            return "Learn more".localize()
        }
        static var manageCustomRules: String {
            return "Manage Custom Rules".localize()
        }
        static var blocking: String {
            return "Blocking".localize()
        }
        static var allowing: String {
            return "Allowing".localize()
        }
    }

    static var unlimited: String {
        return "Unlimited".localize()
    }
    static var pro: String {
        return "Pro".localize()
    }
    static var proSubscription: String {
        return "Pro".localize()
    }

    struct General {
        static var title: String { return "General".localize() }
        static var connectionMode: String { return "Connection Mode".localize() }
        static var language: String { return "Language".localize() }
        static var displayLatency: String { return "Latency Display".localize() }
        static var sendLog: String { return "Send Log".localize() }
        static var ms: String { return "MS".localize() }
        static var bars: String { "Bars".localize() }
        static var latencytypes: [String] { return ["MS".localize(), "Bars".localize()] }
        static var pushNotificationSettings: String { "Enable Notifications".localize() }
        static var openSettings: String { return "Open Settings".localize() }
        static var orderLocationsBy: String { "Location Order".localize() }
        static var protocolType: String { "Protocol".localize() }
        static var port: String { "Port".localize() }
        static var appearance: String { "Appearance".localize() }
        static let protocols = ["WireGuard","IKEv2", "UDP", "TCP", "Stealth", "WStunnel"]
        static var version: String { "Version".localize() }
        static var auto: String { "Auto".localize() }
        static var manual: String { "Manual".localize() }
        static var custom: String { "Custom".localize() }
        static let languages: [String] = Languages.allCases.map({ $0.name })
        static var hapticFeedback: String { "Haptic Feedback".localize() }
        static var showServerHealth: String { "Show Location Load".localize() }
        static var autoSecure: String { "Auto-Secure".localize() }

        static func getValue(displayText: String) -> String? {
            switch displayText {
            case TextsAsset.General.ms:
                return Fields.Values.ms
            case TextsAsset.General.bars:
                return Fields.Values.bars
            case TextsAsset.General.auto:
                return Fields.Values.auto
            case TextsAsset.General.manual:
                return Fields.Values.manual
            case TextsAsset.orderPreferences[0]:
                return Fields.Values.geography
            case TextsAsset.orderPreferences[1]:
                return Fields.Values.alphabet
            case TextsAsset.orderPreferences[2]:
                return Fields.Values.latency
            case TextsAsset.appearances[0]:
                return Fields.Values.light
            case TextsAsset.appearances[1]:
                return Fields.Values.dark
            case TextsAsset.General.hapticFeedback:
                return Fields.hapticFeedback
            case TextsAsset.General.showServerHealth:
                return Fields.showServerHealth
            default:
                return nil
            }
        }

    }
    struct PreferencesDescription {
        static var locationOrder: String { return "Arrange locations alphabetically, geographically, or by latency.".localize()}
        static var displayLatency: String { return "Display latency as signal strength bars or in milliseconds.".localize() }
        static var language: String { return "Localize Windscribe to supported languages.".localize() }
        static var appearance: String { return "Light or Dark. Choose a side, and choose wisely.".localize() }
        static var background: String { return "Customize the background of the main app screen.".localize() }
        static var notificationStats: String { return "Set up push notifications to receive connection updates in case of an interruption".localize() }
        static var locationLoad: String { return "Display a location’s load. Shorter bars mean lesser load (usage)".localize() }
        static var hapticFeedback: String { return "Vibrate the device based on user actions.".localize() }
        static var connectionMode: String { return "Automatically choose the VPN protocol, or select one manually. NOTE: \"Preferred Protocol\" will override this setting.".localize() }
        static var autoSecure: String { return "Windscribe auto-connects if the device connects to this network.".localize()}
    }

    struct Account {
        static var title: String {
            return "Account".localize()
        }
        static var plan: String {
            return "PLAN".localize()
        }
        static var expiryDate: String {
            return "Expiry Date".localize()
        }
        static var resetDate: String {
            return "Reset Date".localize()
        }
        static var dataLeft: String {
            return "Data Left".localize()
        }
        static var info: String {
            return "INFO".localize()
        }
        static var editAccount: String {
            return "Edit Account".localize()
        }
        static var managerAccount: String {
            return "Manage Account".localize()
        }
        static var addEmail: String {
            return "Add".localize()
        }
        static var addEmailDescription: String {
            return "Get 10GB/Mo of data and gain the ability to reset a forgotten password.".localize()
        }
        static var addEmailDescriptionPro: String {
            return "Gain the ability to reset a forgotten password.".localize()
        }
        static var upgrade: String {
            return "Upgrade".localize()
        }
        static var confirmYourEmail: String {
            return "Confirm Your Email".localize()
        }
        static var resend: String {
            return "Resend".localize()
        }
        static var ghostInfo: String {
            return "Sign up or login to view your account details and safeguard your preferences".localize()
        }
        static var cancelAccount: String {
            return "Delete Account".localize()
        }
        static var deleteAccountMessage: String {
            return "Enter your Windscribe password to delete your account. Please be aware this action cannot be undone.".localize()
        }
    }

    struct NetworkSecurity {
        static var title: String {
            return "Network Security".localize()
        }
        static var trusted: String {
            return "Unsecured".localize()
        }
        static var untrusted: String {
            return "Secured".localize()
        }
        static var forget: String {
            return "Forget".localize()
        }
        static var currentNetwork: String {
            return "current network".localize()
        }
        static var otherNetwork: String {
            return "other network".localize()
        }
    }
    struct Debug {
        static var viewLog: String {
            return "View Debug Log".localize()
        }
        static var sendLog: String {
            return "Send Debug Log".localize()
        }
        static var sendingLog: String {
            return "Sending Log".localize()
        }
        static var sentLog: String {
            return "Sent, Thanks!".localize()
        }
        static var enterUsername: String {
            return "Enter Username".localize()
        }
        static var submit: String {
            return "Submit".localize()
        }
    }

    static let noNetworksAvailable = NSLocalizedString("NO INTERNET!", comment: "")
    static let cellular = NSLocalizedString("Cellular", comment: "")
    static let wifi = NSLocalizedString("Wi-fi", comment: "")
    static let noNetworkDetected = NSLocalizedString("No Network Detected", comment: "")
    static let noInternetConnection = NSLocalizedString("No Internet", comment: "")
    static let unknownNetworkName = "unknown"

    struct NewsFeed {
        static var title: String {
            return "News Feed".localize()
        }
    }

    struct EnterEmail {
        static var headline: String {
            return "One last thing!".localize()
        }
        static var description: String {
            return "Add your email address in case you forget your password. We’ll even give you 10GB for it.".localize()
        }
        static var acceptButton: String {
            return "Add".localize()
        }
        static var declineButton: String {
            return "No Thanks".localize()
        }
        static var secureYourAccount: String {
            return "Secure your account".localize()
        }
    }

    struct OutOfData {
        static var title: String {
            return "You’re out of data".localize()
        }
        static var description: String {
            return "Upgrade now to stay protected or wait until your bandwidth is reset on ".localize()
        }
        static var action: String {
            return "Upgrade".localize()
        }
        static var cancel: String {
            return "I'll wait!".localize()
        }
    }

    struct ProPlanExpired {
        static var title: String {
            return "Your Pro Plan expired!".localize()
        }
        static var description: String {
            return "You’ve been downgraded to free for now".localize()
        }
        static var action: String {
            return "Renew Plan".localize()
        }
        static var cancel: String {
            return "Remind me later".localize()
        }
    }

    struct Banned {
        static var title: String {
            return "You’ve been banned".localize()
        }
        static var description: String {
            return "Your account has been disabled for violating our Terms of Service".localize()
        }
        static var action: String {
            return "Learn More".localize()
        }
    }

    struct PushNotifications {
        static var title: String {
            return "Stay Protected".localize()
        }
        static var description: String {
            return "Set up push notifications to receive connection updates in case of an interruption".localize()
        }
        static var action: String {
            return "Turn Notification On".localize()
        }
    }

    struct UpgradeView {
        static var title: String {
            return "Plans".localize()
        }
        static var pricing: String {
            return "Pricing".localize()
        }
        static var benefits: String {
            return "Benefits".localize()
        }
        static var continueFree10GB: String {
            return "Free 10GB/Mo".localize()
        }
        static var unlimitedData: String {
            return "Unlimited Data".localize()
        }
        static var unlimitedDataMessage: String {
            return "Pretty self explanatory. Use as much bandwidth as you'd like.".localize()
        }
        static var allLocations: String {
            return "All Locations".localize()
        }
        static var allLocationsMessage: String {
            return "Access to servers in over 60 countries and 110 data centers.".localize()
        }
        static let robert = "R.O.B.E.R.T"
        static var robertMessage: String {
            return "Best malware and ad-blocker you will ever use. Seriously.".localize()
        }
        static var choosePlan: String {
            return "Choose Plan".localize()
        }
        static var year: String {
            return "Year".localize()
        }
        static var month: String {
            return "Month".localize()
        }
        static var months: String {
            return "Months".localize()
        }
        static var iAPDescription: String {
            return "Subscriptions will automatically renew unless canceled within 24-hours before the end of the current period. You can cancel anytime with your iTunes account settings. Any unused portion of a free trial will be forfeited if you purchase a subscription".localize()
        }
        static var termsOfUse: String {
            return "Terms of Use".localize()
        }
        static var privacyPolicy: String {
            return "Privacy Policy".localize()
        }
        static var restorePurchases: String {
            return "Restore Purchases".localize()
        }

        static var networkError: String {
            return "Error network.".localize()
        }

        static var promoNotValid: String {
            return "Promo is not valid anymore.".localize()
        }
    }

    static var addStaticIP: String {
        return "Add Static IP".localize()
    }
    static var addCustomConfig: String {
        return "Add Custom Config".localize()
    }
    static var addCustomConfigDescription: String {
        return "Custom configs allow you to connect to any OpenVPN or Wireguard server. Just add a valid config file and it will appear in this tab.".localize()
    }
    static var customConfigWithSameFileNameError: String {
        return "Custom config file with this name already exists".localize()
    }

    struct Siri {
        static var connectToVPN: String {
            return "Connect to VPN".localize()
        }
        static var disconnectVPN: String {
            return "Disconnect VPN".localize()
        }
        static var showMyLocation: String {
            return "Show My Location".localize()
        }
    }

    struct RateUs {
        static var title: String {
            return "Rate Us!".localize()
        }
        static var description: String {
            return "Are you enjoying Windscribe? Sure you are. Rate us in the App store and we’ll love you long time.".localize()
        }
        static var action: String {
            return "Rate Windscribe".localize()
        }
        static var maybeLater: String {
            return "Maybe Later".localize()
        }
        static var goAway: String {
            return "Go Away".localize()
        }
    }

    static var orderPreferences: [String] {
        return ["Geography".localize(), "Alphabet".localize(), "Latency".localize()]
    }
    static let openVPN = "OpenVPN"
    static let iKEv2 = "IKEv2"
    static let wireGuard = "WireGuard"
    static var appearances: [String] {
        return ["Light".localize(), "Dark".localize()]
    }
    struct RemoveFavNode {
        static var title: String {
            return "Are you sure?".localize()
        }
        static var message: String {
            return "Removing this location from favourites will make it feel sad.".localize()
        }
    }
    struct TrustedNetworkPopup {
        static var title: String {
            return "This network is unsecured".localize()
        }
        static var message: String {
            return "is unsecured, meaning you don't wish to use Windscribe while on this network".localize()
        }
        static var action: String {
            return "Connect Anyway".localize()
        }
        static var cancel: String {
            return "Cancel".localize()
        }
    }

    static var remove: String {
        return "Remove".localize()
    }
    static var cancel: String {
        return "Cancel".localize()
    }

    struct RestartAppAlert {
        static var title: String {
            return "This action requires a restart".localize()
        }
        static var message: String {
            return "Please restart Windscribe to continue using in the preferred language.".localize()
        }
        static var action: String {
            return "Close App".localize()
        }
    }

    static var refreshLatency: String {
        return "Refresh latency".localize()
    }
    static var disconnectToRefreshLatency: String {
        return "Disconnect to refresh latency".localize()
    }

    static var iKEv2RemoteIDTest: String {
        return "IKEv2 RemoteID Test".localize()
    }
    static var iKEv2RemoteIDTestDescription: String {
        return "Only enable this for testing.".localize()
    }

    static var disconnecting: String {
        return "Disconnecting".localize()
    }

    static var firewall: String {
        return "Firewall".localize()
    }

    static var killSwitch: String {
        return "Always on VPN".localize()
    }

    static var allowLan: String {
        return "Allow LAN Traffic".localize()
    }

    static var firewallDescription: String {
        return "This turns on the on-demand mode.".localize()
    }

    static var killSwitchDescription: String {
        return "Tunnel all traffic via Windscribe at all times. Recommended only for high-risk use-cases and may cause issues with some Apple services.".localize()
    }

    static var allowLanDescription: String {
        return "Allow access to local services and printers while connected to Windscribe.".localize()
    }

    static var circumventCensorship: String {
        return "Circumvent Censorship".localize()
    }

    static var circumventCensorshipDescription: String {
        return "Connect to the VPN even in hostile environment".localize()
    }

    static var connectedDNS: String {
        return "Connected DNS".localize()
    }

    static var connectedDNSDescription: String {
        return "Select the DNS server while connected to Windscribe.".localize()
    }

    static var connectedDNSValueFieldDescription: String {
        return "IP/DNS-over-HTTPS/TLS".localize()
    }

    static var connectedDNSInvalidAlertTitle: String {
        return "Invalid DNS server".localize()
    }

    static var connectedDNSInvalidAlertBody: String {
        return "Something went wrong. Please make sure you have entered a valid DNS server.".localize()
    }

    static var configuredLocation: String {
        return "Custom Config".localize()
    }

    static var configTitle: String {
        return "Config Title".localize()
    }

    struct RemoveCustomConfig {
        static var title: String {
            return "Are you sure?".localize()
        }
        static var message: String {
            return "This custom configuration will be gone forever.".localize()
        }
    }

    struct EnterCredentialsAlert {
        static var title: String {
            return "Enter Credentials".localize()
        }
        static var message: String {
            return "Enter the username and password associated with this custom config".localize()
        }
        static var saveCredentials: String {
            return "Save credentials?".localize()
        }
    }

    struct EditCredentialsAlert {
        static var title: String {
            return "Edit Credentials".localize()
        }
    }
    static var connect: String {
        return "Connect".localize()
    }
    static var save: String {
        return "Save".localize()
    }

    struct FileNotInCorrectFormat {
        static var title: String {
            return "Incorrect File Format".localize()
        }
        static var message: String {
            return "Something went wrong. Please make sure you have the correct OpenVPN configurations.".localize()
        }
    }

    struct ConfigFileNotSupported {
        static var title: String {
            return "Config file is not supported".localize()
        }
        static var message: String {
            return "Your configuration contains unsupported directives.".localize()
        }
    }

    static var delete: String {
        return "Delete".localize()
    }

    struct PrivacyView {
        static var title: String {
            return "Your Privacy Is Important".localize()
        }
        static var description: String {
            return "Windscribe is a no-logging VPN service that takes your privacy seriously. Any activity on our network cannot be traced to a specific account. That being said, we collect the following pieces of information in order to operate the service:".localize()
        }
        static var firstLine: String {
            return "Account data: username, email (if you gave us one), and payment transaction IDs (if you gave us money)".localize()
        }
        static var secondLine: String {
            return "Metadata needed to ensure quality of service: bandwidth used in a 30 day period, number of parallel connections".localize()
        }
        static var action: String {
            return "I'm OK With This".localize()
        }
    }

    struct AskToRetryPopup {
        static var title: String {
            return "Unable to connect".localize()
        }
        static var message: String {
            return "We're unable to connect you via $proto_name protocol. Your network may have unstable Internet connectivity or is blocking VPNs. Let's try another protocol.".localize()
        }
        static func messageWithProtocol(protocolType: String) -> String {
            return "We're unable to connect you via \(protocolType) protocol. Your network may have unstable Internet connectivity or is blocking VPNs. Let's try another protocol.".localize()
        }
    }
    struct AutoModeFailedToConnectPopup {
        static var title: String {
            return "This network hates us".localize()
        }
        static var message: String {
            return "Well we gave it our best shot, we just couldn’t connect you on this network for some reason.".localize()
        }
        static var sendDebugLog: String {
            return "Send Debug Log".localize()
        }
        static var contactSupport: String {
            return "Contact Support".localize()
        }
    }

    // swiftlint:disable inclusive_language
    struct Whitelist {
        static var title: String {
            return "Auto-Secure".localize()
        }
        static var description: String {
            return "When you connect to this network, Windscribe will auto-connect to the last chosen location.".localize()
        }
    }
    // swiftlint:enable inclusive_language

    struct PreferredProtocol {
        static var title: String {
            return "Preferred Protocol".localize()
        }
        static var description: String {
            return "Choose the best protocol for this network. This overrides all global connection settings.".localize()
        }
        static var newDescription: String {
            return "Select the preferred protocol for this network. This overrides global connection preferences.".localize()
        }
    }

    static var forgetNetwork: String {
        return "Forget Network".localize()
    }
    static var autoModeSelectorInfo: String {
        return "Next up in".localize()
    }

    struct SetPreferredProtocolPopup {
        static func title(protocolType: String) -> String {
            let firstPart = "Set".localize()
            let lastPart = "as preferred protocol?".localize()
            return "\(firstPart) \(protocolType) \(lastPart)"
        }

        static var message: String {
            return "Windscribe will keep using the chosen protocol on this network, regardless of your global connection settings.".localize()
        }
        static var action: String {
            return "Set as Preferred".localize()
        }
        static var cancel: String {
            return "Keep it automatic".localize()
        }
        static var dontAskAgain: String {
            return "Don't ask again".localize()
        }

        static var changeMessage: String {
            return "Windscribe will always use this protocol to connect on this network in the future to avoid any interruptions.".localize()
        }

        static var failMessage: String {
            return "We couldn’t connect you on this network. Send us your debug log so we can figure out what happened.".localize()
        }

        static var failHeaderString: String { return "This network hates us".localize()}

    }

    static var back: String {
        return "Back".localize()
    }

    struct ShakeForData {
        static var title: String {
            return "Shake for Data".localize()
        }
        static var shakes: String {
            return "Shakes".localize()
        }
        static var quit: String {
            return "I Quit".localize()
        }
        static var leave: String {
            return "Leave".localize()
        }
        static var claimPrize: String {
            return "Claim Prize".localize()
        }
        static var tryAgain: String {
            return "Try Again".localize()
        }
        static var notBad: String {
            return "Not Bad!".localize()
        }
        static var lowerThanHighScoreMessage: String {
            return "Not Bad!".localize()
        }

        static var popupTitle: String {
            return "Shake for Data!".localize()
        }
        static var popupDescription: String {
            return "Shake your phone as much as you can before the time runs out and win!".localize()
        }
        static var popupAction: String {
            return "Start Shaking".localize()
        }
        static var popupCancel: String {
            return "I hate free stuff".localize()
        }
        static var popupViewLeaderboard: String {
            return "View Leaderboard".localize()
        }

        static var highScore: String {
            return "High Score:".localize()
        }
        static var newHighScore: String {
            return "New High Score!".localize()
        }

        static var leaveAlertTitle: String {
            return "Unlock Shake For Data".localize()
        }
        static var leaveAlertDescription: String {
            return "Unlock access to this feature? It will show up in Preferences.".localize()
        }
        static var leaveAlertUnlock: String {
            return "Unlock".localize()
        }
        static var leaveAlertLeave: String {
            return "Just Leave".localize()
        }

        static var play: String {
            return "Play".localize()
        }
    }

    static var autoSecureNew: String {
        return "Auto-Secure New Networks".localize()
    }
    static var autoSecureNewDescription: String {
        return "Mark all newly encountered networks as Secured.".localize()
    }

    struct NoEmailPrompt {
        static var title: String {
            return "Without an email, your free account will be limited to 2GB/Mo and you won’t be able to reset your password.".localize()
        }
        static var titlePro: String {
            return "You won’t be able to reset a password without an email or receive any service updates from us.".localize()
        }
        static var action: String {
            return "Continue without email".localize()
        }
    }
    struct SetupLaterPrompt {
        static var title: String {
            return "Failure to setup account will prevent access in case you’re logged out.".localize()
        }
        static var action: String {
            return "Setup later".localize()
        }
    }

    struct Powers {
        static var first: String {
            return "Servers in over 100 locations".localize()
        }
        static var second: String {
            return "Automatically secure any network".localize()
        }
        static var third: String {
            return "Strict No-Logging Policy".localize()
        }
        static var fourth: String {
            return "Works with Siri, Shortcuts & Widgets".localize()
        }
    }

    static var searchLocations: String {
        return "Search Locations".localize()
    }

    struct EmailView {
        static var confirmEmail: String {
            return "Confirm Email".localize()
        }
        static var info: String {
            return "Please confirm your email to get 10GB/Mo".localize()
        }
        static var infoPro: String {
            return "Please confirm your email".localize()
        }
        static var resendEmail: String {
            return "Resend Verification Email".localize()
        }
        static var changeEmail: String {
            return "Change Email".localize()
        }
        static var close: String {
            return "Close".localize()
        }
    }

    static var twoFactorRequiredError: String {
        return "2FA code is required".localize()
    }
    static var twoFactorInvalidError: String {
        return "Invalid 2FA code, please try again.".localize()
    }
    static var cantGetConnectedWifi: String {
        return "Problem occured while detecting the connected network on your device.".localize()
    }
    static var restartApp: String {
        return "Restart App".localize()
    }
    static var tryAgain: String {
        return "Try Again".localize()
    }

    struct Refer {
        static var shareWindscribeWithFriend: String {
            return "Share Windscribe with a friend!".localize()
        }
        static var getAdditionalPerMonth: String {
            return "You will both get an additional 1GB per month when they sign up.".localize()
        }
        static var goProTo: String {
            return "If they go Pro, you’ll go Pro too!".localize()
        }
        static var shareInviteLink: String {
            return "Share Invite Link".localize()
        }
        static var refereeMustProvideUsername: String {
            return "Referee must provide your username at sign up and confirm their email in order for the benefits above to apply to your account.".localize()
        }
        static var inviteMessage: String {
            return "is inviting you to join Windscribe. Provide their username at signup and you’ll both get 1gb of free data added to your accounts. If you go pro, they’ll go pro too!".localize()
        }
    }

    static var emergencyConnect: String {
        return "Emergency Connect".localize()
    }
    static var eConnectDescription: String {
        return "Can’t access Windscribe? Connect to our servers to unblock your restrictive network.".localize()
    }
    static var connecting: String {
        return "Connecting".localize()
    }
    static var disconnect: String {
        return "Disconnect".localize()
    }
    static var connectedDescription: String {
        return "You are now connected to Windscribe server. Try to login again.".localize()
    }

    struct MaintenanceLocationPopUp {
        static var title: String {
            return "This Location is Under Maintenance".localize()
        }

        static var subtHeader: String {
            return "Try again later or go\nto our Status page\nfor more info".localize()
        }

        static var checkStatus: String {
            return "Check status".localize()
        }

        static var cancelTitle: String {
            return "Back".localize()
        }
    }
}

struct Links {
    static var base: String = "https://windscribe.com/"
    static let acccount = "myaccount"
    static let helpMe = "help"
    static let portForwarding = "myaccount#portforwards"
    static let staticIPs = "staticips"
    static let terms = "terms"
    static let knowledge = "support/knowledgebase"
    static let garry = "support?garry=1"
    static let reddit = "https://www.reddit.com/r/Windscribe/"
    static let discord = "https://discord.com/invite/vpn"
    static let status = base + "status"
    static let about = base + "about"
    static let termsWindscribe = base + "terms"
    static let privacy = base + "privacy"
    static let blog = "https://blog.windscribe.com/"
    static let jobs = base + "jobs"
    static let learMoreAboutRobert = "features/robert"
    static let softwareLicenses = "https://windscribe.com/terms/oss"
}

struct Help {
    static var helpMe: String {
        return "Help Me!".localize()
    }
    static var knowledgeBase: String {
        return "Knowledge Base".localize()
    }
    static var allYouNeedToknowIsHere: String {
        return "All you need to know about Windscribe.".localize()
    }
    static var talkToGarry: String {
        return "Talk to Garry".localize()
    }
    static var notAsSmartAsSiri: String {
        return "Need help? Garry can help you with most issues, go talk to him.".localize()
    }
    static var sendTicket: String {
        return "Contact Humans".localize()
    }
    static var sendUsATicket: String {
        return "Have a Problem that Garry can't resolve? Contact human support".localize()
    }
    static var communitySupport: String {
        return "Community Support".localize()
    }
    static var bestPlacesTohelp: String {
        return "Best places to help and get help from other users.".localize()
    }
    static var reddit: String {
        return "Reddit".localize()
    }
    static var discord: String {
        return "Discord".localize()
    }
}

struct Robert {
    static let robert = "R.O.B.E.R.T"
    static var description: String {
        return "R.O.B.E.R.T. is a customizable server-side domain and IP blocking tool. Select the block lists you wish to apply on all your devices by toggling the switch.".localize()
    }
    static var learnMore: String {
        return "Learn more".localize()
    }
}

struct Web {
    static let Windscribe = "Windscribe"
}

struct About {
    static var about: String {
        return "About".localize()
    }
    static var status: String {
        return "Status".localize()
    }
    static var aboutUs: String {
        return "About Us".localize()
    }
    static var privacyPolicy: String {
        return "Privacy Policy".localize()
    }
    static var terms: String {
        return "Terms".localize()
    }
    static var blog: String {
        return "Blog".localize()
    }
    static var jobs: String {
        return "Jobs".localize()
    }
    static var softwareLicenses: String {
        return "Software Licenses".localize()
    }
}

struct SubmitTicket {
    static var submitTicket: String {
        return "Send Ticket".localize()
    }
    static var fillInTheFields: String {
        return "Fill in the fields bellow and one of our support agents will personally get back to you very soon™".localize()
    }
    static var category: String {
        return "Category".localize()
    }
    static var email: String {
        return "Email".localize()
    }
    static var required: String {
        return "Required".localize()
    }
    static var soWeCanContactYou: String {
        return "So we can contact you, we won’t use it for anything else".localize()
    }
    static var subject: String {
        return "Subject".localize()
    }
    static var whatsTheIssue: String {
        return "What’s the issue?".localize()
    }
    static var message: String {
        return "Message".localize()
    }
    static let `continue` = "Continue"
    static let acount = "Account"
    static let sales = "Sales"
    static let technical = "Technical"
    static let feedback = "Feedback"
    static let categories = [acount, technical, sales, feedback]
    static let categoryValues = [acount: 1, technical: 2, sales: 3, feedback: 4]
    static var weWillGetBackToYou: String {
        return "Sweet, we’ll get back to you as soon as one of our agents is back from lunch.".localize()
    }
    static var failedToSendTicket: String {
        return "Failed to send support ticket. Please check your network and try again.".localize()
    }
}

struct TvAssets {
    static var loginCodeError: String {
        return "Unable to generate Login code. Check you network connection.".localize()
    }

}
