# clonezilla-auto

*Fork de la branche sambaedu-clonezilla servant pour des tests. NE PAS UTILISER EN PROD!
*UTILISER LES FICHIERS DE LA BRANCHE officielle en tapant sur votre se3  ```git clone  https://github.com/SambaEdu/sambaedu-clonezilla.git```

Ce script est fait pour être utilisé avec les serveurs se3 (sambaedu 3). Il utilise le logiciel libre 'clonezilla'.

Son principe est simple: Le script va créer un fichier ayant pour nom l'adresse mac d'un poste, le faire démarer/redémarrer. Celui-ci va donc recevoir une commande de boot PXE personnalisée qu'il suivra.

## *Clonezilla-auto* va permettre plusieurs opérations:
* **Créer un partage samba** (appelé partimag)  sur le se3. Clonezilla sera ensuite téléchargé sur le serveur, puis modifié de façon à ce qu'**adminse3 puisse y écrire/lire des images automatiquement**. 
* Des entrées dans le menu PXE (perso) seront ajoutées pour que la **création d'image** se fasse en quelques touches de clavier: on fabrique un poste modèle, on boote en PXE et on fabrique l'image. 
* Déployer **automatiquement** à partir d'un shell se3, une image clonezilla préalablement fabriquée vers un/plusieurs poste, ou **tout un parc de machine** si ces images sont sont un partage samba (se3 ou un autre serveur). Il est donc possible d'installer plusieurs salles informatiques pendant un week-end  de chez soi si on a un accès à distance au se3.
* Envoyer des **commandes personnalisées** (*restauration d'une image avec paramètres déjà entrés, faire une sauvegarde/restauration locale,démarrer tout un parc de machine en mode client lors de l'utilisation de clonezilla en mode /client/Serveur.)
* Mettre la dernière version de clonezilla (basée sur **Ubuntu Zesty** qui ajoute un mode **client/serveur** simple d'utilisation).


## Pour fonctionner correctement il faut:
* Que le serveur tftp du se3 soit activé.
* Que les images clonezilla de postes à déployer soient sur un partage samba accessible en lecture (Travail en cours avec un 'NAS').A défaut, on pourra lancer l'option n°1 du script qui crééra sur le se3 ce partage (vérifier la place disponible!!!)
* Que les ordinateurs bootent en priorité par le pxe, avec fonction Wakeonlan activée.
* Que chaque poste client ait une adresse ip réservée dans l'interface dhcp du se3.

*Le répertoire *clonezilla-auto* peut être placé n'importe où sur le serveur.Il faudra juste éditer le script pour indiquer l'emplacement des fichiers contenant des commandes PXE personnalisées.*
*Clonezilla-auto doit être lancé en root sur le se3*.
*A chaque clonage, un répertoire situé dans /var/log/clonezilla-auto/date contient les différents fichiers temporaires effacés.*

## Intégration automatique
Si les postes ont déjà été intégrés (et sont donc considérés commes tels par le serveur) et qu'ils possèdent déjà le compte adminse3 et administrateur avec les mots de passe (utilisateurs à ajouter avant de créer l'image), alors l'integration automatique via l'interface (réservation ip > réintégrer le poste) est possible.

## Utilisation par un débutant
Clonezilla-auto a été conçu pour être simple d'utilisation. Il suffit de lancer *clonezilla-auto.sh* à partir d'un terminal du serveur, puis de se laisser guider.


## Utilisation des options
Pour gagner du temps ou lancer un clonage de façon non interactive, on peut donner des indications en options de ce script qui prend donc la forme:

*./clonezilla-auto --option1 valeur1 --option2 valeur2 --option3 valeur3 ...*

** options disponibles:**

 **--mode** suivi du numéro du choix à indiquer dans le menu de départ(ex --mode 2  pour le deuxième choix).
 
 **--rappel_parc** (sans argument) pour obtenir un rappel des parcs de machine à l'écran.
 
 **--arch** clonezilla64 pour la version  64 bits , ou '--arch clonezilla' pour la version 32 bits.
 
 **--parc** suivi du nom du parc pour lancer le script sur un parc donné, ajouter \| (antislash et pipe) entre les parcs pour en séléctionner plusieurs ex: --parc s217\|s218\|s219 .
 
 **--pxeperso** suivi du nom du fichier pxe à lancer .
 
 **--image** suivi du nom de l'image.
 
 **--ipsamba** suivi de l'ip du partage samba (ex --ipsamba 172.20.0.6) .
 
 **--partage** suivi du nom du partage samba (ex --partage partimag).
 
 **--user** suivi du nom de l'utilisateur autorisé à lire l'image (ex --user clonezilla).
 
 **--mdp** suivi du mot de passe de l'utilisateur précédent (ex --mdp mdp 123).
 
 **--liste_image_samba**' pour obtenir à l'écran la liste des images placées sur le partage samba. **ATTENTION**, les options ipsamba,user,partage et mdp doivent avoir été renseignées pour lancer cette option (ex --ipsamba 172.20.0.6 --partage partimag --user clonezilla --mdp mdp123 --liste_image_samba ).
 
 **--noconfirm** (sans argument)indique qu'aucune vérification n'est faite (nom de fichier, postes concernés,etc...), utilisation pour un mode  non interactif .

**quelques exemples d'utilisation**:

./clonezilla-auto.sh --mode 2 --arch clonezilla64 --parc virtualxp

*Ici on lance le déploiment d'une image placée sur le se3 (choix 2), sur un parc appelée virtualxp, le nom de l'image n'ayant pas été précisé, il faudra le faire manuellement.

./clonezilla-auto.sh --mode 4 --parc s219-5 --pxeperso client_multicast --noconfirm 

*Ici la commande pxe appelée client_multicast est envoyée sur le poste s219-5, l'architecture est déclarée dans le fichier pxeperso (qui contient déjà les autres indications) , l'option noconfirm ayant été indiquée,le poste va redémarrer tout seul).*

./clonezilla-auto.sh --mode 2 --parc s219-5  --arch clonezilla64 --image xp_from_adminse3 --noconfirm 

*Ici on déploie l'image appelée xp_from_adminse3 sur un poste s219-4 avec clonezilla64 sans confirmation*.

./clonezilla-auto.sh --mode 3 --arch clonezilla64 --ipsamba 172.20.0.6 --partage partimag --user clonezilla --mdp mdp123 --image xpv1  --parc 111\|110 --noconfirm

*Clonage complet: ici est indiqué que les machines des parcs 111 **ET** 110 vont restaurer l'image appelée xpv1. Cette image est située sur un partage samba d'ip "172.20.0.6", avec comme utilisateur "clonezilla" et son mot de passe "mdp123". Tout va se produire de façon transparente pour l'utilisateur.*

