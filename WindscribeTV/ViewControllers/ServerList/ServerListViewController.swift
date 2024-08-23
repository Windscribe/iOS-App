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

enum SideMenuType: String {
    case all = "All"
    case fav = "Favorites"
    case windflix = "Windflix"
    case staticIp = "Static IPs"
    
    
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

class ServerListViewController: UIViewController, SideMenuOptionViewDelegate {

    
    var viewModel: MainViewModelType!, logger: FileLogger!, router: ServerListRouter!
    var serverSectionsOrdered: [ServerSection] = []
    @IBOutlet weak var sideMenu: UIStackView!
    var favNodeModels: [FavNodeModel] = []
    var staticIPModels = [StaticIPModel]()
    @IBOutlet var sideMenuContainerView: UIView!
    @IBOutlet var serverListCollectionView: UICollectionView!
    @IBOutlet var favTableView: UITableView!
    @IBOutlet weak var sideMenuWidthConstraint: NSLayoutConstraint!
    
    private var sideOptions: [SideMenuType] = [.all,.fav,.windflix,.staticIp]
    private var selectedRow: Int = 0
    private var optionViews = [SideMenuOptions]()
    let disposeBag = DisposeBag()

    var staticIpSelected = false

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
        viewModel.favNode.subscribe(onNext: { [self] favNodes in
            favNodeModels.removeAll()
            if let favnodes = favNodes {
                for result in favnodes {
                    guard let favNodeModel = result.getFavNodeModel() else { return }
                    favNodeModels.append(favNodeModel)
                }
                favTableView.reloadData()
            }
        }, onError: { error in
            self.logger.logE(self, "Realm server list notification error \(error.localizedDescription)")

        }).disposed(by: disposeBag)
        
    }
    
    func bindData(isStreaming: Bool) {
        guard let results = try? viewModel.serverList.value() else { return }
        if results.count == 0 { return }
        viewModel.sortServerListUsingUserPreferences(isForStreaming: isStreaming, servers: results) { serverSectionsOrdered in
            self.serverSectionsOrdered = serverSectionsOrdered
            self.serverListCollectionView.reloadData()
        }
        self.viewModel.staticIPs.subscribe(onNext: { [self] staticips in
            let staticips = self.viewModel.getStaticIp()
            staticIPModels.removeAll()
            for result in staticips {
                guard let staticIPModel = result.getStaticIPModel() else { return }
                staticIPModels.append(staticIPModel)
            }
            
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
            bindData(isStreaming: false)
        case .fav:
            staticIpSelected = false
            toggleView(viewToToggle: favTableView, isViewVisible: false)
            favTableView.reloadData()
            toggleView(viewToToggle: serverListCollectionView, isViewVisible: true)
        case .windflix:
            toggleView(viewToToggle: serverListCollectionView, isViewVisible: false)
            toggleView(viewToToggle: favTableView, isViewVisible: true)
            bindData(isStreaming: true)
        case .staticIp:
            staticIpSelected = true
            toggleView(viewToToggle: favTableView, isViewVisible: false)
            favTableView.reloadData()
            toggleView(viewToToggle: serverListCollectionView, isViewVisible: true)
    
            
        }
        UIView.animate(withDuration: 0.3) {
            self.sideMenuWidthConstraint.constant = 90
            self.view.layoutIfNeeded()
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
               finalPosition = 100
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
            serverListCollectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            serverListCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            serverListCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 100),
        ])
    
        favTableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            favTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            favTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            favTableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            favTableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 130),
        ])
        
    }
    
}

extension ServerListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return serverSectionsOrdered.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = serverListCollectionView.dequeueReusableCell(withReuseIdentifier: "ServerListCollectionViewCell", for: indexPath) as! ServerListCollectionViewCell
        let serverSection = serverSectionsOrdered[indexPath.item]
        if let countrycode = serverSection.server?.countryCode {
            cell.flagImage.image =  UIImage(named: "\(countrycode)")
        }
        cell.countryCode.text = serverSection.server?.name
        return cell

    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let selectedServer = self.serverSectionsOrdered[indexPath.row].server {
            router.routeTo(to: .serverListDetail(server: selectedServer), from: self)
        }
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
        let headerHeight: CGFloat = 500
        headerView.frame = CGRect(x: 0, y: 0, width: favTableView.frame.width, height: headerHeight)
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if staticIpSelected{
            return staticIPModels.count
        } else {
            return favNodeModels.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServerDetailTableViewCell", for: indexPath) as! ServerDetailTableViewCell
        if !staticIpSelected {
            let favNodes = favNodeModels[indexPath.row]
            cell.displayingFavNode = favNodes
            cell.focusStyle = UITableViewCell.FocusStyle.custom
        } else {
            let staticIP = staticIPModels[indexPath.row]
            cell.displayingStaticIP = staticIP
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
