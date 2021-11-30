//
//  PaintingSettingViewController.swift
//  AgoraEduUI
//
//  Created by HeZhengQing on 2021/9/25.
//

import AgoraUIEduBaseViews
import AgoraEduContext
import SwifterSwift
import UIKit

protocol AgoraSettingUIControllerDelegate: NSObjectProtocol {
    func settingUIControllerDidPressedLeaveRoom(controller: AgoraSettingUIController)
}

fileprivate let kFrontCameraStr = "front"
fileprivate let kBackCameraStr = "back"
class AgoraSettingUIController: UIViewController {
    weak var delegate: AgoraSettingUIControllerDelegate?
    
    var contentView: UIView!
    
    var cameraLabel: UILabel!
    
    var cameraSwitch: UISwitch!
    
    var directionLabel: UILabel!
    
    var frontCamButton: UIButton!
    
    var backCamButton: UIButton!
    
    var sepLine: UIView!
    
    var micLabel: UILabel!
    
    var micSwitch: UISwitch!
    
    var audioLabel: UILabel!
    
    var audioSwitch: UISwitch!
    
    var uploadLogButton: UIButton!
    
    var exitButton: UIButton!
    /** SDK环境*/
    var contextPool: AgoraEduContextPool!
    
    deinit {
        print("\(#function): \(self.classForCoder)")
    }
    
    init(context: AgoraEduContextPool) {
        super.init(nibName: nil, bundle: nil)
        contextPool = context
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createViews()
        createConstrains()
        setup()
        contextPool.room.registerEventHandler(self)
        contextPool.media.registerMediaEventHandler(self)
    }
}
private extension AgoraSettingUIController {
    func setup() {
        frontCamButton.isSelected = true
        
        let cameras = contextPool.media.getLocalDevices(deviceType: .camera)
        for camera in cameras {
            if camera.deviceName.contains(kFrontCameraStr) {
                contextPool.media.getLocalDeviceState(device: camera) { state in
                    frontCamButton.isSelected = (state == .open)
                    backCamButton.isSelected = !(state == .open)
                } fail: { error in
                }
            } else if camera.deviceName.contains(kBackCameraStr) {
                contextPool.media.getLocalDeviceState(device: camera) { state in
                    backCamButton.isSelected = (state == .open)
                    frontCamButton.isSelected = !(state == .open)
                } fail: { error in
                }
            }
        }
        if let d = contextPool.media.getLocalDevices(deviceType: .mic).first {
            contextPool.media.getLocalDeviceState(device: d) { state in
                micSwitch.isOn = (state == .open)
            } fail: { error in
            }
        }
        if let d = contextPool.media.getLocalDevices(deviceType: .speaker).first {
            contextPool.media.getLocalDeviceState(device: d) { state in
                audioSwitch.isOn = (state == .open)
            } fail: { error in
            }
        }
    }
}

