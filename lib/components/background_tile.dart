import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/painting.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class BackgroundTile extends ParallaxComponent<PixelAdventure>
    with HasGameRef<PixelAdventure> {
  final String color;
  BackgroundTile({
    this.color = 'Gray',
  }) : super();

  final double scrollSpeed = 0.4;

  @override
  FutureOr<void> onLoad() async {
    parallax = await gameRef.loadParallax(
      [ParallaxImageData('Background/$color.png')],
      baseVelocity: Vector2(0, 80),
      repeat: ImageRepeat.repeat,
      fill: LayerFill.none,
    );
    priority = -10;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    position.y += scrollSpeed;
    double tileSize = 64;
    int scrollHeight = (game.size.y / tileSize).floor();
    if (position.y > scrollHeight * tileSize) {
      position.y = -tileSize;
    }
    super.update(dt);
  }
}
