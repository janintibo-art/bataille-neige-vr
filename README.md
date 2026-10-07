# Bataille de Neige VR

Jeu VR de bataille de neige pour Meta Quest 3, realise sous Godot 4.7.2 + OpenXR.

## V8 - lancer physique et grosse boule

### Lancer naturel
- la direction et la puissance d'une boule utilisent maintenant la vitesse reelle de la main ;
- la vitesse des mains est echantillonnee et lissee pour eviter les lancers nerveux ;
- un petit geste reste jouable grace a une vitesse minimale ;
- les gestes tres violents sont limites pour garder un comportement stable sur Quest 3 ;
- nouvelle logique : on serre la gachette pour tenir la boule, puis on relache la gachette pour la lancer.

### Grosse boule a deux mains
1. ramasser une boule de neige dans chaque main ;
2. garder les deux grips serres ;
3. rapprocher les deux mains ;
4. maintenir environ 0,75 seconde : les deux boules se compactent en une grosse boule ;
5. serrer les deux gachettes ;
6. faire le geste de lancer avec les deux mains et relacher les deux gachettes.

La grosse boule :
- inflige 3 points de degats sur l'impact direct ;
- inflige 2 points aux adversaires tres proches ;
- repousse les adversaires ;
- produit une grosse eclaboussure de neige.

### Impacts
- toutes les boules produisent maintenant un petit nuage de neige ;
- les adversaires peuvent etre legerement repousses par les impacts ;
- les 20 personnages, les 5 vagues et Raoul le Chef restent en place.

## Controles
- Stick gauche : deplacement.
- Stick droit : rotation par crans.
- Grip pres du sol : ramasser une boule.
- Trigger maintenu puis relache : lancer avec le vrai geste de la main.
- Deux boules + deux grips + mains rapprochees : fabriquer une grosse boule.
- Deux triggers puis relache : lancer la grosse boule.