// MARK: - AgoraEduRoomHandler
extension AgoraSettingUIController: AgoraEduRoomHandler {
    func onUploadLogSuccess(_ logId: String) {
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

extension AgoraSettingUIController: AgoraEduMediaHandler {
    func onLocalDeviceStateUpdated(device: AgoraEduContextDeviceInfo,
                                   state: AgoraEduContextDeviceState) {
        if device.deviceType == .camera {
            cameraSwitch.isOn = (state == .open)
        } else if device.deviceType == .mic {
            micSwitch.isOn = (state == .open)
        } else if device.deviceType == .speaker {
            audioSwitch.isOn = (state == .open)
        }
    }
}

// MARK: - Actions
private extension AgoraSettingUIController {
    @objc func onClickCameraSwitch(_ sender: UISwitch) {
        let devices = contextPool.media.getLocalDevices(deviceType: .camera)
        var camera: AgoraEduContextDeviceInfo?
        if frontCamButton.isSelected {
            camera = devices.first(where: {$0.deviceName.contains(kFrontCameraStr)})
        } else if backCamButton.isSelected {
            camera = devices.first(where: {$0.deviceName.contains(kBackCameraStr)})
        }
        if let c = camera {
            if sender.isOn {
                self.contextPool.media.openLocalDevice(device: c)
            } else {
                self.contextPool.media.closeLocalDevice(device: c)
            }
        }
    }
    
    @objc func onClickMicSwitch(_ sender: UISwitch) {
        guard let d = self.contextPool.media.getLocalDevices(deviceType: .mic).first else {
            return
        }
        if sender.isOn {
            self.contextPool.media.openLocalDevice(device: d)
        } else {
            self.contextPool.media.closeLocalDevice(device: d)
        }
    }
    
    @objc func onClickAudioSwitch(_ sender: UISwitch) {
        guard let d = self.contextPool.media.getLocalDevices(deviceType: .speaker).first else {
            return
        }
        if sender.isOn {
            self.contextPool.media.openLocalDevice(device: d)
        } else {
            self.contextPool.media.closeLocalDevice(device: d)
        }
    }
    
    @objc func onClickUploadLog(_ sender: UIButton) {
        contextPool.monitor.uploadLog { logId in
            let title = AgoraKitLocalizedString("UploadLog")
            
            let button = AgoraAlertButtonModel()
            let buttonTitleProperties = AgoraAlertLabelModel()
            buttonTitleProperties.text = AgoraKitLocalizedString("OK")
            button.titleLabel = buttonTitleProperties
            
            AgoraUtils.showAlert(imageModel: nil,
                                 title: title,
                                 message: logId,
                                 btnModels: [button])
        } failure: { error in
            // TODO: 上传日志失败
        }
    }
    
    @objc func onClickExit(_ sender: UIButton) {
        let leftButtonLabel = AgoraAlertLabelModel()
        leftButtonLabel.text = AgoraKitLocalizedString("CancelText")
        
        let leftButton = AgoraAlertButtonModel()
        leftButton.titleLabel = leftButtonLabel
        
        let rightButtonLabel = AgoraAlertLabelModel()
        rightButtonLabel.text = AgoraKitLocalizedString("SureText")
        
        let rightButton = AgoraAlertButtonModel()
        rightButton.titleLabel = rightButtonLabel
        rightButton.tapActionBlock = { [unowned self] (index) -> Void in
            self.contextPool.room.leaveRoom()
            self.delegate?.settingUIControllerDidPressedLeaveRoom(controller: self)
        }
        AgoraUtils.showAlert(imageModel: nil,
                             title: AgoraKitLocalizedString("LeaveClassTitleText"),
                             message: AgoraKitLocalizedString("LeaveClassText"),
                             btnModels: [leftButton, rightButton])
    }
    
    @objc func onClickFrontCamera(_ sender: UIButton) {
        guard sender.isSelected == false else {
            return
        }
        sender.isSelected = true
        backCamButton.isSelected = false
        let devices = self.contextPool.media.getLocalDevices(deviceType: .camera)
        if let camera = devices.first(where: {$0.deviceName.contains(kFrontCameraStr)}) {
            contextPool.media.openLocalDevice(device: camera)
        }
    }
    
    @objc func onClickBackCamera(_ sender: UIButton) {
        guard sender.isSelected == false else {
            return
        }
        sender.isSelected = true
        frontCamButton.isSelected = false
        let devices = self.contextPool.media.getLocalDevices(deviceType: .camera)
        if let camera = devices.first(where: {$0.deviceName.contains(kBackCameraStr)}) {
            contextPool.media.openLocalDevice(device: camera)
        }
    }
}

// MARK: - Creations
private extension AgoraSettingUIController {
    func createViews() {
        view.layer.shadowColor = UIColor(rgb: 0x2F4192,
                                         alpha: 0.15).cgColor
        view.layer.shadowOffset = CGSize(width: 0,
                                         height: 2)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 6
        
        contentView = UIView()
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 10.0
        contentView.clipsToBounds = true
        view.addSubview(contentView)
        
        cameraLabel = UILabel(frame: .zero)
        cameraLabel.text = AgoraKitLocalizedString("CameraText")
        cameraLabel.font = UIFont.systemFont(ofSize: 12)
        cameraLabel.textColor = UIColor(rgb: 0x191919)
        view.addSubview(cameraLabel)
        
        cameraSwitch = UISwitch()
        cameraSwitch.onTintColor = UIColor(rgb: 0x357BF6)
        cameraSwitch.transform = CGAffineTransform(scaleX: 0.75,
                                                   y: 0.75)
        cameraSwitch.addTarget(self,
                               action: #selector(onClickCameraSwitch(_:)),
                               for: .touchUpInside)
        view.addSubview(cameraSwitch)
        
        directionLabel = UILabel(frame: .zero)
        directionLabel.text = AgoraKitLocalizedString("DirectionText")
        directionLabel.font = UIFont.systemFont(ofSize: 12)
        directionLabel.textColor = UIColor(rgb: 0x677386)
        view.addSubview(directionLabel)
        
        frontCamButton = UIButton(type: .custom)
        frontCamButton.isSelected = true
        frontCamButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        frontCamButton.setTitleColor(.white,
                                     for: .selected)
        frontCamButton.setTitleColor(UIColor(rgb: 0xB5B5C9),
                                     for: .normal)
        frontCamButton.setTitle(AgoraKitLocalizedString("FrontText"),
                                for: .normal)
        frontCamButton.setBackgroundImage(UIImage(color: UIColor(rgb: 0xF4F4F8),
                                                  size: CGSize(width: 1,
                                                               height: 1)),
                                          for: .normal)
        frontCamButton.setBackgroundImage(UIImage(color: UIColor(rgb: 0x7B88A0),
                                                  size: CGSize(width: 1,
                                                               height: 1)),
                                          for: .selected)
        frontCamButton.addTarget(self,
                                 action: #selector(onClickFrontCamera(_:)),
                                 for: .touchUpInside)
        frontCamButton.layer.cornerRadius = 4
        frontCamButton.clipsToBounds = true
        view.addSubview(frontCamButton)
        
        backCamButton = UIButton(type: .custom)
        backCamButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        backCamButton.setTitleColor(.white,
                                    for: .selected)
        backCamButton.setTitleColor(UIColor(rgb: 0xB5B5C9),
                                    for: .normal)
        backCamButton.setBackgroundImage(UIImage(color: UIColor(rgb: 0xF4F4F8),
                                                 size: CGSize(width: 1,
                                                              height: 1)),
                                         for: .normal)
        backCamButton.setBackgroundImage(UIImage(color: UIColor(rgb: 0x7B88A0),
                                                 size: CGSize(width: 1,
                                                              height: 1)),
                                         for: .selected)
        backCamButton.setTitle(AgoraKitLocalizedString("BackText"),
                               for: .normal)
        backCamButton.addTarget(self,
                                action: #selector(onClickBackCamera(_:)),
                                for: .touchUpInside)
        backCamButton.layer.cornerRadius = 4
        backCamButton.clipsToBounds = true
        view.addSubview(backCamButton)
        
        sepLine = UIView(frame: .zero)
        sepLine.backgroundColor = UIColor(rgb: 0xECECF1)
        view.addSubview(sepLine)
        
        micLabel = UILabel(frame: .zero)
        micLabel.text = AgoraKitLocalizedString("MicrophoneText")
        micLabel.font = UIFont.systemFont(ofSize: 12)
        micLabel.textColor = UIColor(rgb: 0x191919)
        view.addSubview(micLabel)
        
        micSwitch = UISwitch()
        micSwitch.onTintColor = UIColor(rgb: 0x357BF6)
        micSwitch.transform = CGAffineTransform(scaleX: 0.75,
                                                y: 0.75)
        micSwitch.addTarget(self,
                            action: #selector(onClickMicSwitch(_:)),
                            for: .touchUpInside)
        view.addSubview(micSwitch)
        
        audioLabel = UILabel(frame: .zero)
        audioLabel.text = AgoraKitLocalizedString("SpeakerText")
        audioLabel.font = UIFont.systemFont(ofSize: 12)
        audioLabel.textColor = UIColor(rgb: 0x191919)
        view.addSubview(audioLabel)
        
        audioSwitch = UISwitch()
        audioSwitch.onTintColor = UIColor(rgb: 0x357BF6)
        audioSwitch.transform = CGAffineTransform(scaleX: 0.75,
                                                  y: 0.75)
        audioSwitch.addTarget(self,
                              action: #selector(onClickAudioSwitch(_:)),
                              for: .touchUpInside)
        view.addSubview(audioSwitch)
        
        let attrs = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize:12.0),
            NSAttributedString.Key.foregroundColor: UIColor(rgb: 0x191919),
            NSAttributedString.Key.underlineStyle: 1] as [NSAttributedString.Key : Any]
        let str = NSMutableAttributedString(string: AgoraKitLocalizedString("upload_log"),
                                            attributes: attrs)
        uploadLogButton = UIButton(type: .custom)
        uploadLogButton.setAttributedTitle(str,
                                           for: .normal)
        uploadLogButton.addTarget(self,
                                  action: #selector(onClickUploadLog(_:)),
                                  for: .touchUpInside)
        view.addSubview(uploadLogButton)
        
        exitButton = UIButton(type: .system)
        exitButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        exitButton.setTitleColor(.white,
                                 for: .normal)
        exitButton.setTitle(AgoraKitLocalizedString("LeaveText"),
                            for: .normal)
        exitButton.setBackgroundImage(
            UIImage(color: UIColor(rgb: 0x191919),
                    size: CGSize(width: 1, height: 1)),
            for: .normal)
        exitButton.addTarget(self,
                             action: #selector(onClickExit(_:)),
                             for: .touchUpInside)
        exitButton.layer.cornerRadius = 6
        exitButton.clipsToBounds = true
        view.addSubview(exitButton)
    }
    
