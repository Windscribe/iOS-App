//
//  UIConstants+ImagesAsset.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation

enum ImagesAsset {
    static let logoOnLogin = "logo-login"
    static let logoText = "logo-text"
    static let failExIcon = "fail-ex"
    static let rightArrow = "right-arrow"
    static let backArrow = "back-arrow"
    static let upArrow = "small-white-up-arrow"
    static let downArrow = "small-white-down-arrow"
    static let loginInActive = "login-inactive"
    static let loginActive = "login-active"
    static let connectButton = "connect-button"
    static let connectionSpinner = "connection-spinner"
    static let disconnectedButton = "disconnected-button"
    static let connectButtonRing = "connect-button-ring"
    static let connectingButtonRing = "connecting-button-ring"
    static let failedConnectionButtonRing = "failed-connection-button-ring"
    static let secure = "secure"
    static let unsecure = "unsecure"
    static let wifi = "wifi"
    static let wifiUnsecure = "wifi-unsecure"
    static let expandHome = "expand-home"
    static let expandHomeUp = "expand-home-up"
    static let smallWhiteRightArrow = "small-white-right-arrow"
    static let mainLogo = "main-logo"
    static let notifications = "notifications"
    static let cellExpand = "cell-expand"
    static let p2p = "p2p"
    static let p2pWhite = "p2p-white"
    static let whiteExpand = "white-expand"
    static let topNavWhite = "top-nav-white"
    static let topNavWhiteSliced = "top-nav-white-sliced"
    static let topNavBlack = "top-nav-black"
    static let topNavBlackSliced = "top-nav-black-sliced"
    static let topNavWhiteForNotch = "top-nav-white-for-notch"
    static let topNavBlackForNotch = "top-nav-black-for-notch"
    static let topNavBarMenu = "top-nav-bar-menu"
    static let favEmpty = "fav-empty"
    static let favFull = "fav-full"
    static let nodeBars = "node-bars-full"
    static let staticIPdc = "static-ip-dc"
    static let staticIPres = "static-ip-res"
    static let brokenHeart = "broken-heart"
    static let proServerIcon = "pro-server"
    static let proNodeIcon = "pro-node"
    static let prefRightIcon = "pref-right-arrow"
    static let prefProIconGreen = "pref-pro-icon-green"
    static let prefProIconBlue = "pref-pro-icon-blue"
    static let prefProIconGrey = "white-pro-star"
    static let prefBackIcon = "pref-back"
    static let dropDownIcon = "dropdown-icon"
    static let closeIcon = "close-icon"
    static let newsIcon = "news-icon"
    static let enterCredentials = "enter-credentials"
    static let checkMark = "check-mark"
    static let powerCheckMark = "power-checkmark"
    static let pushNotifications = "push-notifications"
    static let whiteProStar = "white-pro-star"
    static let greenCheckMark = "green-check-mark"
    static let externalLink = "external-link"
    static let rateUs = "rate-us"
    static let confirmEmail = "confirm-email"
    static let noInternet = "no-internet"
    static let protocolFailed = "protocol-failed"
    static let tenGig = "ten-gig"
    static let windscribeHeart = "windscribe_ic_white"
    static let windscribeWarning = "windscribe_warning_ic_white"
    static let windscribeReload = "windscribe_reload_ic_white"
    static let checkCircleGreen = "check_circle_green"
    static let closeIconMidnight = "close_ico_midnight"
    static let connectedArrow = "connected_arrow"
    static let emergencyConnectIcon = "emergency-connect"
    static let circumventCensorship = "circumvent-censorship"
    static let customDns = "custom-dns"
    static let closeCross = "close-cross"
    static let locationDown = "location-down"
    static let attention = "attention"
    static let clear = "clear"
    static let search = "search"
    static let exitSearch = "exit-search"
    static let delete = "delete-black"
    static let edit = "edit-black"
    static let autoModeSelectorInfoIcon = "auto-mode-selector-info-icon"
    static let promptInfo = "prompt-info"
    static let upgradeInfo = "upgrade-info"
    static let showPassword = "show-password"
    static let hidePassword = "hide-password"
    static let getMoreDataBackground = "get-more-data-background"
    static let getMoreDataBackgroundSmall = "get-more-data-background-small"
    static let radioPriceNotSelected = "radio-price-notselected"
    static let radioPriceSelected = "radio-price-selected"
    static let warningBlack = "warning-black"
    static let preferredProtocolBadgeOff = "preferred-protocol-badge-off"
    static let preferredProtocolBadgeOn = "preferred-protocol-badge-on"
    static let rightArrowBold = "right-arrow-bold"
    static let preferredProtocolBadgeConnecting = "preferred-protocol-badge-connecting"
    static let customConfigIcon = "add-custom-config"
    static let learnMoreIcon = "learn-more-ic"

