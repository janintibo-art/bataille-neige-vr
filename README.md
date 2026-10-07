# Bataille de Neige VR

Jeu VR de bataille de neige pour Meta Quest 3, realise sous Godot 4.7.2 + OpenXR.

## V7 - les 20 adversaires

- 20 personnages nommes repartis sur 5 vagues ;
- Berni, Kevin Turbo, Chantal Mitraillette, Marco Longue Vue ;
- Lea l'Esquive, Jojo la Doudoune, Dede les Poches, Nono Ninja ;
- Ginette du Balcon, Titou la Pelle, Lucette la Moufle, Pierrot de Travers ;
- Momo le Tricheur, Gerard le Bucheron, Fifi Flocon, Josiane Camouflage ;
- Maurice Bonhomme, Gaston Glacon, Robert Couvercle et Raoul le Chef ;
- 6 archetypes de combat : standard, runner, rapid, sniper, tank et zigzag ;
- Raoul le Chef devient le premier mini-boss avec 8 points de vie et de grosses boules de neige ;
- plusieurs silhouettes et accessoires proceduraux : bonnets, pompons, cache-oreilles, lunettes, capuche, bandeau, echarpe et moustache ;
- bras et jambes visibles pour donner une vraie silhouette aux personnages ;
- petit fort de neige en U utilisable comme couverture ;
- deux gros bonshommes de neige servant aussi de couvertures ;
- la structure des personnages est separee dans `scripts/roster.gd` pour faciliter les futures zones.

## Gameplay deja present

- deplacement au joystick gauche ;
- rotation par crans au joystick droit ;
- ramassage de neige au grip pres du sol ;
- lancer a la gachette ;
- 5 points de vie au poignet ;
- impacts ennemis et vibrations ;
- reapparition apres KO ;
- compilation Quest 3 automatique avec GitHub Actions.

## Suite prevue

La prochaine etape pourra enrichir les sensations de lancer : vitesse basee sur le vrai geste de la main, grosse boule a deux mains et effets d'impact dans la neige.
