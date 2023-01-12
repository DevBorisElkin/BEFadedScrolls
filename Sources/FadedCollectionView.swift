//
//  FadedCollectionView.swift
//  BEFadedScrolls
//
//  Created by Boris Elkin on 25.12.2022.
//

import UIKit

open class FadedCollectionView: UICollectionView {
    @IBInspectable private var isVertical: Bool = true
    
    @IBInspectable private var startFadeSizePercents: Int = 10 {
        didSet { startFadeSize = CGFloat(startFadeSizePercents) / 100 }
    }
    @IBInspectable private var endFadeSizePercents: Int = 10 {
        didSet { endFadeSize = CGFloat(endFadeSizePercents) / 100 }
    }
    @IBInspectable private var startProgressToHideFadePercents: Int = 10 {
        didSet { startProgressToHideFade = CGFloat(startProgressToHideFadePercents) / 100 }
    }
    @IBInspectable private var endProgressToHideFadePercents: Int = 10 {
        didSet { endProgressToHideFade = CGFloat(endProgressToHideFadePercents) / 100 }
    }
    
    /// min is 2. preferred max is 10, the smaller the value, the steeper the transition
    @IBInspectable private var logarithmicBase: Double = 10
    
    @IBInspectable private var linearInterpolation: Bool = true
    // further away from top/bottom borders - disappearing of content slows down
    @IBInspectable private var logarithmicFromEdges: Bool = false
    // further away from top/bottom borders - disappearing of content speeds up
    @IBInspectable private var exponentialFromEdges: Bool = false
    
    private var interpolation: CalculationHelpers.FadeInterpolation!
    
    private var enableStartFade: Bool = true
    private var enableEndFade: Bool = true
    private var startFadeSize: CGFloat = 0.1
    private var endFadeSize: CGFloat = 0.1
    private var startProgressToHideFade: CGFloat = 0.10
    private var endProgressToHideFade: CGFloat = 0.10
    
    @IBInspectable var debugId: String = "no_debug_id"
    @IBInspectable var debugModeEnabled: Bool = false
    @IBInspectable var debugProgressLogs: Bool = false
    
    // Internal items
    private var layerGradient: CAGradientLayer?
    
    private let transparentColor = UIColor.white.withAlphaComponent(0)
    private lazy var cgTransparentColor = transparentColor.cgColor
    private let opaqueColor = UIColor.white
    private lazy var cgOpaqueColor = opaqueColor.cgColor
    
    open var progressManager: ProgressManager!
    
