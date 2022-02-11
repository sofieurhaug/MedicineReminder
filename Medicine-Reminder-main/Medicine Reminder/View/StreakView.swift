//
//  StreakView.swift
//  Medicine Reminder
//
//  Created by Sofie Tjønneland Urhaug on 13/01/2022.
//

import Foundation
import UIKit
import CareKitUI

class StreakView: UIView {
    

    var cardView: UIView { self }
    let contentView: UIView = OCKView()
    let headerView = OCKHeaderView()
    var imageHeightConstraint: NSLayoutConstraint!

    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.regular)
        return UIVisualEffectView(effect: blurEffect)
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        headerView.detailLabel.textColor = .secondaryLabel

        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = layer.cornerRadius
        blurView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.frame = bounds

        addSubview(contentView)
        contentView.addSubview(blurView)
        contentView.addSubview(headerView)

       
        blurView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),

            blurView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: contentView.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),

        ])
    }

    func scaledImageHeight(compatibleWith traitCollection: UITraitCollection) -> CGFloat {
        return UIFontMetrics.default.scaledValue(for: 200, compatibleWith: traitCollection)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            imageHeightConstraint.constant = scaledImageHeight(compatibleWith: traitCollection)
        }
    }t
}
