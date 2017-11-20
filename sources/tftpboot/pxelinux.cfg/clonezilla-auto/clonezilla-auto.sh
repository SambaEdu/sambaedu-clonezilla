#!/bin/bash

#####################################################################################
##### Script permettant de lancer des commandes PXE
##### Il servira essentiellement à restaurer des images clonezilla sur des postes clients
##### 
##### version du 18/07/2017
##### modifiée 
#
# Auteurs :      Marc Bansse marc.bansse@ac-versailles.fr
#
# Modifié par :  
#
# Ce programme est un logiciel libre : vous pouvez le redistribuer ou
#    le modifier selon les termes de la GNU General Public Licence tels
#    que publiés par la Free Software Foundation : à votre choix, soit la
#    version 3 de la licence, soit une version ultérieure quelle qu'elle
#    soit.
#
# Ce programme est distribué dans l'espoir qu'il sera utile, mais SANS
#    AUCUNE GARANTIE ; sans même la garantie implicite de QUALITÉ
#    MARCHANDE ou D'ADÉQUATION À UNE UTILISATION PARTICULIÈRE. Pour
#    plus de détails, reportez-vous à la GNU General Public License.
#
# Vous devez avoir reçu une copie de la GNU General Public License
#    avec ce programme. Si ce n'est pas le cas, consultez
#    <http://www.gnu.org/licenses/>]





#définition des variables
TEMP=$(mktemp -d --suffix=-clonezilla-auto)
#récupération des variables se3 (variable se3ip)
. /etc/se3/config_m.cache.sh

# partie ldap --> init $ldap_base_dn
. /etc/se3/config_l.cache.sh

DATE=`date +%Y-%m-%d-%H-%M`

#création du répertoire /var/log/clonezilla-auto (utile seulement la première fois).
mkdir -p /var/log/clonezilla-auto


#variable  A ADAPTER A VOTRE SE3 et à décommenter
PXE_PERSO="/tftpboot/pxelinux.cfg/sambaedu-clonezilla/sources/tftpboot/pxelinux.cfg/clonezilla-auto/pxeperso"



#options du script 
#### EN TEST!!!!!######
#L'idée est de pouvoir lancer en une seule ligne de commande une commande pxe, il suffira ensuite de créer une interface graphique en php contenant chaque argument d'option. 
optspec=":-:"
while getopts "$optspec" optchar; do
case "${OPTARG}" in
   help)
