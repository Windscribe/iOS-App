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

    func updateServerList(with serverSections: [ServerSection], shouldColapse: Bool)
    func updateShouldColapse(with value: Bool)
    func setBestLocationVisibility(to visible: Bool)
}

class ServerListTableViewDataSourceImpl: WExpyTableViewDataSource,
                                         ServerListTableViewDataSource {

    weak var delegate: ServerListTableViewDelegate?
    var serverSections: [ServerSection] = []
    var scrollHappened = false

    private var shouldColapse: Bool = false
    private var cancellables = Set<AnyCancellable>()
    private var favList: [FavouriteModel] = []
    private var locationLoad: Bool = false
    private var bestLocationModel: BestLocationModel?
    private var bestLocationVisible: Bool = true

    private let locationsManager: LocationsManager
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let hapticFeedbackManager: HapticFeedbackManager
    private let preferences: Preferences
    private let userSessionRepository: UserSessionRepository
    private let latencyRepository: LatencyRepository
    private let languageManager: LanguageManager
    private let serverRepository: ServerRepository
    private let alertManager: AlertManager

    init(locationsManager: LocationsManager,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         preferences: Preferences,
         serverRepository: ServerRepository,
         userSessionRepository: UserSessionRepository,
         latencyRepository: LatencyRepository,
         languageManager: LanguageManager,
         alertManager: AlertManager) {
        self.locationsManager = locationsManager
        self.lookAndFeelRepository = lookAndFeelRepository
        self.hapticFeedbackManager = hapticFeedbackManager
        self.preferences = preferences
        self.serverRepository = serverRepository
        self.userSessionRepository = userSessionRepository
        self.latencyRepository = latencyRepository
        self.languageManager = languageManager
        self.alertManager = alertManager
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

        serverRepository.favouriteListSubject
            .sink {[weak self] _ in
                guard let self = self else { return }
                self.delegate?.reloadServerListTableView()
                self.favList = self.serverRepository.favouriteListSubject.value
            }
            .store(in: &cancellables)

        userSessionRepository.sessionModelSubject
            .sink {[weak self] _ in
                self?.delegate?.reloadServerListTableView()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(
            locationsManager.bestLocationUpdated,
            locationsManager.selectedLocationUpdated
        )
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.refreshBestLocation()
        }
        .store(in: &cancellables)
    }

    func setBestLocationVisibility(to visible: Bool) {
        bestLocationVisible = visible
        delegate?.reloadServerListTableView()
    }

    func refreshBestLocation() {
        updateBestlocation(with: locationsManager.getBestLocationModel())
    }

    private func updateBestlocation(with value: BestLocationModel?) {
        bestLocationModel = value
        delegate?.reloadServerListTableView()
    }

    func updateServerList(with serverSections: [ServerSection], shouldColapse: Bool) {
        self.shouldColapse = shouldColapse
        self.serverSections = serverSections.map { serverSection in
            if let server = serverSection.server {
                if shouldColapse {
                    return ServerSection(server: server, collapsed: true)
                } else {
                    if let oldSection = serverSections.first(where: { $0.server?.id == server.id }) {
                        if !oldSection.collapsed {
                            print("ahah \(oldSection.server?.name)")
                        }
                        return ServerSection(server: server, collapsed: oldSection.collapsed)
                    }
                }
            }
            return serverSection
        }
        delegate?.reloadServerListTableView()
    }

    func updateShouldColapse(with value: Bool) {
        updateServerList(with: serverSections, shouldColapse: value)
    }

    func numberOfSections(in _: UITableView) -> Int {
        return serverSections.count + (showBestLocation() ? 1 : 0)
    }

    private func showBestLocation() -> Bool {
        return bestLocationModel != nil && bestLocationVisible
    }

    private func getCalculatedSection(from section: Int) -> Int {
        return section + (showBestLocation() ? -1 : 0)
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && showBestLocation() { return 1 }
        let calculatedSection = getCalculatedSection(from: section)
        if serverSections.indices.contains(calculatedSection) {
            guard let count = serverSections[calculatedSection].server?.groups.count else { return 0 }
            return count + 1
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ReuseIdentifiers.nodeCellReuseIdentifier, for: indexPath) as? NodeTableViewCell
        ?? NodeTableViewCell(style: .default, reuseIdentifier: ReuseIdentifiers.nodeCellReuseIdentifier)
        let calculatedSection = getCalculatedSection(from: indexPath.section)
        if (serverSections.count > calculatedSection) && ((serverSections[calculatedSection].server?.groups.count ?? 0) > indexPath.row - 1) {
            let group = serverSections[calculatedSection].server?.groups[indexPath.row - 1]

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
        if indexPath.section == 0 && showBestLocation() {
            delegate?.connectToBestLocation()
        }
        if indexPath.row == 0 { return }
        let calculatedSection = getCalculatedSection(from: indexPath.section)
        guard let server = serverSections[calculatedSection].server else { return }
        let group = server.groups[indexPath.row - 1]
        delegate?.setSelectedServerAndGroup(server: server, group: group)
    }

    func tableView(_ tableView: ExpyTableView, expandableCellForSection section: Int) -> UITableViewCell {
        if section == 0 && showBestLocation() {
            let bestLocationCell = tableView.dequeueReusableCell(
                withIdentifier: ReuseIdentifiers.bestLocationCellReuseIdentifier)! as? BestLocationCell
            ?? BestLocationCell(
                style: .default,
                reuseIdentifier: ReuseIdentifiers.bestLocationCellReuseIdentifier)
            if bestLocationCell.bestCellViewModel == nil {
                bestLocationCell.bestCellViewModel = BestLocationCellModel()
            }
            bestLocationCell.bestCellViewModel?.update(bestLocationModel: bestLocationModel,
                                                       locationLoad: locationLoad,
                                                       isDarkMode: lookAndFeelRepository.isDarkMode)
            bestLocationCell.refreshUI()
            return bestLocationCell
        } else {
            let calculatedSection = getCalculatedSection(from: section)
            let serverSection = serverSections[calculatedSection]
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ReuseIdentifiers.serverSectionCellReuseIdentifier)! as? ServerSectionCell
            ?? ServerSectionCell(
                style: .default,
                reuseIdentifier: ReuseIdentifiers.serverSectionCellReuseIdentifier)
            if cell.serverCellViewModel == nil {
                cell.serverCellViewModel = ServerSectionCellModel()
            }

            if let expanded = tableView.expandedSections[section], calculatedSection < serverSections.count {
                serverSections[calculatedSection].collapsed = !expanded
            }
            if section <= serverSections.count {
                cell.serverCellViewModel?.update(serverModel: serverSections[calculatedSection].server,
                                                 locationLoad: locationLoad,
                                                 isPremium: userSessionRepository.sessionModel?.isPremium ?? false,
                                                 isDarkMode: lookAndFeelRepository.isDarkMode)
                cell.setCollapsed(collapsed: serverSection.collapsed)
                if !serverSection.collapsed {
                    print("ahah \(serverSection.server?.name ?? "")")
                }
                cell.refreshUI()
            }
            return cell
        }
    }

    func tableView(_: UITableView,  heightForRowAt _: IndexPath) -> CGFloat {
        return 48
    }

    func changeForSection(tableView: UITableView, state: ExpyState, section: Int) {
        guard section < serverSections.count else { return }
        let calculatedSection = getCalculatedSection(from: section)
        guard let cell = tableView.cellForRow(at: IndexPath(item: 0, section: section)) as? ServerSectionCell else { return }
        switch state {
        case .willExpand:
            serverSections[calculatedSection].collapsed = false
            cell.expand()
        case .willCollapse:
            serverSections[calculatedSection].collapsed = true
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
        return favList
            .map { $0.id }
            .contains(String(groupId))
    }
}

extension ServerListTableViewDataSourceImpl: NodeTableViewCellModelDelegate {
    func saveAsFavorite(groupId: String) {
        serverRepository.saveFavorite(for: FavouriteModel(id: "\(groupId)"))
    }

    func removeFavorite(groupId: String) {
        let yesAction = UIAlertAction(title: TextsAsset.remove, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.serverRepository.removeFavorite(with: groupId)
        }
        alertManager.showAlert(title: TextsAsset.Favorites.removeTitle,
                                      message: TextsAsset.Favorites.removeMessage,
                                      buttonText: TextsAsset.cancel, actions: [yesAction])
    }
}
