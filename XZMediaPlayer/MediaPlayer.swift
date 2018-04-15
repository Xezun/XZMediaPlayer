//
//  MediaPlayer.swift
//  XZKit
//
//  Created by mlibai on 2017/5/25.
//  Copyright © 2017年 mlibai. All rights reserved.
//

//  Note1: 在同一个 Window 上，无法隐藏状态栏。

import Foundation
import AVFoundation
import AVKit

extension MediaPlayer {
    
    /// MediaPlayer 执行动画时长的基准时长，每个动画为此值或其整数倍。
    public static let AnimationDuration: TimeInterval = 0.3
    
    /// 定义了 MediaPlayer 展示视频的视图。
    @objc(XZMediaPlayerStatus)
    public enum Status: Int {
        /// 播放器停止，默认状态。
        /// - Note: 播放失败时，播放器进入停止状态。
        case stopped
        /// 正在播放。
        case playing
        /// 播放中断，缓冲中。
        /// - 播放中断时，缓冲完毕会自动播放。
        case stalled
        /// 已暂停。
        /// - 播放完成时，播放器进入暂停状态，定格在最后一帧。
        case paused
    }
    
}


@objc(XZMediaPlayerDelegate)
public protocol MediaPlayerDelegate: class {
    
    /// When the view is ready to display any thing, this method will be called.
    ///
    /// - Parameter mediaPlayer: 调用此方法的 MediaPlayer 对象
    func mediaPlayerIsReadyForDisplay(_ mediaPlayer: MediaPlayer)
    
    /// 当播放完成时，此方法会被调用。
    ///
    /// - Parameter mediaPlayer: 调用此方法的 MediaPlayer 对象
    func mediaPlayerDidPlayToEndTime(_ mediaPlayer: MediaPlayer)
    
    /// 当播放失败时，此方法会被调用。
    ///
    /// - Parameter mediaPlayer: 调用此方法的 MediaPlayer 对象
    func mediaPlayerFailedToPlayToEndTime(_ mediaPlayer: MediaPlayer)
    
    func mediaPlayerPlaybackStalled(_ mediaPlayer: MediaPlayer)
    
    /// 播放器将要开始缩放画面。播放器自适应屏幕方向时，将要进入全屏或将要退出全屏，会触发此方法。
    ///
    /// - Parameter mediaPlayer: 调用此方法的 MediaPlayer 对象
    func mediaPlayerWillBeginZooming(_ mediaPlayer: MediaPlayer)
    
    /// 播放器完成缩放。播放器自适应屏幕方向时，已经进入全屏或以退出全屏，会触发此方法。
    ///
    /// - Parameter mediaPlayer: 调用此方法的 MediaPlayer 对象
    func mediaPlayerDidFinishZooming(_ mediaPlayer: MediaPlayer)
    
}

/// MediaPlayer
@objc(XZMediaPlayer)
public final class MediaPlayer: UIViewController {
    
    /// 事件代理
    public weak var delegate: MediaPlayerDelegate?
    
    public private(set) lazy var playerView: MediaPlayerView = MediaPlayerView(frame: UIScreen.main.bounds)
    public private(set) lazy var player: AVPlayer = AVPlayer.init()
    
    open private(set) var status: Status = .stopped
    
    /// 是否自动适应设备方向。
    /// - 当此属性开启时，如果视频正在播放，屏幕横屏时，播放器将自动旋转至全屏状态。
    /// - 自动进入全屏状态时，竖屏会自动回小屏状态。
    /// - 手动进入全屏，即使该属性开启，也不会自动返回小屏状态。
    public var automaticallyAdjustsDeviceOrientation: Bool = false {
        didSet {
            guard oldValue != automaticallyAdjustsDeviceOrientation else {
                return
            }
            // 屏幕旋转
            if automaticallyAdjustsDeviceOrientation {
                let sel = #selector(deviceOrientationDidChange(_:))
                NotificationCenter.default.addObserver(self, selector: sel, name: .UIDeviceOrientationDidChange, object: nil)
            } else {
                NotificationCenter.default.removeObserver(self, name: .UIDeviceOrientationDidChange, object: nil)
            }
        }
    }
    
    /// 是否处于全屏
    public var isZoomed = false
    
    /// 是否正在进入/退出全屏
    public var isZooming = false
    
    /// 播放进度的观察器
    private var timeObserver: Any?
    
