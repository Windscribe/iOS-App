//
//  ServerListViewController.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 12/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import Swinject
import UIKit

protocol BestLocationConnectionDelegate: AnyObject {
    func connectToBestLocation()
}

enum SideMenuType: String {
    case all = "All"
    case fav = "Favourites"
    case staticIp = "Static IP"

    func getImage(isSelected: Bool) -> UIImage? {
        switch self {
        case .all:
            let img = UIImage(named: ImagesAsset.TvAsset.allIcon)
            return isSelected ? img?.withTintColor(.white) : img?.withTintColor(.whiteWithOpacity(opacity: 0.40))
        case .fav:
            let img = UIImage(named: ImagesAsset.TvAsset.favnavIcon)
            return isSelected ? img?.withTintColor(.white) : img
        case .staticIp:
            let img = UIImage(named: ImagesAsset.TvAsset.staticIp)
            return isSelected ? img?.withTintColor(.white) : img
        }
    }
}

class ServerListViewController: PreferredFocusedViewController, SideMenuOptionViewDelegate {
    // MARK: - Properties

    private let sideOptions: [SideMenuType] = [.all, .fav, .staticIp]

    var viewModel: MainViewModel!, logger: FileLogger!, router: ServerListRouter!, serverListViewModel: ServerListViewModelType!

    @IBOutlet var sideMenu: UIStackView!
    @IBOutlet var sideMenuContainerView: UIView!
    @IBOutlet var serverListCollectionView: UICollectionView!
    @IBOutlet var favTableView: UITableView!
    @IBOutlet var sideMenuWidthConstraint: NSLayoutConstraint!
    @IBOutlet var nothingToSeeLabel: UILabel!
    @IBOutlet var emptyDataView: EmptyListView!

    weak var delegate: LocationsListTableViewDelegate?
    weak var favDelegate: FavouriteListTableViewDelegate?
    weak var bestLocDelegate: BestLocationConnectionDelegate?
    weak var staticIpDelegate: StaticIPListTableViewDelegate?

    var locationSectionsOrdered: [LocationSection] = []
    var favDatacenters: [DatacenterModel] = []
    var staticIPModels = [StaticIPModel]()
    var staticIpSelected = false
    var bestLocation: BestLocationModel?

    private var cancellables = Set<AnyCancellable>()
    private var selectedRow: Int = 0
    private var selectedCollectionIndexPath: IndexPath?
    private var optionViews = [SideMenuOptionsView]()
    private var selectionOption = SideMenuType.all

    // MARK: - View Lifecycle and Selection

