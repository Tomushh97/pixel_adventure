import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
import 'package:pixel_adventure/components/fruit.dart';
import 'package:pixel_adventure/components/saw.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState {
  idle,
  running,
  jumping,
  falling,
  hit,
  appearing,
}

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, KeyboardHandler, CollisionCallbacks {
  Player({
    position,
    this.character = 'Ninja Frog',
  }) : super(position: position);

  final String character;

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation appearingAnimation;
  final double stepTime = 0.05;

  final double _gravity = 9.8;
  final double _jumpForce = 460;
  final double _terminalVelocity = 300;
  double horizontalMovement = 0;
  double verticalMovement = 0;
  double moveSpeed = 120;
  Vector2 velocity = Vector2.zero();
  Vector2 startingPosition = Vector2.zero();
  bool isOnGround = false;
  bool hasJumped = false;
  bool gotHit = false;
  List<CollisionBlock> collisionBlocks = [];
  CustomHitBox hitBox = CustomHitBox(
    offsetX: 10,
    offsetY: 4,
    width: 14,
    height: 28,
  );

  @override
  void update(double dt) {
    if (!gotHit) {
      _updatePlayerState();
      _updatePlayerMovement(dt);
      _checkHorizontalCollisions();
      _applyGravity(dt);
      _checkVerticalCollisions();
    }
    super.update(dt);
  }

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    startingPosition = Vector2(position.x, position.y);

    add(RectangleHitbox(
      position: Vector2(hitBox.offsetX, hitBox.offsetY),
      size: Vector2(hitBox.width, hitBox.height),
    ));
    return super.onLoad();
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);

    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;
    hasJumped = keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.space);

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Fruit) {
      other.collidedWithPlayer();
    }
    if (other is Saw) _respawn();

    super.onCollision(intersectionPoints, other);
  }

  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation('Idle', 11);
    runningAnimation = _spriteAnimation('Run', 12);
    jumpingAnimation = _spriteAnimation('Jump', 1);
    fallingAnimation = _spriteAnimation('Fall', 1);
    hitAnimation = _spriteAnimation('Hit', 7)..loop = false;
    appearingAnimation = _specialSpriteAnimation('Appearing', 7)..loop = false;

    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.appearing: appearingAnimation,
    };

    current = PlayerState.idle;
  }

  SpriteAnimation _spriteAnimation(String playerState, int frameCount) {
    return SpriteAnimation.fromFrameData(
      game.images
          .fromCache('Main Characters/$character/$playerState (32x32).png'),
      SpriteAnimationData.sequenced(
        amount: frameCount,
        stepTime: stepTime,
        textureSize: Vector2.all(32),
      ),
    );
  }

  SpriteAnimation _specialSpriteAnimation(String playerState, int frameCount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Main Characters/$playerState (96x96).png'),
      SpriteAnimationData.sequenced(
        amount: frameCount,
        stepTime: stepTime,
        textureSize: Vector2.all(96),
      ),
    );
  }

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    if (horizontalMovement < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (horizontalMovement > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    //Check falling
    if (velocity.y > _gravity) playerState = PlayerState.falling;

    //Check jumping
    if (velocity.y < 0) playerState = PlayerState.jumping;

    //Check if moving, set running
    if (horizontalMovement > 0 || horizontalMovement < 0) {
      playerState = PlayerState.running;
    }

    current = playerState;
  }

  void _updatePlayerMovement(double dt) {
    if (hasJumped && isOnGround) _playerJump(dt);
    velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  void _playerJump(double dt) {
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (!block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - hitBox.offsetX - hitBox.width;
            break;
          }
          if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + hitBox.width + hitBox.offsetX;
            break;
          }
        }
      }
    }
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitBox.height - hitBox.offsetY;
            isOnGround = true;
            break;
          }
        }
      } else {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitBox.height - hitBox.offsetY;
            isOnGround = true;
            break;
          }
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height - hitBox.offsetY;
          }
        }
      }
    }
  }

  void _respawn() async {
    gotHit = true;
    current = PlayerState.hit;

    final hitAnimation = animationTickers![PlayerState.hit];

    hitAnimation!.completed.whenComplete(() {
      current = PlayerState.appearing;
      scale.x = 1;
      position = startingPosition - Vector2.all(32);
      hitAnimation.reset();
      final appearingAnimation = animationTickers![PlayerState.appearing];
      appearingAnimation!.completed.whenComplete(() {
        position = startingPosition;
        current = PlayerState.idle;
        gotHit = false;
        appearingAnimation.reset();
      });
    });
  }
}
