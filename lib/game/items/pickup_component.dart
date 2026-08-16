import 'package:bonfire/bonfire.dart';
import '../../services/sound_service.dart';
import '../player/agent_q_component.dart';

enum PickupType { health, ammo, shield }

class PickupComponent extends GameDecoration with Sensor {
  final PickupType type;

  PickupComponent({
    required super.position,
    required this.type,
  }) : super.withSprite(
          sprite: Sprite.load(_getAssetPath(type)),
          size: Vector2(20, 20),
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(size: Vector2(20, 20)));
    await super.onLoad();
  }

  static String _getAssetPath(PickupType type) {
    switch (type) {
      case PickupType.health:
        return 'pickups_and_powerups/Health_pickup.png';
      case PickupType.ammo:
        return 'pickups_and_powerups/Ammo_pickup.png';
      case PickupType.shield:
        return 'pickups_and_powerups/shield_power_up.png';
    }
  }

  @override
  void onContact(GameComponent component) {
    if (component is AgentQComponent && !component.isDead) {
      bool collected = false;
      switch (type) {
        case PickupType.health:
          if (component.life < AgentQComponent.maxHealth) {
            component.addLife(25.0);
            collected = true;
          }
          break;
        case PickupType.ammo:
          if (component.ammo < component.maxAmmo || component.isReloading) {
            component.refillAmmo();
            collected = true;
          }
          break;
        case PickupType.shield:
          if (component.shield < component.maxShield) {
            component.addShield(component.maxShield);
            collected = true;
          }
          break;
      }

      if (collected) {
        SoundService.play('pickup.wav');
        removeFromParent();
      }
    }
  }
}

