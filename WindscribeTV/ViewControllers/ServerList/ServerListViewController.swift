//
//  ServerListViewController.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 12/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import Swinject
import RxSwift

protocol BestLocationConnectionDelegate: AnyObject {
    func connectToBestLocation()
}

enum SideMenuType: String {
    case all = "All"
    case fav = "Favourites"
    case windflix = "Windflix"
    case staticIp = "Static IP"

    func getImage(isSelected: Bool) -> UIImage? {
        switch self {
        case .all:
            let img = UIImage(named: ImagesAsset.TvAsset.allIcon)
            return isSelected ? img?.withTintColor(.white) : img?.withTintColor(.whiteWithOpacity(opacity: 0.40))
        case .fav:
            let img = UIImage(named: ImagesAsset.TvAsset.favnavIcon)
            return isSelected ? img?.withTintColor(.white) : img
        case .windflix:
            let img = UIImage(named: ImagesAsset.TvAsset.flixIcon)
            return isSelected ? img?.withTintColor(.white) : img
        case .staticIp:
            let img = UIImage(named: ImagesAsset.TvAsset.staticIp)
            return isSelected ? img?.withTintColor(.white): img
        }
    }

}

class ServerListViewController: PreferredFocusedViewController, SideMenuOptionViewDelegate {
    var viewModel: MainViewModelType!, logger: FileLogger!, router: ServerListRouter!, serverListViewModel: ServerListViewModelType!
    let disposeBag = DisposeBag()

    @IBOutlet weak var sideMenu: UIStackView!
    @IBOutlet var sideMenuContainerView: UIView!
    @IBOutlet var serverListCollectionView: UICollectionView!
    @IBOutlet var favTableView: UITableView!
    @IBOutlet weak var sideMenuWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var nothingToSeeLabel: UILabel!
    @IBOutlet weak var emptyFavView: UIView!

    weak var delegate: ServerListTableViewDelegate?
    weak var favDelegate: FavNodesListTableViewDelegate?
    weak var bestLocDelegate: BestLocationConnectionDelegate?
    weak var staticIpDelegate: StaticIPListTableViewDelegate?

    private var sideOptions: [SideMenuType] = [.all,.fav,.windflix,.staticIp]
    private var selectedRow: Int = 0
    private var optionViews = [SideMenuOptions]()
    private var selectionOption = SideMenuType.all

    var serverSectionsOrdered: [ServerSection] = []
    var favGroups: [Group] = []
    var staticIPModels = [StaticIPModel]()
    var staticIpSelected = false
    var bestLocation: BestLocationModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        serverListCollectionView.delegate = self
        serverListCollectionView.dataSource = self

        sideMenuWidthConstraint.constant = 90
        self.serverListCollectionView.register(UINib(nibName: "ServerListCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ServerListCollectionViewCell")
        favTableView.delegate = self
        favTableView.dataSource = self
        favTableView.register(UINib(nibName: "ServerDetailTableViewCell", bundle: nil), forCellReuseIdentifier: "ServerDetailTableViewCell")
        setup()
        bindData(isStreaming: false)
        toggleView(viewToToggle: favTableView, isViewVisible: true)
        self.serverListCollectionView.contentInsetAdjustmentBehavior = .never
        setupSwipeDownGesture()
        hideEmptyFavView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logger.logD(self, "Displaying Server List View")
    }

