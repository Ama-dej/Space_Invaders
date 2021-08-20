package;

import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.FlxState;

class PlayState extends BarricadeCreationState
{
	var EnemyGroup:FlxGroup = new FlxGroup();
	var EnemyArray:Array<FlxSprite> = [];
	var friendlyBulletGroup:FlxGroup = new FlxGroup();
	var enemyBulletGroup:FlxGroup = new FlxGroup();

	var Player:FlxSprite = new FlxSprite();
	var PlayerhitboxSprite:FlxSprite = new FlxSprite();

	var clock = 1;
	var enemyCooldown = 90;
	var recentlyGotShot = 5;
	var friendlyCooldown = 60;
	var facingLeft:Bool = false;
	var livesText:FlxText;
	var remainingText:FlxText;

	override public function create()
	{
		super.create();
		var firstRow = true;
		var xPos = 10;
		var yPos = 50;
		for (a in 0...5) {
			for (i in 0...8) {
				var newEnemy:EnemyShip = new EnemyShip(xPos, yPos, firstRow);
				EnemyArray.push(newEnemy);
				EnemyGroup.add(newEnemy);
				add(newEnemy);
				xPos += 100;
			}
			firstRow = false;
			yPos += 80;
			xPos = 10;
		}

		Player.loadGraphic("assets/b.png");
		Player.setPosition(610, 690);
		Player.health = 3;
		add(Player);

		livesText = new FlxText(FlxG.width - 10, 10, "Lives: " + Player.health);
		livesText.setFormat(20, FlxColor.WHITE);
		livesText.x -= livesText.width;
		add(livesText);

		remainingText = new FlxText(10, 10, "Remaining: " + EnemyArray.length);
		remainingText.setFormat(20, FlxColor.WHITE);
		add(remainingText);

		PlayerhitboxSprite.makeGraphic(Std.int(Player.width / 2), 60, FlxColor.WHITE);
		PlayerhitboxSprite.setPosition(Player.x + Player.width / 2 - PlayerhitboxSprite.width / 2, 0);
		PlayerhitboxSprite.visible = false;
		add(PlayerhitboxSprite);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		FlxG.overlap(friendlyBulletGroup, EnemyGroup, killDaThing);
		FlxG.overlap(enemyBulletGroup, Player, noooPlayerDie);
		FlxG.overlap(friendlyBulletGroup, BarricadeGroup, destroyBarricade);
		FlxG.overlap(enemyBulletGroup, BarricadeGroup, destroyBarricade);
		movePlayer();
		moveAliens();
		shootAtPlayer();
		if ((FlxG.mouse.justPressed || FlxG.keys.anyJustPressed([ENTER, SPACE])) && friendlyCooldown < 0) {
			boomBulletCool(Player, false);
			friendlyCooldown = 60;
		}
		friendlyCooldown -= 1;
		recentlyGotShot -= 1;
	}
	
	function enemyTooClose() {
		if (EnemyArray[EnemyArray.length - 1].y > Player.y - 150) {
			trace("dead");
			var dedLol:Died = new Died();
			openSubState(dedLol);
		}
	}

	function movePlayer() {
		if (FlxG.keys.anyPressed([A, LEFT])) {
			Player.velocity.x = -200;
		} else if (FlxG.keys.anyPressed([D, RIGHT])) {
			Player.velocity.x = 200;
		} else {
			Player.velocity.x = 0;
		}
	}

	function destroyBarricade(bullet, block) {
		bullet.kill();
		block.kill();
	}

	function moveAliens() {
		if (clock % 90 == 0) {
			if (facingLeft) {
				if (EnemyArray[0].x - EnemyArray[0].width * 2 < 0) {
					for (i in EnemyArray) {
						i.y += 20;
					}
					PlayerhitboxSprite.y += 20;
					facingLeft = false;
				} else {
					for(i in EnemyArray) {
						i.x -= 40;
					}
				}
			} else {
				var prevSprite:FlxSprite = new FlxSprite(EnemyArray[0].x, EnemyArray[0].y);
				var swagVar = 0;
				for (i in EnemyArray) {
					if (i.y == prevSprite.y) {
						swagVar += 1;
						prevSprite = i;
					} else {
						swagVar -= 1;
						break;
					}
				}
				if (EnemyArray[swagVar].x + EnemyArray[swagVar].width * 2 > FlxG.width) {
					for (i in EnemyArray) {
						i.y += 20;
					}
					PlayerhitboxSprite.y += 20;
					facingLeft = true;
				} else {
					for(i in EnemyArray) {
						i.x += 40;
					}
				}
			}
			enemyTooClose();
		}
		clock += 1;
	}