    private var internalEnabledCheck: Bool {
        enableStartFade || enableEndFade
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    open override var contentOffset: CGPoint {
        didSet {
            guard internalEnabledCheck else { return }
            log("contentOffsetChanged to: \(contentOffset)")
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layerGradient?.frame = safeAreaLayoutGuide.layoutFrame
            CATransaction.commit()
            manageGradientColorsOnScroll()
        }
    }
    
    public func configure(startFadeSize: CGFloat, endFadeSize: CGFloat, interpolation: CalculationHelpers.FadeInterpolation) {
        self.configure(isVertical: true, startFadeSize: startFadeSize, endFadeSize: endFadeSize, startProgressToHideFade: startFadeSize, endProgressToHideFade: endFadeSize, interpolation: interpolation)
    }
    
    public func configureDebug(isVertical: Bool = true, startFadeSize: CGFloat = 0.15, endFadeSize: CGFloat = 0.15, startProgressToHideFade: CGFloat = 0.15, endProgressToHideFade: CGFloat = 0.15, interpolation: CalculationHelpers.FadeInterpolation = .logarithmicFromEdges(), debugModeEnabled: Bool, debugProgressLogs: Bool, debugId: String) {
        self.isVertical = isVertical
        self.startFadeSize = startFadeSize
        self.endFadeSize = endFadeSize
        self.startProgressToHideFade = startProgressToHideFade
        self.endProgressToHideFade = endProgressToHideFade
        self.interpolation = interpolation
        self.debugModeEnabled = debugModeEnabled
        self.debugProgressLogs = debugProgressLogs
        self.debugId = debugId
        commonInit()
    }
    
    public func configure(isVertical: Bool = true, startFadeSize: CGFloat = 0.15, endFadeSize: CGFloat = 0.15, startProgressToHideFade: CGFloat = 0.15, endProgressToHideFade: CGFloat = 0.15, interpolation: CalculationHelpers.FadeInterpolation = .logarithmicFromEdges()) {
        self.isVertical = isVertical
        self.startFadeSize = startFadeSize
        self.endFadeSize = endFadeSize
        self.startProgressToHideFade = startProgressToHideFade
        self.endProgressToHideFade = endProgressToHideFade
        self.interpolation = interpolation
        commonInit()
    }
    
    private func commonInit() {
        log("FadedScrollView.CommonInit() / isVertical: \(isVertical)")
        self.enableStartFade = startFadeSize > 0
        self.enableEndFade = endFadeSize > 0
        
        progressManager = isVertical ? VerticalProgressManager(debugModeEnabled: debugModeEnabled, debugId: debugId) : HorizontalProgressManager(debugModeEnabled: debugModeEnabled, debugId: debugId)
        progressManager.configure(parentScrollView: self, startFadeSizeMult: startProgressToHideFade, endFadeSizeMult: endProgressToHideFade)
        
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        
        configureFadeInterpolation(injectedFromCode: interpolation)
        configureFadeLayer()
    }
    
    private func configureFadeLayer() {
        let layerGradient = CAGradientLayer()
        self.layerGradient = layerGradient
        
        let firstColor = enableStartFade ? cgTransparentColor : cgOpaqueColor
        let lastColor = enableEndFade ? cgTransparentColor : cgOpaqueColor
        layerGradient.colors = [firstColor, cgOpaqueColor, cgOpaqueColor, lastColor]
        
        layerGradient.frame = bounds
        if isVertical {
            layerGradient.startPoint = CGPoint(x: 0, y: 0)
            layerGradient.endPoint = CGPoint(x: 0, y: 1)
        } else {
            layerGradient.startPoint = CGPoint(x: 0, y: 0)
            layerGradient.endPoint = CGPoint(x: 1, y: 0)
        }
        
        layerGradient.locations = [0, startFadeSize as NSNumber, (1.0 - endFadeSize) as NSNumber, 1.0]
        
        layer.addSublayer(layerGradient)
        if !debugModeEnabled {
            layer.mask = layerGradient
        }
        
        // first internal call
        manageGradientColorsOnScroll()
    }
    
    private func configureFadeInterpolation(injectedFromCode: CalculationHelpers.FadeInterpolation?) {
        if injectedFromCode == nil {
            if !linearInterpolation && !logarithmicFromEdges && !exponentialFromEdges {
                self.interpolation = .linear
            } else {
                self.interpolation = linearInterpolation ? .linear : logarithmicFromEdges ? .logarithmicFromEdges(base: logarithmicBase) : .exponentialFromEdges(base: logarithmicBase)
            }
        }
    }
    
    // MARK: Mange gradient colors on scroll
    private func manageGradientColorsOnScroll() {
        log("manageGradientColorsOnScroll, isVertical: \(isVertical)")
        if var colors = layerGradient?.colors as? [CGColor] {
            let progress = progressManager.calculateProgress()
            
            progressLog("progress: \(progress)")
            if enableStartFade {
                let startAbsProgress = progressManager.calculateStartFadeProgress()
                let startTransformedProgress = CalculationHelpers.logarythmicBasedDependence(progress: startAbsProgress, interpolation: interpolation)
                colors[0] = opaqueColor.withAlphaComponent(startTransformedProgress).cgColor
                progressLog("startAbsProgress: \(startAbsProgress)")
                progressLog("startTransformedProgress: \(startTransformedProgress)")
            }
            if enableEndFade {
                let endAbsProgress = progressManager.calculateEndFadeProgress()
                let endTransformedProgress = CalculationHelpers.logarythmicBasedDependence(progress: endAbsProgress, interpolation: interpolation)
                colors[3] = opaqueColor.withAlphaComponent(endTransformedProgress).cgColor
                progressLog("endAbsProgress: \(endAbsProgress)")
                progressLog("endTransformedProgress: \(endTransformedProgress)")
            }
            
            layerGradient?.colors = colors
        }
    }
    
    private func log(_ message: String) {
        guard debugModeEnabled else { return }
        print("[\(debugId)]: \(message)")
    }
    private func progressLog(_ message: String) {
        guard debugProgressLogs else { return }
        print("[\(debugId)]: \(message)")
    }
}