    private func hideEmptyFavView() {
        if selectionOption == .fav {
            if favGroups.count > 0 {
                emptyFavView.isHidden = true
                emptyFavView.subviews.forEach { $0.isHidden = true }
            } else {
                emptyFavView.isHidden = false
                emptyFavView.subviews.forEach { $0.isHidden = false }
            }
        } else {
            emptyFavView.isHidden = true
            emptyFavView.subviews.forEach { $0.isHidden = true }
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            super.pressesBegan(presses, with: event)
            if let focusedCell = UIScreen.main.focusedView as? UICollectionViewCell {
                if let indexPath = serverListCollectionView.indexPath(for: focusedCell) {
                    if indexPath.row == 0 && selectedRow == 0 {
                        if press.type == .leftArrow {
                            myPreferredFocusedView = optionViews.first?.button
                            self.setNeedsFocusUpdate()
                            self.updateFocusIfNeeded()
                            break
                        }
                    }
                    if (0...3).contains(indexPath.row), (0...3).contains(selectedRow), press.type == .upArrow {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                    selectedRow = indexPath.row
                }
            }
            if UIScreen.main.focusedView is UIButton {
                if press.type == .leftArrow && preferredFocusedView?.accessibilityIdentifier == AccessibilityIdentifier.connectButton {
                    myPreferredFocusedView = optionViews.first?.button
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                }
            }
        }
    }

    private func setupSwipeDownGesture() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp(_:)))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
    }

    @objc private func handleSwipeLeft(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            if let focusedCell = UIScreen.main.focusedView as? UICollectionViewCell {
                if let indexPath = serverListCollectionView.indexPath(for: focusedCell) {
                    print("IndexPath is \(indexPath)")
                    if indexPath.row == 0 && selectedRow == 0 {
                        myPreferredFocusedView = optionViews.first?.button
                        self.setNeedsFocusUpdate()
                        self.updateFocusIfNeeded()
                        return
                    }
                    selectedRow = indexPath.row
                }
            }
            if UIScreen.main.focusedView is UIButton {
                myPreferredFocusedView = optionViews.first?.button
                self.setNeedsFocusUpdate()
                self.updateFocusIfNeeded()
            }
        }
    }

    @objc private func handleSwipeUp(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            if UIScreen.main.focusedView is UIButton {
                self.navigationController?.popToRootViewController(animated: true)
            }
            if let focusedCell = UIScreen.main.focusedView as? UICollectionViewCell {
                if let indexPath = serverListCollectionView.indexPath(for: focusedCell) {
                    if (0...3).contains(indexPath.row), (0...3).contains(selectedRow) {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                    selectedRow = indexPath.row
                }
            }
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if context.nextFocusedItem is UIButton {
            let view = context.nextFocusedView as? UIButton
            if view?.superview?.superview is UITableViewCell {
                UIView.animate(withDuration: 0.3) {
                    self.sideMenuWidthConstraint.constant = 90
                    self.view.layoutIfNeeded()
                }
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.sideMenuWidthConstraint.constant = 400
                    self.view.layoutIfNeeded()
                }
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.sideMenuWidthConstraint.constant = 90
                self.view.layoutIfNeeded()
            }
        }
        if context.nextFocusedItem === serverListCollectionView || context.nextFocusedItem === favTableView {
            UIView.animate(withDuration: 0.3) {
                self.sideMenuWidthConstraint.constant = 90
                self.view.layoutIfNeeded()
            }
        }

    }

    private func setup() {
        sideMenu.distribution = .fillEqually
        sideOptions.forEach {
            let optionView: SideMenuOptions = SideMenuOptions.fromNib()
            optionView.setup(with: $0)
            optionView.delegate = self
            sideMenu.addArrangedSubview(optionView)
            optionViews.append(optionView)
        }
        nothingToSeeLabel.text = TextsAsset.nothingToSeeHere
    }

    func bindData(isStreaming: Bool) {
        self.viewModel.serverList.subscribe(on: MainScheduler.instance).subscribe( onNext: { [self] results in
            viewModel.sortServerListUsingUserPreferences(isForStreaming: isStreaming, servers: results) { serverSectionsOrdered in
                self.serverSectionsOrdered = serverSectionsOrdered

               if  self.bestLocation != nil {
                    let bestLocationServer = ServerModel(name: Fields.Values.bestLocation)
                    if self.serverSectionsOrdered.first?.server?.name != Fields.Values.bestLocation {
                        self.serverSectionsOrdered.insert(ServerSection(server: bestLocationServer, collapsed: true), at: 0)
                    }
                }
                self.serverListCollectionView.reloadData()
            }
        }).disposed(by: self.disposeBag)
        
        self.viewModel.staticIPs.subscribe(onNext: { [self] staticips in
            let staticips = self.viewModel.getStaticIp()
            staticIPModels.removeAll()
            for result in staticips {
                guard let staticIPModel = result.getStaticIPModel() else { return }
                staticIPModels.append(staticIPModel)
            }

        }).disposed(by: disposeBag)
        viewModel.favouriteGroups.subscribe(onNext: { [self] favourites in
            favGroups.removeAll()
            favGroups.append(contentsOf: favourites)
            self.favTableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            if favourites.count == 0 {
                self.setNeedsFocusUpdate()
            } else {
                self.updateFocusIfNeeded()
                self.view.layoutIfNeeded()
            }
            self.hideEmptyFavView()
        }, onError: { error in
            self.logger.logE(self, "Realm server list notification error \(error.localizedDescription)")
        }).disposed(by: disposeBag)

        serverListViewModel.configureVPNTrigger.subscribe(onNext: {
            print("Testing")
            // self.configureVPN()
        }).disposed(by: disposeBag)
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let vc = self.presentingViewController as? MainViewController {
            vc.isFromServer = true
        }
    }

    func optionWasSelected(with value: SideMenuType) {
        optionViews.forEach {
            $0.updateSelection(with: $0.isType(of: value))
        }
        switch value {
        case .all:
            toggleView(viewToToggle: serverListCollectionView, isViewVisible: false)
            toggleView(viewToToggle: favTableView, isViewVisible: true)
            selectionOption = .all
            hideEmptyFavView()
            bindData(isStreaming: false)
        case .fav:
            staticIpSelected = false
            toggleView(viewToToggle: favTableView, isViewVisible: false)
            selectionOption = .fav
            hideEmptyFavView()
            favTableView.reloadData()
            toggleView(viewToToggle: serverListCollectionView, isViewVisible: true)
        case .windflix:
            toggleView(viewToToggle: serverListCollectionView, isViewVisible: false)
            toggleView(viewToToggle: favTableView, isViewVisible: true)
            selectionOption = .windflix
            hideEmptyFavView()
            bindData(isStreaming: true)
        case .staticIp:
            staticIpSelected = true
            toggleView(viewToToggle: favTableView, isViewVisible: false)
            selectionOption = .staticIp
            hideEmptyFavView()
            favTableView.reloadData()
            toggleView(viewToToggle: serverListCollectionView, isViewVisible: true)

        }
        UIView.animate(withDuration: 0.3) {
            self.sideMenuWidthConstraint.constant = 90
            self.view.layoutIfNeeded()
        }
        optionViews.forEach {
            if $0.sideMenuType == self.selectionOption {
                $0.setHorizontalGradientBackground()
            }
        }
    }

    private func toggleView(viewToToggle: UIView, isViewVisible: Bool) {
        let finalPosition: CGFloat
        let finalAlpha: CGFloat
        let transform: CGAffineTransform

        if isViewVisible {
            // Hide the view
            finalPosition = view.bounds.height + viewToToggle.frame.height
            finalAlpha = 0
            transform = CGAffineTransform(translationX: 0, y: finalPosition)
        } else {
            // Show the view
            finalPosition = 0
            finalAlpha = 1
            transform = CGAffineTransform(translationX: 0, y: finalPosition)
            viewToToggle.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        }

        // Animate the view sliding in or out
        UIView.animate(withDuration: 0.5, animations: {
            viewToToggle.transform = transform
            viewToToggle.alpha = finalAlpha
        }, completion: { _ in
            if isViewVisible {
                viewToToggle.removeFromSuperview()
            } else {
                // Ensure the view is added if it's being shown
                if !viewToToggle.isDescendant(of: self.view) {
                    self.view.addSubview(viewToToggle)
                    self.setConstraints()
                    viewToToggle.sendToBack()
                    self.sideMenuContainerView.bringToFront()
                }
            }
        })
    }

    private func setConstraints() {
        serverListCollectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            serverListCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            serverListCollectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 48),
            serverListCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            serverListCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 100)
        ])

        favTableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            favTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            favTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: -130),
            favTableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            favTableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 130)
        ])
    }
}

