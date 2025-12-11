//
//  ServerListTableViewDataSource+Delegate.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-31.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import ExpyTableView
import UIKit
import Combine

protocol ServerListTableViewDelegate: AnyObject {
    func setSelectedServerAndGroup(server: ServerModel, group: GroupModel)
    func reloadServerListTableView()
    func connectToBestLocation()
    func handleRefresh()
    func tableViewScrolled(toTop: Bool)
}

protocol ServerListTableViewDataSource: WExpyTableViewDataSource,
                                        ExpyTableViewDataSource,
                                        WExpyTableViewDataSourceDelegate,
                                        WTableViewDataSourceDelegate {
    var delegate: ServerListTableViewDelegate? { get set }
    var scrollHappened: Bool { get set }

    var serverSections: [ServerSection] { get }

    func updateServerList(with serverSections: [ServerSection])
    func updateShouldColapse(with value: Bool)
    func clearBestLocation()
    func refreshBestLocation()
}

class ServerListTableViewDataSourceImpl: WExpyTableViewDataSource,
                                         ServerListTableViewDataSource {

    weak var delegate: ServerListTableViewDelegate?
    var serverSections: [ServerSection] = []
    var scrollHappened = false

    private var shouldColapse: Bool = false
    private var cancellables = Set<AnyCancellable>()
    private var favList: [Favourite] = []
    private var locationLoad: Bool = false
    private var bestLocation: BestLocationModel? = nil

    private let locationsManager: LocationsManager
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let hapticFeedbackManager: HapticFeedbackManager
    private let preferences: Preferences
    private let userSessionRepository: UserSessionRepository
    private let latencyRepository: LatencyRepository
    private let languageManager: LanguageManager

    let localDatabase: LocalDatabase

    init(locationsManager: LocationsManager,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         preferences: Preferences,
         localDatabase: LocalDatabase,
         userSessionRepository: UserSessionRepository,
         latencyRepository: LatencyRepository,
         languageManager: LanguageManager) {
        self.locationsManager = locationsManager
        self.lookAndFeelRepository = lookAndFeelRepository
        self.hapticFeedbackManager = hapticFeedbackManager
        self.preferences = preferences
        self.localDatabase = localDatabase
        self.userSessionRepository = userSessionRepository
        self.latencyRepository = latencyRepository
        self.languageManager = languageManager
        super.init()

        scrollViewDelegate = self
        expyDelegate = self

        updateBestlocation(with: locationsManager.getBestLocationModel())

        bind()
    }

    private func bind() {
        self.lookAndFeelRepository.isDarkModeSubject
            .sink {[weak self] _ in
                self?.delegate?.reloadServerListTableView()
            }
            .store(in: &cancellables)

        self.languageManager.activelanguage
            .sink {[weak self] _ in
                self?.delegate?.reloadServerListTableView()
            }
            .store(in: &cancellables)

        preferences.getShowServerHealth()
            .sink {[weak self] locationLoad in
                self?.locationLoad = locationLoad ?? DefaultValues.showServerHealth
                self?.delegate?.reloadServerListTableView()
            }
            .store(in: &cancellables)

        localDatabase.getFavouriteListObservable()
            .toPublisherIncludingEmpty()
            .replaceError(with: [])
            .sink {[weak self] _ in
                self?.delegate?.reloadServerListTableView()
                self?.favList = self?.localDatabase.getFavouriteList() ?? []
            }
            .store(in: &cancellables)

        userSessionRepository.sessionModelSubject
            .sink {[weak self] _ in
                self?.delegate?.reloadServerListTableView()
            }
            .store(in: &cancellables)

        locationsManager.bestLocationUpdated
            .sink { [weak self] _ in
                self?.refreshBestLocation()
            }.store(in: &cancellables)
    }

    func clearBestLocation() {
        updateBestlocation(with: nil)
    }

    func refreshBestLocation() {
        updateBestlocation(with: locationsManager.getBestLocationModel())
    }

    private func updateBestlocation(with value: BestLocationModel?) {
        bestLocation = value
        if bestLocation != nil,
           serverSections.first?.server?.name != Fields.Values.bestLocation,
           let groupId = bestLocation?.groupId,
           let serverModel = getServerModel(from: groupId) {
            let bestLocationServer = ServerModel(name: Fields.Values.bestLocation, serverModel: serverModel)
            serverSections.insert(ServerSection(server: bestLocationServer, collapsed: true), at: 0)
        }
        delegate?.reloadServerListTableView()
    }

    func updateServerList(with serverSections: [ServerSection]) {
        self.serverSections = serverSections.map {
            if shouldColapse, let server = $0.server {
                return ServerSection(server: server, collapsed: true)
            }
            return $0
        }
        delegate?.reloadServerListTableView()
    }

    func updateShouldColapse(with value: Bool) {
        shouldColapse = value
        updateServerList(with: serverSections)
    }

    func numberOfSections(in _: UITableView) -> Int {
        if bestLocation != nil,
           serverSections.first?.server?.name != Fields.Values.bestLocation,
           let groupId = bestLocation?.groupId,
           let serverModel = getServerModel(from: groupId) {
            let bestLocationServer = ServerModel(name: Fields.Values.bestLocation, serverModel: serverModel)
            serverSections.insert(ServerSection(server: bestLocationServer, collapsed: true), at: 0)
        }
        return serverSections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && bestLocation != nil { return 1 }
        if serverSections.indices.contains(section) {
            guard let count = serverSections[section].server?.groups.count else { return 0 }
            return count + 1
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ReuseIdentifiers.nodeCellReuseIdentifier, for: indexPath) as? NodeTableViewCell
        ?? NodeTableViewCell(style: .default, reuseIdentifier: ReuseIdentifiers.nodeCellReuseIdentifier)
        if (serverSections.count > indexPath.section) && ((serverSections[indexPath.section].server?.groups.count ?? 0) > indexPath.row - 1) {
            let group = serverSections[indexPath.section].server?.groups[indexPath.row - 1]

            var latency = -1
            if let group = group {
                latency = latencyRepository.getPingData(ip: group.pingIp)?.latency ?? latency
            }

            if cell.nodeCellViewModel == nil {
                cell.nodeCellViewModel = NodeTableViewCellModel()
                cell.nodeCellViewModel?.delegate = self
            }
            cell.nodeCellViewModel?.update(displayingGroup: group,
                                           locationLoad: locationLoad,
                                           isSavedHasFav: isGroupFavorite(group?.id),
                                           isUserPro: userSessionRepository.sessionModel?.isUserPro ?? false,
                                           isPremium: userSessionRepository.sessionModel?.isPremium ?? false,
                                           isDarkMode: lookAndFeelRepository.isDarkMode,
                                           latency: latency)
            cell.refreshUI()
        }
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && bestLocation != nil {
            delegate?.connectToBestLocation()
        }
        if indexPath.row == 0 { return }
        guard let server = serverSections[indexPath.section].server else { return }
        let group = server.groups[indexPath.row - 1]
        delegate?.setSelectedServerAndGroup(server: server, group: group)
    }

    func tableView(_ tableView: ExpyTableView, expandableCellForSection section: Int) -> UITableViewCell {
        if section == 0 && bestLocation != nil {
            let bestLocationCell = tableView.dequeueReusableCell(
                withIdentifier: ReuseIdentifiers.bestLocationCellReuseIdentifier)! as? BestLocationCell
            ?? BestLocationCell(
                style: .default,
                reuseIdentifier: ReuseIdentifiers.bestLocationCellReuseIdentifier)
            if bestLocationCell.bestCellViewModel == nil {
                bestLocationCell.bestCellViewModel = BestLocationCellModel()
            }
            bestLocationCell.bestCellViewModel?.update(bestLocationModel: bestLocation,
                                                       locationLoad: locationLoad,
                                                       isDarkMode: lookAndFeelRepository.isDarkMode)
            bestLocationCell.refreshUI()
            return bestLocationCell
        } else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ReuseIdentifiers.serverSectionCellReuseIdentifier)! as? ServerSectionCell
            ?? ServerSectionCell(
                style: .default,
                reuseIdentifier: ReuseIdentifiers.serverSectionCellReuseIdentifier)
            if cell.serverCellViewModel == nil {
                cell.serverCellViewModel = ServerSectionCellModel()
            }

            if let expanded = tableView.expandedSections[section] {
                serverSections[section].collapsed = !expanded
            }
            if serverSections.count > 0 {
                cell.serverCellViewModel?.update(serverModel: serverSections[section].server,
                                                 locationLoad: locationLoad,
                                                 isPremium: userSessionRepository.sessionModel?.isPremium ?? false,
                                                 isDarkMode: lookAndFeelRepository.isDarkMode)
                cell.setCollapsed(collapsed: serverSections[section].collapsed)
                cell.refreshUI()
            }
            return cell
        }
    }

    func tableView(_: UITableView,  heightForRowAt _: IndexPath) -> CGFloat {
        return 48
    }

    func changeForSection(tableView: UITableView, state: ExpyState, section: Int) {
        guard let cell = tableView.cellForRow(at: IndexPath(item: 0, section: section)) as? ServerSectionCell else { return }
        switch state {
        case .willExpand:
            serverSections[section].collapsed = false
            cell.expand()
        case .willCollapse:
            serverSections[section].collapsed = true
            cell.collapse()
        default:
            return
        }
    }

    func handleRefresh() {
        delegate?.handleRefresh()
    }

    func tableViewScrolled(toTop: Bool) {
        delegate?.tableViewScrolled(toTop: toTop)
    }

    override func scrollViewWillBeginDragging(_: UIScrollView) {
        scrollHappened = true
    }

    func tableView(_: UITableView, willDisplay _: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == 0 && scrollHappened {
            hapticFeedbackManager.run(level: .light)
        }
    }

    func tableView(_ tableView: ExpyTableView, canExpandSection section: Int) -> Bool {
        true
    }

    private func getServerModel(from groupId: Int) -> ServerModel? {
        try? locationsManager.getLocation(from: String(groupId)).0
    }

    private func isGroupFavorite(_ groupId: Int?) -> Bool {
        guard let groupId = groupId else { return false }
        return favList.filter { !$0.isInvalidated }
            .map { $0.id }
            .contains(String(groupId))
    }
}

extension ServerListTableViewDataSourceImpl: NodeTableViewCellModelDelegate {
    func saveAsFavorite(groupId: String) {
        Task {
            localDatabase.saveFavourite(favourite: Favourite(id: "\(groupId)"))
        }
    }

    func removeFavorite(groupId: String) {
        let yesAction = UIAlertAction(title: TextsAsset.remove, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.localDatabase.removeFavourite(groupId: "\(groupId)")
            }
        }
        AlertManager.shared.showAlert(title: TextsAsset.Favorites.removeTitle,
                                      message: TextsAsset.Favorites.removeMessage,
                                      buttonText: TextsAsset.cancel, actions: [yesAction])
    }
}
