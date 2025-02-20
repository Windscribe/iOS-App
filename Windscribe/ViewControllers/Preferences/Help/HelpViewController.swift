import RxSwift
import UIKit

class HelpViewController: WSNavigationViewController {
    var router: HelpRouter!, logger: FileLogger!, viewModel: HelpViewModel!

    // MARK: UI elements

    private lazy var knowledgeBaseRow = HelpView(item: HelpItem(icon: ImagesAsset.Help.apple,
                                                                title: Help.knowledgeBase,
                                                                subTitle: Help.allYouNeedToknowIsHere),
                                                 type: .navigation,
                                                 delegate: self, isDarkMode: viewModel.isDarkMode)
    private lazy var talkToGarryRow = HelpView(item: HelpItem(icon: ImagesAsset.Help.garry,
                                                              title: Help.talkToGarry,
                                                              subTitle: Help.notAsSmartAsSiri),
                                               type: .navigation,
                                               delegate: self, isDarkMode: viewModel.isDarkMode)

    private lazy var sendTicketRow = HelpView(item: HelpItem(icon: ImagesAsset.Help.ticket,
                                                             title: Help.sendTicket,
                                                             subTitle: Help.sendUsATicket),
                                              type: .navigation,
                                              delegate: self, isDarkMode: viewModel.isDarkMode)

    private lazy var viewDebugLogRow = HelpView(item: HelpItem(icon: ImagesAsset.Help.debugView,
                                                               title: TextsAsset.Debug.viewLog),
                                                type: .action,
                                                delegate: self, isDarkMode: viewModel.isDarkMode)
    private lazy var advanceParams = HelpView(item: HelpItem(icon: ImagesAsset.Preferences.advanceParams,
                                                             title: TextsAsset.Preferences.advanceParameters,
                                                             subTitle: Help.advanceParamDescription),
                                              type: .navigation,
                                              delegate: self, isDarkMode: viewModel.isDarkMode)

    private lazy var sendDebugLogRow: HelpView = {
        let vw = HelpView(item: HelpItem(icon: ImagesAsset.Help.debugSend,
                                         title: TextsAsset.Debug.sendLog),
                          type: .action,
                          delegate: self, isDarkMode: viewModel.isDarkMode)
        vw.header.updateStatus(TextsAsset.Debug.sentLog)
        return vw
    }()

    private lazy var communitySupportRow: HelpView = {
        let row = HelpView(item: HelpItem(icon: ImagesAsset.Help.community,
                                          title: Help.communitySupport,
                                          subTitle: Help.bestPlacesTohelp),
                           type: .navigation,
                           delegate: self, isDarkMode: viewModel.isDarkMode)
        redditRow.addTopDivider()
        redditRow.addBottomDivider()
        row.header.isUserInteractionEnabled = false
        row.listSubView = [redditRow, discordRow]
        return row
    }()

    private lazy var redditRow = HelpSubRowView(header: Help.reddit, isDarkMode: viewModel.isDarkMode, delegate: self)
    private lazy var discordRow = HelpSubRowView(header: Help.discord, isDarkMode: viewModel.isDarkMode, delegate: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.logD(self, "Displaying Help View")
        titleLabel.text = Help.helpMe

        viewModel.isDarkMode.subscribe { data in
            self.setupViews(isDark: data)
        }.disposed(by: disposeBag)

        setupUI()
    }

    override func viewWillLayoutSubviews() {
        layoutView.setup()
    }

    private func setupUI() {
        setupFillLayoutView()
        // if free user, then hide send ticket
        guard let isUserPro = sessionManager.session?.isUserPro else {
            logger.logD(HelpViewController.self, "session.isPremium is nil")
            return
        }
        if isUserPro {
            layoutView.stackView.addArrangedSubviews([
                knowledgeBaseRow,
                talkToGarryRow,
                sendTicketRow,
                communitySupportRow,
                advanceParams,
                viewDebugLogRow,
                sendDebugLogRow
            ])
        } else {
            layoutView.stackView.addArrangedSubviews([
                knowledgeBaseRow,
                talkToGarryRow,
                communitySupportRow,
                advanceParams,
                viewDebugLogRow,
                sendDebugLogRow
            ])
        }

        layoutView.stackView.setPadding(UIEdgeInsets(horizontalInset: 16, verticalInset: 12))
        layoutView.stackView.spacing = 16
    }

    @objc func sendLogButtonTapped() {
        if viewModel.networkStatus != NetworkStatus.connected {
            logger.logD(self, "No Internet available")
            DispatchQueue.main.async {
                self.viewModel.alertManager.showSimpleAlert(viewController: self, title: TextsAsset.appLogSubmitFailAlert, message: "", buttonText: TextsAsset.okay)
            }
        } else {
            sendDebugLogRow.header.updateTitle("\(TextsAsset.Debug.sendingLog)...", font: UIFont.text(size: 16))
            sendDebugLogRow.header.showLoading()
            viewModel.submitDebugLog(username: nil) { _, error in
                DispatchQueue.main.async {
                    self.sendDebugLogRow.header.updateTitle(TextsAsset.Debug.sendLog, font: UIFont.bold(size: 16))
                    self.sendDebugLogRow.header.completeLoading(error)
                    if error == nil {
                        self.sendDebugLogRow.header.updateTitle(TextsAsset.Debug.sendLog, font: UIFont.bold(size: 16))
                        self.sendDebugLogRow.isUserInteractionEnabled = false
                    } else {
                        self.viewModel.alertManager.showSimpleAlert(viewController: self, title: TextsAsset.appLogSubmitFailAlert, message: "", buttonText: TextsAsset.okay)
                    }
                }
            }
        }
    }

    @objc func viewLogButtonTapped() {
        router?.routeTo(to: RouteID.viewLog, from: self)
    }
}

// MARK: - HelpViewController

extension HelpViewController: HelpViewDelegate {
    func helpViewDidSelect(_ sender: HelpView) {
        switch sender {
        case knowledgeBaseRow:
            openLink(url: LinkProvider.getWindscribeLink(path: Links.knowledge))
        case talkToGarryRow:
            openLink(url: LinkProvider.getWindscribeLink(path: Links.garry))
        case sendTicketRow:
            router?.routeTo(to: RouteID.submitTicket, from: self)
        case communitySupportRow:
            break
        case viewDebugLogRow:
            viewLogButtonTapped()
        case sendDebugLogRow:
            sendLogButtonTapped()
        case advanceParams:
            router?.routeTo(to: RouteID.advanceParams, from: self)
        default:
            break
        }
    }
}

// MARK: - HelpSubRowViewDelegate

extension HelpViewController: HelpSubRowViewDelegate {
    func helpSubRowViewDidTap(_ sender: HelpSubRowView) {
        switch sender {
        case redditRow:
            openLink(url: Links.reddit)
        case discordRow:
            openLink(url: Links.discord)
        default:
            break
        }
    }
}
