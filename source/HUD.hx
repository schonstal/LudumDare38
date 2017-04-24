package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.math.FlxPoint;

class HUD extends FlxSpriteGroup {
  var healthBar:HUDBar;
  var staminaBar:HUDBar;

  public function new():Void {
    super();
    scrollFactor.x = scrollFactor.y = 0;

    healthBar = new HUDBar(50, 14, 0xffe23168);
    healthBar.x = FlxG.width - 50;
    add(healthBar);

    staminaBar = new HUDBar(50, 14, 0xff7e979d);
    staminaBar.x = FlxG.width - 50;
    staminaBar.y = 14;
    add(staminaBar);
  }

  public override function update(elapsed:Float):Void {
    healthBar.value = Reg.player.health;
    staminaBar.value = Reg.player.stamina;

    super.update(elapsed);
  }
}
