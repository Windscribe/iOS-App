//
//  ServerDetailViewController.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 19/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift
import Swinject

class ServerDetailViewController: UIViewController {
    @IBOutlet weak var flagView: UIImageView!
    @IBOutlet weak var serverTitle: PageTitleLabel!
    @IBOutlet weak var countLabel: PageTitleLabel!
    @IBOutlet weak var tableView: UITableView!
    var flagBackgroundView: UIView!
    var gradient,
        backgroundGradient,
        flagBottomGradient: CAGradientLayer!
    var server: ServerModel?
    var viewModel: MainViewModelType?
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        setupUI()
        bindData()
        // Do any additional setup after loading the view.
    }
    var favNodes: [FavNodeModel]?

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
        self.view.addSubview(flagBackgroundView)
        flagBackgroundView.sendToBack()
        if let server = server {
            flagView.image = UIImage(named: server.countryCode ?? "")
            serverTitle.text = server.name
            countLabel.text = String(describing: server.groups?.count ?? 0)
        }
        tableView.contentInset = UIEdgeInsets.zero
        tableView.register(UINib(nibName: "ServerDetailTableViewCell", bundle: nil), forCellReuseIdentifier: "ServerDetailTableViewCell")
        
    }
    
    func bindData() {
        viewModel?.favNode.bind(onNext: { favNodes in
            self.favNodes = favNodes?.compactMap({ $0.getFavNodeModel() })

        }).disposed(by: disposeBag)
    }
}

extension ServerDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return server?.groups?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServerDetailTableViewCell", for: indexPath) as! ServerDetailTableViewCell
        if let group = server?.groups?[indexPath.row] {
            cell.bindData(group: group)
            cell.displayingGroup = group
            cell.displayingNodeServer = server
            
        }
        cell.focusStyle = UITableViewCell.FocusStyle.custom
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 125
    }
}
