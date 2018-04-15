//
//  MediaPlayerPlaybackControlsView.swift
//  XZKit
//
//  Created by mlibai on 2017/5/26.
//  Copyright © 2017年 mlibai. All rights reserved.
//

import UIKit

@objc(XZMediaPlayerPlaybackControlsView)
open class MediaPlayerPlaybackControlsView: UIView {
    
    /// 播放进度发生改变时，此方法会被调用。
    ///
    /// - Parameter mediaPlayer: MediaPlayer
    open func mediaPlayerPlaybackDidUpdate(_ mediaPlayer: MediaPlayer) {
        
    }
    
    /// 播放状态发生改变。
    ///
    /// - Parameters:
    ///   - mediaPlayer: MediaPlayer
    ///   - status: MediaPlayer.Status
    open func mediaPlayer(_ mediaPlayer: MediaPlayer, statusDidChange status: MediaPlayer.Status) {
        
    }
    
    /// 全屏状态发生改变。
    ///
    /// - Parameters:
    ///   - mediaPlayer: MediaPlayer
    ///   - isZoomed: isZoomed
    open func mediaPlayer(_ mediaPlayer: MediaPlayer, didZoom isZoomed: Bool) {
        
    }
    
    /// 缓冲进度发生改变。
    ///
    /// - Parameters:
    ///   - mediaPlayer: MediaPlayer
    ///   - progress: 0 ~ 1.0
    open func mediaPlayer(_ mediaPlayer: MediaPlayer, didLoadMediaWith progress: CGFloat) {
        
    }
    
}
//
//@available(*, deprecated, message: "重构中，请勿使用！")
//public protocol MediaPlayerPlaybackControlsViewDelegate: class {
//
//}
//
//
//
//@available(*, deprecated, message: "重构中，请勿使用！")
//open class MediaPlayerPlaybackControlsView: UIView {
//    
//    open weak var delegate: MediaPlayerPlaybackControlsViewDelegate?
//    
//    open let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
//    
//    open let controlBar      = UIView()
//    open let playButton      = UIButton()
//    open let progressView    = MediaPlayer.PlaybackProgressSlider()
//    open let playedTimeLabel = UILabel()
//    open let remainTimeLabel = UILabel()
//    open let zoomButton      = UIButton()
//    
//    convenience init() {
//        self.init(frame: CGRect(x: 0, y: 0, width: 480, height: 320))
//    }
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        didInitialize()
//    }
//    
//    required public init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        didInitialize()
//    }
//    
//    deinit {
//        _controlBarAutoHideTimer?.invalidate()
//    }
//    
//    @objc fileprivate func playButtonAction(_ button: UIButton) {
//        
//    }
//    
//    @objc fileprivate func zoomButtonAction(_ button: UIButton) {
//        
//    }
//    
//    @objc fileprivate func progressViewValueDidChange(_ progressView: MediaPlayer.PlaybackProgressSlider) {
//        
//    }
//    
//    fileprivate func statusDidChange() {
//        
//    }
//    
//    // 自动隐藏控制栏的定时器
//    fileprivate var _controlBarAutoHideTimer: Timer?
//    fileprivate var controlBarAutoHideTimer: Timer {
//        if let timer = _controlBarAutoHideTimer {
//            return timer
//        }
//        let timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(hideControlBarIfNeeded), userInfo: nil, repeats: true)
//        _controlBarAutoHideTimer = timer
//        return timer
//    }
//    
//    /// 如果当前正在播放就隐藏控制栏
//    @objc fileprivate func hideControlBarIfNeeded() {
//        
//    }
//    
//    /// 手势单击事件，正在播放过程中，控制播放控制栏的显示和隐藏
//    @objc fileprivate func tapAction(_ tap: UITapGestureRecognizer) {
//        
//    }
//    
//    // MARK: ★★★  布局 UI  ★★★
//    
//    fileprivate func didInitialize() {
//        backgroundColor = .clear
//        let BOUNDS = self.bounds
//        
//        activityIndicatorView.frame = BOUNDS
//        activityIndicatorView.hidesWhenStopped = true
//        activityIndicatorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        addSubview(activityIndicatorView)
//        
//        controlBar.frame = CGRect(x: 0, y: BOUNDS.maxY - 40, width: BOUNDS.width, height: 40)
//        controlBar.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
//        controlBar.backgroundColor = UIColor(white: 0, alpha: 0.7)
//        addSubview(controlBar)
//        
//        controlBar.translatesAutoresizingMaskIntoConstraints = false
//        do {
//            let formatH = "H:|[controlBar]|"
//            let formatV = "V:[controlBar(==40)]|"
//            let views: [String: Any] = [
//                "controlBar": controlBar
//            ]
//            let lcs2 = NSLayoutConstraint.constraints(withVisualFormat: formatV, options: .directionLeftToRight, metrics: nil, views: views)
//            let lcs3 = NSLayoutConstraint.constraints(withVisualFormat: formatH, options: .alignAllLeft, metrics: nil, views: views)
//            addConstraints(lcs2)
//            addConstraints(lcs3)
//        }
//        
//        // 播放按钮
//        playButton.setImage(UIImage(XZKit: "btn_player_play"), for: .normal)
//        playButton.setImage(UIImage(XZKit: "btn_player_pause"), for: .selected)
//        controlBar.addSubview(playButton)
//        // 已播放时间
//        let textColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
//        let font = UIFont.systemFont(ofSize: 9)
//        playedTimeLabel.text        = "00:00"
//        playedTimeLabel.textColor   = textColor
//        playedTimeLabel.font        = font
//        controlBar.addSubview(playedTimeLabel)
//        // 进度条
//        progressView.progress = 0.0
//        progressView.bufferProgress = 0.0
//        controlBar.addSubview(progressView)
//        // 剩余时间
//        remainTimeLabel.text        = "--:--"
//        remainTimeLabel.textColor   = textColor
//        remainTimeLabel.font        = font
//        controlBar.addSubview(remainTimeLabel)
//        // 全屏按钮
//        zoomButton.setImage(UIImage(XZKit: "btn_player_zoomin"), for: .normal)
//        zoomButton.setImage(UIImage(XZKit: "btn_player_zoomout"), for: .selected)
//        controlBar.addSubview(zoomButton)
//        
//        playButton.translatesAutoresizingMaskIntoConstraints        = false
//        playedTimeLabel.translatesAutoresizingMaskIntoConstraints   = false
//        progressView.translatesAutoresizingMaskIntoConstraints      = false
//        remainTimeLabel.translatesAutoresizingMaskIntoConstraints   = false
//        zoomButton.translatesAutoresizingMaskIntoConstraints        = false
//        do {
//            let format = "H:|-10-[playButton(==30)]-10-[playedTimeLabel]-10-[progressView]-10-[remainTimeLabel]-10-[zoomButton(==30)]-10-|"
//            let views: [String: Any] = [
//                "playButton": playButton,
//                "playedTimeLabel": playedTimeLabel,
//                "progressView": progressView,
//                "remainTimeLabel": remainTimeLabel,
//                "zoomButton": zoomButton
//            ]
//            let lcs1 = NSLayoutConstraint.constraints(withVisualFormat: format, options: .directionLeftToRight, metrics: nil, views: views)
//            controlBar.addConstraints(lcs1)
//            
//            let lc1 = NSLayoutConstraint(item: playButton, attribute: .centerY, relatedBy: .equal, toItem: controlBar, attribute: .centerY, multiplier: 1.0, constant: 0)
//            let lc2 = NSLayoutConstraint(item: playButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 30)
//            let lc3 = NSLayoutConstraint(item: playedTimeLabel, attribute: .centerY, relatedBy: .equal, toItem: controlBar, attribute: .centerY, multiplier: 1.0, constant: 0)
//            let lc4 = NSLayoutConstraint(item: progressView, attribute: .centerY, relatedBy: .equal, toItem: controlBar, attribute: .centerY, multiplier: 1.0, constant: 0)
//            let lc5 = NSLayoutConstraint(item: progressView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 40)
//            let lc6 = NSLayoutConstraint(item: remainTimeLabel, attribute: .centerY, relatedBy: .equal, toItem: controlBar, attribute: .centerY, multiplier: 1.0, constant: 0)
//            let lc7 = NSLayoutConstraint(item: zoomButton, attribute: .centerY, relatedBy: .equal, toItem: controlBar, attribute: .centerY, multiplier: 1.0, constant: 0)
//            let lc8 = NSLayoutConstraint(item: zoomButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 30)
//            controlBar.addConstraint(lc1)
//            controlBar.addConstraint(lc2)
//            controlBar.addConstraint(lc3)
//            controlBar.addConstraint(lc4)
//            controlBar.addConstraint(lc5)
//            controlBar.addConstraint(lc6)
//            controlBar.addConstraint(lc7)
//            controlBar.addConstraint(lc8)
//        }
//        
//        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
//        addGestureRecognizer(tap)
//        
//        // events
//        
//        playButton.addTarget(self, action: #selector(playButtonAction(_:)), for: .touchUpInside)
//        zoomButton.addTarget(self, action: #selector(zoomButtonAction(_:)), for: .touchUpInside)
//        progressView.addTarget(self, action: #selector(progressViewValueDidChange(_:)), for: .valueChanged)
//        
//        statusDidChange()
//    }
//    
//    
//}