    deinit {
        if let observer = self.timeObserver {
            player.removeTimeObserver(observer)
        }
        
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.status), context: &KVOContext.AVPlayerStatus)
        playerView.playerLayer.removeObserver(self, forKeyPath: #keyPath(AVPlayerLayer.isReadyForDisplay), context: &KVOContext.AVPlayerLayerIsReadyForDisplay)
        
        if let item = player.currentItem {
            stopObserving(item)
        }
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: nil)
        
        if automaticallyAdjustsDeviceOrientation {
            NotificationCenter.default.removeObserver(self, name: .UIDeviceOrientationDidChange, object: nil)
        }
    }
    
    /// 视频时长。
    /// 如果没有视频，或没有获取到视频时长，返回 0 。
    public var duration: TimeInterval {
        guard let item = player.currentItem else { return 0 }
        let duration = item.duration.seconds
        guard duration.isNormal else {
            return 0
        }
        return duration
    }
    
    /// 缓冲时长。
    /// 如果当前没有视频资源，或者没有缓存，返回 0 。
    public var loadedDuration: TimeInterval {
        guard let item = player.currentItem else { return 0 }
        
        var timeRange: CMTimeRange! = nil
        for item in item.loadedTimeRanges {
            if timeRange != nil {
                timeRange = timeRange.union(item.timeRangeValue)
            } else {
                timeRange = item.timeRangeValue
            }
        }
        let loadedDuration = (timeRange.start.seconds + timeRange.duration.seconds)
        guard loadedDuration.isNormal else {
            return 0
        }
        
        return loadedDuration
    }
    
    /// 当前播放时长。如果没有在播放的视频，或无法获取当前播放时长，返回 0 。
    public var currentTime: TimeInterval {
        let currentTime = player.currentTime().seconds
        guard currentTime.isNormal else {
            return 0
        }
        return currentTime
    }
    
    private func startObserving(_ playerItem: AVPlayerItem) {
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: &KVOContext.AVPlayerItemStatus)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: .new, context: &KVOContext.AVPlayerItemIsPlaybackLikelyToKeepUp)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: .new, context: &KVOContext.AVPlayerItemLoadedTimeRanges)
    }
    
    private func stopObserving(_ playerItem: AVPlayerItem) {
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &KVOContext.AVPlayerItemStatus)
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), context: &KVOContext.AVPlayerItemIsPlaybackLikelyToKeepUp)
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), context: &KVOContext.AVPlayerItemLoadedTimeRanges)
    }
    
    /// 替换当前的媒体播放资源。
    ///
    /// - Parameter url: 媒体资源的 URL
    public func replaceCurrentItem(with url: URL?) {
        if let item = player.currentItem {
            stopObserving(item)
        }
        var playerItem: AVPlayerItem? = nil
        if let url = url {
            let item = AVPlayerItem(url: url)
            startObserving(item)
            playerItem = item
        }
        player.replaceCurrentItem(with: playerItem)
    }
    
    public var currentItem: AVPlayerItem? {
        return player.currentItem
    }
    
    /// 播放
    public func play() {
        guard status != .playing && status != .stalled else {
            return
        }
        guard let playerItem = player.currentItem else { return }
        player.play()
        if playerItem.isPlaybackLikelyToKeepUp {
            self.status = .playing
        } else {
            self.status = .stalled
        }
    }
    
    /// 暂停播放
    public func pause() {
        guard self.status == .playing || self.status == .stalled else {
            return
        }
        player.pause()
        self.status = .paused
    }
    
    var isPlaying: Bool {
        return player.rate > 0
    }
    
    /// 播放跳转
    public func seek(to time: TimeInterval, completionHandler: ((Bool) -> Void)?) {
        player.seek(to: CMTime(seconds: time, preferredTimescale: 1)) { (finished) in
            completionHandler?(finished)
        }
    }
    
    /// 截屏。
    ///
    /// - Returns: The current output image.
    public func capture() -> UIImage? {
        guard let item = self.player.currentItem else { return nil }
        var output: AVPlayerItemVideoOutput! = item.outputs.first as? AVPlayerItemVideoOutput
        if output == nil {
            output = AVPlayerItemVideoOutput()
            item.add(output)
        }
        
        guard let pixelBuffer = output.copyPixelBuffer(forItemTime: item.currentTime(), itemTimeForDisplay: nil) else {
            return nil
        }
        let ciimage = CIImage(cvPixelBuffer: pixelBuffer)
        return UIImage(ciImage: ciimage);
        /*
         let context = CIContext(options: nil)
         let width = CVPixelBufferGetWidth(pixelBuffer)
         let height = CVPixelBufferGetWidth(pixelBuffer)
         guard let cgimage = context.createCGImage(ciimage, from: CGRect(x: 0, y: 0, width: width, height: height)) else {
         return nil
         }
         return UIImage(cgImage: cgimage)
         */
    }
    
    /// 播放进度每秒更新频率。默认 0，不推送播放状态事件。
    /// 推荐值，1 ～ 10。
    open var preferredPlaybackUpdatesPerSecond: Int32 = 0 {
        didSet {
            guard oldValue != preferredPlaybackUpdatesPerSecond else {
                return
            }
            if let timeObserver = self.timeObserver {
                player.removeTimeObserver(timeObserver)
            }
            let time = CMTime(value: 1, timescale: preferredPlaybackUpdatesPerSecond)
            self.timeObserver = player.addPeriodicTimeObserver(forInterval: time, queue: nil) { (time) in
                
            }
        }
    }

}