    func createConstrains() {
        contentView.mas_makeConstraints { make in
            make?.left.right().top().bottom().equalTo()(contentView.superview)
        }
        cameraLabel.mas_makeConstraints { make in
            make?.top.left().equalTo()(16)
        }
        cameraSwitch.mas_makeConstraints { make in
            make?.right.equalTo()(-16)
            make?.width.equalTo()(40)
            make?.height.equalTo()(20)
            make?.centerY.equalTo()(cameraLabel)?.offset()(-5)
        }
        directionLabel.mas_makeConstraints { make in
            make?.left.equalTo()(cameraLabel)
            make?.top.equalTo()(cameraLabel.mas_bottom)?.offset()(20)
        }
        frontCamButton.mas_makeConstraints { make in
            make?.width.equalTo()(40)
            make?.height.equalTo()(22)
            make?.right.equalTo()(cameraSwitch)
            make?.centerY.equalTo()(directionLabel)
        }
        backCamButton.mas_makeConstraints { make in
            make?.width.equalTo()(40)
            make?.height.equalTo()(22)
            make?.right.equalTo()(frontCamButton.mas_left)?.offset()(-5)
            make?.centerY.equalTo()(frontCamButton)
        }
        sepLine.mas_makeConstraints { make in
            make?.top.equalTo()(directionLabel.mas_bottom)?.offset()(17)
            make?.left.equalTo()(16)
            make?.right.equalTo()(-16)
            make?.height.equalTo()(1)
        }
        micLabel.mas_makeConstraints { make in
            make?.left.equalTo()(cameraLabel)
            make?.top.equalTo()(sepLine.mas_bottom)?.offset()(16)
        }
        micSwitch.mas_makeConstraints { make in
            make?.right.equalTo()(-16)
            make?.width.equalTo()(40)
            make?.height.equalTo()(20)
            make?.centerY.equalTo()(micLabel)?.offset()(-5)
        }
        audioLabel.mas_makeConstraints { make in
            make?.left.equalTo()(cameraLabel)
            make?.top.equalTo()(micLabel.mas_bottom)?.offset()(18)
        }
        audioSwitch.mas_makeConstraints { make in
            make?.right.equalTo()(-16)
            make?.width.equalTo()(40)
            make?.height.equalTo()(20)
            make?.centerY.equalTo()(audioLabel)?.offset()(-5)
        }
        exitButton.mas_makeConstraints { make in
            make?.left.equalTo()(15)
            make?.right.equalTo()(-15)
            make?.height.equalTo()(30)
            make?.bottom.equalTo()(-16)
        }
        uploadLogButton.mas_makeConstraints { make in
            make?.right.equalTo()(cameraSwitch)
            make?.height.equalTo()(20)
            make?.bottom.equalTo()(exitButton.mas_top)?.offset()(-30)
        }
    }
}
