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

import ARKit

class GameScene: SKScene {
  var sceneView: ARSKView { return view as! ARSKView }
  
  var isWorldSetUp = false // flag to check if AR nodes are already added to the game world
  
  // update(_:) is called every frame; attempt to call the method inside there
  // this way, you only run the set up code once, and only when the session is ready.
  override func update(_ currentTime: TimeInterval) {
    if !isWorldSetUp { setUpWorld() }
  }
  
  // load the alien once — only if isWorldSetUp is false
  private func setUpWorld() {
    // check if the session has an initialized currentFrame
    guard let currentFrame = sceneView.session.currentFrame
      else { return }
    
    var translation = matrix_identity_float4x4
    translation.columns.3.z = -0.3
  
    let transform = currentFrame.camera.transform * translation
    
    //Each frame tracks this anchor and recalculates the transformation matrices of the anchors and the camera using the device’s new position and orientation.
    //When you add an anchor, the session calls sceneView’s delegate method view(_:nodeFor:) to find out what sort of SKNode you want to attach to this anchor.
    let anchor = ARAnchor(transform: transform)
    sceneView.session.add(anchor: anchor)
    
    //retrieve the light estimate from the session’s current frame
    guard let lightEstimate = currentFrame.lightEstimate else { return }
    
    //Using the light estimate’s intensity of ambient light in the scene, you calculate a blend factor between 0 and 1, where 0 will be the brightest.
    let neutralIntensity: CGFloat = 1000
    let ambientIntensity = min(lightEstimate.ambientIntensity,
                               neutralIntensity)
    let blendFactor = 1 - ambientIntensity / neutralIntensity
    
    //Using this blend factor, calculate how much black should tint the bugs
    for node in children {
      if let bug = node as? SKSpriteNode {
        bug.color = .black
        bug.colorBlendFactor = blendFactor
      }
    }
    
    isWorldSetUp = true
  }
}
