//
//  TextsAsset.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-18.
//  Copyright © 2019 Windscribe. All rights reserved.
//

// swiftlint:disable file_length
// swiftlint:disable type_body_length

import Foundation

enum TextsAsset {
    static var slogan: String {
        return "Keep Your Secrets.".localized
    }

    static var getStarted: String {
        return "Get Started".localized
    }

    static var loading: String {
        return "Loading".localized
    }

    static var login: String {
        return "Login".localized
    }

    static var get10GbAMonth: String {
        return "Get 10GB/Mo".localized
    }

    static var tenGbAMonth: String {
        return "10GB/Mo".localized
    }

    static var continueWithoutAccount: String {
        return "Continue without account".localized
    }

    static var ghostAccountInfoLabel: String {
        return "Limited to 2GB/Mo".localized
    }

    static var `continue`: String {
        return "Continue".localized
    }

    static var setupLater: String {
        return "Setup later".localized
    }

    static var signUp: String {
        return "Sign up".localized
    }

    static var signUpFree: String {
        return "Sign up free".localized
    }

    static var createAccount: String {
        return "Create Account".localized
    }

    static var accountSetupTitle: String {
        return "Account setup".localized
    }

    static var accountSetupMessage: String {
        return "Safeguard your Pro account and access it from any device.".localized
    }

    static var signUpInfo: String {
        return "Safeguard your account, access your settings from any device and get more data.".localized
    }

    static var optional: String {
        return "Optional".localized
    }

    static var getMoreData: String {
        return "Get More Data".localized
    }

    static var addEmail: String {
        return "Add Email".localized
    }

    static var addEmailInfo: String {
        return "For password recovery, updates & promo only. No spam".localized
    }

    static var setupAccount: String {
        return "Setup Account".localized
    }

    static var email: String {
        return "Email".localized
    }

    static var yourEmail: String {
        return "Your email".localized
    }

    static var emailInfoLabel: String {
        return "For password recovery, updates & promo only. No spam".localized
    }

    static var enterYourEmail: String {
        return "Enter your email".localized
    }

    static var verifyYourPassword: String {
        return "Verify your password".localized
    }

    static var chooseUsername: String {
        return "Choose Username".localized
    }

    static var choosePassword: String {
        return "Choose Password".localized
    }

    static var confirmPassword: String {
        return "Confirm password".localized
    }

    static var referredBySomeone: String {
        return "Referred by someone?".localized
    }

    static var mustConfirmEmail: String {
        return "You must confirm your email in order for the benefits above to apply to you and the referrer.".localized
    }

    static var yes: String {
        return "Yes".localized
    }

    static var no: String {
        return "No".localized
    }

    static var okay: String {
        return "Okay".localized
    }

    static var ok: String {
        return "OK".localized
    }

    static var error: String {
        return "Error".localized
    }

    static var loginFailed: String {
        return "The username and password combination is wrong.".localized
    }

    static var pleaseDisconnectFirst: String {
        return "You can't make changes while connected to a VPN.".localized
    }

    static var youWillBothGetTenGb: String {
        return "You will both get an additional 1GB per month when you sign up.".localized
    }

    static var ifYouGoPro: String {
        return "If you go Pro, they’ll go Pro too!".localized
    }

    static var signInProgress: [String] {
        return ["Getting Server List".localized,
                "Getting IKEv2 Server Credentials".localized,
                "Getting OpenVPN Server Credentials".localized,
                "Getting Static IPs".localized,
                "Getting Port Maps".localized,
                "Getting Mobile Plans".localized,
                "Getting Configurations".localized,
                "Getting Notifications".localized,
                "Preparing Your Dashboard".localized]
    }

    static var passwordsDontMatch: String {
        return "The passwords don't match.".localized
    }

    static var cannotRegister: String {
        return "Registration failed, please contact support.".localized
    }

    static var pleaseContactSupport: String {
        return "Please contact support.".localized
    }

    static var usernameIsTaken: String {
        return "Awww! This username is taken.".localized
    }

    static var emailIsTaken: String {
        return "Awww! This email already exists.".localized
    }

    static var disposableEmail: String {
        return "Disposable emails are not allowed. Provide a valid email, or leave the email field blank.".localized
    }

    static var cannotChangeExistingEmail: String {
        return "Cannot change existing email because it is already confirmed.".localized
    }

    static var usernameValidationError: String {
        return "Must only contain letters, numbers and underscores.".localized
    }

    static var passwordValidationError: String {
        return "Must be longer than 7 characters.".localized
    }

    static var emailValidationError: String {
        return "Enter a valid email.".localized
    }

    static var ghostModeError: String {
        return "Unfortunately you cannot use Windscribe without an account as we detected potential abuse. Please make one, it's really easy.".localized
    }

    static var pleaseEnterEmailFirst: String {
        return "Please provide an email first".localized
    }

    static var referringUsername: String {
        return "Referring username".localized
    }

    static var voucherCode: String {
        return "Voucher Code".localized
    }

    static var send: String {
        return "Send".localized
    }

    static var submit: String {
        return "Submit".localized
    }

    static var confirm: String {
        return "Confirm".localized
    }

    static var failedToLoadData: String {
        return "Failed to load data".localized
    }

    static var staticIPList: String {
        return "Static IPs".localized
    }

    static var customConfigs: String {
        return "Custom Configs".localized
    }

    static var favoriteNodes: String {
        return "Favorite Locations".localized
    }

    enum SignInError {
        static var usernameExpectedEmailProvided: String {
            return "Please login with your username, not your email".localized
        }
    }

    enum ProtocolVariation {
        static var connectionFailureTitle: String {
            return "Connection Failure!".localized
        }

        static var protocolChangeTitle: String {
            return "Change Protocol".localized
        }

        static var connectionFailureDescription: String {
            return "The protocol you’ve chosen has failed to connect. Windscribe will attempt to reconnect using the first protocol below.".localized
        }

        static var protocolChangeDescription: String {
            return "Quickly re-connect using a different protocol.".localized
        }

        static var ikev2ProtocolDescription: String {
            return "IKEv2 is an IPsec based tunnelling protocol.".localized
        }

        static var udpProtocolDescription: String {
            return "Balanced speed and security.".localized
        }

        static var tcpProtocolDescription: String {
            return "Use it if OpenVPN UDP fails.".localized
        }

        static var wsTunnelProtocolDescription: String {
            return "Wraps your HTTPS traffic with web sockets.".localized
        }

        static var stealthProtocolDescription: String {
            return "Disguises your traffic as HTTPS traffic with TLS".localized
        }

        static var wireGuardProtocolDescription: String {
            return "Extremely simple yet fast and modern VPN protocol.".localized
        }