echo "Clonezilla-auto permet de lancer des commandes pxe à distance sur un ensemble de machine, ce qui va permettre de cloner des postes essentiellement"
echo " Aide : voir la documentation (https://github.com/SambaEdu/sambaedu-clonezilla) associée (A FAIRE)."
echo ""
echo "Si le script est lancé sans option, il suffit de répondre aux questions posées interactivement.
echo """
echo "Pour gagner du temps ou lancer un clonage de façon non interactive, on peut donner des indications en options de ce script qui prend donc la forme ./clonezilla-auto --option1 valeur1 --option2 valeur2 --option3 valeur3 ..."
echo ""
echo " options disponibles:"
echo " '--mode' suivi du numéro du choix à indiquer dans le menu de départ(ex --mode 2  pour le deuxième choix)"
echo " '--rappel_parc' (sans argument) pour obtenir un rappel des parcs de machine à l'écran"
echo " '--arch' clonezilla64 pour la version  64 bits , ou '--arch clonezilla' pour la version 32 bits"
echo " '--parc' suivi du nom du parc pour lancer le script sur un parc donné, ajouter \| (antislash et pipe) entre les parcs pour en séléctionner plusieurs ex: --parc s217\|s218\|s219 "
echo " '--pxeperso' suivi du nom du fichier pxe à lancer"
echo " '--image' suivi du nom de l'image"
echo " '--ipsamba' suivi de l'ip du partage samba (ex --ipsamba 172.20.0.6)"
echo " '--partage' suivi du nom du partage samba (ex --partage partimag)."
echo " '--user' suivi du nom de l'utilisateur autorisé à lire l'image (ex --user clonezilla)."
echo " '--mdp' suivi du mot de passe de l'utilisateur précédent (ex --mdp mdp 123)."
echo " '--liste_image_samba' pour obtenir à l'écran la liste des images placées sur le partage samba. ATTENTION, les options ipsamba,user,partage et mdp doivent avoir été renseignées pour lancer cette option (ex --ipsamba 172.20.0.6 --partage partimag --user clonezilla --mdp mdp123 --liste_image_samba )."
echo " --noconfirm (sans argument)indique qu'aucune vérification n'est faite (nom de fichier, postes concernés,etc...), utilisation pour un mode  non interactif . "
echo ""
echo "quelques exemples d'utilisation:"
echo ""
echo "./clonezilla-auto.sh --mode 2 --arch clonezilla64 --parc virtualxp "
echo "./clonezilla-auto.sh --mode 4 --parc s219-5 --pxeperso client_multicast --noconfirm (ici la commande pxe appelée 'client_multicast' est envoyée sur le poste s219-5, l'architecture est déclarée dans le fichier pxeperso)."
echo "./clonezilla-auto.sh --mode 2 --parc s219-5  --arch clonezilla64 --image xp_from_adminse3 --noconfirm (ici on déploie l'image appelée xp_from_adminse3 sur un poste s219-4 avec clonezilla64 sans confirmation)"
echo "./clonezilla-auto.sh --mode 3 --arch clonezilla64 --ipsamba 172.20.0.6 --partage partimag --user clonezilla --mdp mdp123 --image xpv1  --parc 111\|110 --noconfirm"
exit 1
;;
h)
echo " Aide : voir la documentation (https://github.com/SambaEdu/sambaedu-clonezilla) associée."
echo " options disponibles:"
echo " '--mode' suivi du numéro du choix à indiquer dans le menu de départ(ex --mode 2  pour le deuxième choix)"
echo " '--rappel_parc' (sans argument) pour obtenir un rappel des parcs de machine à l'écran"
echo " '--arch' clonezilla64 pour la version  64 bits , ou '--arch clonezilla' pour la version 32 bits"
echo " '--parc' suivi du nom du parc pour lancer le script sur un parc donné. Ajouter \| (antislash et pipe) entre les parcs pour en séléctionner plusieurs ex: --parc s217\|s218\|s219  "
echo " '--pxeperso' suivi du nom du fichier pxe à lancer"
echo " '--image' suivi du nom de l'image"
echo " '--ipsamba' suivi de l'ip du partage samba (ex --ipsamba 172.20.0.6)"
echo " '--partage' suivi du nom du partage samba (ex --partage partimag)."
echo " '--user' suivi du nom de l'utilisateur autorisé à lire l'image (ex --user clonezilla)."
echo " '--mdp' suivi du mot de passe de l'utilisateur précédent (ex --mdp mdp 123)."
echo " '--liste_image_samba' pour obtenir l liste des images placées sur le partage samba. ATTENTION, les options ipsamba,user,partage et mdp doivent avoir été renseignées pour lancer cette option (ex --ipsamba 172.20.0.6 --partage partimag --user clonezilla --mdp mdp123 --liste_image_samba )."
echo " --noconfirm (sans argument)indique qu'aucune vérification n'est faite (nom de fichier, postes concernés,etc...), utilisation pour un mode  non interactif . "
echo "quelques exemples d'utilisation:" 
echo "./clonezilla-auto.sh --mode 2 --arch clonezilla64 --parc virtualxp "
echo " ./clonezilla-auto.sh --mode 4 --parc s219-5 --pxeperso client_multicast --noconfirm (ici la commande pxe appelée 'client_multicast' est envoyée sur le poste s219-5, l'architecture est déclarée dans le fichier pxeperso)."
echo "./clonezilla-auto.sh --mode 2 --parc s219-5  --arch clonezilla64 --image xp_from_adminse3 --noconfirm (ici on déploie l'image appelée xp_from_adminse3 sur un poste s219-4 avec clonezilla64 sans confirmation)"

exit 1
;;
mode)
valeur="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
choixlanceur="$valeur"
;;
rappel_parc)
LISTE_PARCS=$(ldapsearch -xLLL  -b ou=Parcs,$ldap_base_dn|grep dn:|sed 's/.*cn=//'|sed 's/,ou.*//' |sed '1d' |sed 1n |sed 's/$/ /'| tr '\n' ' ' |sed 's/>%/>\n/g')
echo "Voici la liste des parcs de machine séparés par un espace"
echo "$LISTE_PARCS"
exit 1
;;
arch)
valeur2="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
CLONEZILLA="$valeur2"
;;
noconfirm)
NOCONFIRM=yes
;;
parc)
valeur3="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
debutip="$valeur3"
;;
pxeperso)
valeur4="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
choix="$valeur4"
;;

image)
valeur5="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
choix="$valeur5"
;;
ipsamba)
valeur6="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
IPSAMBA="$valeur6"
;;
partage)
valeur7="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
PARTAGE="$valeur7"
;;
user)
valeur8="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
UTILISATEUR="$valeur8"
;;
mdp)
valeur9="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
MDP="$valeur9"
;;

liste_image_samba)

#listing_images_samba (fonction définie plus bas...donc non prise en charge
mkdir -p /mnt/liste-image/
LISTE_IMAGE="/mnt/liste-image/"
mount -t cifs //"$IPSAMBA"/"$PARTAGE" "$LISTE_IMAGE" -o user="$UTILISATEUR",password="$MDP" 
#vérification que le montage s'est fait correctement (si le répertoire liste-image n'est pas monté, on quitte le script)
VERIFMONTAGE=$(mount |grep liste-image)
if [ "$VERIFMONTAGE" = ""  ]; then  echo " le montage de partage samba a échoué, veuillez vérifier les paramètres entrés puis relancer le script"
echo "Echec du montage du partage samba, il faut vérifier les données entrées et consulter le fichier de log pour en trouver la cause."
exit
else

echo -e "le montage du partage samba est effectué,recopier parmi la liste suivante le \033[31m\033[1m NOM EXACT\033[0m  de l'image à restaurer."
echo " Montage du partage samba: Montage du partage samba réussi" 
ls   "$LISTE_IMAGE"
umount  "$LISTE_IMAGE"
exit
fi

exit
;;

esac
done




creation_log()
{
mkdir -p /var/log/clonezilla-auto/"$DATE"
mkdir -p /var/log/clonezilla-auto/"$DATE"/machine
touch /var/log/clonezilla-auto/"$DATE"/"$DATE"
#On met des droits de lecture/ecriture à root seulement
chown root:root -R /var/log/clonezilla-auto/
chmod 600 -R /var/log/clonezilla-auto/
LOG="/var/log/clonezilla-auto/$DATE/$DATE"
echo "Journal de l'opération du $DATE" >> "$LOG"
echo "" >> "$LOG"
echo -e "\033[31m  Le compte-rendu de l'opération sera écrit dans le fichier $LOG .\033[0m "

}





logo()
{

if [ "$choixlanceur" = ""  ]; then  
clear
echo "...............................?~~~~=..............~+=.................................................................."
echo "..............................?~~~.?~.............=+++~.................~~=++++:...........................,~~~,........"
echo "..............................~~~...~?...........~++++~...............+++++++++~.......................~~III~=III7~....."
echo ".............................=~~....=~...........++++~~................++++++~~......................~???~.....~7777~..."
echo -e "\033[1mse3se3\033[0m.\033[1mse3se3\033[0m.\033[1mse\033[0m..\033[1m3s\033[0m.\033[1mse3se\033[0m..\033[1mse3se3\033[0m..=~..........~+~~~~.................:+++++~......................~???III=:...?7777~.."
echo -e "\033[1me\033[0m......\033[1me\033[0m....\033[1ms\033[0m.\033[1me\033[0m.\033[1m3s\033[0m.\033[1me\033[0m.\033[1me\033[0m....\033[1ms\033[0m.\033[1me\033[0m....\033[1ms\033[0m..~~I=~~~=?....~......................=+++++...............+~,....~???IIIII~.~77777~.."
echo -e "\033[1m3se3se\033[0m.\033[1m3se3se\033[0m.\033[1m3\033[0m....\033[1m3\033[0m~\033[1m3se3s\033[0m..\033[1m3se3se\033[0m~?+~~?.~~~....~:+++++~~...............~+++++~..............++++++~~???IIIII,.~77777~.."
echo -e ".....\033[1me\033[0m.\033[1ms\033[0m....\033[1m3\033[0m.\033[1ms\033[0m....\033[1ms\033[0m:\033[1ms\033[0m....\033[1m3\033[0m.\033[1ms\033[0m....\033[1m3\033[0m.~+~~~?:~?.~++++++++++++:.....:++++:...+++++~..+++++++++~.,++++~~~.:~=?=~~..~777777~.."
echo -e "\033[1mse3se3\033[0m.\033[1me\033[0m....\033[1ms\033[0m.\033[1me\033[0m....\033[1me\033[0m.\033[1mse3se3\033[0m.\033[1me\033[0m....\033[1ms\033[0m.=~?......~+++:~~~:,~:+++~...~++++++++.+++++~.~~~~~~+++:~.~+++:,..........~II7777~~..."
echo "......................~~~=.........~~......~++++~......:++++:.~+++++++++++++++~.....:++++~..~+++~........~IIIII~~~......"
echo "....................?I~~~?........=~~......+++++++++++++++++~,++++++++++++++++~....:++++~:..?+++~........:~~~~IIIIII=~.."
echo ".....................:~~=?~.......~~~......++++++~~+++++++++~:+++++:~~~~~+++++~...~+++++~..,++++~.............~IIIIIII~."
echo ".....................,:?~~~=.....?~~.......++++++~...~~~~~++~+++~~~......~+++=~...+++++~,..~++++~......:~~.....~??????+."
echo "......................,~~~~??....~::.......:+++++~..:?+~~..:~+++~.......:++++~...~+++++~...+++++~...~=+++???~..~???????~"
echo ".......................,~~+.....=~?........:+++++~.+++++++~..++++~:..:~++++++~...++++++~..~+++++~..~++++++++?~..???????,"
echo ".......................?~~:....+~~..........~++++~.++++++++~.+++++++++++++++~++:.++++++~..+++++++++~+++++++++...?+++++~."
echo ".......................~~~.....~~............++++:.~+++++++~.++++++++++++++++++~,+++++++:++=+++++++~+++++++~:...++++++:."
echo ".......................~~~....~~..............++++~..:++++~~..+++++++++~~+++++?~.++++++++~~+++++~~~~~+++=~.....~+++++:.."
echo ".......................+~:...~?................~=++++++++~~....~~~~~~~~,~:~~~~.~.,++++++~~.++~~~......:++~::=++++++~...."
echo "........................~~+?+....................~~~~~~~~................~.........~~~~~..::~,..........,~~~~~~~,......."
echo "...........................................................................................:............................"
echo ""
echo " Ce script va permettre de:"
echo ""
echo -e "\033[31m(1)\033[0m\033[4mMettre en place un partage samba  appelé \033[1mpartimag\033[0m sur /var/se3, télécharger clonezilla sur le serveur et le rendre accessible automatiquement par adminse3."
echo ""
echo -e "\033[31m(2)\033[0mRestaurer automatiquement une image clonezilla placée dans le partage samba \033[1mpartimag du se3\033[0m sur un parc de machine (ou machine seule)."
echo ""
echo -e "\033[31m(3)\033[0mRestaurer automatiquement une image clonezilla placée dans un partage samba (autre que sur SE3) sur un parc de machine (ou machine seule)."
echo ""
echo -e "\033[31m(4)\033[0mLancer des commandes  pxe personnalisées sur une machine ou un ensemble de machines"
echo ""
echo -e "\033[31m(5)\033[0mVérifier votre version de clonezilla et la mettre à jour le cas échéant"
echo ""
echo ""

creation_log
echo ""
echo -e "Entrer le \033[31mnumero\033[0m correspondant à votre choix ou \033[4mn'importe quoi\033[0m pour quitter, puis la touche entrée."

read  choixlanceur
else
creation_log
echo "vous avez choisi l'option  $valeur en passant par les options" >> "$LOG"
fi

}

#----- -----
# les fonctions

#Les fonctions notées  *_samba proviennent du script pour restaurer une image placée sur un partage samba quelconque
#----- -----

accueil_maj_zesty()
{
#Principe, on télécgarge un fichier version.txt sur le serveur, on compare son contenu avec le contenu du même fichier local. Si le contenu est différent, on supprime le clonezilla existant, on télécharge deux archives que l'on décompresse
#Si clonezilla n'a jamais ét installé, il faut créer les répertoires /var/se3/clonezilla et /var/se3/clonezilla64
mkdir -p /var/se3/clonezilla
mkdir -p /var/se3/clonezilla64

#Suppression de l'ancien clonezilla i386
#On télécharge le fichier indiquant la version présente sur le serveur
cd "$TEMP"
wget https://edu-nuage.ac-versailles.fr/s/8UWvQ2I3D8bsk7I/download
mv download version-serveur.txt
VERSION_SERVEUR=$(cat version-serveur.txt)
VERSION_LOCALE=$(cat /var/se3/clonezilla64/version-locale.txt)

#Si les deux versions sont différentes, alors le script va  supprimer l'ancien dispositif, et recréer un nouveau
if [ "$VERSION_SERVEUR" != "$VERSION_LOCALE"  ]; then  echo "Vous ne disposez pas de la dernière version de clonezilla" 

#Suppression de l'ancien clonezilla i386
#On télécharge le fichier indiquant la version présente sur le serveur


cd /tftpboot/
unlink clonezilla

cd /var/se3
rm -Rf clonezilla/*

#Récupération de la nouvelle version basée sur Ubuntu
cd /var/se3/clonezilla
wget https://edu-nuage.ac-versailles.fr/s/5iPV6MgH1aPkkHd/download
mv download clonezilla.zip
unzip clonezilla.zip
rm -f clonezilla.zip
cd /tftpboot/
ln -s /var/se3/clonezilla/ clonezilla

#On refait la même chose avec clonezilla version AMD64

cd /tftpboot/
unlink clonezilla64

cd /var/se3
rm -Rf clonezilla64/*

#Récupération de la nouvelle version basée sur Ubuntu Zesty AMD64
cd /var/se3/clonezilla64
wget https://edu-nuage.ac-versailles.fr/s/iB4gRVIPcDaNuvv/download
mv download clonezilla64.zip
unzip clonezilla64.zip
rm -f clonezilla64.zip
cd /tftpboot/
ln -s /var/se3/clonezilla64/ clonezilla64
cd /var/se3/clonezilla64
#On créer un fichier VERSIONLOCALE pour vérifier plus tard si la dernière version est bien celle présente sur le se3
wget https://edu-nuage.ac-versailles.fr/s/8UWvQ2I3D8bsk7I/download
mv download version-locale.txt

#On remet le fichier de test qui servira à l'interface

cat <<EOF>> /var/se3/clonezilla/script_clonezilla_test.sh

#!/bin/bash
echo "Test clonezilla: $(date +%Y%m%d%H%M%S)">>/tmp/test_clonezilla.txt

EOF
chmod u+x /var/se3/clonezilla/script_clonezilla_test.sh
echo "La dernière version de clonezilla a été installée"

exit
else
echo "Vous disposez déjà de la dernière version de clonezilla présente sur le serveur"
fi

}


accueil_mise_en_place()
{
echo " le se3 a pour ip: $se3ip"
echo " ce script  permet de créer un partage partimag sur le se3"
echo " Ce partage sera accéssible pour adminse3 et admin"
echo " Ensuite, le dispositif clonezilla sera mis en place, puis modifié de façon à ce qu'adminse3 puisse s'y connecter automatiquement"
PLACE=$(df -h /var/se3)
echo " La partition /var/se3 est dans l'état: "$PLACE" "
}

accueil_samba()
{
 #On demande à l'utilisateur quelle image restaurer parmi celles qui sont présentes dans le répertoire image
# On affiche une liste de type d images ( dans un répertoire): on demande quel type d'image sera à restaurer: il faudra donc creer un fichier commande-pxe-parc (appelé M72-tertaire par ex) pour chaque type d image.
clear
echo "Ce script permet de restaurer une image clonezilla existante  sur un/plusieurs postes du réseau"
echo ""
echo "Les images existantes doivent être stockées sur un partage samba "
echo ""
echo "Les postes doivent avoir le wakeonlan d'activé et un boot par défaut en pxe "
    }

accueil_se3()
{
 #On demande à l'utilisateur quelle image restaurer parmi celles qui sont présentes dans le répertoire image
# On affiche une liste de type d images ( dans un répertoire): on demande quel type d'image sera à restaurer: il faudra donc creer un fichier commande-pxe-parc (appelé M72-tertaire par ex) pour chaque type d image.
clear
echo "Ce script permet de restaurer une image clonezilla existante  sur un/plusieurs postes du réseau"
echo ""
echo -e "Les images existantes doivent être stockées sur le partage \033[31m "partimag"\033[0m créé sur le se3 par le script de mise en place (choix n°1 du script "clonezilla-auto") "
echo ""
echo "Les postes doivent avoir le wakeonlan d'activé et un boot par défaut en pxe "
}
accueil_pxeperso()
{
#On demande à l'utilisateur quel fichier de  consigne pxe contenant les indications pour restaurer  parmi ceux qui sont présents dans le répertoire pxeperso
# On affiche une liste des commandes personnalises dans le répertoire): on demande laquelle sera à appliquer:
#il faudra donc creer un fichier commande-pxe pour chaque type de poste (appelé M72-tertaire par ex).
if [ "$choix" = "" ] ; then
clear
echo " Ce script permet d'envoyer une consigne de boot par pxe(par exemple restaurer une image clonezilla existante, faire une sauvegarde locale)  sur un/plusieurs postes"
echo "Les postes doivent avoir le wakeonlan d'activé, un boot par défaut en pxe "
echo "recopier parmi la liste suivante la commande pxe à envoyer ( type d'image à restaurer dans le cadre de clonezilla) "
#la liste des fichiers de commande pxe est placée dans le répertoire pxeperso, son contenu va être lu ici.
ls  "$PXE_PERSO"
read choix
else
echo " Lancement de la commande pxeperso appelée "$choix" par option --pxeperso "$choix" " >> "$LOG"
fi

echo "" >> "$LOG"
echo " Voux avez choisi la commande pxe-perso appelée $choix" >> "$LOG"

if [ "$NOCONFIRM" = "yes" ]; then echo "aucune confirmation de l'exactitude du choix du pxeperso n'a été demandée par option --noconfirm  " >> "$LOG"
else

#On vérifie que ce qui a été tapé correspond bien à une image existante
VERIF=$(ls "$PXE_PERSO" |grep "$choix")
#si ce qui a été  tapé ne correspond à aucune ligne de la liste, alors le script s'arrête.
if [ "$VERIF" = ""  ]; then  echo "pas d'image choisie ou image inexistante, le script est arrêté" >> "$LOG"
exit
else
echo "les commandes pxe personnalisées contenues dans  $choix seront envoyées sur les postes"
fi
fi
}
creation_partage()
{
echo -e " Voulez vous installer un partage samba situé dans /var/se3/partimag ? répondre  \033[1moui pour valider ou n'importe quoi d'autre pour sauter cette étape "
read reponse1

if [ "$reponse1" = "oui"  ]; then  echo "Création du partage samba "
mkdir -p /var/se3/partimag/

cat <<EOF>> /etc/samba/smb_etab.conf

[partimag]
        comment = images_clonezilla
        path    = /var/se3/partimag
        read only       = No
        valid users     = adminse3
        admin users     = adminse3
#</partimag>

EOF

chown -R admin:admins /var/se3/partimag
chmod -R 775 /var/se3/partimag/

#On relance le service samba
/etc/init.d/samba restart
echo "Le partage samba  'partimag' est maintenant fonctionnel et accessible par adminse3"
else
clear
echo "Le partage samba n'a pas été créé, passage à l'étape suivante"
fi
}

modif_clonezilla()
{
#etape 2
#On vérifie que clonezilla est bien installé
VERIF=$(ls -l /var/se3/ |grep clonezilla )
if [ "$VERIF" = ""  ]; then  echo " Clonezilla n'est pas installé sur le se3, l'archive va être téléchargée."
#on lance le script de téléchargement de clonezilla
accueil_maj_zesty

else
clear
echo "clonezilla est déjà installé sur le se3, pas besoin de le retélécharger."
fi

#etape 3
#on va modifier le livecd contenu dans le fichier filesystem.squashfs
#on installe le paquet squashfs-tools
apt-get install -y --force-yes squashfs-tools

#Modification du livecd clonezilla i386
echo "Voulez-vous modifier le livecd Clonezilla pour qu'adminse3 puisse se connecter automatiquement au partage samba PARTIMAG placé dans /var/se3/partimag ?"
echo "taper OUI pour proceder à cette modification ou autre chose pour quitter"
read demandemodif

if [ "$demandemodif" = "OUI"  ]; then  echo "Modification des fichiers de clonezilla, cela prendra un certain temps..."

cd /var/se3/clonezilla
mkdir -p /var/se3/temp/
cp /var/se3/clonezilla/filesystem.squashfs /var/se3/temp/
mv /var/se3/clonezilla/filesystem.squashfs  /var/se3/clonezilla/filesystem.squashfs-sav
cd /var/se3/temp/
unsquashfs filesystem.squashfs 2>> "$LOG"
#le fichier filesystem est décompressé dans un sous-répertoire squashfs-root, le fichier  filesystem.squashfs n'est donc plus utile
rm -f /var/se3/temp/filesystem.squashfs
#on va ensuite ajouter au livecd un fichier credentials situé dans /root du livecd contenant login et mdp d'adminse3
cd /var/se3/temp/squashfs-root/root/
touch credentials

cat <<EOF>> /var/se3/temp/squashfs-root/root/credentials
username=adminse3
password=$xppass
EOF

#On refabrique le fichier filesystem.squashfs
cd /var/se3/temp/
mksquashfs squashfs-root filesystem.squashfs -b 1024k -comp xz -Xbcj x86 -e boot 2>> "$LOG"
rm -Rf squashfs-root
mv /var/se3/temp/filesystem.squashfs /var/se3/clonezilla/filesystem.squashfs
chmod 444 /var/se3/clonezilla/filesystem.squashfs
touch /var/se3/clonezilla/modif_ok
rm -Rf /var/se3/temp/


#Modification du livecd clonezilla 64
cd /var/se3/clonezilla64
mkdir -p /var/se3/temp/
cp /var/se3/clonezilla64/filesystem.squashfs /var/se3/temp/
mv /var/se3/clonezilla64/filesystem.squashfs  /var/se3/clonezilla64/filesystem.squashfs-sav
cd /var/se3/temp/
unsquashfs filesystem.squashfs 2>> "$LOG"
#le fichier filesystem est décompressé dans un sous-répertoire squashfs-root, le fichier  filesystem.squashfs n'est donc plus utile
rm -f /var/se3/temp/filesystem.squashfs
#on va ensuite ajouter au livecd un fichier credentials situé dans /root du livecd contenant login et mdp d'adminse3
cd /var/se3/temp/squashfs-root/root/
touch credentials

cat <<EOF>> /var/se3/temp/squashfs-root/root/credentials
username=adminse3
password=$xppass
EOF

#On refabrique le fichier filesystem.squashfs
cd /var/se3/temp/
mksquashfs squashfs-root filesystem.squashfs -b 1024k -comp xz -e boot 2>> "$LOG"
rm -Rf squashfs-root
mv /var/se3/temp/filesystem.squashfs /var/se3/clonezilla64/filesystem.squashfs
chmod 444 /var/se3/clonezilla64/filesystem.squashfs
touch /var/se3/clonezilla/modif_ok
rm -Rf /var/se3/temp/

else
echo  "Pas de modification, fin du script."
exit
fi

}

ajout_dans_menu_pxe()
{
#etape 4, on va ajouter dans le menu perso.menu l'intrée clonezilla avec le montage du partage déjà fait
cat <<EOF>> /tftpboot/pxelinux.cfg/perso.menu
label Clonezilla-live
MENU LABEL restauration d'une image (sur se3)
KERNEL clonezilla64/vmlinuz
APPEND initrd=clonezilla64/initrd.img boot=live config noswap nolocales edd=on nomodeset  ocs_prerun="mount -t cifs //$ipse3/partimag /home/partimag/ -o credentials=/root/credentials"  ocs_live_run="ocs-sr  -e1 auto -e2  -r -j2  -p reboot restoredisk  ask_user sda" ocs_live_extra_param="" keyboard-layouts="fr" ocs_live_batch="no" locales="fr_FR.UTF-8" vga=788 nosplash noprompt fetch=tftp://$ipse3/clonezilla64/filesystem.squashfs

label Clonezilla-live
MENU LABEL creation d'une image (sur se3)
KERNEL clonezilla64/vmlinuz
APPEND initrd=clonezilla64/initrd.img boot=live config noswap nolocales edd=on nomodeset  ocs_prerun="mount -t cifs //$ipse3/partimag /home/partimag/ -o credentials=/root/credentials"  ocs_live_run="ocs-sr  -q2 -c -j2 -z1 -i 4096   -p reboot savedisk  ask_user sda" ocs_live_extra_param="" keyboard-layouts="fr" ocs_live_batch="no" locales="fr_FR.UTF-8" vga=788 nosplash noprompt fetch=tftp://"$ipse3"/clonezilla64/filesystem.squashfs

label Clonezilla-live
MENU LABEL restauration d'une image x86 (sur se3)
KERNEL clonezilla/vmlinuz
APPEND initrd=clonezilla/initrd.img boot=live config noswap nolocales edd=on nomodeset  ocs_prerun="mount -t cifs //$ipse3/partimag /home/partimag/ -o credentials=/root/credentials"  ocs_live_run="ocs-sr  -e1 auto -e2  -r -j2  -p reboot restoredisk  ask_user sda" ocs_live_extra_param="" keyboard-layouts="fr" ocs_live_batch="no" locales="fr_FR.UTF-8" vga=788 nosplash noprompt fetch=tftp://$ipse3/clonezilla/filesystem.squashfs

label Clonezilla-live
MENU LABEL creation d'une image x86 (sur se3)
KERNEL clonezilla/vmlinuz
APPEND initrd=clonezilla/initrd.img boot=live config noswap nolocales edd=on nomodeset  ocs_prerun="mount -t cifs //$ipse3/partimag /home/partimag/ -o credentials=/root/credentials"  ocs_live_run="ocs-sr  -q2 -c -j2 -z1 -i 4096   -p reboot savedisk  ask_user sda" ocs_live_extra_param="" keyboard-layouts="fr" ocs_live_batch="no" locales="fr_FR.UTF-8" vga=788 nosplash noprompt fetch=tftp://"$ipse3"/clonezilla/filesystem.squashfs




EOF
}

choix_clonezilla()
{
if [ "$CLONEZILLA" = ""  ]; then
echo " Vous devez choisir si vous voulez utiliser la version 32 bits (clonezilla), ou la version 64 bits (clonezilla64) "
echo -e "Taper \033[31mclonezilla\033[0m  ou   \033[31mclonezilla64\033[0m puis appuyer sur entrée ."
read CLONEZILLA
echo "" >> "$LOG"
echo "Vous avez choisi la version $CLONEZILLA" >> "$LOG"
else
echo " version de clonezilla choisie par l'option arch $CLONEZILLA" >> "$LOG"
fi
}

prealable_samba()
{
#creation du répertoire de montage pour la première utilisation et mise en variable
mkdir -p /mnt/liste-image/
LISTE_IMAGE="/mnt/liste-image/"
}

prealable_se3()
{
#creation du répertoire de montage pour la première utilisation et mise en variable
LISTE_IMAGE="/var/se3/partimag/"
}


choix_samba()
{
#L'utilisateur doit entrer l'ip du partage samba, le nom du partage, le login de l'utilisateur et le mdp, sauf si les données ont été indiquées en options
if [ "$IPSAMBA" = ""  ]; then
echo "" 
echo -e "\033[34mEntrer l'ip du partage samba\033[0m (ex  172.20.0.6)"
read IPSAMBA
echo "ip du partage samba choisi: $IPSAMBA" >> "$LOG"
else
echo "ip du partage samba choisi par option --ipsamba $IPSAMBA" >> "$LOG"
fi

if [ "$PARTAGE" = ""  ]; then
echo -e "\033[34mEntrer le nom du partage samba\033[0m  (ex partimag) "
read PARTAGE
echo "Nom du partage samba choisi: $PARTAGE" >> "$LOG"
else
echo "Nom du partage samba choisipar option --partage $PARTAGE" >> "$LOG"
fi

if [ "$UTILISATEUR" = ""  ]; then
echo -e "\033[34mEntrer le nom d'un utilisateur autorisé à lire sur le partage\033[0m (ex clonezilla)"
read UTILISATEUR
echo "Nom d'utilisateur choisi pour lire les images dans le partage samba : $UTILISATEUR" >> "$LOG"
else
echo "Nom d'utilisateur choisi pour lire les images dans le partage samba par option --user  $UTILISATEUR" >> "$LOG"
fi

if [ "$MDP" = ""  ]; then
echo -e "\033[34mEntrer le mot de passe de l'utilisateur\033[0m  (le mot de passe n'apparait pas sur l'écran )"
read -s MDP
else echo "mot de passe entré  par option --mdp" >> "$LOG"
fi
}
montage_samba()
{
echo " le partage samba est monté provisoirement dans $LISTE_IMAGE"
#le partage samba contenant les images est monté dans le répertoire liste_image juste pour établir le fichier  contenant la liste des images disponibles.
echo "Montage du partage samba" >> "$LOG"
mount -t cifs //$IPSAMBA/$PARTAGE $LISTE_IMAGE -o user=$UTILISATEUR,password=$MDP 2>> "$LOG"
#vérification que le montage s'est fait correctement (si le répertoire liste-image n'est pas monté, on quitte le script)
VERIFMONTAGE=$(mount |grep liste-image)
if [ "$VERIFMONTAGE" = ""  ]; then  echo " le montage de partage samba a échoué, veuillez vérifier les paramètres entrés puis relancer le script"
echo "" >> "$LOG"
echo "Résultat du montage du partage samba sur le se3" >> "$LOG"
echo "Echec du montage du partage samba, il faut vérifier les données entrées et consulter le fichier de log pour en trouver la cause."
echo "Echec du montage du partage samba, voir plus haut le message d'erreur affiché par la commande de montage." >> "$LOG"
rm -Rf "$TEMP"
exit
else
clear
echo -e "le montage du partage samba est effectué dans $LISTE_IMAGE."
echo " Montage du partage samba: Montage du partage samba réussi" >> "$LOG"
fi
}

#on crée une fonction  permettant de faire simplement le listing des images placées sur le partage samba (utile en cas d'utilisattion en mode non interactif)
listing_images_samba()
{
mount -t cifs //$IPSAMBA/$PARTAGE $LISTE_IMAGE -o user=$UTILISATEUR,password=$MDP 2>> "$LOG"
#vérification que le montage s'est fait correctement (si le répertoire liste-image n'est pas monté, on quitte le script)
VERIFMONTAGE=$(mount |grep liste-image)
if [ "$VERIFMONTAGE" = ""  ]; then  echo " le montage de partage samba a échoué, veuillez vérifier les paramètres entrés puis relancer le script"
echo "" >> "$LOG"
echo "Résultat du montage du partage samba sur le se3" >> "$LOG"
echo "Echec du montage du partage samba, il faut vérifier les données entrées et consulter le fichier de log pour en trouver la cause."
echo "Echec du montage du partage samba, voir plus haut le message d'erreur affiché par la commande de montage." >> "$LOG"
rm -Rf "$TEMP"
exit
else
clear
echo "le montage du partage samba est effectué dans $LISTE_IMAGE"
echo " Montage du partage samba: Montage du partage samba réussi" >> "$LOG"
ls   "$LISTE_IMAGE"
exit
fi
}

choix_image_samba()
{
if [ "$choix" = ""  ]; then

echo "" >> "$LOG"
echo " Choix d'une image à restaurer:" >> "$LOG"
# on affiche la liste des images disponibles sur le partage.
ls   "$LISTE_IMAGE"
#la liste des  images est écrite dans un fichier liste 
ls   "$LISTE_IMAGE" > "$TEMP"/liste
echo "" >> "$LOG"
echo "Voici la liste des images disponibles: $LISTE_IMAGES" >> "$LOG"
echo -e "le montage du partage samba est effectué,recopier parmi la liste suivante le \033[31m\033[1m NOM EXACT\033[0m  de l'image à restaurer."
read choix
echo " image choisie par l'utilisateur: $choix" >> "$LOG"
#On démonte le partage samba du se3
echo "démontage du partage samba sur le se3" >> "$LOG"
umount  "$LISTE_IMAGE"  2>> "$LOG"
#On vérifie que ce qui a été tapé correspond bien à une image existante
VERIF=$(cat $TEMP/liste |grep $choix)
if [ "$VERIF" = ""  ]; then  echo "pas d'image choisie ou image inexistante, le script est arrêté"
echo "Pas d'image choisie ou image inexistante: script arreté!" >> "$LOG"
rm -Rf "$TEMP"
exit
else
clear
echo -e "L'image appelée \033[31m$choix \033[0m a été choisie."
fi
else
echo "Image choisie par option --image $image" >> "$LOG"
fi
}

choix_image_se3()
{


if [ "$choix" = "" ]; then 
#choix étant ide, il n'a pas été indiqué par option dans le script.
# on vérifie qu'il y a bien une image à restaurer sur le partage (on va voir directement le contenu de /var/se3/partimag/).
ls "$LISTE_IMAGE"

echo "Liste des images disponibles" >> "$LOG"
ls "$LISTE_IMAGE" >> "$LOG"
ls "$LISTE_IMAGE" > "$TEMP"/liste 

if [ "ls $LISTE_IMAGE" = ""  ]; then echo " pas d'image dans le répertoire /var/se3/partimag/"
exit
else
clear
#echo -e "Recopier parmi la liste suivante le \033[31m\033[1m NOM EXACT\033[0m  de l'image à restaurer."
fi

#la liste des  images est écrite dans un fichier liste
echo -e "Recopier parmi la liste suivante le \033[31m\033[1m NOM EXACT\033[0m  de l'image à restaurer."
ls   "$LISTE_IMAGE"
ls   "$LISTE_IMAGE" > "$TEMP"/liste
read choix
echo " image choisie par l'utilisateur: $choix" >> "$LOG"
else
echo "Liste des images disponibles sur le se3: $LISTE_IMAGE" >> "$LOG"
echo "ls $LISTE_IMAGE" >> "$LOG"
echo " image choisie par l'utilisateur: "$choix" en utilisant l'option --image "$choix""  >> "$LOG"
ls   "$LISTE_IMAGE" > "$TEMP"/liste
fi

if [ "$NOCONFIRM" = "yes" ]; then 
echo " Option --noconfirm ; il n'y a donc  pas de vérification sur le choix du nom de l'image à déployer. " >> "$LOG"
else
#On vérifie que ce qui a été tapé correspond bien à une image existante
VERIF=$(cat "$TEMP"/liste |grep "$choix")
if [ "$VERIF" = ""  ]; then  echo "pas d'image choisie ou image inexistante, le script est arrêté"
#rm -Rf "$TEMP"
exit
else
clear
echo -e "L'image appelée \033[31m$choix \033[0m a été choisie."
fi
fi
}


creation_pxe_perso_samba()
{
# On peut maintenant créer un fichier de commande pxe personnalisé pour le clonage clonezilla
cat <<EOF> "$TEMP"/pxe-perso
# Script de boot pour personnalisé: image déployée = "$choix" 

# Echappatoires pour booter sur le DD:
label 0
   localboot 0x80
label a
   localboot 0x00
label q
   localboot -1
label disk1
   localboot 0x80
label disk2
  localboot 0x81

label clonezilla
#MENU LABEL Clonezilla restore "$choix" (partimag)
KERNEL $CLONEZILLA/vmlinuz
APPEND initrd=$CLONEZILLA/initrd.img boot=live config noswap nolocales edd=on nomodeset  ocs_prerun="mount -t cifs //$IPSAMBA/$PARTAGE /home/partimag/ -o user=$UTILISATEUR,password=$MDP "  ocs_live_run="ocs-sr  -e1 auto -e2  -r -j2 -scr -p reboot restoredisk  $choix sda" ocs_live_extra_param="" keyboard-layouts="fr" ocs_live_batch="no" locales="fr_FR.UTF-8" vga=788 nosplash noprompt fetch=tftp://$se3ip/$CLONEZILLA/filesystem.squashfs

# Choix de boot par défaut:
default clonezilla

# On boote après 6 secondes:
timeout 60

# Permet-on à l'utilisateur de choisir l'option de boot?
# Si on ne permet pas, le timeout n'est pas pris en compte.
prompt 1
EOF

echo "Voici le contenu  de la commande PXE créée par le script" >> "$LOG"
cat "$TEMP"/pxe-perso >> "$LOG"
echo "" >> "$LOG"

}

creation_pxe_perso_se3()
{
# On peut maintenant créer un fichier de commande pxe personnalisé pour le clonage clonezilla
cat <<EOF> "$TEMP"/pxe-perso
# Script de boot pour personnalisé: image déployée = "$choix"

# Echappatoires pour booter sur le DD:
label 0
   localboot 0x80
label a
   localboot 0x00
label q
   localboot -1
label disk1
   localboot 0x80
label disk2
  localboot 0x81

label clonezilla
#MENU LABEL Clonezilla restore "$choix" (se3)
KERNEL $CLONEZILLA/vmlinuz
APPEND initrd=$CLONEZILLA/initrd.img boot=live config noswap nolocales edd=on nomodeset  ocs_prerun="mount -t cifs //$se3ip/partimag /home/partimag/ -o credentials=/root/credentials "  ocs_live_run="ocs-sr  -e1 auto -e2  -r -j2 -scr -p reboot restoredisk  $choix sda" ocs_live_extra_param="" keyboard-layouts="fr" ocs_live_batch="no" locales="fr_FR.UTF-8" vga=788 nosplash noprompt fetch=tftp://$se3ip/$CLONEZILLA/filesystem.squashfs

# Choix de boot par défaut:
default clonezilla

# On boote après 6 secondes:
timeout 60

# Permet-on à l'utilisateur de choisir l'option de boot?
# Si on ne permet pas, le timeout n'est pas pris en compte.
prompt 1
EOF
echo "Voici le contenu  de la commande PXE créée par le script" >> "$LOG"
cat "$TEMP"/pxe-perso >> "$LOG"
echo "" >> "$LOG"
}


maj_machines()
{
#On génère le nouveau fichier d'inventaire d'après la branche computer ldap .
echo "le script génère le nouveau fichier d'inventaire des machines( cela prendra quelques secondes)"

##### Script de génération du fichier de correspondance NOM;IP;MAC;PARCS #####
#
# Auteur : Stephane Boireau (Bernay/Pont-Audemer (27))
#
## $Id$ ##
# modifié par Marc Bansse pour générer l'inventaire simple dans le script /tftpboot/pxelinux.cfg/clonezilla-auto/temp/ et ajouter les parcs dans lequels une machine est inscrite.


fich_nom_ip_mac_parcs="$TEMP/inventaire.csv"

BASE=$(grep "^BASE" /etc/ldap/ldap.conf | cut -d" " -f2 )
ldapsearch -xLLL -b ou=computers,$ldap_base_dn cn | grep ^cn | cut -d" " -f2 | while read nom
do
        if [ ! -z $(echo ${nom:0:1} | sed -e "s/[0-9]//g") ]; then
                # PB: on récupère les cn des entrées machines aussi (xpbof et xpbof$)
                ip=$(ldapsearch -xLLL -b ou=computers,$ldap_base_dn cn=$nom ipHostNumber | grep ipHostNumber | cut -d" " -f2)
                mac=$(ldapsearch -xLLL -b ou=computers,$ldap_base_dn cn=$nom macAddress | grep macAddress | cut -d" " -f2)
                parcs=$( ldapsearch -xLLL  -b ou=Parcs,$ldap_base_dn | sed -e '/./{H;$!d;}' -e 'x;/'$nom'/!d;'|grep dn: |sed 's/.*cn=//' |sed 's/,ou.*//'|sed 1n | tr '\n' ' ' |sed 's/>%/>\n/g')
                if [ ! -z "$ip" -a ! -z "$mac" ]; then
                        echo "$ip;$nom;$mac;$parcs" >> $fich_nom_ip_mac_parcs

                fi
        fi
done

echo "Les fichiers ont été générés dans $TEMP"
echo "Terminé."

#on a ainsi placé dans le répertoire temp un export des entrées computer du ldap.  Chaque ligne est du genre ip;nom-netbios;mac;parcs   (ex:172.20.50.101;virtualxp1;08:00:27:0e:5a:d0;m72e sciences)

echo ""
#On effectue une recherche ldap pour  afficher l'ensemble des parcs  mis en place. Chaque parc est espacé d'un autre.
LISTE_PARCS=$(ldapsearch -xLLL  -b ou=Parcs,$ldap_base_dn|grep dn:|sed 's/.*cn=//'|sed 's/,ou.*//' |sed '1d' |sed 1n |sed 's/$/ /'| tr '\n' ' ' |sed 's/>%/>\n/g')
}

choix_machines()
{
if [ "$debutip" = "" ]; then

echo -e "\033[4mPour rappel, voici la liste des parcs\033[0m"
echo "$LISTE_PARCS"
echo""
echo -e "Entrer \033[1mle nom du parc\033[0m (ex sciences) ou \033[1mles premiers octets\033[0m de l'ip du parc à cloner (ex 172.20.50.)\033[0m"
echo -e "S'il faut restaurer seulement \033[1mun poste\033[0m, on entrera l'adresse ip (ex 172.20.50.101) ou le nom  du poste (ex s218-2)" 
echo -e "On peut choisir plusieurs parcs en même temps en les séparant par un antislash suivi d'un pipe \033[1m\|\033[0m comme dans l'exemple suivant: s217\|s218\|s219"
read debutip
else
echo "vous avez choisi comme parametre de recherche de machine: $debutip" >> "$LOG"
fi

echo "vous avez choisi comme parametre de recherche de machine: $debutip" >> "$LOG"
# on affiche uniquementt les entrées du fichier d'export contenant ce début d'ip
cat  $TEMP/inventaire* |grep -E "$debutip" > "$TEMP"/exportauto
#On a créé un fichier "exportauto" à partir du fichier d'inventaire dhcp qui contient quatre colonnes ip;nom-netbios;mac;parcs   (ex:172.20.50.101;virtualxp1;08:00:27:0e:5a:d0;m72e sciences) 
echo "voici  le contenu du fichier exportauto qui contient les éléments  ip:nom:mac:parcs" >> "$LOG"
cat  "$TEMP"/exportauto >> "$LOG"

#on ne garde que la deuxième colonne pour avoir la liste des postes sensés être clonés qu'il faudra vérifier.
cut -d';' -s -f2   "$TEMP"/exportauto > "$TEMP"/verifpostes


#Il faut maintenant confirmer que les postes à restaurer sont bien ceux qui sont attendus.
echo " vous avez choisi les postes dont l'ip est/commence par \033[34mA"$debutip"\033[0m. "

echo -e " \033[31mATTENTION, le mdp du partag samba va apparaitre très brievement en clair sur l'écran des postes lors du montage automatique du serveur\033[0m."
echo -e "\033[1mVeillez à ce que la salle soit vide\033[Om"
POSTES=$(cat "$TEMP"/verifpostes)


clear
#si la liste des postes est vide, c'est qu'aucun ordinateur ne correspond à la demande
if [ "$POSTES" = "" ]; then echo "aucun poste ne correspond à cette demande"
echo "aucun poste ne correspond à cette demande" >> "$LOG"
exit
else echo "les postes suivants seront effacés puis restaurés. "
echo -e "\033[34m"$POSTES"\033[0m"
fi

if [ "$NOCONFIRM" = "yes" ]; then echo "aucune confirmation n'a été demandée par option " >> "$LOG"
else
echo -e "taper \033[31moui\033[0m pour continuer ou \033[34mnano\033[0m pour éditer la liste des postes à restaurer"
echo -e "Pour éditer la liste, il suffit de \033[31msupprimer les lignes entières inutiles \033[0m. On enregistre \033[31m(CTRL+O)\033[0m , suivi de quitter \033[31m(CTRL+X)\033[0m ." 
read REPONSE
fi

#On relance la procédure de vérification avec le nouveau exportauto
if [ "$REPONSE" = nano ]; then  nano "$TEMP"/exportauto 
else echo "On continue"
 fi
cut -d';' -s -f2   "$TEMP"/exportauto > "$TEMP"/verifpostes2
POSTES2=$(cat "$TEMP"/verifpostes2)
echo " voici la liste des postes choisi après vérification" >> "$LOG"
cat  "$TEMP"/verifpostes2 >> "$LOG"
clear


#si la liste des postes est vide, c'est qu'aucun ordinateur ne correspond à la demande
if [ "$POSTES2" = "" ]; then echo "aucun poste ne correspond à cette demande"
echo "aucun poste ne correspond à cette demande" >> "$LOG"
exit
else echo " Plusieurs postes ont été séléctionnés" 
fi

if [ "$NOCONFIRM" = "yes" ]; then echo "aucune confirmation n'a été demandée par option " >> "$LOG"
else
echo ""
echo " Etes-vous sur de vouloir restaurer ces postes?"
echo -e "\033[31m "$POSTES2"\033[0m"
echo -e " \033[4mATTENTION, le mdp du partag samba va apparaitre très brievement en clair sur l'écran des postes lors du montage automatique du serveur, veillez à ce que la salle soit vide\033[0m"
echo -e "taper \033[31moui\033[0m pour continuer ou autre chose pour quitter"
read REPONSE2


# On continue le script uniquement si la réponse oui est faite. tout autre choix provoque l'arret du script.

if [ "$REPONSE2" = oui ]; then  echo "On lance le clonage" 
else
 echo "Clonage annulé"
echo "Vous n'avez pas répondu oui à la vérification, le clonage est annulé ">> "$LOG"
 #on efface les fichiers temporaires créés
rm -f "$TEMP"/*
 exit  
fi
fi
}

generation_variables()
{
#ici, le fichier exportauto a été  édité et contient donc la véritable liste des postes à restaurer
#On le sauvegarde dans log pour vérifier en cas de problème.
echo "Voici le contenu du fichier export-auto contenant la liste non éditée des postes, ip;mac et parcs" >> "$LOG"
cat "$TEMP"/exportauto >> "$LOG"

#on supprime les deux premières colonnes contenant le nom et l'ip pour ne garder que la troisième colonne contenant l'adresse mac.
cut -d';' -s -f3   "$TEMP"/exportauto > "$TEMP"/liste1
echo "voici le contenu du fichier liste1 (seulement adresses mac normalement) " >> "$LOG"
cat "$TEMP"/liste1 >> "$LOG"

#on ne garde que la deuxième colonne pour avoir la liste des postes cloné
cut -d';' -s -f2   "$TEMP"/exportauto > "$TEMP"/postes
echo "Voici le contenu du fichier postes contenant la liste non éditée des postes" >> "$LOG"
cat "$TEMP"/postes >> "$LOG"

# on modifie  le fichier liste1 pour remplacer les ":" par des "-" pour la création du fichier 01-suitedel'adressemac
sed 's/\:/\-/g' "$TEMP"/liste1 > "$TEMP"/listeok
cp "$TEMP"/listeok "$LOG"-mac_tirets
echo "Voici la liste des adresses mac avec des - " >> "$LOG"
cat "$TEMP"/listeok >> "$LOG"

#On place la première adresse mac de la listemac  dans une variable pour créer ensuite le fichier de commande pxe personnalisé du poste.
#toutes les majuscules de l'adresse mac doivent être transformées en minuscules, ou le pxe du poste ne sera pas pris en compte par la machine
mac=$(sed -n "1p" "$TEMP"/listeok | sed 's/.*/\L&/')
#On met en variable le nom du premier poste de la liste pour le lancer avec le script se3 lance_poste
NOM_CLIENT=$(sed -n "1p" "$TEMP"/postes)
}



boucle()
{
#on  crée notre boucle ici: On va supprimer la première ligne de la liste des adresses mac. Dès que le fichier contenant les adresses mac est vide, il y a arret de la boucle
until [ "$mac" = "" ]
do 
 
#le fichier de commande pxe choisi pour les xp est copié dans le répertoire pxelinux.cfg. Il faut ajouter '01'-devant l'adresse mac
cp  "$TEMP"/pxe-perso /tftpboot/pxelinux.cfg/01-"$mac"
cp  "$TEMP"/pxe-perso /var/log/clonezilla-auto/"$DATE"/machine/01-"$mac"-"$NOM_CLIENT"
chmod 644 /tftpboot/pxelinux.cfg/01-*
 

#si le poste est déjà allumé sous windows, on lui envoie un signal de reboot
echo " On envoie un signal de reboot suivi d'un signal d'allumage pour $NOM_CLIENT . Le poste étant soit arreté, soit démarré, il y aura un des deux signaux qui provoquera un  message d'erreur sans importance" 
/usr/share/se3/scripts/start_poste.sh  "$NOM_CLIENT" reboot
/usr/share/se3/scripts/start_poste.sh  "$NOM_CLIENT" wol



#la première ligne du fichier listeok/liste1/postes est à supprimer pour que l'opération continue avec les adresses mac suivantes
sed -i '1d' "$TEMP"/listeok
sed -i '1d' "$TEMP"/liste1
sed -i '1d' "$TEMP"/postes

#On  actualise la vairable mac.
mac=$(sed -n "1p" "$TEMP"/listeok | sed 's/.*/\L&/')

#On actualise les variables NOM_CLIENT
NOM_CLIENT=$(sed -n "1p" "$TEMP"/postes)


done
}

boucle_pxeperso()
{
#on  créer notre boucle ici: On va supprimer la première ligne de la liste des adresses mac. Dès que le fichier contenant les adresses mac est vide, il y a arret de la boucle
until [ "$mac" = "" ]
do

#le fichier de commande pxe choisi pour les xp est copié dans le répertoire pxelinux.cfg. Il faut ajouter '01'-devant l'adresse mac
cp "$PXE_PERSO"/"$choix" /tftpboot/pxelinux.cfg/01-"$mac"
chmod 644  /tftpboot/pxelinux.cfg/01-*
cp "$PXE_PERSO"/"$choix" /var/log/clonezilla-auto/"$DATE"/machine/01-"$mac"-"$NOM_CLIENT"


#Il faut ensuite allumer le poste qui va donc détecter les instructions pxe.
echo " On envoie un signal de reboot suivi d'un signal d'allumage pour $NOM_CLIENT . Le poste étant soit arreté, soit démarré, il y aura un des deux signaux qui provoquera un  message d'erreur sans importance"
/usr/share/se3/scripts/start_poste.sh "$NOM_CLIENT" reboot
/usr/share/se3/scripts/start_poste.sh "$NOM_CLIENT" wol
#la première ligne du fichier listeok est à supprimer pour que l'opération continue avec les adresses mac suivantes. Idem avec les autres fichiers
sed -i '1d' "$TEMP"/listeok
sed -i '1d' "$TEMP"/liste1
sed -i '1d' "$TEMP"/postes

#On actualise la variable en mettant des majuscules dans les adresses mac au lieu des minuscules!
mac=$(sed -n "1p" "$TEMP"/listeok | sed 's/.*/\L&/')

#On actualise la variable.
mac2=$(sed -n "1p" "$TEMP"/liste1)
#On actualise la variable.
NOM_CLIENT=$(sed -n "1p" "$TEMP"/postes)

done
}

fin_script_samba()
{

if [ "$mac" = "" ]; then  echo "On attends deux minutes pour que les postes aient le temps de booter en pxe et de récupérer les consignes"
sleep 2m
else echo " ça continue..."
# Normalement on ne devrait pas avoir  besoin de du if, car cette partie est lancée seulement quand la boucle est terminée
fi


#On attend deux minutes que les ordinateurs se lancent, recoivent leur instruction pour ensuite effacer les fichiers nommés avec l'adresse mac ou le poste se clonera en boucle.
#echo "On attends deux minutes pour que les postes aient le temps de booter en pxe et de récupérer les consignes"
#sleep 2m

#on efface tous les fichiers commecnant par 01- , seuls les fichiers générés par le script  sont donc effacés.
rm -f /tftpboot/pxelinux.cfg/01*
#rm -Rf "$TEMP"
## d'apres flaf ;) - on protège la variable....
TEMP=$(cd "$TEMP" && pwd) && printf '%s\n' "$TEMP" | grep -q '^/tmp/' && \rm -r --one-file-system "$TEMP"

echo " Opération terminée. Vous pouvez consulter le compte-rendu dans le fichier $LOG ."
}

####fin des fonctions###



###############################################################début du programme###########################################################################################

script1()
{
accueil_mise_en_place
creation_partage
modif_clonezilla
ajout_dans_menu_pxe
}


script2()
{
accueil_se3
prealable_se3
choix_clonezilla
choix_image_se3
creation_pxe_perso_se3
maj_machines
choix_machines
generation_variables
boucle
fin_script_samba
}

script3()
{
accueil_samba
prealable_samba
choix_clonezilla
choix_samba
montage_samba
choix_image_samba
creation_pxe_perso_samba
maj_machines
choix_machines
generation_variables
boucle
fin_script_samba
}

script4()
{
accueil_pxeperso
maj_machines
choix_machines
generation_variables
boucle_pxeperso
fin_script_samba
}

script5()
{
accueil_maj_zesty
modif_clonezilla
}

#recuperer_options "$@"
logo
if [ "$choixlanceur" = "1" ]
then
echo "Vous avez choisi de mettre en place un partage samba." >> "$LOG"
script1
exit
elif [ "$choixlanceur" = "2" ]
then
echo "Vous avez choisi de restaurer une image présente sur le se3 sur des postes." >> "$LOG"
script2
elif [ "$choixlanceur" = "3" ]
then
echo "Vous avez choisi de restaurer une image présente sur un partage samba sur des postes." >> "$LOG"
script3
elif [  "$choixlanceur" = "4"  ]
then
echo "Vous avez choisi de lancer des commandes PXE personnalisées  sur des postes." >> "$LOG"
script4
elif [  "$choixlanceur" = "5"  ]
then
echo "Vous avez choisi de vérifier/mettre à jour votre version de clonezilla." >> "$LOG"
script5
else exit
fi


