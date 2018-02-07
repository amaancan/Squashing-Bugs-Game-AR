/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import ARKit

// IB NOTES::
// 1. Change self.view to 'ARSKView'

// INFO.PLIST NOTES::
// 1. Added "Privacy - Camera Usage Description"

class GameViewController: UIViewController {
  
  var sceneView: ARSKView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // get the loaded view as an ARSKView — matching the change in Main.storyboard
    if let view = self.view as? ARSKView {
      sceneView = view // main view is set: will soon start displaying camera video feed
      sceneView.delegate = self // MARK: removed ! from sceneView
      
      // Initialize the SKScene: GameScene, directly, instead of through the .sks file
      let scene = GameScene(size: view.bounds.size)
      scene.scaleMode = .resizeFill
      scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
      view.presentScene(scene)
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let configuration = ARWorldTrackingConfiguration() //tracks device's orientation & posn
    sceneView.session.run(configuration)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sceneView.session.pause()
  }
  
  override var shouldAutorotate: Bool {
    return true
  }
  
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    if UIDevice.current.userInterfaceIdiom == .phone {
      // tailor style & behavior of UI to device type
      return .allButUpsideDown
    } else {
      return .all
    }
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
}


// MARK: - ARSKView DELEGATE METODS FOR SESSION EVENTS
extension GameViewController: ARSKViewDelegate {
  
  func session(_ session: ARSession, didFailWithError error: Error) {
    // user will have to allow access to the camera through the Settings app.
    // TODO: This is a good spot to display an appropriate dialog.
    print("Session Failed - probably due to lack of camera access")
  }
  
  func sessionWasInterrupted(_ session: ARSession) {
    print("Session interrupted")
  }
  
  func sessionInterruptionEnded(_ session: ARSession) {
    // camera won’t be in exactly the same orientation or position so reset tracking & anchors
    print("Session resumed")
    sceneView.session.run(session.configuration!, options: [.resetTracking, .removeExistingAnchors])
  }
}