    enum Servers {
        static let all = "servers-all"
        static let fav = "servers-fav"
        static let flix = "servers-flix"
        static let staticIP = "servers-static-ip"
        static let config = "servers-config"
    }

    enum Preferences {
        static let general = "pref-general"
        static let account = "pref-account"
        static let robert = "pref-robert"
        static let networkSecurity = "pref-network-security"
        static let connection = "pref-connection"
        static let debug = "pref-debug"
        static let logOut = "pref-logout"
        static let helpMe = "pref-help-me"
        static let about = "about"
        static let logoutRed = "pref-logout-red"
        static let advanceParams = "advance-params"
    }

    enum ShakeForData {
        static let icon = "shake-for-data"
        static let arrowTopLeft = "arrow-top-left"
        static let arrowTopRight = "arrow-top-right"
        static let arrowBottomLeft = "arrow-bottom-left"
        static let arrowBottomRight = "arrow-bottom-right"
        static let dataTimer = "shake-for-data-timer"
    }

    enum Help {
        static let apple = "apple"
        static let garry = "garry"
        static let ticket = "ticket"
        static let community = "community"
        static let reddit = "Reddit"
        static let discord = "Discord"
        static let success = "success"
        static let debugView = "debug-view"
        static let debugSend = "debug-send"
    }

    enum Robert {
        static let filterIcons = ["malware": "malware", "ads": "ads", "social": "social",
                                  "porn": "porn", "gambling": "gambling", "fakenews": "fake-news",
                                  "competitors": "other-vpn", "cryptominers": "crypto"]
    }

    enum General {
        static let locationOrder = "location_order_ic_white"
        static let latencyDisplay = "latency_display_ic_white"
        static let language = "language_ic_white"
        static let appearance = "appearance_ic_white"
        static let appBackground = "app_background_ic_white"
        static let locationLoad = "location_load_ic_white"
        static let hapticFeedback = "haptic_feedback_ic_white"
        static let firewall = "firewall-ic-white"
        static let killSwitch = "kill-switch-white"
        static let allowLan = "allow-lan-white"
        static let autoConnection = "auto-connection-ic-white"
        static let connectionMode = "connection-mode-ic-white"
        static let autoSecure = "auto_secure"
        static let preferredProtocol = "preferred_protocol"
        static let autoSecureNew = "auto_secure_new"
    }

    enum SignalBars {
        static let connectedFull = "signal-bars-connected-full"
        static let connectedMedium = "signal-bars-connected-med"
        static let connectedLow = "signal-bars-connected-low"
        static let connectedNone = "signal-bars-connected-none"

        static let disconnectedNone = "signal-bars-disconnected-none"
    }

    enum CellSignalBars {
        static let low = "cell-signal-bars-connected-low"
        static let medium = "cell-signal-bars-connected-med"
        static let full = "cell-signal-bars-connected-full"
        static let down = "cell-signal-bars-down"
    }

    enum Garry {
        static let noData = "garry-no-data"
        static let sad = "garry-sad"
        static let angry = "garry-angry"
        static let con = "garry-con"
    }

    enum DarkMode {
        static let serversAll = "servers-all-white"
        static let serversFav = "servers-fav-white"
        static let serversFlix = "servers-flix-white"
        static let serversStaticIP = "servers-static-ip-white"
        static let serversConfig = "servers-config-white"