// MARK: ★★★  Key Value Observer  ★★★

extension MediaPlayer {
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let context = context, let observedKeyPath = keyPath else {
            return
        }
        
        switch context {
        case &KVOContext.AVPlayerStatus:
            let status = self.player.status
            #if DEBUG
                print("KVO: \(status)")
            #endif
            switch observedKeyPath {
            case #keyPath(AVPlayer.status):
                switch status {
                case .readyToPlay:
                    //delegate?.mediaPlayerPlaybackDidChange(self)
                    
                    break
                    
                case .failed:
                    print("Error: \(String(describing: player.error))")
                    
                case .unknown:
                    break
                }
            default:
                break
            }
            
        case &KVOContext.AVPlayerItemStatus:
            guard let playerItem = self.player.currentItem else { return }
            // 播放资源状态发生改变
            guard playerItem.isEqual(object) else {
                return
            }
            
            let status = playerItem.status
            #if DEBUG
                print("KVO: \(status) \nError: \(String(describing: playerItem.error))")
            #endif
            switch status {
            case .failed:
                self.status = .failed
            default:
                break
            }
            
        case &KVOContext.AVPlayerItemIsPlaybackLikelyToKeepUp:
            // 播放资源状态发生改变
            guard let playerItem = self.player.currentItem else { return }
            guard playerItem.isEqual(object) else {
                return
            }
            
            if self.status == .playing && !playerItem.isPlaybackLikelyToKeepUp {
                self.status = .stalled
            } else if self.status == .stalled && playerItem.isPlaybackLikelyToKeepUp {
                self.status = .playing
            }
            
            break
            
        case &KVOContext.AVPlayerItemLoadedTimeRanges: break
//            guard let playbackControlsView = self.playbackControlsView else { return }
//            guard let playerItem = self.player.currentItem else { return }
//            guard playerItem.isEqual(object) else {
//                return
//            }
//            guard let loadedTimeRanges = change?[.newKey] as? [NSValue] else { return }
//            var timeRange: CMTimeRange! = nil
//            for item in loadedTimeRanges {
//                if timeRange != nil {
//                    timeRange = timeRange.union(item.timeRangeValue)
//                } else {
//                    timeRange = item.timeRangeValue
//                }
//            }
//            let loadedDuration = (timeRange.start.seconds + timeRange.duration.seconds)
//            guard loadedDuration.isNormal else {
//                return
//            }
//            playbackControlsView.mediaPlayer(self, didLoadMediaWith: CGFloat(loadedDuration / playerItem.duration.seconds))
            
        case &KVOContext.AVPlayerLayerIsReadyForDisplay:
            #if DEBUG
                print("KVO: AVPlayerLayer is ready for display.")
            #endif
            delegate?.mediaPlayerIsReadyForDisplay(self)
            
        default:
            super.observeValue(forKeyPath: observedKeyPath, of: object, change: change, context: context)
        }
        
    }
    
}

// MARK: ★★★  Notification  ★★★

extension MediaPlayer {
    