    override func viewDidLoad() {
        super.viewDidLoad()
        serverListCollectionView.delegate = self
        serverListCollectionView.dataSource = self

        sideMenuWidthConstraint.constant = 90
        serverListCollectionView.register(UINib(nibName: "ServerListCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ServerListCollectionViewCell")
        favTableView.delegate = self
        favTableView.dataSource = self
        favTableView.register(UINib(nibName: "ServerDetailTableViewCell", bundle: nil), forCellReuseIdentifier: "ServerDetailTableViewCell")
        setup()
        favTableView.isHidden = true
        bindData()
        serverListCollectionView.contentInsetAdjustmentBehavior = .never
        setupSwipeDownGesture()
        changeEmptyViewVisibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Restore focus to previously selected collection view item
        if let indexPath = selectedCollectionIndexPath,
           selectionOption == .all {
            // Scroll to the item first
            serverListCollectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logger.logD("ServerListViewController", "Displaying Server List View")

        // Set focus after view is fully loaded with a small delay to ensure cell is ready
        if let indexPath = selectedCollectionIndexPath,
           selectionOption == .all {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let cell = self.serverListCollectionView.cellForItem(at: indexPath) {
                    self.myPreferredFocusedView = cell
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                }
            }
        }
    }

    override func viewWillDisappear(_: Bool) {
        if let vc = presentingViewController as? MainViewController {
            vc.isFromServer = true
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            super.pressesBegan(presses, with: event)
            if let focusedCell = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.focusSystem?.focusedItem as? UICollectionViewCell {

                if let indexPath = serverListCollectionView.indexPath(for: focusedCell) {
                    if indexPath.row == 0 && selectedRow == 0 {
                        if press.type == .leftArrow {
                            focusSelectedMenuOption()

                            setNeedsFocusUpdate()
                            updateFocusIfNeeded()
                            break
                        }
                    }
                    if (0 ... 3).contains(indexPath.row), (0 ... 3).contains(selectedRow), press.type == .upArrow {
                        navigationController?.popToRootViewController(animated: true)
                    }
                    selectedRow = indexPath.row
                }
            }

            if let focusedItem = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.focusSystem?.focusedItem, focusedItem is UIButton {

                if press.type == .leftArrow && preferredFocusedView?.accessibilityIdentifier == AccessibilityIdentifier.connectButton {
                    focusSelectedMenuOption()

                    setNeedsFocusUpdate()
                    updateFocusIfNeeded()
                }
            }
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if context.nextFocusedItem is UIButton {
            let view = context.nextFocusedView as? UIButton

            if view?.superview?.superview is UITableViewCell {
                changeSideMenuVisibility(isExpanded: false)
            } else {
                changeSideMenuVisibility(isExpanded: true)
            }
        } else {
            changeSideMenuVisibility(isExpanded: false)
        }

        if context.nextFocusedItem === serverListCollectionView || context.nextFocusedItem === favTableView {
            changeSideMenuVisibility(isExpanded: false)
        }
    }

    func optionWasSelected(with value: SideMenuType) {
        let selectionChanged = value != selectionOption
        selectionOption = value
        staticIpSelected = value == .staticIp
        serverListCollectionView.isHidden = value != .all
        favTableView.isHidden = value == .all
        changeEmptyViewVisibility()

        if selectionChanged && value != .all {
            favTableView.reloadData()
        }

        switch value {
        case .all:
            myPreferredFocusedView = serverListCollectionView
        case .fav:
            myPreferredFocusedView = favDatacenters.isEmpty ? nil : favTableView
        case .staticIp:
            myPreferredFocusedView = staticIPModels.isEmpty ? nil : favTableView
        }
        if myPreferredFocusedView == nil {
            focusSelectedMenuOption()
        }
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
        changeSideMenuVisibility(isExpanded: false)

        for optionView in optionViews {
            optionView.updateSelection(with: optionView.isType(of: selectionOption))
            optionView.highlightSelectedOption(optionView.isType(of: selectionOption))
        }
    }

    // MARK: - Private Helpers

    private func setup() {
        sideMenu.distribution = .fillEqually
        for sideOption in sideOptions {
            let optionView: SideMenuOptionsView = SideMenuOptionsView.fromNib()
            optionView.setup(with: sideOption)
            optionView.delegate = self
            sideMenu.addArrangedSubview(optionView)
            optionViews.append(optionView)
        }
        nothingToSeeLabel.text = TextsAsset.nothingToSeeHere
    }

    private func bindData() {
        self.viewModel.locationsList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                guard let self else { return }

                locationSectionsOrdered = viewModel.sortLocationListUsingUserPreferences(ignoreStreaming: false,
                                                                                         isForStreaming: false,
                                                                                         locations: results)
                addBestLocation()
                serverListCollectionView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.staticIPs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                staticIPModels = self.viewModel.getStaticIp()
                if staticIpSelected {
                    favTableView.reloadData()
                }
                self.changeEmptyViewVisibility()
            }
            .store(in: &cancellables)
        viewModel.favouriteDatacenters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.logger.logE("ServerListViewController", "Realm server list notification error \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] favourites in
                guard let self else { return }

                favDatacenters.removeAll()
                favDatacenters.append(contentsOf: favourites)
                if selectionOption == .fav {
                    self.favTableView.reloadSections(IndexSet(integer: 0), with: .automatic)
                }
                if favourites.count == 0 {
                    self.setNeedsFocusUpdate()
                } else {
                    self.updateFocusIfNeeded()
                    self.view.layoutIfNeeded()
                }
                self.changeEmptyViewVisibility()
            }
            .store(in: &cancellables)
    }

    private func addBestLocation() {
        if  bestLocation != nil,
            let datacenterId = bestLocation?.datacenterId,
            let locationModel = viewModel.getLocationModel(from: datacenterId) {
            let bestLocation = locationModel.getBestLocationModel()
            if locationSectionsOrdered.first?.location?.name != Fields.Values.bestLocation {
                locationSectionsOrdered.insert(LocationSection(location: bestLocation, collapsed: true), at: 0)
            }
        }
    }

    private func changeEmptyViewVisibility() {
        switch selectionOption {
        case .fav:
            emptyDataView.isHidden = favDatacenters.count > 0
            emptyDataView.subviews.forEach { $0.isHidden = favDatacenters.count > 0 }
            emptyDataView.configure(image: UIImage(named: ImagesAsset.favEmpty), text: TextsAsset.nothingToSeeHere)
        case .staticIp:
            emptyDataView.isHidden = staticIPModels.count > 0
            emptyDataView.subviews.forEach { $0.isHidden = staticIPModels.count > 0 }
            emptyDataView.configure(image: UIImage(named: "static_ip"), text: TextsAsset.noStaticIPs)
        default:
            emptyDataView.isHidden = true
            emptyDataView.subviews.forEach { $0.isHidden = true }
        }
    }

    private func setupSwipeDownGesture() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)

        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp(_:)))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
    }

    @objc private func handleSwipeRight(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            guard let focusedItem = view.window?.windowScene?.focusSystem?.focusedItem else { return }
            if focusedItem is UIButton {
                optionWasSelected(with: selectionOption)
            }
        }
    }

    @objc private func handleSwipeLeft(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            guard let focusedItem = view.window?.windowScene?.focusSystem?.focusedItem else { return }

            if let focusedCell = focusedItem as? UICollectionViewCell {
                if let indexPath = serverListCollectionView.indexPath(for: focusedCell) {

                    if indexPath.row == 0 && selectedRow == 0 {
                        focusSelectedMenuOption()

                        setNeedsFocusUpdate()
                        updateFocusIfNeeded()
                        return
                    }
                    selectedRow = indexPath.row
                }
            } else if focusedItem is UIButton {

                focusSelectedMenuOption()

                setNeedsFocusUpdate()
                updateFocusIfNeeded()

                changeSideMenuVisibility(isExpanded: true)
            }

            for optionView in optionViews {
                optionView.highlightSelectedOption(optionView.isType(of: selectionOption))
            }
        }
    }

    @objc private func handleSwipeUp(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            guard let focusedItem = view.window?.windowScene?.focusSystem?.focusedItem else { return }
            if let focusedButton = focusedItem as? UIButton,
               focusedButton == optionViews.first?.button {
                navigationController?.popToRootViewController(animated: true)
            } else if let focusedCell = focusedItem as? UICollectionViewCell {
                if let indexPath = serverListCollectionView.indexPath(for: focusedCell) {
                    if (0 ... 3).contains(indexPath.row), (0 ... 3).contains(selectedRow) {
                        navigationController?.popToRootViewController(animated: true)
                    }
                    selectedRow = indexPath.row
                }
            }
        }
    }

    private func changeSideMenuVisibility(isExpanded: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.sideMenuWidthConstraint.constant = isExpanded ? 400 : 90
            self.view.layoutIfNeeded()
        }
    }

    private func focusSelectedMenuOption() {
        if let selectedIndex = sideOptions.firstIndex(of: selectionOption) {
            myPreferredFocusedView = optionViews[selectedIndex].button
        } else {
            myPreferredFocusedView = optionViews.first?.button
        }
    }

}

