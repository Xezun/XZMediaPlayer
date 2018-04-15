//
//  MediaPlayerView.swift
//  XZKit
//
//  Created by mlibai on 2018/4/14.
//  Copyright © 2018年 mlibai. All rights reserved.
//

import UIKit
import AVFoundation

/// MediaPlayerView 播放器视图。
@objc(XZMediaPlayerView) public final class MediaPlayerView: UIView {
    
    open override class var layerClass: Swift.AnyClass {
        return AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    //    public override func draw(_ rect: CGRect) {
    //
    //        let bounds = self.bounds
    //
    //        let shadow = NSShadow()
    //        shadow.shadowColor = UIColor(rgba: 0x444444EE)
    //        shadow.shadowOffset = CGSize.zero//(width: 0, height: 3.0)
    //        shadow.shadowBlurRadius = 3.0
    //
    //        let attribute: [String: Any] = [
    //            NSFontAttributeName: UIFont.systemFont(ofSize: 24),
    //            NSForegroundColorAttributeName: UIColor.darkGray,
    //            NSShadowAttributeName: shadow
    //        ]
    //
    //        let string: NSAttributedString = NSAttributedString(string: "XZKit®", attributes: attribute)
    //        let size = string.size()
    //        string.draw(at: CGPoint(x: (bounds.width - size.width) * 0.5, y: (bounds.height - size.height) * 0.5))
    //
    //    }
    
}
