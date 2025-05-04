---------Node 構成---------

main(node2d)
-player(area2d)
-shot(area2d)
-homingshot(area2d)
-zako1(area2d)
-enemyspawner(node2d)
-bg(control2d)

player(area2d)
-shot(area2d)
-AnimatedSprite2D
-collisionshape2D
-shotsound(AudioStreamPlayer)
-damagesound(AudioStreamPlayer)
-shotL
-shotR

shot(area2d)
-collisionshape2D
-Sprite2D

homingshot(area2d)
-Sprite2D
-homingcollision(area2d)
--collisionshape2D

zako1(area2d)
-animationsprite2D
-collisionShape2D
-AudioStreamPlayer
