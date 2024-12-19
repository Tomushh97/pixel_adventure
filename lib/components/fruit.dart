import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class Fruit extends SpriteAnimationComponent
    with HasGameRef<PixelAdventure>, CollisionCallbacks {
  final String fruit;
  Fruit({
    required Vector2 position,
    required Vector2 size,
    this.fruit = 'Apple',
  }) : super(
          position: position,
          size: size,
        );

  bool _collected = false;
  final double stepTime = 0.05;
  final hitBox = CustomHitBox(
    offsetX: 10,
    offsetY: 10,
    width: 12,
    height: 12,
  );

  @override
  FutureOr<void> onLoad() {
    priority = -1;
    // debugMode = true;

    add(
      RectangleHitbox(
        position: Vector2(hitBox.offsetX, hitBox.offsetY),
        size: Vector2(hitBox.width, hitBox.height),
        collisionType: CollisionType.passive,
      ),
    );
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Items/Fruits/$fruit.png'),
      SpriteAnimationData.sequenced(
          amount: 17, stepTime: stepTime, textureSize: Vector2.all(32)),
    );
    return super.onLoad();
  }

  void collidedWithPlayer() {
    if (!_collected) {
      animation = SpriteAnimation.fromFrameData(
        game.images.fromCache('Items/Fruits/Collected.png'),
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: stepTime,
          textureSize: Vector2.all(32),
          loop: false,
        ),
      );
    }
    _collected = true;
    Future.delayed(const Duration(milliseconds: 400), () => removeFromParent());
  }
}