        static var debugLogCompletionDescription: String {
            return "Your debug log has been received. Please contact support if you want assistance with this issue.".localized
        }

        static var connectedState: String {
            return "Connected to".localized
        }
    }

    enum Permission {
        static var locationDescription: String {
            return "Location permission is denied . Settings > Privacy > Location services > Windscribe > check while in use and presise location.".localized
        }

        static var locationPermissionLabel: String {
            return "Locations".localized
        }
        static var disclosureDescription: String {
            return "Windscribe requires the Locations permission, with Precise Location enabled, in order to make the \"Network Whitelist\" feature work. This permission is required to access WiFi network names. This permission is used solely for this feature. Your location data does not leave your device, and is not used for anything else.".localized
        }

        static var disclaimer: String {
            return "Disclaimer".localized
        }

        static var grantPermission: String {
            return "Grant Permission".localized
        }

        static var openSettings: String {
            return "Open Settings".localized
        }
    }

    enum ConnectingAlert {
        static var title: String {
            return "Connecting...".localized
        }

        static var message: String {
            return "Please terminate the current connection before starting new connection.".localized
        }
    }

    enum DisconnectingAlert {
        static var title: String {
            return "Disconnecting...".localized
        }

        static var message: String {
            return "Please wait until you are disconnected before starting new connection.".localized
        }
    }

    enum NoInternetAlert {
        static var title: String {
            return "No Internet".localized
        }

        static var message: String {
            return "Your device is currently offline. Please enable WiFi or cellular connection.".localized
        }
    }

    enum AutomaticModeFailedAlert {
        static var title: String {
            return "Sorry! We tried our best and couldn't connect you.".localized
        }

        static var message: String {
            return "Well, we gave it our best shot, but we couldn't connect you on this network. Please send us a debug log via the button below and open a support ticket on Windscribe.com".localized
        }
    }

    enum UnableToConnect {
        static var title: String {
            return "Unable to connect".localized
        }

        static var message: String {
            return "Windscribe was unable to connect to this location, please try another location or contact support.".localized
        }
    }

    enum AuthFailure {
        static var title: String {
            return "Unable to connect".localized
        }

        static var message: String {
            return "VPN will be disconnected due to credential failure.".localized
        }
    }

    static var appLogSubmitSuccessAlert: String {
        return "App Log Submitted.".localized
    }

    static var appLogSubmitFailAlert: String {
        return "App log cannot be submitted at this time.".localized
    }

    enum ConfirmationEmailSentAlert {
        static var title: String {
            return "Confirmation Email Sent".localized
        }

        static var message: String {
            return "Please check your inbox and junk/spam folder.".localized
        }
    }

    static var SubmitEmailFailAlertMessage: String {
        return "Please make sure you have entered a correct password and a valid email.".localized
    }

    enum PurchaseRestoredAlert {
        static var title: String {
            return "Purchases Restored".localized
        }

        static var message: String {
            return "All purchases restored.".localized
        }

        static var error: String {
            return "No valid transaction found to restore."
        }
    }

    enum Status {
        static var connectedTo: String {
            return "CONNECTED".localized
        }

        static var connecting: String {
            return "CONNECTING".localized
        }

        static var disconnected: String {
            return "DISCONNECTED".localized
        }

        static var disconnecting: String {
            return "DISCONNECTING".localized
        }

        static var connectivityTest: String {
            return "CONNECTIVITY TEST".localized
        }

        static var lowWifiSignal: String {
            return "LOW WIFI SIGNAL".localized
        }

        static var failed: String {
            return "FAILED".localized
        }

        static var on: String {
            return "ON".localized
        }

        static var off: String {
            return "OFF".localized
        }
    }

    static var yourIP: String {
        return "Your IP".localized
    }

    static var trusted: String {
        return "Trusted".localized
    }

    static var upgrade: String {
        return "Upgrade".localized
    }

    static var left: String {
        return "Left".localized
    }

    static var bestLocation: String {
        return "Best Location".localized
    }

    static var nothingToSeeHere: String {
        return "Nothing to see here".localized
    }

    static var noStaticIPs: String {
        return "No Static IP's".localized
    }

    static var noConfiguredLocations: String {
        return "No Custom Configs".localized
    }

    enum Preferences {
        static var title: String { return "Preferences".localized }
        static var general: String { return "General".localized }
        static var account: String { return "Account".localized }
        static var robert: String { return "R.O.B.E.R.T.".localized }
        static var lookFeel: String { return "Look & Feel".localized }
        static var connection: String { return "Connection".localized }
        static var debug: String { return "Debug".localized }
        static var logout: String { return "Log Out".localized }
        static var helpMe: String { return "Help Me!".localized }
        static var leaderboard: String { return "Leaderboard".localized }
        static var about: String { return "About".localized }
        static var privacy: String { return "Privacy & EULA".localized }
        static var logOutAlert: String { return "Are you sure you want to log out of Windscribe?".localized }
        static var referForData: String { return "Refer for Data".localized }
        static var advanceParameters: String { return "Advanced Parameters".localized }
        static var networkSecurity: String { return "Network Options".localized }
    }

    enum Connection {
        static var title: String { return "Connection".localized }
        static var networkOptions: String { return "Network Options".localized }
        static var connectionMode: String { return "Connection Mode".localized }
        static var killSwitch: String { return "Always on VPN".localized }
        static var connectedDNS: String { return "Connected DNS".localized }
        static var allowLan: String { return "Allow LAN Traffic".localized }
        static var circumventCensorship: String { return "Circumvent Censorship".localized }
        static var autoSecure: String { "Auto-Secure".localized }
        static var autoSecureNew: String { "Auto-Secure New Networks".localized }
        static var protocolType: String { "Protocol".localized }
        static var port: String { "Port".localized }

        static var connectionModeDescription: String {
            return "Automatically choose the VPN protocol, or select one manually. NOTE: \"Preferred Protocol\" will override this setting.".localized
        }
        static var killSwitchDescription: String {
            return "Tunnel all traffic via Windscribe at all times. Recommended only for high-risk use-cases and may cause issues with some Apple services.".localized
        }
        static var connectedDNSDescription: String {
            return "Select the DNS server while connected to Windscribe. NOTE: IKEv2 protocol will override this setting.".localized
        }
        static var allowLanDescription: String {
            return "Allow access to local services and printers while connected to Windscribe.".localized
        }
        static var circumventCensorshipDescription: String {
            return "Connect to the VPN even in hostile environment".localized
        }
        static var connectedDNSValueFieldDescription: String {
            return "IP/DNS-over-HTTPS/TLS".localized
        }
        static var connectedDNSInvalidAlertTitle: String {
            return "Invalid DNS server".localized
        }
        static var connectedDNSInvalidAlertBody: String {
            return "Something went wrong. Please make sure you have entered a valid DNS server.".localized
        }
        static var autoSecureNewDescription: String {
            return "Windscribe will mark every new network as “Secured” and turn ON automatically when your device connects to them.".localized
        }
        static var autoSecureSettingsDescription: String {
            return "Windscribe will turn ON automatically if your device connects to this network.".localized
        }
    }