	function shootAtPlayer() {
		PlayerhitboxSprite.x = Player.x + Player.width / 2 - PlayerhitboxSprite.width / 2;
		if (enemyCooldown < 0) {
			FlxG.overlap(PlayerhitboxSprite, EnemyGroup, coolFunction);
			enemyCooldown = 90;
		}
		enemyCooldown -= 1;
	}

	function coolFunction(hitbox, sprite) {
		boomBulletCool(sprite, true);
	}

	function boomBulletCool(spritePls:FlxSprite, goDown:Bool) {
		var coolBullet:FlxSprite = new FlxSprite(spritePls.x + spritePls.width / 2, spritePls.y);
		coolBullet.makeGraphic(5, 20, FlxColor.RED);
		coolBullet.x -= coolBullet.width / 2;
		coolBullet.y -= coolBullet.height;
		if (goDown == false) {
		    coolBullet.velocity.y = -600;
			friendlyBulletGroup.add(coolBullet);
		} else {
			coolBullet.velocity.y = 1200;
			coolBullet.y += spritePls.height * 2;
			enemyBulletGroup.add(coolBullet);
		}
		add(coolBullet);
	}

	function killDaThing(bullet, sprite:FlxSprite) {
		bullet.kill();
		sprite.kill();
		EnemyArray.remove(sprite);
		remainingText.text = "Remaining: " + EnemyArray.length;
	}

	function noooPlayerDie(bullet, sprite:FlxSprite) {
		if (Player.health != 1) {
			bullet.kill();
		}
		if (recentlyGotShot < 0) {
			recentlyGotShot = 5;
			Player.health -= 1;
			livesText.text = "Lives: " + Player.health;
			if (Player.health == 0) {
				Player.kill();
				var dedLol:Died = new Died();
				openSubState(dedLol);
			}
		}
	}
}

class EnemyShip extends FlxSprite {
	public function new(x, y, firstrow) {
		super(x, y);
		if (firstrow) {
			loadGraphic("assets/cool.png");
		} else {
			loadGraphic("assets/scrub.png");
		}
	}
}

class BarricadeCreationState extends FlxState {
	var BarricadeGroup:FlxGroup = new FlxGroup();

	override public function create() {
		super.create();
		for (i in 1...5) {
			createBarricade(Std.int(i * FlxG.width / 5 - 60), 600, BarricadeGroup);
		}
		add(BarricadeGroup);
	}

	function createBarricade(x, y, group:FlxGroup) {
		var xPos = x;
		var yPos = y;
		for (i in 0...4) {
			var newBlock:FlxSprite = new FlxSprite(xPos, yPos);
			newBlock.makeGraphic(20, 20, FlxColor.WHITE);
			group.add(newBlock);
			xPos += 20;
		}
		xPos = x - 20;
		yPos += 20;
		for (i in 0...6) {
			var newBlock:FlxSprite = new FlxSprite(xPos, yPos);
			newBlock.makeGraphic(20, 20, FlxColor.WHITE);
			group.add(newBlock);
			xPos += 20;
		}
		xPos = x - 20;
		yPos += 20;
		for (i in 0...2) {
			var newBlock:FlxSprite = new FlxSprite(xPos, yPos);
			newBlock.makeGraphic(20, 20, FlxColor.WHITE);
			group.add(newBlock);
			xPos += 100;
		}
	}
}

class Died extends FlxSubState {
	override public function create() {
		super.create();
		var youDiedText:FlxText = new FlxText("You Died");
		youDiedText.setFormat(60, FlxColor.LIME);
		youDiedText.screenCenter(XY);
		add(youDiedText);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		if (FlxG.keys.anyJustPressed([ESCAPE, ENTER, TAB])) {
			FlxG.resetGame();
		}
	}
}