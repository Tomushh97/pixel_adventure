import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/actors/player.dart';
import 'package:pixel_adventure/levels/level.dart';

class PixelAdventure extends FlameGame with HasKeyboardHandlerComponents {
  @override
  Color backgroundColor() => const Color(0xFF211F30);
  Player player = Player(character: 'Mask Dude');
  late Level _world;
  late TiledComponent level;
  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    _world = Level(
      levelName: 'Level-01',
      player: player,
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    await add(_world);
  }
}
