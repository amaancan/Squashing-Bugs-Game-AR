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
  let gameSize = CGSize(width: 2, height: 2)
  var sight: SKSpriteNode!
  
  override func didMove(to view: SKView) { // Called once, immediately after a scene is presented by a view (not called every frame, so don't put game logic or node changes here.
    sight = SKSpriteNode(imageNamed: "sight") // a sight to the center of the screen for aiming
    addChild(sight)
    
    srand48(Int(Date.timeIntervalSinceReferenceDate)) // seed the random number generator used for bug's y-posn
    // MARK: Q - why seeding in didMove(to:) instead of update(_:)?
  }
  
  
  //MARK: - ADDING BUGS
  
  
  var isWorldSetUp = false // flag to check if AR nodes are already added to the game world
  
    // update(_:) is called once per frame; attempt to call the method inside there
    // this way, you only run the set up code once, and only when the session is ready.
  override func update(_ currentTime: TimeInterval) {
    if !isWorldSetUp { setUpWorld() } // setUpWorld() not called every frame, just once!
    
    guard let currentFrame = sceneView.session.currentFrame else { return }
    
    setUpLightEstimation() // MARK: Q - move inside if scope above?
    
    // MARK: Check for collision with bug spray every single frame
    for anchor in currentFrame.anchors {
      guard let node = sceneView.node(for: anchor),
        node.name == NodeType.bugspray.rawValue
        else { continue }

      let distance = simd_distance(anchor.transform.columns.3, currentFrame.camera.transform.columns.3)

      if distance < 0.2 { remove(bugspray: anchor); break }
    }

    
  }
  
  private func setUpWorld() {  // load the alien once — only if isWorldSetUp is false
    
    // check if the session has an initialized currentFrame
    guard let currentFrame = sceneView.session.currentFrame,
      let scene = SKScene(fileNamed: "Level1")
      else { return }
    
    for node in scene.children {
      if let node = node as? SKSpriteNode {
        var translation = matrix_identity_float4x4
        
        // MARK: Convert bug's position from 2D-SK to 3D-ARK
        let positionX = node.position.x / scene.size.width
        let positionY = node.position.y / scene.size.height
        translation.columns.3.x = Float(positionX * gameSize.width)
        translation.columns.3.z = -Float(positionY * gameSize.height)
        translation.columns.3.y = Float(drand48() - 0.5) // generates a pseudo-random # b/w 0 to 1, using the linear congruential algorithm and 48-bit integer arithmetic
        let transform = currentFrame.camera.transform * translation
        
        // Each frame tracks this anchor and recalculates the transformation matrices of the anchors and the camera using the device’s new position and orientation.
        // When you add an anchor, the session calls sceneView’s delegate method view(_:nodeFor:) to find out what sort of SKNode you want to attach to this anchor.
        let anchor = GameAnchor(transform: transform)
        if let name = node.name, //get the type of the bug from the SKSpriteNode name you specified in Level1.sks
          let type = NodeType(rawValue: name) {
          
          anchor.type = type
          sceneView.session.add(anchor: anchor)
          if anchor.type == .firebug {
            addBugSpray(to: currentFrame)
          }
          
        }
      }
    }
    
    isWorldSetUp = true
  }
  
  private func setUpLightEstimation() {
      //retrieve the light estimate from the session’s current frame
    guard let currentFrame = sceneView.session.currentFrame,
      let lightEstimate = currentFrame.lightEstimate else { return }
    
      //Using the light estimate’s intensity of ambient light in the scene, you calculate a blend factor between 0 and 1, where 0 will be the brightest.
    let neutralIntensity: CGFloat = 1000 // lumens in a brightly lit room
    let ambientIntensity = min(lightEstimate.ambientIntensity,
                               neutralIntensity)
    let blendFactor = 1 - ambientIntensity / neutralIntensity
    
      //Using this blend factor, calculate how much black should tint the bugs
    for node in children { // MARK: Q - how does it know we're referring to root node: SKScene
      if let bug = node as? SKSpriteNode {
        bug.color = .black
        bug.colorBlendFactor = blendFactor // % of colour (black) blended with sprite's texture
      }
    }
  }
  
  
  //MARK: - SQUASHING THE BUGS
  
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    run(Sounds.fire)
    var hitBug: SKNode?
    
    // MARK: Find if bug is hit
    let hitNodes = nodes(at: sight.position) // retrieve all nodes intersecting the sight's xy location. ARKit calculates a 2D posn and scale for the SKNode from the 3D information
    
    for node in hitNodes {
      if node.name == NodeType.bug.rawValue ||
        (node.name == NodeType.firebug.rawValue && hasBugspray)  {
        hitBug = node
        break
      }
    }
    
    // MARK: If hit, remove bug's anchor (system auto-removes node) and run sound
    if let hitBug = hitBug,
      let anchor = sceneView.anchor(for: hitBug) {
      
      let action = SKAction.run {
        self.sceneView.session.remove(anchor: anchor)
      }
      let group = SKAction.group([Sounds.hit, action])
      let sequence = [SKAction.wait(forDuration: 0.3), group]
      hitBug.run(SKAction.sequence(sequence))
    }
    
    hasBugspray = false
  }
  
  
  //MARK: - BUG SPRAY
  
  
  // Add a new anchor of type bugspray with a random position. You randomize the x (side) and z (forward/back) values between -1 and 1 and the y (up/down) value between -0.5 and 0.5
  private func addBugSpray(to currentFrame: ARFrame) { //MARK: Q - why need currentFrame parameter
    var translation = matrix_identity_float4x4
    translation.columns.3.x = Float(drand48()*2 - 1)
    translation.columns.3.z = -Float(drand48()*2 - 1)
    translation.columns.3.y = Float(drand48() - 0.5)
    let transform = currentFrame.camera.transform * translation
    
    let anchor = GameAnchor(transform: transform)
    anchor.type = .bugspray
    sceneView.session.add(anchor: anchor)
  }
  
  private func remove(bugspray anchor: ARAnchor) {
    run(Sounds.bugspray)
    sceneView.session.remove(anchor: anchor)
    hasBugspray = true
  }
  
  var hasBugspray = false {
    didSet {
      let sightImageName = hasBugspray ? "bugspraySight" : "sight"
      sight.texture = SKTexture(imageNamed: sightImageName)
    }
  }
}
