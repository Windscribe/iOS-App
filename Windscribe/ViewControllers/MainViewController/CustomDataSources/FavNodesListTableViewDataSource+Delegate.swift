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
    func setSelectedFavourite(favourite: GroupModel)
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

    var favList: [FavouriteGroupModel] { get }

    func updateFavoriteList(with favList: [FavouriteGroupModel])
}

class FavouriteListTableViewDataSourceImpl: WSTableViewDataSource, FavouriteListTableViewDataSource {
    weak var delegate: FavouriteListTableViewDelegate?
    var scrollHappened = false

    var favList: [FavouriteGroupModel] = []
    private var cancellables = Set<AnyCancellable>()
    private var locationLoad: Bool = false

    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let hapticFeedbackManager: HapticFeedbackManager
    private let preferences: Preferences
    private let userSessionRepository: UserSessionRepository
    private let languageManager: LanguageManager
    private let latencyRepository: LatencyRepository

    let localDatabase: LocalDatabase

    init(lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         preferences: Preferences,
         localDatabase: LocalDatabase,
         userSessionRepository: UserSessionRepository,
         languageManager: LanguageManager,
         latencyRepository: LatencyRepository) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.hapticFeedbackManager = hapticFeedbackManager
        self.preferences = preferences
        self.localDatabase = localDatabase
        self.userSessionRepository = userSessionRepository
        self.languageManager = languageManager
        self.latencyRepository = latencyRepository
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

        preferences.getShowServerHealth()
            .sink {[weak self] locationLoad in
                self?.locationLoad = locationLoad ?? DefaultValues.showServerHealth
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

    func updateFavoriteList(with favList: [FavouriteGroupModel]) {
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
        let favourite = favList[indexPath.row]

        let latency = latencyRepository.getPingData(ip: favourite.groupModel.pingIp)?.latency ?? -1

        if cell.favNodeCellViewModel == nil {
            cell.favNodeCellViewModel = FavNodeTableViewCellModel()
            cell.favNodeCellViewModel?.delegate = self
        }

        cell.favNodeCellViewModel?.update(displayingFavGroup: favourite,
                                          locationLoad: locationLoad,
                                          isSavedHasFav: true,
                                          isUserPro: userSessionRepository.sessionModel?.isUserPro ?? false,
                                          isPremium: userSessionRepository.sessionModel?.isPremium ?? false,
                                          isDarkMode: lookAndFeelRepository.isDarkMode,
                                          latency: latency)
        cell.refreshUI()

        return cell
    }

    func tableView(_: UITableView,  heightForRowAt _: IndexPath) -> CGFloat {
        return 48
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let favourite = favList[indexPath.row]
        delegate?.setSelectedFavourite(favourite: favourite.groupModel)
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 0
    }

    func showEmptyView(tableView: UITableView) {
        let view = ListEmptyView(type: .favNodes, isDarkMode: lookAndFeelRepository.isDarkModeSubject, activeLanguage: languageManager.activelanguage)
        tableView.backgroundView = view
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // view
            view.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            view.heightAnchor.constraint(equalTo: tableView.heightAnchor),
            view.widthAnchor.constraint(equalTo: tableView.widthAnchor)
        ])
        view.updateLayout()
        tableView.backgroundView = view
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

extension FavouriteListTableViewDataSourceImpl: NodeTableViewCellModelDelegate {
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