extension ServerListViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return locationSectionsOrdered.count
    }

    func collectionView(_: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = serverListCollectionView.dequeueReusableCell(withReuseIdentifier: "ServerListCollectionViewCell", for: indexPath) as? ServerListCollectionViewCell else { return ServerListCollectionViewCell() }
        let locationSection = locationSectionsOrdered[indexPath.item]

        if indexPath.item == 0 && bestLocation != nil {
            cell.flagImage.image = UIImage(named: "bestLocation_cell")
            cell.setup(isShadow: false)
        } else {
            if let countrycode = locationSection.location?.countryCode {
                cell.flagImage.image = UIImage(named: "\(countrycode.lowercased())-s")
            }
            cell.setup(isShadow: true)
        }

        cell.countryCode.text = locationSection.location?.name.localized
        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Store the selected index path to restore focus when returning
        selectedCollectionIndexPath = indexPath

        if indexPath.row == 0 && bestLocation != nil {
            navigationController?.popToRootViewController(animated: true)
            bestLocDelegate?.connectToBestLocation()
            return
        }
        if let selectedLocation = locationSectionsOrdered[indexPath.row].location {
            router.routeTo(to: .locationListDetail(location: selectedLocation, delegate: delegate), from: self)
        }
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        return CGSize(width: 421, height: 273)
    }
}