extension ServerListViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return serverSectionsOrdered.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = serverListCollectionView.dequeueReusableCell(withReuseIdentifier: "ServerListCollectionViewCell", for: indexPath) as? ServerListCollectionViewCell else { return ServerListCollectionViewCell() }
        let serverSection = serverSectionsOrdered[indexPath.item]
        if indexPath.item == 0 && self.bestLocation != nil {
            cell.flagImage.image =  UIImage(named: "bestLocation_cell")
            cell.setup(isShadow: false)
        } else {
            if let countrycode = serverSection.server?.countryCode {
                cell.flagImage.image =  UIImage(named: "\(countrycode.lowercased())-s")
            }
            cell.setup(isShadow: true)
        }
        cell.countryCode.text = serverSection.server?.name?.localize()
        return cell

    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 && self.bestLocation != nil {
            self.navigationController?.popToRootViewController(animated: true)
            bestLocDelegate?.connectToBestLocation()
            return
        }
        if let selectedServer = self.serverSectionsOrdered[indexPath.row].server {
            router.routeTo(to: .serverListDetail(server: selectedServer, delegate: self.delegate), from: self)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: 421, height: 273)
    }
}

extension ServerListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Create a container view for the header
        let headerView = UIView()
        headerView.backgroundColor = .clear

        // Create the label
        let label = PageTitleLabel()
        label.text = staticIpSelected ? TvAssets.staticIPTitle : TvAssets.favTitle
        label.textAlignment = .left

        label.translatesAutoresizingMaskIntoConstraints = false

        // Add the label to the header view
        headerView.addSubview(label)

        // Add constraints for the label
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 0),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16)
        ])

        // Set a fixed height for the header view
        let headerHeight: CGFloat = 300
        headerView.frame = CGRect(x: 0, y: 0, width: favTableView.frame.width, height: headerHeight)

        return headerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if staticIpSelected {
            return staticIPModels.count
        } else {
            return favGroups.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ServerDetailTableViewCell", for: indexPath) as? ServerDetailTableViewCell else { return ServerDetailTableViewCell() }
        if !staticIpSelected {
            let favNodes = favGroups[indexPath.row]
            cell.displayingFavGroup = favNodes
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

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 125
    }
}

extension ServerListViewController: FavNodesListTableViewDelegate {
    func setSelectedFavNode(favNode: FavNodeModel) {
        self.navigationController?.popToRootViewController(animated: true)
        self.favDelegate?.setSelectedFavNode(favNode: favNode)
    }
    func showUpgradeView() {
        self.delegate?.showUpgradeView()
    }
    func showExpiredAccountView() {
        self.delegate?.showExpiredAccountView()
    }
    func showOutOfDataPopUp() {
        self.delegate?.showOutOfDataPopUp()
    }
}

extension ServerListViewController: StaticIPListTableViewDelegate {
    func setSelectedStaticIP(staticIP: StaticIPModel) {
        self.navigationController?.popToRootViewController(animated: true)
        self.staticIpDelegate?.setSelectedStaticIP(staticIP: staticIP)
    }
}
