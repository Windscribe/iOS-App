import UIKit

class NewsFeedDataCell: UITableViewCell {
    private let readStatusDot = UIView()
    private let background = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let expandIcon = UIImageView()
    private let actionButton = UILabel()
    private let arrowIcon = UIImageView()
    private let stackView = UIStackView()
    private var item: NewsFeedData?
    private let expandTapHandler = UIView()
    private let actionTapHandler = UIView()
    private let titleStackView = UIStackView()

    var didTapActionLabel: ((ActionLink) -> Void)?
    var didTapExpandIcon: ((Int) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        accessoryType = .none
        contentView.isUserInteractionEnabled = true
        backgroundColor = UIColor.clear

        // Background
        background.clipsToBounds = true
        background.backgroundColor = UIColor.white
        background.layer.opacity = 0.05
        background.layer.cornerRadius = 8
        contentView.addSubview(background)

        // Stack View for title, description, and actions
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .leading
        contentView.addSubview(stackView)

        // Dot
        readStatusDot.backgroundColor = UIColor.seaGreen
        readStatusDot.layer.cornerRadius = 3.5
        contentView.addSubview(readStatusDot)

        // Expand Icon
        expandIcon.image = UIImage(named: ImagesAsset.whiteExpand)
        expandIcon.isUserInteractionEnabled = true
        expandIcon.contentMode = .center
        contentView.addSubview(expandIcon)

        // Title
        titleLabel.font = UIFont.bold(size: 12)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.numberOfLines = 1
        titleLabel.textColor = UIColor.whiteWithOpacity(opacity: 0.5)

        // Description
        descriptionLabel.font = UIFont.regular(size: 14)
        descriptionLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        descriptionLabel.numberOfLines = 0

        // Action
        actionButton.textColor = UIColor.white.withAlphaComponent(0.5)
        actionButton.font = UIFont.bold(size: 14)
        actionButton.isUserInteractionEnabled = true

        // Arrow icon
        arrowIcon.contentMode = .scaleAspectFit
        arrowIcon.image = UIImage(named: ImagesAsset.smallWhiteRightArrow)
        contentView.addSubview(arrowIcon)

        // Action tap handler
        let actionTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onActionTap))
        actionTapHandler.addGestureRecognizer(actionTapGestureRecognizer)
        contentView.addSubview(actionTapHandler)

        titleStackView.axis = .horizontal
        titleStackView.alignment = .center
        titleStackView.spacing = 8
        titleStackView.distribution = .fill
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(expandIcon)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        expandIcon.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        stackView.addArrangedSubview(titleStackView)
        stackView.addArrangedSubview(descriptionLabel)
        stackView.addArrangedSubview(actionButton)

        // Expand Tap handler
        let expandTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onExpandButtonTap))
        expandTapHandler.addGestureRecognizer(expandTapGestureRecognizer)
        contentView.addSubview(expandTapHandler)

        // Disable Auto Layout
        readStatusDot.translatesAutoresizingMaskIntoConstraints = false
        background.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        expandIcon.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        arrowIcon.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        actionTapHandler.translatesAutoresizingMaskIntoConstraints = false
        expandTapHandler.translatesAutoresizingMaskIntoConstraints = false

        // Constraints
        NSLayoutConstraint.activate([
            titleStackView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            titleStackView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

            background.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            background.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            background.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            background.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            stackView.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: background.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -16),

            // ReadStatusDot positioning
            readStatusDot.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            readStatusDot.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: -3.5),
            readStatusDot.widthAnchor.constraint(equalToConstant: 7),
            readStatusDot.heightAnchor.constraint(equalToConstant: 7),

            // Expand Icon positioning within titleStackView
            expandIcon.widthAnchor.constraint(equalToConstant: 24),
            expandIcon.heightAnchor.constraint(equalToConstant: 24),

            // Action and arrow icons
            arrowIcon.leadingAnchor.constraint(equalTo: actionButton.trailingAnchor, constant: 4),
            arrowIcon.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor),
            arrowIcon.widthAnchor.constraint(equalToConstant: 12),
            arrowIcon.heightAnchor.constraint(equalToConstant: 12),

            actionTapHandler.leadingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -4),
            actionTapHandler.trailingAnchor.constraint(equalTo: arrowIcon.trailingAnchor, constant: 4),
            actionTapHandler.topAnchor.constraint(equalTo: actionButton.topAnchor, constant: -4),
            actionTapHandler.bottomAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 4),

            expandTapHandler.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            expandTapHandler.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            expandTapHandler.topAnchor.constraint(equalTo: background.topAnchor, constant: 0),
            expandTapHandler.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(with item: NewsFeedData) {
        self.item = item
        titleLabel.text = item.title.uppercased()
        titleLabel.tag = item.id
        readStatusDot.isHidden = item.readStatus
        if item.expanded {
            updateCollapseUI(collapsed: false, animate: item.animate)
            descriptionLabel.text = item.description
            descriptionLabel.isHidden = false
            setActionButtonState()
        } else {
            setTitleOnlyState()
        }
    }

    private func setTitleOnlyState() {
        if let item = item {
            updateCollapseUI(collapsed: true, animate: item.animate)
            descriptionLabel.text = ""
            descriptionLabel.isHidden = true
            actionButton.isHidden = true
            arrowIcon.isHidden = true
            actionTapHandler.isHidden = true
        }
    }

    private func setActionButtonState() {
        if let actionLink = item?.actionLink {
            actionButton.text = actionLink.title
            actionButton.isHidden = false
            arrowIcon.isHidden = false
            actionTapHandler.isHidden = false
        } else {
            actionButton.isHidden = true
            arrowIcon.isHidden = true
            actionTapHandler.isHidden = true
        }
    }

    private func updateCollapseUI(collapsed: Bool, animate: Bool) {
        if animate {
            if collapsed { showForExpand() } else { showForCollapse() }
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                collapsed ? self?.showForCollapse() : self?.showForExpand()
            })
        } else {
            if collapsed { showForCollapse() } else { showForExpand() }
        }
    }

    private func showForExpand() {
        titleLabel.textColor = UIColor.white
        expandIcon.layer.opacity = 1.0
        expandIcon.transform = CGAffineTransform(rotationAngle: .pi / 4)
    }

    private func showForCollapse() {
        titleLabel.textColor = UIColor.whiteWithOpacity(opacity: 0.5)
        expandIcon.layer.opacity = 0.4
        expandIcon.transform = CGAffineTransform(rotationAngle: .pi * 4)
    }

    @objc func onExpandButtonTap() {
        didTapExpandIcon?(titleLabel.tag)
    }

    @objc func onActionTap() {
        if let actionLink = item?.actionLink {
            didTapActionLabel?(actionLink)
        }
    }
}