extension ServerListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        // Create a container view for the header
        let headerView = UIView()
        headerView.backgroundColor = .clear

        // Create the label
        let label = PageTitleLabel()
        label.text = staticIpSelected ? TextsAsset.TVAsset.staticIPTitle : TextsAsset.TVAsset.favTitle
        label.textAlignment = .left

        label.translatesAutoresizingMaskIntoConstraints = false

        // Add the label to the header view
        headerView.addSubview(label)

        // Add constraints for the label
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 0),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16)
        ])

        // Set a fixed height for the header view
        let headerHeight: CGFloat = 300
        headerView.frame = CGRect(x: 0, y: 0, width: favTableView.frame.width, height: headerHeight)

        return headerView
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        if staticIpSelected {
            return staticIPModels.count
        } else {
            return favDatacenters.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ServerDetailTableViewCell", for: indexPath) as? ServerDetailTableViewCell else { return ServerDetailTableViewCell() }
        if !staticIpSelected {
            let favDatacenter = favDatacenters[indexPath.row]
            cell.displayingFavDatacenter = favDatacenter
            cell.favDelegate = self
            cell.focusStyle = UITableViewCell.FocusStyle.custom
        } else {
            let staticIP = staticIPModels[indexPath.row]
            cell.displayingStaticIP = staticIP
            cell.staticIpDelegate = self
            cell.focusStyle = UITableViewCell.FocusStyle.custom
        }
        return cell
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 100
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 125
    }
}

extension ServerListViewController: FavouriteListTableViewDelegate {
    func setSelectedFavourite(favourite: DatacenterModel) {
        navigationController?.popToRootViewController(animated: true)
        favDelegate?.setSelectedFavourite(favourite: favourite)
    }

    func showUpgradeView() {
        delegate?.showUpgradeView()
    }

    func showExpiredAccountView() {
        delegate?.showExpiredAccountView()
    }

    func showOutOfDataPopUp() {
        delegate?.showOutOfDataPopUp()
    }
}

extension ServerListViewController: StaticIPListTableViewDelegate {
    func setSelectedStaticIP(staticIP: StaticIPModel) {
        navigationController?.popToRootViewController(animated: true)
        staticIpDelegate?.setSelectedStaticIP(staticIP: staticIP)
    }
}

class EmptyListView: UIView {
    @IBOutlet weak var emptyImageView: UIImageView!
    @IBOutlet weak var emptyLabel: UILabel!

    func configure(image: UIImage?, text: String) {
        emptyImageView.image = image
        emptyLabel.text = text
    }
}
