# _Custom Roles for TTT_ Roles Pack for Jingle Jam 2026
A pack of [Custom Roles for TTT](https://github.com/Custom-Roles-for-TTT/TTT-Custom-Roles) roles created based on the generous donations of our community members in support of [Jingle Jam 2026](https://www.jinglejam.co.uk/).

# Roles

## ![Role Icon](/gamemodes/terrortown/content/materials/vgui/ttt/roles/amn/tab_amn.png) Amnesiac
_Contributed By_: Nick\
The Amnesiac is an innocent role that has an unknown randomly generated ability that is slowly revealed over time.
\
\
**ConVars**
```cpp
ttt_amnesiac_enabled                        0   // Whether or not an Amnesiac should spawn
ttt_amnesiac_spawn_weight                   1   // The weight assigned to spawning an Amnesiac
ttt_amnesiac_min_players                    0   // The minimum number of players required to spawn an Amnesiac
ttt_amnesiac_starting_health                100 // The amount of health an Amnesiac starts with
ttt_amnesiac_max_health                     100 // The maximum amount of health an Amnesiac can have
ttt_amnesiac_ability_reveal_time            300 // How long it takes (in seconds) for the Amnesiac's ability to be fully revealed to them
ttt_amnesiac_ability_success_sound          1   // Whether a sound plays for the player whose Amnesiac ability successfully runs
ttt_amnesiac_show_status_effects            1   // Whether particles and sounds play for buffs and debuffs from Amnesiac abilities
ttt_amnesiac_airborne_enabled               1   // Whether the "While you are in the air" trigger is enabled
ttt_amnesiac_attack_enabled                 1   // Whether the "When you attack" trigger is enabled
ttt_amnesiac_beinglookedat_enabled          1   // Whether the "While another player is looking at you" trigger is enabled
ttt_amnesiac_close_enabled                  1   // Whether the "When you get close to another player" trigger is enabled
ttt_amnesiac_crouch_enabled                 1   // Whether the "When you crouch" trigger is enabled
ttt_amnesiac_crouching_enabled              1   // Whether the "While you are crouching" trigger is enabled
ttt_amnesiac_dealdamage_enabled             1   // Whether the "When you damage another player" trigger is enabled
ttt_amnesiac_death_enabled                  1   // Whether the "When you die" trigger is enabled
ttt_amnesiac_emptyclip_enabled              1   // Whether the "When you empty a clip" trigger is enabled
ttt_amnesiac_fullhealth_enabled             1   // Whether the "When you are at full health" trigger is enabled
ttt_amnesiac_jump_enabled                   1   // Whether the "When you jump" trigger is enabled
ttt_amnesiac_lookat_enabled                 1   // Whether the "When you look at another player" trigger is enabled
ttt_amnesiac_lookedat_enabled               1   // Whether the "When another player looks at you" trigger is enabled
ttt_amnesiac_lookingat_enabled              1   // Whether the "While you are looking at another player" trigger is enabled
ttt_amnesiac_lowhealth_enabled              1   // Whether the "When you are at or below 25% health" trigger is enabled
ttt_amnesiac_outofammo_enabled              1   // Whether the "When you run out of ammo" trigger is enabled
ttt_amnesiac_reload_enabled                 1   // Whether the "When you reload" trigger is enabled
ttt_amnesiac_searchbody_enabled             1   // Whether the "When you search a body" trigger is enabled
ttt_amnesiac_sprint_enabled                 1   // Whether the "When you sprint" trigger is enabled
ttt_amnesiac_sprinting_enabled              1   // Whether the "While you are sprinting" trigger is enabled
ttt_amnesiac_standingstill_enabled          1   // Whether the "While you are standing still for more than 5 seconds" trigger is enabled
ttt_amnesiac_standstill_enabled             1   // Whether the "When you stand still for 5 seconds" trigger is enabled
ttt_amnesiac_stayingclose_enabled           1   // Whether the "While you are close to another player" trigger is enabled
ttt_amnesiac_takedamage_enabled             1   // Whether the "When you take damage" trigger is enabled
ttt_amnesiac_throwgrenade_enabled           1   // Whether the "When you throw a grenade" trigger is enabled
ttt_amnesiac_weaponswitch_enabled           1   // Whether the "When you switch weapons" trigger is enabled
ttt_amnesiac_blind_enabled                  1   // Whether the "Blind" effect is enabled
ttt_amnesiac_damage_enabled                 1   // Whether the "Damage" effect is enabled
ttt_amnesiac_damageboost_enabled            1   // Whether the "Damage boost (Instant)" effect is enabled
ttt_amnesiac_damageboosting_enabled         1   // Whether the "Damage boost (Ongoing)" effect is enabled
ttt_amnesiac_damageresist_enabled           1   // Whether the "Resist boost (Instant)" effect is enabled
ttt_amnesiac_damageresisting_enabled        1   // Whether the "Resist boost (Ongoing)" effect is enabled
ttt_amnesiac_damagevulnerable_enabled       1   // Whether the "Resist debuff (Instant)" effect is enabled
ttt_amnesiac_damagevulnerableing_enabled    1   // Whether the "Resist debuff (Ongoing)" effect is enabled
ttt_amnesiac_damageweaken_enabled           1   // Whether the "Damage debuff (Instant)" effect is enabled
ttt_amnesiac_damageweakening_enabled        1   // Whether the "Damage debuff (Ongoing)" effect is enabled
ttt_amnesiac_disablerole_enabled            1   // Whether the "Disable role ability (Instant)" effect is enabled
ttt_amnesiac_disableshop_enabled            1   // Whether the "Disable shop (Instant)" effect is enabled
ttt_amnesiac_disablingrole_enabled          1   // Whether the "Disable role ability (Ongoing)" effect is enabled
ttt_amnesiac_disablingshop_enabled          1   // Whether the "Disable shop (Ongoing)" effect is enabled
ttt_amnesiac_drainclip_enabled              1   // Whether the "Empty clip" effect is enabled
ttt_amnesiac_dropweapon_enabled             1   // Whether the "Drop weapon" effect is enabled
ttt_amnesiac_fast_enabled                   1   // Whether the "Speed boost (Instant)" effect is enabled
ttt_amnesiac_fasting_enabled                1   // Whether the "Speed boost (Ongoing)" effect is enabled
ttt_amnesiac_fling_enabled                  1   // Whether the "Fling" effect is enabled
ttt_amnesiac_freeze_enabled                 1   // Whether the "Freeze" effect is enabled
ttt_amnesiac_fullammo_enabled               1   // Whether the "Full ammo" effect is enabled
ttt_amnesiac_ghost_enabled                  1   // Whether the "Ghost (Instant)" effect is enabled
ttt_amnesiac_ghosting_enabled               1   // Whether the "Ghost (Ongoing)" effect is enabled
ttt_amnesiac_heal_enabled                   1   // Whether the "Heal" effect is enabled
ttt_amnesiac_ignite_enabled                 1   // Whether the "Ignite" effect is enabled
ttt_amnesiac_invulnerable_enabled           1   // Whether the "Invulnerability" effect is enabled
ttt_amnesiac_packapunch_enabled             1   // Whether the "Pack-a-Punch" effect is enabled
ttt_amnesiac_poison_enabled                 1   // Whether the "Poison" effect is enabled
ttt_amnesiac_ragdoll_enabled                1   // Whether the "Ragdoll" effect is enabled
ttt_amnesiac_regenerate_enabled             1   // Whether the "Regenerate" effect is enabled
ttt_amnesiac_respawn_enabled                1   // Whether the "Respawn" effect is enabled
ttt_amnesiac_shopitem_enabled               1   // Whether the "Free shop item" effect is enabled
ttt_amnesiac_slow_enabled                   1   // Whether the "Speed debuff (Instant)" effect is enabled
ttt_amnesiac_slowing_enabled                1   // Whether the "Speed debuff (Ongoing)" effect is enabled
ttt_amnesiac_swap_enabled                   1   // Whether the "Swap positions" effect is enabled
ttt_amnesiac_unlimitedammo_enabled          1   // Whether the "Unlimited ammo" effect is enabled
```

# Special Thanks
- [Game icons](https://game-icons.net/) for the role icons