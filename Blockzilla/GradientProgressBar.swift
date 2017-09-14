/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// ADAPTED FROM:
//
//  GradientProgressBar.swift
//  GradientProgressBar
//
//  Created by Felix Mau on 01.03.17.
//  Copyright © 2017 Felix Mau. All rights reserved.
//

import Foundation
import UIKit

open class GradientProgressBar: UIProgressView {

    private struct DefaultValues {
        static let backgroundColor = UIColor.clear

        static let gradientColors = [
            UIColor(rgb: 0xFF1AD9).cgColor,
            UIColor(rgb: 0x9400FF).cgColor,
            UIColor(rgb: 0xFF1AD9).cgColor,
            UIColor(rgb: 0x9400FF).cgColor,
            UIColor(rgb: 0xFF1AD9).cgColor,
            UIColor(rgb: 0x9400FF).cgColor,
            UIColor(rgb: 0xFF1AD9).cgColor
        ]

        static let animationDuration = 0.2 // CALayer default animation duration
    }

    // Alpha mask for visible part of gradient.
    private var alphaMaskLayer: CALayer = CALayer()

    // Gradient layer.
    open var gradientLayer: CAGradientLayer = CAGradientLayer()

    // Duration for "setProgress(animated: true)"
    open var animationDuration = DefaultValues.animationDuration

    // Workaround to handle orientation change, as "layoutSubviews()" gets triggered each time
    // the progress value is changed.
    override open var bounds: CGRect {
        didSet {
            updateAlphaMaskLayerWidth()
        }
    }

    // Update layer mask on direct changes to progress value.
    override open var progress: Float {
        didSet {
            updateAlphaMaskLayerWidth()
        }
    }

    // MARK: - Initializers

    override public init(frame: CGRect) {
        super.init(frame: frame)

        setupProgressViewColors()
        setupAlphaMaskLayer()
        setupGradientLayer()

        layer.insertSublayer(gradientLayer, at: 0)
        updateAlphaMaskLayerWidth()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupProgressViewColors()
        setupAlphaMaskLayer()
        setupGradientLayer()

        layer.insertSublayer(gradientLayer, at: 0)
        updateAlphaMaskLayerWidth()
    }

    // MARK: - Setup UIProgressView

    private func setupProgressViewColors() {
        backgroundColor = DefaultValues.backgroundColor
        trackTintColor = .clear
        progressTintColor = .clear
    }

    // MARK: - Setup layers

    private func setupAlphaMaskLayer() {
        alphaMaskLayer.frame = bounds
        alphaMaskLayer.cornerRadius = 3

        alphaMaskLayer.anchorPoint = CGPoint(x: 0, y: 0)
        alphaMaskLayer.position = CGPoint(x: 0, y: 0)

        alphaMaskLayer.backgroundColor = UIColor.white.cgColor
    }

    private func setupGradientLayer() {
        // Apply "alphaMaskLayer" as a mask to the gradient layer in order to show only parts of the current "progress"
        gradientLayer.mask = alphaMaskLayer

        gradientLayer.frame = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.size.width * 2, height: bounds.size.height)
        gradientLayer.colors = DefaultValues.gradientColors
        gradientLayer.locations = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.0]
        gradientLayer.startPoint = CGPoint(x:0, y:0)
        gradientLayer.endPoint = CGPoint(x:1, y:0)
        gradientLayer.drawsAsynchronously = true
    }

    func hideProgressBar() {
        CATransaction.begin()
        let moveAnimation = CABasicAnimation(keyPath: "position")
        moveAnimation.duration = UIConstants.layout.overlayAnimationDuration
        moveAnimation.fromValue = gradientLayer.position
        moveAnimation.toValue = CGPoint(x: gradientLayer.frame.width, y: gradientLayer.position.y)
        moveAnimation.fillMode = kCAFillModeForwards
        moveAnimation.isRemovedOnCompletion = false


        CATransaction.setCompletionBlock {
            self.resetProgressBar()
        }

        gradientLayer.add(moveAnimation, forKey: "position")

        CATransaction.commit()
    }

    func resetProgressBar() {
        setProgress(0, animated: false)
        gradientLayer.removeAllAnimations()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        self.gradientLayer.frame = CGRect(x: bounds.origin.x - 4, y: bounds.origin.y, width: bounds.size.width * 2, height: bounds.size.height)
    }

    func animateGradient() {
        let gradientChangeAnimation = CABasicAnimation(keyPath: "locations")
        gradientChangeAnimation.duration = 0.4
        gradientChangeAnimation.toValue = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.0]
        gradientChangeAnimation.fromValue = [0.0, 0.0, 0.0, 0.2, 0.4, 0.6, 0.8]
        gradientChangeAnimation.fillMode = kCAFillModeForwards
        gradientChangeAnimation.isRemovedOnCompletion = false
        gradientChangeAnimation.repeatCount = .infinity
        gradientLayer.add(gradientChangeAnimation, forKey: "colorChange")
    }

    // MARK: - Update gradient

    open func updateAlphaMaskLayerWidth(animated: Bool = false) {
        CATransaction.begin()
        // Workaround for non animated progress change
        // Source: https://stackoverflow.com/a/16381287/3532505
        CATransaction.setAnimationDuration(animated ? animationDuration : 0.0)
        alphaMaskLayer.frame = bounds.updateWidth(byPercentage: CGFloat(progress))
        CATransaction.commit()
    }

    override open func setProgress(_ progress: Float, animated: Bool) {
        super.setProgress(progress, animated: animated)

        updateAlphaMaskLayerWidth(animated: animated)
    }
}

extension CGRect {
    func updateWidth(byPercentage percentage: CGFloat) -> CGRect {
        return CGRect(x: origin.x, y: origin.y, width: size.width * percentage, height: size.height)
    }
}
