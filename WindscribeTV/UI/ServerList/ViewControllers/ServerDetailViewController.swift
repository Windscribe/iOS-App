//
//  ServerDetailViewController.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 19/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import Swinject
import UIKit

class ServerDetailViewController: UIViewController {
    @IBOutlet var flagView: UIImageView!
    @IBOutlet var serverTitle: PageTitleLabel!
    @IBOutlet var countLabel: PageTitleLabel!
    @IBOutlet var tableView: UITableView!
    private var focusServerDetailCellPath: IndexPath?

    private var cancellables = Set<AnyCancellable>()

    var flagBackgroundView: UIView!
    var gradient,
        backgroundGradient,
        flagBottomGradient: CAGradientLayer!
    var location: LocationModel?
    var viewModel: MainViewModel?, serverListViewModel: ServerListViewModelType?, logger: FileLogger!
    weak var delegate: LocationsListTableViewDelegate?
    var favList: [DatacenterModel]?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        setupUI()
        bindData()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logger.logD("ServerDetailViewController", "Displaying Server List View")
    }

    func setupUI() {
        flagView.contentMode = .scaleAspectFill
        flagView.layer.opacity = 0.25
        gradient = CAGradientLayer()
        gradient.frame = flagView.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.lightMidnight.cgColor]
        gradient.locations = [0, 0.65]
        flagView.layer.mask = gradient

        flagBackgroundView = UIView()
        flagBackgroundView.frame = flagView.bounds
        flagBackgroundView.backgroundColor = UIColor.lightMidnight
        backgroundGradient = CAGradientLayer()
        backgroundGradient.frame = flagBackgroundView.bounds
        backgroundGradient.colors = [UIColor.lightMidnight.withAlphaComponent(0.75).cgColor, UIColor.clear.cgColor]
        backgroundGradient.locations = [0.0, 1.0]
        flagBackgroundView.layer.mask = backgroundGradient
        view.addSubview(flagBackgroundView)
        flagBackgroundView.sendToBack()
        if let location = location {
            flagView.image = UIImage(named: "\(location.countryCode.lowercased())-l")
            serverTitle.text = location.name
            countLabel.text = String(describing: location.datacenters.count)
        }
        tableView.contentInset = UIEdgeInsets.zero
        tableView.register(UINib(nibName: "ServerDetailTableViewCell", bundle: nil), forCellReuseIdentifier: "ServerDetailTableViewCell")
    }

    func bindData() {
        viewModel?.favouriteList
            .sink { favList in
                self.favList = favList?.compactMap { $0.datacenterModel }
            }
            .store(in: &cancellables)
    }
}

extension ServerDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return location?.datacenters.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ServerDetailTableViewCell", for: indexPath) as? ServerDetailTableViewCell else { return ServerDetailTableViewCell() }
        if let datacenter = location?.datacenters[indexPath.row] {
            cell.bindData(datacenter: datacenter)
            cell.displayingDatacenter = datacenter
            cell.displayingNodeServer = location
        }
        cell.delegate = self
        cell.focusStyle = UITableViewCell.FocusStyle.custom
        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 125
    }
}

extension ServerDetailViewController: LocationsListTableViewDelegate {
    func setSelectedLocationAndDatacenter(location: LocationModel, datacenter: DatacenterModel) {
        navigationController?.popToRootViewController(animated: true)
        delegate?.setSelectedLocationAndDatacenter(location: location, datacenter: datacenter)
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

    /// Save last cell with focus.
    /// Reload table.
    /// Request focus update if last cell with focus is found.
    func reloadTable(cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            focusServerDetailCellPath = indexPath
        }
        tableView.reloadData()
        if let indexPath = focusServerDetailCellPath {
            tableView.scrollToRow(at: indexPath, at: .none, animated: false)
            if tableView.cellForRow(at: indexPath) is ServerDetailTableViewCell {
                setNeedsFocusUpdate()
                updateFocusIfNeeded()
            }
        }
    }

    /// Bring focus back to last focused cell if required
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if let indexPath = focusServerDetailCellPath,
           let cell = tableView.cellForRow(at: indexPath) as? ServerDetailTableViewCell {
            return [cell.favButton]
        }
        return super.preferredFocusEnvironments
    }
}
