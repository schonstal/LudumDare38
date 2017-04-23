package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flash.geom.Point;
import flixel.system.FlxSound;
import flixel.math.FlxRandom;
import flixel.math.FlxVector;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxTimer;
import flixel.util.FlxSpriteUtil;

class Player extends Enemy
{
  public static var RUN_SPEED:Float = 200;
  public static var gravity:Float = 800;

  public var justHurt:Bool = false;

  public var attackSprite:AttackSprite;

  var speed:Point;
  var terminalVelocity:Float = 150;

  var jumpPressed:Bool = false;
  var jumpAmount:Float = 300;
  var jumpTimer:Float = 0;
  var jumpThreshold:Float = 0.075;

  var canJumpTimer:Float = 0;
  var canJumpThreshold:Float = 0.23;

  var elapsed:Float = 0;

  public function new(X:Float=0,Y:Float=0) {
    super();
    x = X;
    y = Y;
    loadGraphic("assets/images/player/player.png", true, 32, 32);

    animation.add("jump start", [0], 15, true);
    animation.add("jump peak", [0], 15, true);
    animation.add("jump fall", [0], 15, true);

    width = 5;
    height = 8;

    offset.y = 1;
    offset.x = 3;

    speed = new Point();
    speed.y = jumpAmount;
    speed.x = 800;
    solid = false;

    maxVelocity.x = RUN_SPEED;

    attackSprite = new AttackSprite();

    setFacingFlip(FlxObject.LEFT, true, false);
    setFacingFlip(FlxObject.RIGHT, false, false);
  }

  public function init():Void {
    Reg.player = this;
    jumpPressed = false;

    jumpTimer = 0;

    velocity.x = velocity.y = 0;
    acceleration.x = 0;

    facing = FlxObject.RIGHT;
    acceleration.y = 0;
    Reg.started = false;
    health = 100;

    x = FlxG.width/2 - width/2;
    y = 80;
  }

  private function start():Void {
    acceleration.y = gravity;
    solid = true;
    alive = true;
    Reg.started = true;
  }

  public override function hurt(damage:Float):Void {
    if(justHurt && damage < 100) return;

    FlxG.camera.flash(0xccff1472, 0.5, null, true);
    FlxG.camera.shake(0.005, 0.2);
    Reg.combo = 0;

    justHurt = true;
    FlxSpriteUtil.flicker(this, 0.6, 0.04, true, true, function(flicker) {
      justHurt = false;
    });

    super.hurt(damage);
  }

  private function isJumpPressed():Bool {
    //Check for jump input, allow for early timing
    jumpTimer += elapsed;
    if(justPressed("jump")) {
      jumpPressed = true;
      jumpTimer = 0;
    }
    if(jumpTimer > jumpThreshold) {
      jumpPressed = false;
    }

    return jumpPressed;
  }

  private function jump():Void {
    if(!canJump()) return;
    animation.play("jump start");
    velocity.y = -speed.y;
    jumpPressed = false;
    FlxG.camera.flash(0x33ffccff, 0.1);
    canJumpTimer = canJumpThreshold;
  }

  private function canJump():Bool {
    return canJumpTimer <= 0;
  }

  private function tryJumping():Void {
    if(isJumpPressed()) jump();

    if(velocity.y < -1) {
      if(velocity.y > -50) {
        animation.play("jump peak");
      }
    } else if (velocity.y > 1) {
      if(velocity.y > 100) {
        animation.play("jump fall");
      }
    }

    if(!pressed("jump") && velocity.y < 0)
      acceleration.y = gravity * 3;
    else
      acceleration.y = gravity;
  }

  private function handleMovement():Void {
    if(justPressed("attack")) {
      attackSprite.attack('slash');
      return;
    }

    if(pressed("right")) {
      acceleration.x = -speed.x * (velocity.x > 0 ? 4 : 1);
      facing = FlxObject.LEFT;
    } else if(pressed("left")) {
      acceleration.x = speed.x * (velocity.x < 0 ? 4 : 1);
      facing = FlxObject.RIGHT;
    } else if (Math.abs(velocity.x) < 10) {
      velocity.x = 0;
      acceleration.x = 0;
    } else if (velocity.x > 0) {
      acceleration.x = -speed.x * 2;
    } else if (velocity.x < 0) {
      acceleration.x = speed.x * 2;
    }

    if (x < 0) x = 0;
    if (x > FlxG.width - width) x = FlxG.width - width;
    if (y < 0) y = 0;
    if (y > FlxG.height - height) y = FlxG.height - height;

    if (velocity.y < 0) {
      acceleration.x = 0;
      velocity.x = 100;
      drag.x = 100;
    } else {
      drag.x = 0;
    }
  }

  private function computeTerminalVelocity():Void {
    if(velocity.y > terminalVelocity) {
      velocity.y = terminalVelocity;
    }
  }

  override public function update(elapsed:Float):Void {
    this.elapsed = elapsed;

    if(!Reg.started && (justPressed("left") || justPressed("right") || justPressed("jump"))) {
      start();
    }

    if(alive && Reg.started) {
      handleMovement();
      tryJumping();
      computeTerminalVelocity();
      updateTimers();
    }

    super.update(elapsed);

    attackSprite.x = x;
    attackSprite.y = y;
  }

  public override function kill():Void {
    visible = false;
    alive = false;
    Reg.started = false;
    solid = false;
    exists = false;
    acceleration.y = acceleration.x = velocity.x = velocity.y = 0;
    Reg.enemyExplosionService.explode(x + width/2, y + height/2 + explosionOffset.y, 0, 0, true);
  }

  private function updateTimers():Void {
    canJumpTimer -= elapsed;
  }

  private function justPressed(action:String):Bool {
    if (action == "jump") {
      return FlxG.keys.justPressed.S || FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.W ||
             FlxG.keys.justPressed.UP || FlxG.keys.justPressed.SPACE;
    }
    if (action == (FlxG.save.data.invertControls ? "left" : "right")) {
      return FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A;
    }
    if (action == (FlxG.save.data.invertControls ? "right" : "left")) {
      return FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D;
    }
    if (action == "direction") {
      return justPressed("left") || justPressed("right");
    }
    if (action == "attack") {
      return FlxG.keys.justPressed.SPACE;
    }
    return false;
  }

  private function pressed(action:String):Bool {
    if (action == "jump") {
      return FlxG.keys.pressed.S || FlxG.keys.pressed.DOWN || FlxG.keys.pressed.W ||
             FlxG.keys.pressed.UP || FlxG.keys.pressed.SPACE;
    }
    if (action == (FlxG.save.data.invertControls ? "left" : "right")) {
      return FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A;
    }
    if (action == (FlxG.save.data.invertControls ? "right" : "left")) {
      return FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D;
    }
    if (action == "direction") {
      return pressed("left") || pressed("right");
    }
    if (action == "attack") {
      return FlxG.keys.pressed.SPACE;
    }
    return false;
  }
}
