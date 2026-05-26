//
//  FavouriteListTableViewDataSource+Delegate.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-31.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Combine
import UIKit

protocol FavouriteListTableViewDelegate: AnyObject {
    func setSelectedFavourite(favourite: DatacenterModel)
    func reloadFavouriteListTableView()
    func hideFavouritesRefreshControl()
    func showFavouritesRefreshControl()
    func handleRefresh()
    func tableViewScrolled(toTop: Bool)
}

protocol FavouriteListTableViewDataSource: WSTableViewDataSource,
                                           UITableViewDataSource,
                                           WTableViewDataSourceDelegate {
    var delegate: FavouriteListTableViewDelegate? { get set }
    var scrollHappened: Bool { get set }

    var favList: [FavoriteDatacenterlModel] { get }

    func updateFavoriteList(with favList: [FavoriteDatacenterlModel])
}

class FavouriteListTableViewDataSourceImpl: WSTableViewDataSource, FavouriteListTableViewDataSource {
    weak var delegate: FavouriteListTableViewDelegate?
    var scrollHappened = false

    var favList: [FavoriteDatacenterlModel] = []
    private var cancellables = Set<AnyCancellable>()
    private var locationLoad: Bool = false

    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let hapticFeedbackManager: HapticFeedbackManager
    private let preferences: Preferences
    private let userSessionRepository: UserSessionRepository
    private let languageManager: LanguageManager
    private let latencyRepository: LatencyRepository
    private let locationListRepository: LocationListRepository
    private let alertManager: AlertManager

    init(lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         preferences: Preferences,
         locationListRepository: LocationListRepository,
         userSessionRepository: UserSessionRepository,
         languageManager: LanguageManager,
         latencyRepository: LatencyRepository,
         alertManager: AlertManager) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.hapticFeedbackManager = hapticFeedbackManager
        self.preferences = preferences
        self.locationListRepository = locationListRepository
        self.userSessionRepository = userSessionRepository
        self.languageManager = languageManager
        self.latencyRepository = latencyRepository
        self.alertManager = alertManager
        super.init()
        scrollViewDelegate = self

        bind()
    }

    private func bind() {
        self.lookAndFeelRepository.isDarkModeSubject
            .sink {[weak self] _ in
                self?.delegate?.reloadFavouriteListTableView()
            }
            .store(in: &cancellables)

        preferences.getShowServerNetLoad()
            .sink {[weak self] locationLoad in
                self?.locationLoad = locationLoad ?? DefaultValues.showServerNetLoad
                self?.delegate?.reloadFavouriteListTableView()
            }
            .store(in: &cancellables)

        userSessionRepository.sessionModelSubject
            .sink {[weak self] _ in
                self?.delegate?.reloadFavouriteListTableView()
            }
            .store(in: &cancellables)

        languageManager.activelanguage
            .sink {[weak self] _ in
                self?.delegate?.reloadFavouriteListTableView()
            }
            .store(in: &cancellables)
    }

    func updateFavoriteList(with favList: [FavoriteDatacenterlModel]) {
        self.favList = favList
        delegate?.reloadFavouriteListTableView()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection _: Int) -> Int {
        if favList.count == 0 {
            delegate?.hideFavouritesRefreshControl()
            showEmptyView(tableView: tableView)
            tableView.tableHeaderView?.isHidden = true
        } else {
            delegate?.showFavouritesRefreshControl()
            tableView.backgroundView = nil
            tableView.tableHeaderView?.isHidden = false
        }
        return favList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ReuseIdentifiers.favNodeCellReuseIdentifier, for: indexPath) as? FavNodeTableViewCell
        ?? FavNodeTableViewCell(
                style: .default,
                reuseIdentifier: ReuseIdentifiers.favNodeCellReuseIdentifier)
        guard indexPath.row < favList.count else { return cell }
        let favourite = favList[indexPath.row]
        var latency = -1
        if let randomServer = locationListRepository.getRandomServer(for: favourite.datacenterModel.id),
           let newlatency = latencyRepository.getPingData(ip: randomServer.ip)?.latency {
            latency = newlatency
        }

        // Get the location to check the countryCode and the shortName
        let locationModel = locationListRepository.getLocation(by: favourite.datacenterModel.locationId)

        if cell.favNodeCellViewModel == nil {
            cell.favNodeCellViewModel = FavNodeTableViewCellModel()
            cell.favNodeCellViewModel?.delegate = self
        }

        cell.favNodeCellViewModel?.update(displayingFavGroup: favourite,
                                          locationLoad: locationLoad,
                                          isSavedHasFav: true,
                                          isPremium: userSessionRepository.canAccesstoProLocation(locationId: favourite.datacenterModel.locationId),
                                          isDarkMode: lookAndFeelRepository.isDarkMode,
                                          latency: latency,
                                          countryCode: locationModel?.countryCode)
        cell.refreshUI()

        return cell
    }

    func tableView(_: UITableView,  heightForRowAt _: IndexPath) -> CGFloat {
        return 48
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < favList.count else { return }
        let favourite = favList[indexPath.row]
        delegate?.setSelectedFavourite(favourite: favourite.datacenterModel)
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 0
    }

    func showEmptyView(tableView: UITableView) {
        let view = ListEmptyView(type: .favNodes, isDarkMode: lookAndFeelRepository.isDarkModeSubject, activeLanguage: languageManager.activelanguage)
        tableView.backgroundView = view
        view.updateLayout()
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
}

extension FavouriteListTableViewDataSourceImpl: DatacenterTableViewCellModelDelegate {
    func saveAsFavorite(datacenterId: Int) {
        locationListRepository.saveFavorite(for: FavouriteModel(id: String(datacenterId)))
    }

    func removeFavorite(datacenterId: Int) {
        let yesAction = UIAlertAction(title: TextsAsset.remove, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.locationListRepository.removeFavorite(with: datacenterId)
        }
        alertManager.showAlert(title: TextsAsset.Favorites.removeTitle,
                               message: TextsAsset.Favorites.removeMessage,
                               buttonText: TextsAsset.cancel, actions: [yesAction])
    }
}
