//
//  ViewController.swift
//  Walkstance
//
//  Created by Nikki Jack on 3/26/20.
//  Copyright © 2020 Dev. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import SpriteKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var messageLabel: UILabel?
    @IBOutlet weak var spinLabel: UILabel?
    @IBOutlet weak var sessionStateLabel: UILabel?
    
    var grids = [Grid]()
    var rainbowNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetLabels()
        
        sceneView.delegate = self
        let scene = SCNScene()
        sceneView.scene = scene
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(tap)
        
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(swipe:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(swipe:)))
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        sceneView.addGestureRecognizer(leftSwipe)
        sceneView.addGestureRecognizer(rightSwipe)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true

        // Run the view's session
        sceneView.session.run(configuration,options: [.resetTracking, .removeExistingAnchors])
        sceneView.session.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    
    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard let label = self.sessionStateLabel else { return }
        showMessage(error.localizedDescription, label: label, seconds: 3)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        guard let label = self.sessionStateLabel else { return }
        showMessage("Session interrupted", label: label, seconds: 3)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        guard let label = self.sessionStateLabel else { return }
        showMessage("Session resumed", label: label, seconds: 3)

        DispatchQueue.main.async {
          self.removeAllNodes()
          self.resetLabels()
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // align rainbow with device (camera) position
        let trans = frame.camera.transform
        rainbowNode?.position.x =  trans.columns.3.x
        rainbowNode?.position.z =  trans.columns.3.z
    }
    
    
    
    
    func addRainbow(_ hitResult: ARHitTestResult, _ grid: Grid) {
        // 1.
        let planeGeometry = SCNPlane(width: 4.0, height: 4.0)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "rainb3")
        planeGeometry.materials = [material]
        planeGeometry.cornerRadius = 2.0

        // 2.
        rainbowNode = SCNNode(geometry: planeGeometry)
        rainbowNode.transform = SCNMatrix4(hitResult.anchor!.transform)
        rainbowNode.eulerAngles = SCNVector3(rainbowNode.eulerAngles.x + (-Float.pi / 2), rainbowNode.eulerAngles.y, rainbowNode.eulerAngles.z)
        rainbowNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y,  hitResult.worldTransform.columns.3.z - hitResult.worldTransform.columns.3.z)
        
        sceneView.scene.rootNode.addChildNode(rainbowNode)

        for gridNode in self.grids {
            gridNode.removeFromParentNode()
        }
        self.messageLabel?.alpha = 0.0
        self.messageLabel?.text = ""
    }
    
    @objc func tapped(gesture: UITapGestureRecognizer) {
        // Get 2D position of touch event on screen
        let touchPosition = gesture.location(in: sceneView)

        // Translate those 2D points to 3D points using hitTest (existing plane)
        let hitTestResults = sceneView.hitTest(touchPosition, types: .existingPlaneUsingExtent)

        // Get hitTest results and ensure that the hitTest corresponds to a grid that has been placed on a wall
        guard let hitTest = hitTestResults.first, let anchor = hitTest.anchor as? ARPlaneAnchor, let gridIndex = grids.firstIndex(where: { $0.anchor == anchor }) else {
            return
        }
        
        if self.messageLabel?.text != "" {
            addRainbow(hitTest, grids[gridIndex])
            guard let label = self.spinLabel else { return }
            showMessage("⬅️  ➡️ \n\nSwipe left or right \nto spin he rainbow", label: label, seconds: 3)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if anchor is ARPlaneAnchor {
              guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .horizontal else { return }
              let grid = Grid(anchor: planeAnchor)
              if self.messageLabel?.text != "" {
                  self.grids.append(grid)
                  node.addChildNode(grid)
                 
                self.messageLabel?.backgroundColor = UIColor.systemTeal
                  self.messageLabel?.text =
                  "2️⃣ Tap on the grid to place\nthe distance rainbow."
              }
          }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .horizontal else { return }
        let grid = self.grids.filter { grid in
            return grid.anchor.identifier == planeAnchor.identifier
            }.first

        guard let foundGrid = grid else {
            return
        }
        foundGrid.update(anchor: planeAnchor)
    }
    
    
    func resetLabels() {
      messageLabel?.alpha = 1.0
      messageLabel?.text =
        "1️⃣ Move the phone around\n" +
        "Until you see a grid."
      sessionStateLabel?.alpha = 0.0
      sessionStateLabel?.text = ""
      spinLabel?.alpha = 0.0
      spinLabel?.text = ""
    }
    
    func showMessage(_ message: String, label: UILabel, seconds: Double) {
      label.text = message
      label.alpha = 1

      DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        if label.text == message {
            label.text = ""
            label.alpha = 0
        }
      }
    }
    
    func removeAllNodes() {
        for gridNode in self.grids { gridNode.removeFromParentNode() }
        rainbowNode?.removeFromParentNode()
        self.grids = [Grid]()
    }
    
    @objc func handleSwipes(swipe: UISwipeGestureRecognizer) {
        if self.messageLabel?.text == "" {
            switch swipe.direction.rawValue {
            case 2: // left
                let rotateLeft = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi), z: 0, duration: 5.0)
                let repeatForever = SCNAction.repeatForever(rotateLeft)
                self.rainbowNode.runAction(repeatForever)
            case 1: // right
                let rotateRight = SCNAction.rotateBy(x: 0, y: CGFloat(0 - Float.pi), z: 0, duration: 5.0)
                let repeatForever = SCNAction.repeatForever(rotateRight)
                self.rainbowNode.runAction(repeatForever)
            default:
               break
            }
        }
    }

}