        static let brokenHeart = "broken-heart-white"
        static let proServerIcon = "pro-server-white"
        static let favEmpty = "fav-empty-white"
        static let favFull = "fav-full-white"

        static let cellSignalBarsLow = "cell-signal-bars-connected-low-white"
        static let cellSignalBarsMedium = "cell-signal-bars-connected-med-white"
        static let cellSignalBarsFull = "cell-signal-bars-connected-full-white"
        static let cellSignalBarsDown = "cell-signal-bars-down-white"

        static let proNodeIcon = "pro-node-white"
        static let locationDown = "location-down-white"
        static let staticIPdc = "static-ip-dc-white"
        static let staticIPres = "static-ip-res-white"
        static let externalLink = "external-link-white"
        static let delete = "delete-white"
        static let edit = "edit-white"
        static let clear = "clear-white"
        static let search = "search-white"
        static let exitSearch = "exit-search-white"
        static let dropDownIcon = "dropdown-icon-white"
        static let prefRightIcon = "pref-right-arrow-white"
        static let prefBackIcon = "pref-back-white"
        static let tenGig = "ten-gig-white"
        static let filterIcons = ["malware": "malware-white", "ads": "ads-white", "social": "social-white",
                                  "porn": "porn-white", "gambling": "gambling-white", "fakenews": "fake-news-white",
                                  "competitors": "other-vpn-white", "cryptominers": "crypto-white"]
    }

    enum SwitchButton {
        static let on = "switch-button-on"
        static let off = "switch-button-off"
        static let offBlack = "switch-button-off-black"
    }

    enum CheckMarkButton {
        static let on = "check-mark-on"
        static let off = "check-mark-off"
    }

    enum ProtocolBadges {
        static let iKEV2 = "badge-ikev2"
        static let udp = "badge-udp"
        static let tcp = "badge-tcp"
    }

    enum Subscriptions {
        static let glare = "subscription-button-glare"
        static let checkTerms = "subscription-checkbox-terms"
        static let heroGraphic = "subscription-hero-graphic"
        static let heroGrid = "subscription-hero-grid"
        static let heroStars = "subscription-hero-stars"
        static let heroStarsLarge = "subscription-hero-stars-large"
        static let proLogo = "subscription-pro-logo"
        static let successLogo = "subscription-success-logo"
        static let discordIcon = "share-discord-icon"
        static let redditIcon = "share-reddit-icon"
        static let xIcon = "share-x-icon"
        static let youtubeIcon = "share-youtube-icon"
    }

    enum Welcome {
        static let icon = "welcome-icon"
        static let background = "welcome-background"
        static let tabInfo1 = "welcome-info-tab-1"
        static let tabInfo2 = "welcome-info-tab-2"
        static let tabInfo3 = "welcome-info-tab-3"
        static let tabInfo4 = "welcome-info-tab-4"
    }

    enum TvAsset {
        static let settingsButton = "settingButton"
        static let notificationsIcon = "notifications_icon"
        static let helpIcon = "help_icon"
        static let helpIconFocused = "help_icon_focused"
        static let notificationIconFocused = "notification_icon_focused"
        static let settingsIconFocused = "settings_icon_focused"
        static let connectionButtonOff = "connectionButton_off"
        static let connectionButtonOn = "connectionButton_on"
        static let disconnectedRing = "disconnected_ring"
        static let staticIp = "static_ip"
        static let allIcon = "all_icon"
        static let favnavIcon = "favnav_icon"
        static let flixIcon = "flix_icon"
        static let connectIcon = "connect_icon"
        static let connectIconFocused = "connect_icon_focused"
        static let addFavIcon = "add_fav_icon"
        static let addFavIconFocused = "add_fav_icon_focused"
        static let removeFavIcon = "remove_fav_icon"
        static let removeFavIconFocused = "remove_fav_icon_focused"
        static let connectionButtonOffFocused = "connectionButtonOffFocused"
        static let connectionButtonOnFocused = "connectionButtonOnFocused"
        static let connectingRing = "connecting_ring"
        static let connectedRing = "connected_ring"
    }
}