    @objc fileprivate func playerItemDidPlayToEndTimeAction(_ notification: Notification) {
        guard let object = (notification.object as AnyObject?) else {
            return
        }
        guard object === self.player.currentItem else {
            return
        }
        self.status = .ended
        delegate?.mediaPlayerDidPlayToEndTime(self)
    }
    
    @objc fileprivate func playerItemFailedToPlayToEndTimeAction(_ notification: Notification) {
        guard let object = (notification.object as AnyObject?) else {
            return
        }
        guard object === self.player.currentItem else {
            return
        }
        self.status = .failed
        delegate?.mediaPlayerFailedToPlayToEndTime(self)
    }
    
    @objc fileprivate func playerItemPlaybackStalled(_ notification: Notification) {
        guard let object = (notification.object as AnyObject?) else {
            return
        }
        guard object === self.player.currentItem else {
            return
        }
        // playbackControlsView?.status = .stalled // kvo isPlaybackLikelyToKeepUp
        delegate?.mediaPlayerPlaybackStalled(self)
    }
    
}

// MARK: ★★★  屏幕方向事件  ★★★

extension MediaPlayer {
    
    @objc fileprivate func deviceOrientationDidChange(_ notification: Notification)  {
        #if DEBUG
            print("deviceOrientationDidChange: \(automaticallyAdjustsDeviceOrientation)")
        #endif
        guard automaticallyAdjustsDeviceOrientation else {
            return
        }
        zoomIfNeeded()
    }
    
    /// 该属性表明需要旋转播放器。在一个旋转事件完成之后判断此属性，以确定是否需要再次旋转。
    private var needsZooming: Bool {
        get {
            return valueWrapper.needsZooming
        }
        set {
            valueWrapper.needsZooming = newValue
        }
    }
    
    /// 如果当前没有在缩放，根据当前状态，如果需要则立即执行缩放；
    /// 如果当前正在缩放，则标记当前需要缩放。
    /// 如果当前没有在缩放，则立即执行缩放。
    private func zoomIfNeeded() {
        guard !isZooming else {
            self.needsZooming = true
            return
        }
        
        // 通过方向来判断是否需要旋转
        let orientation = UIDevice.current.orientation
        guard (isZoomed && orientation == .portrait) || (!isZoomed && (orientation == .landscapeRight || orientation == .landscapeLeft)) else {
            return
        }
        
        if isZoomed {
            // If the `displayView` does not exists, do nothing.
            guard let displayView = self.containerView else {
                needsZooming = false
                return
            }
            delegate?.mediaPlayerWillBeginZooming(self)
            zoomOut(displayView, completion: { (_) in
                self.containerView = nil
                self.delegate?.mediaPlayerDidFinishZooming(self)
                if self.needsZooming {
                    self.needsZooming = false
                    self.zoomIfNeeded()
                }
            })
        } else {
            guard status == .playing else {
                return
            }
            delegate?.mediaPlayerWillBeginZooming(self)
            let superview = self.view.superview
            zoomIn({ (_) in
                self.containerView = superview
                self.delegate?.mediaPlayerDidFinishZooming(self)
                if self.needsZooming {
                    self.needsZooming = false
                    self.zoomIfNeeded()
                }
            })
        }
    }
    
    /// 全屏。
    ///
    /// - Parameter completion: 放大完成后的回调，布尔参数表示放大是否完成
    public func zoomIn(_ completion: ((_ finished: Bool)->Void)? = nil) {
        guard !isZoomed else {
            completion?(false)
            return
        }
        
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            completion?(false)
            return
        }
        
        isZoomed = true     // 已放大
        isZooming = true    // 正在放大
        
        // 设置播放器不改变状态栏样式。在播放器完全展示后，改变此属性，并隐藏状态栏。
        self.modalPresentationCapturesStatusBarAppearance = false
        
        // 自定义转场动画
        self.transitioningDelegate = self.zoomInAnimationController
        let oldStyle = self.modalPresentationStyle
        self.modalPresentationStyle = .custom
        