    static var learnMore: String {
        return "Learn more".localized
    }

    enum Robert {
        static var title: String {
            return "R.O.B.E.R.T.".localized
        }

        static var manageCustomRules: String {
            return "Manage Custom Rules".localized
        }

        static var blocking: String {
            return "Blocking".localized
        }

        static var allowing: String {
            return "Allowing".localized
        }

        static var description: String {
            return "R.O.B.E.R.T. is a customizable server-side domain and IP blocking tool. Select the block lists you wish to apply on all your devices by toggling the switch.".localized
        }

        static var failedToGetFilters: String {
            return "Failed to get Robert Filters.".localized
        }

        static var unableToLoadRules: String {
            return "Unable to load robert rules. Check your network connection.".localized
        }
    }

    static var unlimited: String {
        return "Unlimited".localized
    }

    static var pro: String {
        return "Pro".localized
    }

    static var proSubscription: String {
        return "Pro".localized
    }

    static var allServers: String {
        return "All Locations".localized
    }

    enum General {
        static var title: String { return "General".localized }
        static var language: String { return "Language".localized }
        static var displayLatency: String { return "Latency Display".localized }
        static var sendLog: String { return "Send Log".localized }
        static var ms: String { return "MS".localized }
        static var bars: String { "Bars".localized }
        static var latencytypes: [String] { return ["MS".localized, "Bars".localized] }
        static var pushNotificationSettings: String { "Enable Notifications".localized }
        static var openSettings: String { return "Open Settings".localized }
        static var orderLocationsBy: String { "Location Order".localized }
        static let protocols = ["WireGuard", "IKEv2", "UDP", "TCP", "Stealth", "WStunnel"]
        static let openVpnProtocols = ["UDP", "TCP", "Stealth", "WStunnel"]
        static var version: String { "Version".localized }
        static var auto: String { "Auto".localized }
        static var manual: String { "Manual".localized }
        static var bundled: String { "Bundled".localized }
        static var custom: String { "Custom".localized }
        static var none: String { "None".localized }
        static var flag: String { "Flags".localized }
        static var stretch: String { "Stretch".localized }
        static var fill: String { "Fill".localized }
        static var tile: String { "Tile".localized }
        static let languages: [String] = Languages.allCases.map { $0.name }
        static let languagesList: [Languages] = Languages.allCases
        static var hapticFeedback: String { "Haptic Feedback".localized }
        static var showServerHealth: String { "Location Load".localized }
        static var enabled: String { "Enabled".localized }
        static var disabled: String { "Disabled".localized }
        static var customBackground: String { "Custom Background".localized }

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
            case TextsAsset.General.hapticFeedback:
                return Fields.hapticFeedback
            case TextsAsset.General.showServerHealth:
                return Fields.showServerHealth
            default:
                return nil
            }
        }
    }

    enum CustomLocationNames {
        static var exportLocations: String { "Export Locations".localized }
        static var importLocations: String { "Import Custom Locations".localized }
        static var exportLocationsDesc: String { "Export your server location list to a local file in JSON that you can edit to change the locations names into your own custom ones".localized }
        static var importLocationsDesc: String { "Import a custom name server location names list from a local JSON file".localized }
        static var failedImporting: String { "Failed to import custom location names list".localized }
        static var successfullyImported: String { "Successfully imported custom location names list".localized }
        static var failedExporting: String { "Failed to export custom location names list".localized }
        static var successfullyExported: String { "Successfully exported custom location names list".localized }
        static var resetSuccessful: String { "Successfully reset custom location names list".localized }
        static var exportTitleSuccess: String { "Export Successful".localized }
        static var importTitleSuccess: String { "Import Successful".localized }
        static var exportTitleFailed: String { "Export Failed".localized }
        static var importTitleFailed: String { "Import Failed".localized }
        static var resetTitleSuccess: String { "Reset Successful".localized }
    }

    enum CustomAssetsAlert {
        static var successTitle: String { return "Success!".localized }
        static var failedTitle: String { return "Failed!".localized }
        static var successMessage: String { return "Assets imported successfully!".localized }
        static var failedMessage: String { return "Failed to import asset.".localized }
    }

    enum PreferencesDescription {
        static var locationOrder: String { return "Arrange locations alphabetically, geographically, or by latency.".localized }
        static var displayLatency: String { return "Display latency as signal strength bars or in milliseconds.".localized }
        static var language: String { return "Localize Windscribe to supported languages.".localized }
        static var background: String { return "Customize the background of the main app screen.".localized }
        static var notificationStats: String { return "Set up push notifications to receive connection updates in case of an interruption".localized }
        static var locationLoad: String { return "Display a location’s load. Smaller circle arc mean lesser load (usage).".localized }
        static var hapticFeedback: String { return "Vibrate the device based on user actions.".localized }
        static var customBackground: String { return "Use the app custom background instead of the locations flag.".localized }
    }

    enum LookFeel {
        static var title: String {
            return "Look & Feel".localized
        }

        static var appearanceTitle: String {
            "Appearance".localized
        }

        static var appBackgroundTitle: String {
            "App Background".localized
        }

        static var soundNotificationTitle: String {
            "Sound Notifications".localized
        }

        static var versionTitle: String {
            "Version".localized
        }

        static var appearanceDescription: String {
            "Light or Dark. Choose a side, and choose wisely.".localized
        }

        static var appBackgroundDescription: String {
            "Customize the background of the main app screen.".localized
        }

        static var soundNotificationDescription: String {
            "Choose sounds to play when connection events occur.".localized
        }

        static var aspectRatioModeTitle: String {
            "Aspect Ratio Mode".localized
        }

        static var connectedActionTitle: String {
            "When Connected".localized
        }

        static var disconnectedActionTitle: String {
            "When Disconnected".localized
        }

        static var noSelectedActionTitle: String {
            "no selected".localized
        }

        static var renameLocationsTitle: String {
            "Rename Locations".localized
        }

        static var renameLocationsDescription: String {
            "Change location names to your liking.".localized
        }

        static var exportActionTitle: String {
            "Export".localized
        }

        static var importActionTitle: String {
            "Import".localized
        }

        static var resetActionTitle: String {
            "Reset".localized
        }

        static func getValue(displayText: String) -> String? {
            switch displayText {
            case TextsAsset.appearances[0]:
                return Fields.Values.light
            case TextsAsset.appearances[1]:
                return Fields.Values.dark
            default:
                return nil
            }
        }
    }

    enum Account {
        static var title: String {
            return "Account".localized
        }

        static var plan: String {
            return "PLAN".localized
        }

        static var expiryDate: String {
            return "Expiry Date".localized
        }

        static var resetDate: String {
            return "Reset Date".localized
        }

        static var dataLeft: String {
            return "Data Left".localized
        }

        static var info: String {
            return "ACCOUNT INFO".localized
        }

        static var editAccount: String {
            return "Edit Account".localized
        }

        static var managerAccount: String {
            return "Manage Account".localized
        }

        static var addEmail: String {
            return "Add".localized
        }

        static var addEmailDescription: String {
            return "Get 10GB/Mo of data and gain the ability to reset a forgotten password.".localized
        }

        static var addEmailDescriptionPro: String {
            return "Gain the ability to reset a forgotten password.".localized
        }

        static var upgrade: String {
            return "Upgrade".localized
        }

        static var confirmYourEmail: String {
            return "Confirm Your Email".localized
        }

        static var resend: String {
            return "Resend".localized
        }

        static var ghostInfo: String {
            return "Sign up or login to view your account details and safeguard your preferences".localized
        }

        static var cancelAccount: String {
            return "Delete Account".localized
        }

        static var deleteAccountMessage: String {
            return "Enter your Windscribe password to delete your account. Please be aware this action cannot be undone.".localized
        }

        static var other: String {
            return "Other".localized
        }

        static var enterCode: String {
            return "Enter Code".localized
        }

        static var enterCodeHere: String {
            return "Enter code here".localized
        }

        static var enter: String {
            return "Enter".localized
        }

        static var lazyLogin: String {
            return "Lazy Login".localized
        }

        static var lazyLoginDescription: String {
            return "Login into Windscribe's TV apps with a short code".localized
        }

        static var lazyLoginSuccess: String {
            return "Sweet, you should be all good to go now"
        }

        static var voucherCodeDescription: String {
            return "Apply voucher code to your account".localized
        }

        static var voucherCodeSuccessful: String {
            return "Sweet, Voucher code is applied successfully".localized
        }

        static var voucherAlreadyMessage: String {
            return "Your account is already on the plan this code provides".localized
        }

        static var invalidVoucherCode: String {
            return "Voucher provided is invalid or expired.".localized
        }

        static var emailRequired: String {
            return "Confirmed email is required.".localized
        }

        static var freeAccountDescription: String {
            return "Free".localized
        }

        static var includeEmailDesciption: String {
            return "Add your Email to get 10 GB/Month of data and gain the ability to reset a forgotten password. No Spam".localized
        }

        static var addEmailActionTitle: String {
            "Add Email (Get 10 GB/Month)".localized
        }

        static var upgradeToProActionTitle: String {
            "Upgrade to Pro".localized
        }

        static var defaultDialogTitle: String {
            "Enter here".localized
        }

        static var defaultDialogMessage: String {
            "Enter your information".localized
        }

        static var voucherCodeTitle: String {
            "Voucher Code".localized
        }

        static var accountPasswordTitle: String {
            "Account Password".localized
        }

        static var loginCodeTitle: String {
            "Login Code".localized
        }
    }
    enum NetworkDetails {
        static var title: String {
            return "Network Details".localized
        }
    }

    enum NetworkSecurity {
        static var title: String {
            return "Network Security".localized
        }

        static var header: String {
            return "Windscribe will auto-disconnect when you join a network tagged \"Unsecured\".".localized
        }

        static var trusted: String {
            return "Secured".localized
        }

        static var untrusted: String {
            return "Unsecured".localized
        }

        static var forget: String {
            return "Forget".localized
        }

        static var currentNetwork: String {
            return "current network".localized
        }

        static var allNetwork: String {
            return "all networks".localized
        }

        static var unknownNetwork: String {
            return "Unknown Network".localized.uppercased()
        }
    }

    enum Debug {
        static var viewLog: String {
            return "View Debug Log".localized
        }

        static var sendLog: String {
            return "Send Debug Log".localized
        }

        static var sendingLog: String {
            return "Sending Log".localized
        }

        static var sentLog: String {
            return "Sent, Thanks!".localized
        }

        static var sendingAction: String {
            "Sending...".localized
        }

        static var sentStatus: String {
            "Sent".localized
        }

        static var retryAction: String {
            "Retry".localized
        }

    }

    static var noNetworksAvailable: String {
        return "NO INTERNET!".localized
    }
    static var cellular: String {
        return "Cellular".localized
    }

    static var wifi: String {
        return "Wi-fi".localized
    }

    static var noNetworkDetected: String {
        return "No Network Detected".localized
    }
    static var noInternetConnection: String {
        return "No Internet".localized
    }

    static var unknownNetworkName: String {
        return "unknown".localized
    }

    enum NewsFeed {
        static var title: String {
            return "News Feed".localized
        }
    }

    enum EnterEmail {
        static var headline: String {
            return "One last thing!".localized
        }

        static var description: String {
            return "Add your email address in case you forget your password. We’ll even give you 10GB for it.".localized
        }

        static var acceptButton: String {
            return "Add".localized
        }

        static var declineButton: String {
            return "No Thanks".localized
        }

        static var secureYourAccount: String {
            return "Secure your account".localized
        }
    }

    enum OutOfData {
        static var title: String {
            return "You’re out of data".localized
        }

        static var description: String {
            return "Upgrade now to stay protected or wait until your bandwidth is reset on ".localized
        }

        static var action: String {
            return "Upgrade".localized
        }

        static var cancel: String {
            return "I'll wait!".localized
        }
    }

    enum ProPlanExpired {
        static var title: String {
            return "Your Pro Plan expired!".localized
        }

        static var description: String {
            return "You’ve been downgraded to free for now".localized
        }

        static var action: String {
            return "Renew Plan".localized
        }

        static var cancel: String {
            return "Remind me later".localized
        }
    }

    enum Banned {
        static var title: String {
            return "You’ve been banned".localized
        }

        static var description: String {
            return "Your account has been disabled for violating our Terms of Service".localized
        }

        static var action: String {
            return "Done".localized
        }
    }

    enum FreeAccount {
        static var header: String {
            return "Unlock full access to Windscribe".localized
        }

        static var outOfDataHeader: String {
            return "You’re out of data".localized
        }

        static var body: String {
            return "Go Pro for unlimited everything".localized
        }
    }

    enum PushNotifications {
        static var title: String {
            return "Stay Protected".localized
        }

        static var description: String {
            return "Set up push notifications to receive connection updates in case of an interruption".localized
        }

        static var action: String {
            return "Turn Notification On".localized
        }
    }

    enum RestrictiveNetwork {
        static var title: String {
            return "Restrictive Network Detected".localized
        }

        static var description: String {
            return "You appear to be on a highly restritive network which is blocking Windscribe. Please us the \"Emergency Connect\" feature on the main screen and then try to signup or login again. If you're unsuccessful, please contact us.".localized
        }

        static var exportAction: String {
            return "Export Log".localized
        }

        static var supportContactsAction: String {
            return "Contact Support".localized
        }
    }

    enum UpgradeView {
        static var title: String {
            return "Plans".localized
        }

        static var pricing: String {
            return "Pricing".localized
        }

        static var benefits: String {
            return "Benefits".localized
        }

        static var continueFree10GB: String {
            return "Free 10GB/Mo".localized
        }

        static var unlimitedData: String {
            return "Unlimited Data".localized
        }

        static var unlimitedDataMessage: String {
            return "Pretty self explanatory. Use as much bandwidth as you'd like.".localized
        }

        static var allLocations: String {
            return "All Locations".localized
        }

        static var allLocationsMessage: String {
            return "Access to servers in over 60 countries and 110 data centers.".localized
        }

        static let robert = "R.O.B.E.R.T"
        static var robertMessage: String {
            return "Best malware and ad-blocker you will ever use. Seriously.".localized
        }

        static var choosePlan: String {
            return "Choose Plan".localized
        }

        static var year: String {
            return "Year".localized
        }

        static var month: String {
            return "Month".localized
        }

        static var months: String {
            return "Months".localized
        }

        static var oneMonth: String {
            return "1 Month Pro Subscription".localized
        }

        static var oneYear: String {
            return "1 Year Pro Subscription".localized
        }

        static var iAPDescription: String {
            return "Subscriptions will automatically renew unless canceled within 24-hours before the end of the current period. You can cancel anytime with your iTunes account settings. Any unused portion of a free trial will be forfeited if you purchase a subscription".localized
        }

        static var termsOfUse: String {
            return "Terms of Use".localized
        }

        static var privacyPolicy: String {
            return "Privacy Policy".localized
        }

        static var restorePurchases: String {
            return "Restore Purchases".localized
        }

        static var networkError: String {
            return "Error network.".localized
        }

        static var promoNotValid: String {
            return "Promo is not valid anymore.".localized
        }

        static var yearly: String {
            return "Yearly".localized
        }

        static var billedAnnually: String {
            return "Billed Annually".localized
        }

        static var monthly: String {
            return "Monthly".localized
        }

        static var billedMonthly: String {
            return "Billed Monthly".localized
        }

        static var subscribe: String {
            return "Subscribe".localized
        }

        static var details: String {
            return "Subscriptions may be managed monthly, yearly or turned off by going to the App Store Account Settings after purchase. All prices include applicable taxes.".localized
        }

        static var restore: String {
            return "Restore".localized
        }

        static var planBenefitUnlimitedTitle: String {
            return "Unlimited Everything".localized
        }

        static var planBenefitUnlimitedDescription: String {
            return "Use on all devices, with no data limits".localized
        }

        static var planBenefitAllLocationsTitle: String {
            return "All VPN Locations".localized
        }

        static var planBenefitAllLocationsDescription: String {
            return "Servers in 130 cities, more than any other VPN".localized
        }

        static var planBenefitSpeedSecurityTitle: String {
            return "Increased Speed and Security".localized
        }

        static var planBenefitSpeedSecurityDescription: String {
            return "Blocks 99.9% of malicious websites and trackers".localized
        }

        static var planBenefitUnableConnectAppStore: String {
            return "Unable to connect to app store services. Please try again.".localized
        }

        static var planBenefitSuccessfullPurchaseTitle: String {
            return "You're all set".localized
        }

        static var planBenefitSuccessfullPurchase: String {
            return "Your purchase is successful.".localized
        }

        static var planBenefitSuccessScreenTitle: String {
            return "Welcome to Windscribe Pro!".localized
        }

        static var planBenefitSuccessScreenDescription: String {
            return "Thanks for upgrading to Windscribe Pro! You now have access to even more powerful features.".localized
        }

        static var planBenefitSuccessShareTitle: String {
            return "Share".localized
        }

        static var planBenefitSuccessStartTitle: String {
            return "Start using Pro".localized
        }

        static var planBenefitTransactionFailedAlertTitle: String {
            return "Failed to complete transaction.".localized
        }

        static var planBenefitTransactionFailedAlert: String {
            return "Something went wrong. Please try another payment method or contact our customer support.".localized
        }

        static var planBenefitTransactionFailedRestoreTitle: String {
            return "Failed to restore transaction.".localized
        }

        static var planBenefitNetworkProblemTitle: String {
            return "Failed to load products. Check your internet connection and try again.".localized
        }

        static var planBenefitSuccessShareDevices: String {
            return "Set Up on All Your Devices".localized
        }

        static var planBenefitSuccessShareLocation: String {
            return "Connect to Any Location".localized
        }

        static var planBenefitSuccessShareBandwidth: String {
            return "Unlimited Bandwidth".localized
        }

        static var planBenefitJoinDiscord: String {
            return "Join our Discord community".localized
        }

        static var planBenefitJoinReddit: String {
            return "Join our Reddit community".localized
        }

        static var planBenefitFindUsYoutube: String {
            return "Find us on YouTube".localized
        }

        static var planBenefitFollowUsX: String {
            return "Follow us on X".localized
        }
    }

    static var addStaticIP: String {
        return "Add Static IP".localized
    }

    static var addCustomConfig: String {
        return "Add Custom Config".localized
    }

    static var addCustomConfigDescription: String {
        return "Custom configs allow you to connect to any OpenVPN or Wireguard server. Just add a valid config file and it will appear in this tab.".localized
    }

    static var customConfigWithSameFileNameError: String {
        return "Custom config file with this name already exists".localized
    }

    enum Siri {
        static var connectToVPN: String {
            return "Connect to VPN".localized
        }

        static var disconnectVPN: String {
            return "Disconnect VPN".localized
        }

        static var showMyLocation: String {
            return "Show My Location".localized
        }
    }

    enum RateUs {
        static var title: String {
            return "Rate Us!".localized
        }

        static var description: String {
            return "Are you enjoying Windscribe? Sure you are. Rate us in the App store and we’ll love you long time.".localized
        }

        static var action: String {
            return "Rate Windscribe".localized
        }

        static var maybeLater: String {
            return "Maybe Later".localized
        }

        static var goAway: String {
            return "Go Away".localized
        }
    }

    static var orderPreferences: [String] {
        return ["Geography".localized, "Alphabet".localized, "Latency".localized]
    }

    static let openVPN = "OpenVPN"
    static let iKEv2 = "IKEv2"
    static let wireGuard = "WireGuard"
    static var appearances: [String] {
        return ["Light".localized, "Dark".localized]
    }
    static var lightAppearance: String {
        "Light".localized
    }

    static var connectionModes: [String] {
        [TextsAsset.General.auto, TextsAsset.General.manual]
    }

    static var connectedDNSOptions: [String] {
        [TextsAsset.General.auto, TextsAsset.General.custom]
    }

     enum Favorites {
        static var removeTitle: String {
            return "Are you sure?".localized
        }

        static var removeMessage: String {
            return "Removing this location from favourites will make it feel sad.".localized
        }

        static var noFavorites: String {
            return "No Favourites".localized
        }
    }

    enum TrustedNetworkPopup {
        static var title: String {
            return "This network is unsecured".localized
        }

        static var message: String {
            return "is unsecured, meaning you don't wish to use Windscribe while on this network".localized
        }

        static var action: String {
            return "Connect Anyway".localized
        }

        static var cancel: String {
            return "Cancel".localized
        }
    }

    static var remove: String {
        return "Remove".localized
    }

    static var cancel: String {
        return "Cancel".localized
    }

    enum RestartAppAlert {
        static var title: String {
            return "This action requires a restart".localized
        }

        static var message: String {
            return "Please restart Windscribe to continue using in the preferred language.".localized
        }

        static var action: String {
            return "Close App".localized
        }
    }

    static var refreshLatency: String {
        return "Refresh latency".localized
    }

    static var disconnectToRefreshLatency: String {
        return "Disconnect to refresh latency".localized
    }

    static var iKEv2RemoteIDTest: String {
        return "IKEv2 RemoteID Test".localized
    }

    static var iKEv2RemoteIDTestDescription: String {
        return "Only enable this for testing.".localized
    }

    static var disconnecting: String {
        return "Disconnecting".localized
    }

    static var firewall: String {
        return "Firewall".localized
    }

    static var firewallDescription: String {
        return "This turns on the on-demand mode.".localized
    }

    static var configuredLocation: String {
        return "Custom Config".localized
    }

    static var configTitle: String {
        return "Config Title".localized
    }

    enum RemoveCustomConfig {
        static var title: String {
            return "Are you sure?".localized
        }

        static var message: String {
            return "This custom configuration will be gone forever.".localized
        }
    }

    enum EnterCredentialsAlert {
        static var title: String {
            return "Enter Credentials".localized
        }

        static var message: String {
            return "Enter the username and password associated with this custom config".localized
        }

        static var saveCredentials: String {
            return "Save credentials?".localized
        }
    }

    enum EditCredentialsAlert {
        static var title: String {
            return "Edit Credentials".localized
        }
    }

    static var connect: String {
        return "Connect".localized
    }

    static var save: String {
        return "Save".localized
    }

    enum FileNotInCorrectFormat {
        static var title: String {
            return "Incorrect File Format".localized
        }

        static var message: String {
            return "Something went wrong. Please make sure you have the correct OpenVPN configurations.".localized
        }
    }

    enum ConfigFileNotSupported {
        static var title: String {
            return "Config file is not supported".localized
        }

        static var message: String {
            return "Your configuration contains unsupported directives.".localized
        }
    }

    static var delete: String {
        return "Delete".localized
    }

    enum PrivacyView {
        static var title: String {
            return "Your Privacy Is Important".localized
        }

        static var description: String {
            return """
            Data Collection Notice

            We respect your privacy and are committed to keeping your data secure. Here’s how we handle your information:

            - When You Sign Up: We only collect a username and password for account creation. You may optionally provide an email address for password recovery and service updates. Payment information is handled by third-party processors; we only retain the transaction ID for 30 days to prevent fraud.

            - When You Use Our Service: We track the total amount of data you transfer and the timestamp of your last activity to enforce service limits and prevent abuse. We do not store any records of your VPN sessions, source IP, or browsing history.

            - When You Are Connected: During your connection, temporary data such as your VPN username and connection time is stored in memory but is discarded immediately after disconnection. We keep a count of parallel connections and your total data usage over 30 days.

            What We Don’t Do:
            - We do not log or share your browsing history.
            - We do not store any unnecessary data.

            Your information is never shared with third parties, and any data requests would yield minimal information due to our minimal logging practices.

            By proceeding, you agree to the collection and use of your data as described above.
            """
        }

        static var firstLine: String {
            return "Account data: username, email (if you gave us one), and payment transaction IDs (if you gave us money)".localized
        }

        static var secondLine: String {
            return "Metadata needed to ensure quality of service: bandwidth used in a 30 day period, number of parallel connections".localized
        }

        static var action: String {
            return "I'm OK With This".localized
        }
    }

    enum AskToRetryPopup {
        static var title: String {
            return "Unable to connect".localized
        }

        static var message: String {
            return "We're unable to connect you via $proto_name protocol. Your network may have unstable Internet connectivity or is blocking VPNs. Let's try another protocol.".localized
        }

        static func messageWithProtocol(protocolType: String) -> String {
            return "We're unable to connect you via \(protocolType) protocol. Your network may have unstable Internet connectivity or is blocking VPNs. Let's try another protocol.".localized
        }
    }

    enum AutoModeFailedToConnectPopup {
        static var title: String {
            return "This network hates us".localized
        }

        static var message: String {
            return "Well we gave it our best shot, we just couldn’t connect you on this network for some reason.".localized
        }

        static var sendDebugLog: String {
            return "Send Debug Log".localized
        }

        static var contactSupport: String {
            return "Contact Support".localized
        }
    }

    // swiftlint:disable inclusive_language
    enum Whitelist {
        static var title: String {
            return "Auto-Secure".localized
        }

        static var description: String {
            return "When you connect to this network, Windscribe will auto-connect to the last chosen location.".localized
        }
    }

    // swiftlint:enable inclusive_language

    enum PreferredProtocol {
        static var title: String {
            return "Preferred Protocol".localized
        }

        static var description: String {
            return "Choose the best protocol for this network. This overrides all global connection settings.".localized
        }

        static var newDescription: String {
            return "Windscribe will always use this protocol to connect for this network. This overrides global connection preferences.".localized
        }
    }

    static var forgetNetwork: String {
        return "Forget Network".localized
    }

    static var autoModeSelectorInfo: String {
        return "Next up in".localized
    }

    enum SetPreferredProtocolPopup {
        static func title(protocolType: String) -> String {
            let firstPart = "Set".localized
            let lastPart = "as preferred protocol?".localized
            return "\(firstPart) \(protocolType) \(lastPart)"
        }

        static var message: String {
            return "Windscribe will keep using the chosen protocol on this network, regardless of your global connection settings.".localized
        }

        static var action: String {
            return "Set as Preferred".localized
        }

        static var cancel: String {
            return "Keep it automatic".localized
        }

        static var dontAskAgain: String {
            return "Don't ask again".localized
        }

        static var changeMessage: String {
            return "Windscribe will always use this protocol to connect on this network in the future to avoid any interruptions.".localized
        }

        static var failMessage: String {
            return "We couldn’t connect you on this network. Send us your debug log so we can figure out what happened.".localized
        }

        static var failHeaderString: String { return "This network hates us".localized }
    }

    static var back: String {
        return "Back".localized
    }

    enum ShakeForData {
        static var title: String {
            return "Shake for Data".localized
        }

        static var shakes: String {
            return "Shakes".localized
        }

        static var quit: String {
            return "I Quit".localized
        }

        static var leave: String {
            return "Leave".localized
        }

        static var claimPrize: String {
            return "Claim Prize".localized
        }

        static var tryAgain: String {
            return "Try Again".localized
        }

        static var notBad: String {
            return "Not Bad!".localized
        }

        static var lowerThanHighScoreMessage: String {
            return "Not Bad!".localized
        }

        static var popupTitle: String {
            return "Shake for Data!".localized
        }

        static var popupDescription: String {
            return "Shake your phone as much as you can before the time runs out and win!".localized
        }

        static var popupAction: String {
            return "Start Shaking".localized
        }

        static var popupCancel: String {
            return "I hate free stuff".localized
        }

        static var popupViewLeaderboard: String {
            return "View Leaderboard".localized
        }

        static var highScore: String {
            return "High Score:".localized
        }

        static var newHighScore: String {
            return "New High Score!".localized
        }

        static var leaveAlertTitle: String {
            return "Unlock Shake For Data".localized
        }

        static var leaveAlertDescription: String {
            return "Unlock access to this feature? It will show up in Preferences.".localized
        }

        static var leaveAlertUnlock: String {
            return "Unlock".localized
        }

        static var leaveAlertLeave: String {
            return "Just Leave".localized
        }

        static var play: String {
            return "Play".localized
        }
    }

    enum NoEmailPrompt {
        static var title: String {
            return "Without an email, your free account will be limited to 2GB/Mo and you won’t be able to reset your password.".localized
        }

        static var titlePro: String {
            return "You won’t be able to reset a password without an email or receive any service updates from us.".localized
        }

        static var action: String {
            return "Continue without email".localized
        }
    }

    enum SetupLaterPrompt {
        static var title: String {
            return "Failure to setup account will prevent access in case you’re logged out.".localized
        }

        static var action: String {
            return "Setup later".localized
        }
    }

    enum Powers {
        static var first: String {
            return "Servers in over 100 locations".localized
        }

        static var second: String {
            return "Automatically secure any network".localized
        }

        static var third: String {
            return "Strict No-Logging Policy".localized
        }

        static var fourth: String {
            return "Works with Siri, Shortcuts & Widgets".localized
        }
    }

    static var searchLocations: String {
        return "Search Locations".localized
    }

    static var clearSearch: String {
        return "Clear".localized
    }

    enum EmailView {
        static var confirmEmail: String {
            return "Confirm Email".localized
        }

        static var info: String {
            return "Please confirm your email to get 10GB/Mo".localized
        }

        static var infoPro: String {
            return "Please confirm your email".localized
        }

        static var resendEmail: String {
            return "Resend Verification Email".localized
        }

        static var changeEmail: String {
            return "Change Email".localized
        }

        static var close: String {
            return "Close".localized
        }
    }

    static var twoFactorRequiredError: String {
        return "2FA code is required".localized
    }

    static var twoFactorInvalidError: String {
        return "Invalid 2FA code, please try again.".localized
    }

    static var unknownAPIError: String {
        return "Unknown API error".localized
    }

    static var loginCodeExpired: String {
        return "Login code expired. Please try again.".localized
    }

    static var cantGetConnectedWifi: String {
        return "Problem occured while detecting the connected network on your device.".localized
    }

    static var restartApp: String {
        return "Restart App".localized
    }

    static var tryAgain: String {
        return "Try Again".localized
    }

    enum Refer {
        static var shareWindscribeWithFriend: String {
            return "Share Windscribe with a friend!".localized
        }

        static var getAdditionalPerMonth: String {
            return "You will both get an additional 1GB per month when they sign up.".localized
        }

        static var goProTo: String {
            return "If they go Pro, you’ll go Pro too!".localized
        }

        static var shareInviteLink: String {
            return "Share Invite Link".localized
        }

        static var refereeMustProvideUsername: String {
            return "Referee must provide your username at sign up and confirm their email in order for the benefits above to apply to your account.".localized
        }

        static var inviteMessage: String {
            return "is inviting you to join Windscribe. Provide their username at signup and you’ll both get 1gb of free data added to your accounts. If you go pro, they’ll go pro too!".localized
        }

        static var usernamePlaceholder: String {
            return "User".localized
        }
    }

    static var emergencyConnect: String {
        return "Emergency Connect".localized
    }

    static var eConnectDescription: String {
        return "Can’t access Windscribe? Connect to our servers to unblock your restrictive network.".localized
    }

    static var connecting: String {
        return "Connecting".localized
    }

    static var disconnect: String {
        return "Disconnect".localized
    }

    static var connectedDescription: String {
        return "You are now connected to Windscribe server. Try to login again.".localized
    }

    enum MaintenanceLocationPopUp {
        static var title: String {
            return "This Location is Under Maintenance".localized
        }

        static var subtHeader: String {
            return "Try again later or go to our Status page for more info".localized
        }

        static var checkStatus: String {
            return "Check status".localized
        }

        static var cancelTitle: String {
            return "Back".localized
        }
    }

    enum Help {
        static var helpMe: String {
            return "Help Me!".localized
        }

        static var knowledgeBase: String {
            return "Knowledge Base".localized
        }

        static var allYouNeedToknowIsHere: String {
            return "All you need to know about Windscribe.".localized
        }

        static var talkToGarry: String {
            return "Talk to Garry".localized
        }

        static var notAsSmartAsSiri: String {
            return "Need help? Garry can help you with most issues, go talk to him.".localized
        }

        static var sendTicket: String {
            return "Contact Humans".localized
        }

        static var sendUsATicket: String {
            return "Have a problem that Garry can't resolve? Contact human support".localized
        }

        static var communitySupport: String {
            return "Community Support".localized
        }

        static var bestPlacesTohelp: String {
            return "Best places to help and get help from other users.".localized
        }

        static var reddit: String {
            return "Reddit".localized
        }

        static var discord: String {
            return "Discord".localized
        }

        static var advanceParamDescription: String {
            return "Make advanced tweaks to the way the app functions".localized
        }
    }

    enum About {
        static var title: String {
            return "About".localized
        }

        static var status: String {
            return "Status".localized
        }

        static var aboutUs: String {
            return "About us".localized
        }

        static var privacyPolicy: String {
            return "Privacy Policy".localized
        }

        static var terms: String {
            return "Terms".localized
        }

        static var blog: String {
            return "Blog".localized
        }

        static var jobs: String {
            return "Jobs".localized
        }

        static var softwareLicenses: String {
            return "Software Licenses".localized
        }

        static var changelog: String {
            return "Changelog".localized
        }
    }

    enum SubmitTicket {
        static var submitTicket: String {
            return "Send Ticket".localized
        }

        static var fillInTheFields: String {
            return "Fill in the fields bellow and one of our support agents will personally get back to you very soon™".localized
        }

        static var category: String {
            return "Category".localized
        }

        static var email: String {
            return "Email".localized
        }

        static var enterEmail: String {
            return "Enter email".localized
        }

        static var required: String {
            return "Required".localized
        }

        static var soWeCanContactYou: String {
            return "So we can contact you, we won’t use it for anything else".localized
        }

        static var subject: String {
            return "Subject".localized
        }

        static var enterSubject: String {
            return "Enter subject".localized
        }

        static var whatsTheMatter: String {
            return "What’s the matter?".localized
        }

        static var tellUs: String {
            return "Tell us what’s wrong".localized
        }

        static var message: String {
            return "Message".localized
        }

        static var `continue`: String {
            return "Continue".localized
        }

        static var acount: String {
            return "Account".localized
        }

        static var sales: String {
            return "Sales".localized
        }

        static var technical: String {
            return "Technical".localized
        }

        static var feedback: String {
            return "Feedback".localized
        }

        static var categories = [acount, technical, sales, feedback]

        static var categoryValues = [acount: 1, technical: 2, sales: 3, feedback: 4]

        static var weWillGetBackToYou: String {
            return "Sweet, we’ll get back to you as soon as one of our agents is back from lunch.".localized
        }

        static var failedToSendTicket: String {
            return "Failed to send support ticket. Please check your network and try again.".localized
        }
    }

    enum Welcome {
        static var tabInfo1: String {
            return "Servers in over 69 countries and 134 cities.".localized
        }

        static var tabInfo2: String {
            return "Automatically Secure any Network".localized
        }

        static var tabInfo3: String {
            return "No-Logging Policy".localized
        }

        static var tabInfo4: String {
            return "Works with Siri, Shortcuts & Widgets".localized
        }

        static var signup: String {
            return "Sign Up".localized
        }

        static var login: String {
            return "Login".localized
        }

        static var connectionFault: String {
            return "Can't Connect?".localized
        }

        static var emergencyConnectOn: String {
            return "Emergency Connect On".localized
        }

        static var continueWithGoogle: String {
            return "Continue with Google".localized
        }
        static var continueWithApple: String {
            return "Continue with Apple".localized

        }
        static var ssoErrorAppleTitle: String {
            return "Apple Sign-In Unsuccesful"
        }
    }

    enum Authentication {
        static var username: String {
            return "Username".localized
        }

        static var enterUsername: String {
            return "Enter username".localized
        }

        static var password: String {
            return "Password".localized
        }

        static var enterPassword: String {
            return "Enter password".localized
        }

        static var twoFactorCode: String {
            return "2FA code".localized
        }

        static var twoFactorDescription: String {
            return "If enabled, use an authentication app to generate the code.".localized
        }

        static var forgotPassword: String {
            return "Forgot password?".localized
        }

        static var enterEmailAddress: String {
            return "Enter email".localized
        }

        static var enterVoucherCode: String {
            return "Enter voucher code".localized
        }

        static var done: String {
            return "Done".localized
        }

        static var appleLoginCanceled: String {
            return "Apple login canceled".localized
        }

        static var appleLoginFailed: String {
            return "Unable to obtain Apple identity token.".localized
        }

        static var captchaDescription: String {
            return "Complete Puzzle \n to continue".localized
        }

        static var captchaSliderDescription: String {
            return "Drag left puzzle piece into place".localized
        }

        static var tokenRetrievalFailed: String {
            return "Authentication Token retrieval failed.".localized
        }

        static var captchaImageDecodingFailed: String {
            return "Captcha image decoding failed. Please try again later.".localized
        }
    }
}

