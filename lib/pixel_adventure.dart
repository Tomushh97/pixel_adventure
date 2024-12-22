import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/components/level.dart';

class PixelAdventure extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks, HasCollisionDetection {
  @override
  Color backgroundColor() => const Color(0xFF211F30);
  Player player = Player(character: 'Mask Dude');
  late JoystickComponent joystick;
  bool showJoystick = false;
  List<String> levelNames = ['Level-01', 'Level-02', 'Level-03'];
  int currentLevelIndex = 0;

  late Level _world;
  late TiledComponent level;
  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    _loadLevel();

    if (showJoystick) {
      addJoystick();
    }
  }

  @override
  void update(double dt) {
    if (showJoystick) {
      updateJoystick();
    }
    super.update(dt);
  }

  void addJoystick() {
    joystick = JoystickComponent(
      margin: const EdgeInsets.only(left: 32, bottom: 32),
      knob: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Knob.png'),
        ),
      ),
      background: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Joystick.png'),
        ),
      ),
    );
    add(joystick);
  }

  void updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        player.horizontalMovement = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        player.horizontalMovement = 1;
        break;
      default:
        player.horizontalMovement = 0;
        break;
    }
  }

  void loadNextLevel() {
    removeWhere((component) => component is Level);
    if (currentLevelIndex < levelNames.length - 1) {
      currentLevelIndex++;
      _loadLevel();
    } else {
      // no more levels
      currentLevelIndex = 0;
      _loadLevel();
    }
  }

  void _loadLevel() async {
    Future.delayed(const Duration(seconds: 1), () {
      _world = Level(
        levelName: levelNames[currentLevelIndex],
        player: player,
      );
      camera.viewfinder.anchor = Anchor.topLeft;
      add(_world);
    });
  }
}
