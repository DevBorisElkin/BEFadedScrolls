//
//  ProgressManager.swift
//  BEFadedScrolls
//
//  Created by Boris Elkin on 25.12.2022.
//

import UIKit

open class ProgressManager {
    internal weak var parentScrollView: UIScrollView!
    internal var startFadeSizeMult: CGFloat = 0
    internal var endFadeSizeMult: CGFloat = 0
    internal var debugModeEnabled: Bool
    internal var debugId: String = "no_debug_id"
    
    init(debugModeEnabled: Bool, debugId: String) {
        self.debugModeEnabled = debugModeEnabled
        self.debugId = debugId
    }
    
    // for debugging only
    func calculateProgress() -> CGFloat {
        let maxHeightForProgress = contentSize() - scrollViewSize()
        return max(min(contentOffset() / maxHeightForProgress, 1), 0)
    }
    
    func scrollViewSize() -> CGFloat { print("Internal Error! Base class ProgressManager method is being called!"); return 0 }
    func contentSize() -> CGFloat { print("Internal Error! Base class ProgressManager method is being called!"); return 0 }
    func contentOffset() -> CGFloat { print("Internal Error! Base class ProgressManager method is being called!"); return 0 }
    func effectiveContentOffset() -> CGFloat {
        return contentOffset() + scrollViewSize()
    }
    
    func calculateStartFadeProgress() -> CGFloat {
        let maxProgress = scrollViewSize() * startFadeSizeMult
        if contentOffset() > maxProgress { return 0 }
        
        return min(1 - (contentOffset() / maxProgress), 1)
    }
    func calculateEndFadeProgress() -> CGFloat {
        let scrolledFromEnd = contentSize() - effectiveContentOffset()
        let maxProgress = scrollViewSize() * endFadeSizeMult
        if scrolledFromEnd > maxProgress { return 0 }
        return min(1 - scrolledFromEnd / maxProgress, 1)
    }
    
    func configure(parentScrollView: UIScrollView?, startFadeSizeMult: CGFloat, endFadeSizeMult: CGFloat) {
        self.parentScrollView = parentScrollView
        self.startFadeSizeMult = startFadeSizeMult
        self.endFadeSizeMult = endFadeSizeMult
    }
    
    internal func log(_ message: String) {
        guard debugModeEnabled else { return }
        print("[\(debugId)]: \(message)")
    }
}

class VerticalProgressManager: ProgressManager {
    override init(debugModeEnabled: Bool, debugId: String) {
        super.init(debugModeEnabled: debugModeEnabled, debugId: debugId)
        log("VerticalProgressManager created")
    }
    override func scrollViewSize() -> CGFloat { parentScrollView.bounds.height }
    override func contentSize() -> CGFloat { parentScrollView.contentSize.height }
    override func contentOffset() -> CGFloat { parentScrollView.contentOffset.y }
}

class HorizontalProgressManager: ProgressManager {
    override init(debugModeEnabled: Bool, debugId: String) {
        super.init(debugModeEnabled: debugModeEnabled, debugId: debugId)
        log("HorizontalProgressManager created")
    }
    override func scrollViewSize() -> CGFloat { parentScrollView.bounds.width }
    override func contentSize() -> CGFloat { parentScrollView.contentSize.width }
    override func contentOffset() -> CGFloat { parentScrollView.contentOffset.x }
}
