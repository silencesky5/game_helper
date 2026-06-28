import '../engine/game_task.dart';
import 'boss/boss_task.dart';
import 'guild/guild_task.dart';
import 'inventory/inventory_task.dart';
import 'login/login_task.dart';
import 'mail/mail_task.dart';
import 'mine/mine_task.dart';
import 'repair/repair_task.dart';
import 'shop/shop_task.dart';
import 'sign/sign_task.dart';
import 'stone/stone_task.dart';

/// Default task plugin catalog sorted later by scheduler priority.
const List<GameTask> defaultGameTasks = <GameTask>[
  LoginTask(),
  SignTask(),
  MailTask(),
  ShopTask(),
  StoneTask(),
  InventoryTask(),
  RepairTask(),
  MineTask(),
  BossTask(),
  GuildTask(),
];