        rootViewController.present(self, animated: true, completion: { () -> Void in
            self.transitioningDelegate = nil
            self.modalPresentationStyle = oldStyle
            
            // 隐藏状态栏
            self.modalPresentationCapturesStatusBarAppearance = true
            self.setNeedsStatusBarAppearanceUpdate()
            
            self.isZooming = false
            completion?(true)
        })
    }
    
    // 退出全屏
    public func zoomOut(_ view: UIView? = nil, completion: ((_ finished: Bool)->Void)? = nil) {
        guard isZoomed else {
            completion?(false)
            return
        }
        
        guard let presentingViewController = self.presentingViewController else {
            completion?(false)
            return
        }

        isZoomed = false
        isZooming = true
        
        // 自定义动画
        self.transitioningDelegate  = self.zoomOutAnimationController
        let oldStyle = self.modalPresentationStyle
        self.modalPresentationStyle = .custom
        self.zoomOutAnimationController.targetView = view
        
        presentingViewController.dismiss(animated: true) {
            self.transitioningDelegate = nil
            self.modalPresentationStyle = oldStyle
            
            if let superview = view {
                self.view.frame = superview.bounds
                superview.addSubview(self.view)
            }
            
            self.isZooming = false
            completion?(true)
        }
    }

    /// 用于自动旋转屏幕时，记住原父视图。
    private var containerView: UIView? {
        get {
            return valueWrapper.containerView
        }
        set {
            valueWrapper.containerView = newValue
        }
    }
    
    private var zoomInAnimationController: MediaPlayer.ZoomInAnimationController {
        return valueWrapper.zoomInAnimationController
    }
    
    private var zoomOutAnimationController: MediaPlayer.ZoomOutAnimationController {
        return valueWrapper.zoomOutAnimationController
    }
    
}



// MARK: ★★★  Override Methods  ★★★

extension MediaPlayer {
    
    /// 将根视图替换为播放器视图 MediaPlayer.View 。
    override public func loadView() {
        self.playerView.backgroundColor = UIColor.black
        self.playerView.playerLayer.player = self.player
        self.view = self.playerView
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // 播放完成、播放失败
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTimeAction(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemFailedToPlayToEndTimeAction(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemPlaybackStalled(_:)), name: .AVPlayerItemPlaybackStalled, object: nil)
        
        // 播放器状态、播放器可显示
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: .new, context: &KVOContext.AVPlayerStatus)
        playerView.playerLayer.addObserver(self, forKeyPath: #keyPath(AVPlayerLayer.isReadyForDisplay), options: .new, context: &KVOContext.AVPlayerLayerIsReadyForDisplay)
    }

    /// 状态栏默认隐藏。
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    /// 状态栏样式 .default 。
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    /// 状态栏动画样式 .fade 。
    override public var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    /// 屏幕旋转 false 。视频显示方向用 transform 控制。
    override public var shouldAutorotate: Bool {
        return false
    }
    
    /// 屏幕方向 .portrait ，视频显示方向用 transform 控制。
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    /// 屏幕方向 .portrait ，视频显示方向用 transform 控制。
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
}

// MARK: ★★★  MediaPlayer Animation  ★★★

extension MediaPlayer {
    
    /// 判断状态栏是否是由控制器控制的。
    static let isStatusBarAppearanceControllable: Bool = { () -> Bool in
        if let bool = Bundle.main.object(forInfoDictionaryKey: "UIViewControllerBasedStatusBarAppearance") as? Bool {
            return bool
        }
        return true
    }()
    
    /// 从嵌入模式到全屏模式的过渡动画控制器
    class ZoomInAnimationController: NSObject, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
        
