//
//  AgoraRoomUIController.swift
//  AgoraEduUI
//
//  Created by SRS on 2021/4/18.
//

import AgoraUIEduBaseViews
import AgoraUIBaseViews
import AgoraEduContext

protocol AgoraRoomUIControllerDelegate: NSObjectProtocol {
    func roomController(_ controller: AgoraRoomUIController,
                         didClicked button: AgoraBaseUIButton)
}

fileprivate class AgoraRoomTimeInfo: NSObject {
    var classState: AgoraEduContextClassState = .default
    var startTime: Int64 = 0
    var differTime: Int64 = 0
    var duration: Int64 = 0
    var closeDelay: Int64 = 0
}

class AgoraRoomUIController: NSObject, AgoraUIController {
    // Contexts
    private var context: AgoraEduRoomContext? {
        return contextProvider?.controllerNeedRoomContext()
    }
    
    private let navigationBar = AgoraUINavigationBar(frame: .zero)
    private var loadingView: AgoraAlertView?
    
    // move timer handle to ui
    private var timer: DispatchSourceTimer?
    private var timeInfo: AgoraRoomTimeInfo = AgoraRoomTimeInfo()
    
    private weak var contextProvider: AgoraControllerContextProvider?
    private weak var delegate: AgoraRoomUIControllerDelegate?
    
    var containerView = AgoraUIControllerContainer(frame: .zero)

    public init(contextProvider: AgoraControllerContextProvider,
                delegate: AgoraRoomUIControllerDelegate) {
        self.contextProvider = contextProvider
        self.delegate = delegate
        
        super.init()
        initViews()
        initLayout()
        observeUI()
    }
    
    func updateSetInteraction(enabled: Bool) {
        navigationBar.setButton.isUserInteractionEnabled = enabled
    }
    
    deinit {
        self.stopTimer()
    }
}

private extension AgoraRoomUIController {
    func initViews() {
        containerView.backgroundColor = .clear
        containerView.addSubview(navigationBar)
    }
    
    func initLayout() {
        navigationBar.agora_x = 0
        navigationBar.agora_y = 0
        navigationBar.agora_right = 0
        navigationBar.agora_bottom = 0
    }

    func observeUI() {
        navigationBar.setButton.tap { [unowned self] (button) in
            self.delegate?.roomController(self,
                                          didClicked: button)
        }
        
        navigationBar.logButton.tap { [unowned self] (button) in
            self.context?.uploadLog()
        }
    }
}

// MARK: UI
private extension AgoraRoomUIController {
    /* 显示课程时间:
     * 上课前：`距离上课还有：X分X秒`
     * 开始上课：`已开始上课:X分X秒`
     * 结束上课：`已开始上课:X分X秒`
     */
    func updateTimeUI(_ time: Int64,
                      countdown: Int64) {
        let hourInt = time / 3600
        let minuteInt = (time - 3600 * hourInt) / 60
        let secondInt = time % 60
        
        let hourString = NSString(format: "%02d", hourInt) as String
        let minuteString = NSString(format: "%02d", minuteInt) as String
        let secondString = NSString(format: "%02d", secondInt) as String
        
        var timeText: String
        
        if hourInt > 0 {
            timeText = hourString + ":" + minuteString + ":" + secondString
        } else {
            timeText = minuteString + ":" + secondString
        }
        
        var text: String
        
        switch timeInfo.classState {
        case .default:
            let before = AgoraUILocalizedString("ClassBeforeStartText",
                                                object: self)
            text = before + timeText
        case .start:
            switch countdown {
            case (5 * 60 + timeInfo.closeDelay):
                let strStart = AgoraUILocalizedString("ClassEndWarningStartText",
                                                      object: self)
                let strMid = "5"
                let strEnd = AgoraUILocalizedString("ClassEndWarningEndText",
                                                    object: self)
                AgoraUtils.showToast(message: strStart + strMid + strEnd)
            default:
                break
            }
            let start = AgoraUILocalizedString("ClassAfterStartText",
                                               object: self)
            text = start + timeText
            /*
             * 课程还有5分钟结束
             */
        case .end:
            switch countdown {
            case timeInfo.closeDelay:
                // 课程结束咯，还有10分钟关闭教室
                let strStart = AgoraUILocalizedString("ClassCloseWarningStartText",
                                                      object: self)
                let minNum = Int(timeInfo.closeDelay / 60)
                let strMid = "\(minNum)"
                let strMin = AgoraUILocalizedString("ClassCloseWarningEnd2Text",
                                                    object: self)
                let strEnd = AgoraUILocalizedString("ClassCloseWarningEndText",
                                                    object: self)
                AgoraUtils.showToast(message: strStart + strMid + strMin + strEnd)
            case 1 * 60:
                // 距离教室关闭还有1分钟
                let strStart = AgoraUILocalizedString("ClassCloseWarningStart2Text",
                                                      object: self)
                let strMid = "1"
                let strEnd = AgoraUILocalizedString("ClassCloseWarningEnd2Text",
                                                    object: self)
                AgoraUtils.showToast(message: strStart + strMid + strEnd)
            default:
                break
            }
            let end = AgoraUILocalizedString("ClassAfterStopText",
                                             object: self)
            text = end + timeText
        case .close:
            text = ""
        }
        
        navigationBar.setClassTime(text)
    }
    func classOverAlert() {
        let ButtonLabel = AgoraAlertLabelModel()
        ButtonLabel.text = AgoraKitLocalizedString("SureText")
        
        let button = AgoraAlertButtonModel()
        button.titleLabel = ButtonLabel
        button.tapActionBlock = { [weak self] (index) -> Void in
            self?.context?.leaveRoom()
        }
        
        AgoraUtils.showAlert(imageModel: nil,
                             title: AgoraKitLocalizedString("ClassOverNoticeText"),
                             message: AgoraKitLocalizedString("ClassOverText"),
                             btnModels: [button])
    }
}

