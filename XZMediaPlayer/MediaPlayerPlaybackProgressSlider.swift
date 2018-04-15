//
//  MediaPlayerPlaybackProgressSlider.swift
//  XZKit
//
//  Created by mlibai on 2017/6/28.
//
//

import UIKit



@objc(XZMediaPlayerPlaybackProgressSlider)
open class MediaPlayerPlaybackProgressSlider: UIControl {
    
    public let thumbImageView      = UIImageView()      // 拖动按钮
    public let trackView           = UIView()           // 轨道
    public let progressView        = UIView()           // 播放进度
    public let bufferProgressView  = UIView()           // 缓冲进度
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        didInitialize()
    }
    
    
    private func didInitialize() {
        trackView.backgroundColor           = UIColor.gray
        addSubview(trackView)
        
        bufferProgressView.backgroundColor  = UIColor.lightGray
        addSubview(bufferProgressView)
        
        progressView.backgroundColor        = UIColor.blue
        addSubview(progressView)
        
        thumbImageView.image                = UIImage(XZKit: "img_player_slider_thumb")
        addSubview(thumbImageView)
    }
    
    open var progress: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    open var bufferProgress: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    open var thumbImage: UIImage? {
        get {
            return thumbImageView.image
        }
        set {
            thumbImageView.image = newValue
            setNeedsLayout()
        }
    }
    
    open var trackTintColor: UIColor? {
        get { return trackView.backgroundColor }
        set { trackView.backgroundColor = newValue }
    }
    
    open var progressTintColor: UIColor? {
        get { return progressView.backgroundColor }
        set { progressView.backgroundColor = newValue }
    }
    
    open var bufferProgressTintColor: UIColor? {
        get { return bufferProgressView.backgroundColor }
        set { bufferProgressView.backgroundColor = newValue }
    }
    
    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if abs(touch.location(in: self).x - progressView.frame.maxX) < 60 {
            return true
        }
        return false
    }
    
    override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let progress = min(1.0, max(0, touch.location(in: self).x / trackView.frame.width))
        if self.progress != progress {
            self.progress = progress
            sendActions(for: .valueChanged)
        }
        return true
    }
    
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let kBounds = self.bounds
        
        let frame1 = CGRect(x: 0, y: kBounds.midY - 1.0, width: kBounds.width, height: 2.0)
        trackView.frame = frame1
        
        let frame2 = CGRect(x: frame1.minX, y: frame1.minY, width: frame1.width * progress, height: frame1.height)
        progressView.frame = frame2
        
        let frame3 = CGRect(x: frame1.minX, y: frame1.minY, width: frame1.width * bufferProgress, height: frame1.height)
        bufferProgressView.frame = frame3
        
        thumbImageView.sizeToFit()
        var size = thumbImageView.frame.size
        if size == .zero {
            size = CGSize(width: 4.0, height: 4.0)
        }
        let x = min(frame2.maxX, max(frame2.maxX - size.width * 0.5, 0))
        
        let frame4 = CGRect(x: x, y: frame2.midY - size.height * 0.5, width: size.width, height: size.height)
        thumbImageView.frame = frame4
    }
    
}