        public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            return self
        }
        
        func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
            return nil
        }
        
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return MediaPlayer.AnimationDuration
        }
        
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            let duration = transitionDuration(using: transitionContext)
            let containerView = transitionContext.containerView
            
            guard let mediaPlayer = transitionContext.viewController(forKey: .to) else { return }
            let mediaPlayerFinalFrame = transitionContext.finalFrame(for: mediaPlayer)
            
            if let superview = mediaPlayer.view.superview {
                // 如果视图已经显示，则从视图初始位置开始动画
                let initialFrame = superview.convert(mediaPlayer.view.frame, to: containerView)
                mediaPlayer.view.frame = initialFrame
                containerView.addSubview(mediaPlayer.view)
                
                let x = (mediaPlayerFinalFrame.width - mediaPlayerFinalFrame.height) * 0.5
                let y = (mediaPlayerFinalFrame.height - mediaPlayerFinalFrame.width) * 0.5
                let finalFrame = CGRect(x: x, y: y, width: mediaPlayerFinalFrame.height, height: mediaPlayerFinalFrame.width)
                
                UIView.animate(withDuration: duration, delay: 0, options: .layoutSubviews, animations: {
                    mediaPlayer.view.frame = finalFrame
                    mediaPlayer.view.transform = self.makeTransform()
                }) { (finished) in
                    transitionContext.completeTransition(true)
                }
            } else {
                // 如果视图没有显示，则从屏幕底部显示出来
                let kBounds = containerView.bounds
                
                mediaPlayer.view.transform = self.makeTransform()
                mediaPlayer.view.frame = kBounds.offsetBy(dx: kBounds.width, dy: 0)
                
                transitionContext.containerView.addSubview(mediaPlayer.view)
                
                UIView.animate(withDuration: duration, delay: 0, options: .layoutSubviews, animations: {
                    mediaPlayer.view.frame = kBounds
                }, completion: { (finished) in
                    transitionContext.completeTransition(true)
                })
            }
            
        }
        
        func animationEnded(_ transitionCompleted: Bool) {
            
        }
        
        func makeTransform() -> CGAffineTransform {
            if UIDevice.current.orientation == .landscapeRight {
                return CGAffineTransform(rotationAngle: CGFloat.pi * -0.5)
            } else {
                return CGAffineTransform(rotationAngle: CGFloat.pi * 0.5)
            }
        }
    }
    
    /// 从全屏模式到嵌入模式的过渡动画控制器
    class ZoomOutAnimationController: NSObject, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
        
        public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            return self
        }
        
        var targetView: UIView?
        
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return MediaPlayer.AnimationDuration
        }
        
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            #if DEBUG
                print("Zoom out start")
            #endif
            let duration = transitionDuration(using: transitionContext)
            let containerView = transitionContext.containerView
            
            guard let mediaPlayer = transitionContext.viewController(forKey: .from) else { return }
            mediaPlayer.view.frame = transitionContext.initialFrame(for: mediaPlayer)
            containerView.addSubview(mediaPlayer.view)
            
            if let targetView = self.targetView {
                #if DEBUG
                    print("从全屏视图退出到嵌入视图")
                #endif
                // 如果目标视图存在
                let frame = targetView.convert(targetView.bounds, to: containerView)
                UIView.animate(withDuration: duration, delay: 0, options: .layoutSubviews, animations: {
                    mediaPlayer.view.transform = .identity
                    mediaPlayer.view.frame     = frame
                }) { (finished) in
                    transitionContext.completeTransition(true)
                }
            } else {
                #if DEBUG
                    print("从全屏视图直接退出")
                #endif
                // 如果目标视图不存在，从底部退出
                let frame = mediaPlayer.view.frame
                UIView.animate(withDuration: duration, delay: 0, options: .layoutSubviews, animations: {
                    mediaPlayer.view.frame = frame.offsetBy(dx: frame.width, dy: 0)
                }, completion: { (finished) in
                    mediaPlayer.view.transform = .identity
                    transitionContext.completeTransition(true)
                })
            }
            
            
        }
        
        func animationEnded(_ transitionCompleted: Bool) {
            
        }
    }
    
}

private class ValueWrapper {
    
    static var associationKey = 0
    
    weak var containerView: UIView?
    var playbackControlsView: MediaPlayerPlaybackControlsView?
    var needsZooming: Bool = false
    let zoomInAnimationController: MediaPlayer.ZoomInAnimationController = MediaPlayer.ZoomInAnimationController()
    let zoomOutAnimationController: MediaPlayer.ZoomOutAnimationController = MediaPlayer.ZoomOutAnimationController()
    
}

extension MediaPlayer {
    
    fileprivate var valueWrapper: ValueWrapper {
        if let wrapper = objc_getAssociatedObject(self, &ValueWrapper.associationKey) as? ValueWrapper {
            return wrapper
        }
        let wrapper = ValueWrapper()
        objc_setAssociatedObject(self, &ValueWrapper.associationKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return wrapper
    }
}



private struct KVOContext {
    
    static var AVPlayerStatus                       = "AVPlayerStatus"
    
    static var AVPlayerItemStatus                   = "AVPlayerItemStatus"
    static var AVPlayerItemIsPlaybackLikelyToKeepUp = "AVPlayerItemIsPlaybackLikelyToKeepUp"
    static var AVPlayerItemLoadedTimeRanges         = "AVPlayerItemLoadedTimeRanges"
    
    static var AVPlayerLayerIsReadyForDisplay       = "AVPlayerLayerIsReadyForDisplay"
    
}