// MARK: - AgoraEduRoomHandler
extension AgoraRoomUIController: AgoraEduRoomHandler {
    // 设置课程名称
    public func onClassroomName(_ name: String) {
        navigationBar.setClassroomName(name)
    }
    
    // 设置课程状态
    public func onClassState(_ state: AgoraEduContextClassState) {
        timeInfo.classState = state
        switch state {
        case .close:
            classOverAlert()
            navigationBar.timeLabel.textColor = .red
        case .end:
            navigationBar.timeLabel.textColor = .red
        default:
            navigationBar.timeLabel.textColor = UIColor(rgb: 0x677386)
        }
    }
    
    // 设置课程时间信息
    public func onClassTimeInfo(startTime: Int64,
                                differTime: Int64,
                                duration: Int64,
                                closeDelay: Int64) {
        timeInfo.startTime = startTime
        timeInfo.differTime = differTime
        timeInfo.duration = duration
        timeInfo.closeDelay = closeDelay
        if startTime > 0 {
            startTimer()
        }
    }
    
    // 网络状态
    public func onNetworkQuality(_ quality: AgoraEduContextNetworkQuality) {
        navigationBar.setNetworkQuality(quality.barType)
    }
    
    // 连接状态
    public func onConnectionState(_ state: AgoraEduContextConnectionState) {
        switch state {
        case .aborted:
            // 踢出
            loadingView?.removeFromSuperview()
            AgoraUtils.showToast(message: AgoraKitLocalizedString("LoginOnAnotherDeviceText"))
            context?.leaveRoom()
        case .connecting:
            if loadingView?.superview == nil {
                self.loadingView = AgoraUtils.showLoading(message: AgoraKitLocalizedString("LoaingText"),
                                                          shared: true)
            }
        case .disconnected, .reconnecting:
            if loadingView?.superview == nil {
                self.loadingView = AgoraUtils.showLoading(message: AgoraKitLocalizedString("ReconnectingText"),
                                                          shared: true)
            }
        case .connected:
            loadingView?.removeFromSuperview()
        }
    }
    
    // 上课过程中，错误信息
    public func onShowErrorInfo(_ error: AgoraEduContextError) {
        AgoraUtils.showToast(message: error.message ?? "")
    }
    
    public func onUploadLogSuccess(_ logId: String) {
        let title = AgoraKitLocalizedString("UploadLog")
        
        let button = AgoraAlertButtonModel()
        let buttonTitleProperties = AgoraAlertLabelModel()
        buttonTitleProperties.text = AgoraKitLocalizedString("OK")
        button.titleLabel = buttonTitleProperties
        
        AgoraUtils.showAlert(imageModel: nil,
                             title: title,
                             message: logId,
                             btnModels: [button])
    }
}

// MARK: - Timer
private extension AgoraRoomUIController {
    func startTimer() {
        guard self.timer == nil else {
            return
        }
        
        let timer = DispatchSource.makeTimerSource(flags: [],
                                                   queue: DispatchQueue.global())
        timer.schedule(deadline: .now() + 1,
                       repeating: 1)
        
        timer.setEventHandler { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.updateRoomTime()
            }
        }
        
        timer.resume()
        
        self.timer = timer
    }
    
    func stopTimer() {
        guard let `timer` = timer,
              !timer.isCancelled else {
            return
        }
        
        timer.cancel()
    }
    
    func updateRoomTime() {
        let state = timeInfo.classState
        let differTime = timeInfo.differTime
        let startTime = timeInfo.startTime
        let duration = Int64(timeInfo.duration * 1000)
        let closeDelay = Int64(timeInfo.closeDelay * 1000)
        
        let interval = Date().timeIntervalSince1970 * 1000
        let currentRealTime = Int64(interval - Double(differTime))
        
        var time: Int64 // 距离课程已经开始时间
        
        switch state {
        case .default:
            time = startTime - currentRealTime
        case .start:
            time = currentRealTime - startTime
        case .end:
            time = currentRealTime - startTime
        case .close:
            stopTimer()
            return
        @unknown default:
            return
        }
        
        if time < 0 {
            time = 0
        }
        
        let countdown = closeDelay + duration - time
        updateTimeUI((time / 1000),
                    countdown: countdown)
    }
}

fileprivate extension AgoraEduContextNetworkQuality {
    var barType: AgoraUINavigationBar.NetworkQuality {
        switch self {
        case .good:    return .good
        case .medium:  return .medium
        case .bad:     return .bad
        case .unknown: return .unknown
        @unknown default:
            fatalError()
        }
    }
}
