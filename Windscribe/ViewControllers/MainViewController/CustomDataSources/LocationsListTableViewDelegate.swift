//
//  LocationsListTableViewDataSource+Delegate.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-31.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import ExpyTableView
import UIKit
import Combine

protocol LocationsListTableViewDelegate: AnyObject {
    func setSelectedLocationAndDatacenter(location: LocationModel, datacenter: DatacenterModel)
    func reloadLocationsListTableView()
    func connectToBestLocation()
    func handleRefresh()
    func tableViewScrolled(toTop: Bool)
}

protocol LocationsListTableViewDataSource: WExpyTableViewDataSource,
                                        ExpyTableViewDataSource,
                                        WExpyTableViewDataSourceDelegate,
                                        WTableViewDataSourceDelegate {
    var delegate: LocationsListTableViewDelegate? { get set }
    var scrollHappened: Bool { get set }

    var locationsSections: [LocationSection] { get }

    func updateServerList(with locationsSections: [LocationSection], shouldColapse: Bool)
    func updateShouldColapse(with value: Bool)
    func setBestLocationVisibility(to visible: Bool)
}

class LocationsListTableViewDataSourceImpl: WExpyTableViewDataSource,
                                         LocationsListTableViewDataSource {

    weak var delegate: LocationsListTableViewDelegate?
    var locationsSections: [LocationSection] = []
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
    private let locationListRepository: LocationListRepository
    private let alertManager: AlertManager

    init(locationsManager: LocationsManager,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         preferences: Preferences,
         locationListRepository: LocationListRepository,
         userSessionRepository: UserSessionRepository,
         latencyRepository: LatencyRepository,
         languageManager: LanguageManager,
         alertManager: AlertManager) {
        self.locationsManager = locationsManager
        self.lookAndFeelRepository = lookAndFeelRepository
        self.hapticFeedbackManager = hapticFeedbackManager
        self.preferences = preferences
        self.locationListRepository = locationListRepository
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
                self?.delegate?.reloadLocationsListTableView()
            }
            .store(in: &cancellables)

        self.languageManager.activelanguage
            .sink {[weak self] _ in
                self?.delegate?.reloadLocationsListTableView()
            }
            .store(in: &cancellables)

        preferences.getShowServerNetLoad()
            .sink {[weak self] locationLoad in
                self?.locationLoad = locationLoad ?? DefaultValues.showServerNetLoad
                self?.delegate?.reloadLocationsListTableView()
            }
            .store(in: &cancellables)

        locationListRepository.favouriteListSubject
            .sink {[weak self] _ in
                guard let self = self else { return }
                self.delegate?.reloadLocationsListTableView()
                self.favList = self.locationListRepository.favouriteListSubject.value
            }
            .store(in: &cancellables)

        userSessionRepository.sessionModelSubject
            .sink {[weak self] _ in
                self?.delegate?.reloadLocationsListTableView()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(
            locationsManager.bestLocationUpdatedTrigger,
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
        delegate?.reloadLocationsListTableView()
    }

    func refreshBestLocation() {
        updateBestlocation(with: locationsManager.getBestLocationModel())
    }

    private func updateBestlocation(with value: BestLocationModel?) {
        bestLocationModel = value
        delegate?.reloadLocationsListTableView()
    }

    func updateServerList(with locationsSections: [LocationSection], shouldColapse: Bool) {
        self.shouldColapse = shouldColapse
        self.locationsSections = locationsSections
            .map { locationSection in
            if let location = locationSection.location {
                if shouldColapse {
                    return LocationSection(location: location, collapsed: true)
                } else {
                    if let oldSection = locationsSections.first(where: { $0.location?.id == location.id }) {
                        return LocationSection(location: location, collapsed: oldSection.collapsed)
                    }
                }
            }
            return locationSection
        }
        delegate?.reloadLocationsListTableView()
    }

    func updateShouldColapse(with value: Bool) {
        updateServerList(with: locationsSections, shouldColapse: value)
    }

    func numberOfSections(in _: UITableView) -> Int {
        return locationsSections.count + (showBestLocation() ? 1 : 0)
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
        if locationsSections.indices.contains(calculatedSection) {
            guard let count = locationsSections[calculatedSection].location?.datacenters.count else { return 0 }
            return count + 1
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ReuseIdentifiers.datacenterCellReuseIdentifier, for: indexPath) as? DatacenterTableViewCell
        ?? DatacenterTableViewCell(style: .default, reuseIdentifier: ReuseIdentifiers.datacenterCellReuseIdentifier)
        let calculatedSection = getCalculatedSection(from: indexPath.section)
        if locationsSections.count > calculatedSection,
           let locationModel = locationsSections[calculatedSection].location,
           locationModel.datacenters.count > (indexPath.row - 1) {
            let datacenter = locationsSections[calculatedSection].location?.datacenters[indexPath.row - 1]

            var latency = -1
            if let pingServer = datacenter?.pingServer,
               let newlatency = latencyRepository.getPingData(ip: pingServer.ip)?.latency {
                latency = newlatency
            }

            if cell.datacenterCellViewModel == nil {
                cell.datacenterCellViewModel = DatacenterTableViewCellModel()
                cell.datacenterCellViewModel?.delegate = self
            }
            cell.datacenterCellViewModel?.update(displayingDatacenter: datacenter,
                                                 locationLoad: locationLoad,
                                                 isSavedHasFav: isGroupFavorite(datacenter?.id),
                                                 hasAccess: userSessionRepository.canAccesstoProLocation(location: locationModel),
                                                 isDarkMode: lookAndFeelRepository.isDarkMode,
                                                 latency: latency,
                                                 countryCode: locationModel.countryCode)
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

        // Bounds check to prevent crash when serverSections is updated
        guard calculatedSection >= 0 && calculatedSection < locationsSections.count else { return }

        guard let location = locationsSections[calculatedSection].location else { return }
        let datacenter = location.datacenters[indexPath.row - 1]
        delegate?.setSelectedLocationAndDatacenter(location: location, datacenter: datacenter)
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

            // Bounds check to prevent crash when serverSections is updated during scrolling
            guard calculatedSection >= 0 && calculatedSection < locationsSections.count else {
                // Return empty cell if section index is out of bounds
                return UITableViewCell()
            }

            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.locationSectionCellReuseIdentifier)! as? LocationSectionCell
            ?? LocationSectionCell(style: .default, reuseIdentifier: ReuseIdentifiers.locationSectionCellReuseIdentifier)
            if locationsSections.count <= calculatedSection {
                return cell
            }

            let locationSection = locationsSections[calculatedSection]
            if cell.locationCellViewModel == nil {
                cell.locationCellViewModel = LocationSectionCellModel()
            }

            if let expanded = tableView.expandedSections[section],
               calculatedSection >= 0 && calculatedSection < locationsSections.count {
                locationsSections[calculatedSection].collapsed = !expanded
            }
            if calculatedSection >= 0 && calculatedSection < locationsSections.count {
                cell.locationCellViewModel?.update(locationModel: locationsSections[calculatedSection].location,
                                                   locationLoad: locationLoad,
                                                   isPremium: userSessionRepository.sessionModel?.isPremium ?? false,
                                                   isDarkMode: lookAndFeelRepository.isDarkMode,
                                                   alcList: userSessionRepository.sessionModel?.alc ?? [])
                cell.setCollapsed(collapsed: locationSection.collapsed)
                if !locationSection.collapsed {
                    print("ahah \(locationSection.location?.name ?? "")")
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
        let calculatedSection = getCalculatedSection(from: section)
        // Bounds check to prevent crash when serverSections is updated
        guard calculatedSection >= 0 && calculatedSection < locationsSections.count else { return }

        guard let cell = tableView.cellForRow(at: IndexPath(item: 0, section: section)) as? LocationSectionCell else { return }

        switch state {
        case .willExpand:
            locationsSections[calculatedSection].collapsed = false
            cell.expand()
        case .willCollapse:
            locationsSections[calculatedSection].collapsed = true
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

    private func getLocationModel(from datacenterId: Int) -> LocationModel? {
        try? locationsManager.getLocationDatacenter(from: datacenterId).0
    }

    private func isGroupFavorite(_ datacenterId: Int?) -> Bool {
        guard let datacenterId = datacenterId else { return false }
        return favList
            .map { $0.id }
            .contains(String(datacenterId))
    }
}

extension LocationsListTableViewDataSourceImpl: DatacenterTableViewCellModelDelegate {
    func saveAsFavorite(datacenterId: Int) {
        locationListRepository.saveFavorite(for: FavouriteModel(id: "\(datacenterId)"))
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