extension TextsAsset {
    enum TVAsset {
        static var loginCodeError: String {
            return "Unable to generate Login code. Check you network connection.".localized
        }

        static var addToFav: String {
            return "Add to fav".localized
        }

        static var removeFromFav: String {
            return "Remove from fav".localized
        }

        static var favTitle: String {
            return "Favourites".localized
        }

        static var staticIPTitle: String {
            return "Static IP".localized
        }

        static var allTitle: String {
            return "All".localized
        }

        static var welcomeDescription: String {
            return "If you already have an account.".localized
        }

        static var lazyLogin: String {
            return "Lazy Login".localized
        }

        static var lazyLoginDescription: String {
            return "Go to https://windscribe.com/lazy on any device and enter the code below.".localized
        }

        static var or: String {
            return "OR".localized
        }

        static var lazyLoginDescription2: String {
            return "Using your Windscribe iOS app on your phone or iPad, go to Preferences (Top left),\n under \"Account\" choose \"Lazy Login\" and enter the code below.".localized
        }

        static var generateCode: String {
            return "Generate Code".localized.uppercased()
        }

        static var manualLogin: String {
            return "Manual Login".localized
        }

        static var forgotPasswordInfo: String {
            return "Please visit windscribe.com to reset your password".localized
        }

        static var twofaDescription: String {
            return "2FA require to proceed.\nUse an authentication\napp to generate the code.".localized
        }

        static var locationMaintenanceDescription: String {
            return "This Location is Under Maintenance. Try again later or go to our Status page for more info. https://windscribe.com/status"
        }

        static var locationMaintenanceTitle: String {
            return "Location Maintenance"
        }

        static var supportTitle: String {
            return "Support".localized
        }

        static var supportBody: String {
            return "Go to the address above on your phone or computer for all support related inquiries.".localized
        }
    }
}

// swiftlint:enable type_body_length
